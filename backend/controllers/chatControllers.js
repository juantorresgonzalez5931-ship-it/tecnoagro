import Groq from 'groq-sdk';
import { supabase } from '../config/supabase.js';
import {
    crearConversacion,
    obtenerConversacionesPorUsuario,
    obtenerConversacionPorId,
    eliminarConversacion,
    crearMensaje,
    obtenerMensajesPorConversacion
} from '../models/chatModel.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

const GROQ_MODEL = 'openai/gpt-oss-20b';

// Arma el system prompt con el catálogo actual desde Supabase
const construirSystemPrompt = async () => {
    const { data: productos, error } = await supabase
        .from('helados')
        .select('nombre, descripcion, precio');

    if (error) {
        console.error('Error al consultar el catálogo:', error.message);
    }

    const catalogoTexto = productos && productos.length > 0
        ? productos.map(p =>
            `- **${p.nombre}**: $${Number(p.precio).toLocaleString('es-CO')} COP | Descripción: ${p.descripcion}`
          ).join('\n')
        : 'No hay productos registrados en este momento.';

    return `Eres el asesor virtual de TecnoAgro.
Eres alegre, amable, coherente y educado.

CATÁLOGO ACTUAL:
${catalogoTexto}

REGLAS DE ATENCIÓN:
1. Si el cliente solo saluda, responde con cortesía sin dar precios ni catálogo completo.
2. Da precios y detalles ÚNICAMENTE cuando el cliente pregunta explícitamente por ellos.
3. Especifica los valores siempre en pesos colombianos ($ COP).
4. Sé conciso y completa tus oraciones.`;
};

const llamarIA = async (historialMensajes) => {
    const systemPrompt = await construirSystemPrompt();

    const messages = [
        { role: 'system', content: systemPrompt },
        ...historialMensajes.map(m => ({
            role: m.sender === 'assistant' ? 'assistant' : 'user',
            content: m.content
        }))
    ];

    const completion = await groq.chat.completions.create({
        model: GROQ_MODEL,
        messages,
        temperature: 0.3,
        max_tokens: 500
    });

    const respuesta = completion.choices[0]?.message?.content;

    if (!respuesta) {
        throw new Error('Groq no devolvió una respuesta válida');
    }

    return respuesta;
};

// POST /chat/mensaje  { usuario_id, conversation_id (opcional), mensaje }
export const enviarMensaje = async (req, res) => {
    try {
        const { usuario_id, conversation_id, mensaje } = req.body;

        if (!usuario_id || !mensaje) {
            return res.status(400).json({ error: 'usuario_id y mensaje son requeridos' });
        }

        let conversacionId = conversation_id;
        if (!conversacionId) {
            const { data: nuevaConv, error: errorConv } = await crearConversacion(usuario_id);
            if (errorConv || !nuevaConv) {
                return res.status(500).json({ error: 'Error al crear la conversación' });
            }
            conversacionId = nuevaConv[0].id;
        }

        await crearMensaje(conversacionId, 'user', mensaje);

        const { data: historial, error: errorHistorial } = await obtenerMensajesPorConversacion(conversacionId);
        if (errorHistorial) {
            return res.status(500).json({ error: 'Error al obtener el historial' });
        }

        const respuestaIA = await llamarIA(historial);

        await crearMensaje(conversacionId, 'assistant', respuestaIA);

        return res.status(200).json({
            conversation_id: conversacionId,
            respuesta: respuestaIA
        });

    } catch (error) {
        console.error('Error en enviarMensaje:', error);
        return res.status(500).json({ error: error.message });
    }
};

// GET /chat/conversaciones?usuario_id=
export const misConversaciones = async (req, res) => {
    try {
        const { usuario_id } = req.query;
        if (!usuario_id) return res.status(400).json({ error: 'usuario_id requerido' });

        const { data, error } = await obtenerConversacionesPorUsuario(usuario_id);
        if (error) return res.status(500).json({ error: 'Error al obtener las conversaciones' });

        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

// GET /chat/conversaciones/:id/mensajes
export const mensajesDeConversacion = async (req, res) => {
    try {
        const { id } = req.params;

        const { data: conversacion } = await obtenerConversacionPorId(id);
        if (!conversacion) return res.status(404).json({ error: 'Conversación no encontrada' });

        const { data, error } = await obtenerMensajesPorConversacion(id);
        if (error) return res.status(500).json({ error: 'Error al obtener los mensajes' });

        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

// DELETE /chat/conversaciones/:id
export const borrarConversacion = async (req, res) => {
    try {
        const { id } = req.params;
        const { error } = await eliminarConversacion(id);
        if (error) return res.status(500).json({ error: 'Error al eliminar la conversación' });
        return res.status(200).json({ message: 'Conversación eliminada' });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};