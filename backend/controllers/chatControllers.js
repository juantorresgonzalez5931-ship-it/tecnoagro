import {
    crearConversacion,
    obtenerConversacionesPorUsuario,
    obtenerConversacionPorId,
    eliminarConversacion,
    crearMensaje,
    obtenerMensajesPorConversacion
} from '../models/chatModel.js';

const SYSTEM_PROMPT = `Eres un asistente experto en agricultura para TecnoAgro. 
Ayudas a los usuarios con dudas sobre cultivos, plagas, enfermedades y productos agrícolas.
Responde de forma clara, breve y práctica.`;

const GEMINI_MODEL = 'gemini-3.6-flash';
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${process.env.GEMINI_API_KEY}`;

// Llama a la API de Gemini con el historial de la conversación
const llamarIA = async (historialMensajes) => {
    
    const contents = historialMensajes.map(m => ({
        role: m.sender === 'assistant' ? 'model' : 'user',
        parts: [{ text: m.content }]
    }));

    const response = await fetch(GEMINI_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            system_instruction: {
                parts: [{ text: SYSTEM_PROMPT }]
            },
            contents
        })
    });

    if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`Error de la API de Gemini: ${response.status} - ${errorBody}`);
    }

    const data = await response.json();
    const respuesta = data.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!respuesta) {
        throw new Error('Gemini no devolvió una respuesta válida');
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

        // 1. Obtener o crear la conversación
        let conversacionId = conversation_id;
        if (!conversacionId) {
            const { data: nuevaConv, error: errorConv } = await crearConversacion(usuario_id);
            if (errorConv || !nuevaConv) {
                return res.status(500).json({ error: 'Error al crear la conversación' });
            }
            conversacionId = nuevaConv[0].id;
        }

        // Guardar el mensaje del usuario (columna real: sender)
        await crearMensaje(conversacionId, 'user', mensaje);

        // Traer el historial completo para dar contexto a la IA
        const { data: historial, error: errorHistorial } = await obtenerMensajesPorConversacion(conversacionId);
        if (errorHistorial) {
            return res.status(500).json({ error: 'Error al obtener el historial' });
        }

        // Llamar a Gemini
        const respuestaIA = await llamarIA(historial);

        // Guardar la respuesta de la IA
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