import Groq from 'groq-sdk';
import { supabase } from '../config/supabase.js';
import {
    obtenerEnfermedades,
    obtenerEnfermedadPorId,
    crearEnfermedad,
    actualizarEnfermedad,
    eliminarEnfermedad,
    asociarProducto,
    desasociarProducto,
    reemplazarProductos
} from '../models/enfermedadmodel.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
const GROQ_MODEL = 'openai/gpt-oss-20b';

// "productos" llega como texto JSON ("[1,2,3]") cuando se envía como formulario.
// Si no viene, devuelve null y no se tocan los vínculos.
const leerIds = (valor) => {
    if (valor === undefined) return null;
    try {
        const ids = typeof valor === 'string' ? JSON.parse(valor) : valor;
        return Array.isArray(ids) ? ids : null;
    } catch {
        return null;
    }
};

export const listarEnfermedades = async (req, res) => {
    try {
        const { data, error } = await obtenerEnfermedades();
        if (error) return res.status(500).json({ error: 'Error al obtener las enfermedades' });
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

export const obtenerEnfermedad = async (req, res) => {
    try {
        const { id } = req.params;
        const { data, error } = await obtenerEnfermedadPorId(id);
        if (error || !data) return res.status(404).json({ error: 'Enfermedad no encontrada' });
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

export const crear = async (req, res) => {
    try {
        const { nombre, descripcion, sintomas, tratamiento, cultivos } = req.body;
        const imagen_url = req.file ? req.file.path : null;

        if (!nombre) {
            return res.status(400).json({ error: 'El nombre es requerido' });
        }

        const { data, error } = await crearEnfermedad({
            nombre, descripcion, sintomas, tratamiento, cultivos, imagen_url
        });
        if (error) return res.status(500).json({ error: 'Error al crear la enfermedad' });

        const ids = leerIds(req.body.productos);
        if (ids) {
            const { error: errorProductos } = await reemplazarProductos(data[0].id, ids);
            if (errorProductos) return res.status(500).json({ error: 'Enfermedad creada, pero falló vincular los productos' });
        }

        return res.status(201).json({ message: 'Enfermedad creada', enfermedad: data[0] });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

export const editar = async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, descripcion, sintomas, tratamiento, cultivos } = req.body;
        const cambios = {};
        if (nombre !== undefined) cambios.nombre = nombre;
        if (descripcion !== undefined) cambios.descripcion = descripcion;
        if (sintomas !== undefined) cambios.sintomas = sintomas;
        if (tratamiento !== undefined) cambios.tratamiento = tratamiento;
        if (cultivos !== undefined) cambios.cultivos = cultivos;
        if (req.file) cambios.imagen_url = req.file.path;

        let enfermedad = null;
        if (Object.keys(cambios).length) {
            const { data, error } = await actualizarEnfermedad(id, cambios);
            if (error) return res.status(500).json({ error: 'Error al actualizar la enfermedad' });
            enfermedad = data[0];
        }

        const ids = leerIds(req.body.productos);
        if (ids) {
            const { error } = await reemplazarProductos(id, ids);
            if (error) return res.status(500).json({ error: 'Error al actualizar los productos recomendados' });
        }

        return res.status(200).json({ message: 'Enfermedad actualizada', enfermedad });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

export const eliminar = async (req, res) => {
    try {
        const { id } = req.params;
        const { error } = await eliminarEnfermedad(id);
        if (error) return res.status(500).json({ error: 'Error al eliminar la enfermedad' });
        return res.status(200).json({ message: 'Enfermedad eliminada' });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

export const vincularProducto = async (req, res) => {
    try {
        const { id } = req.params;
        const { producto_id } = req.body;
        if (!producto_id) return res.status(400).json({ error: 'producto_id es requerido' });

        const { data, error } = await asociarProducto(id, producto_id);
        if (error) return res.status(500).json({ error: 'Error al vincular el producto' });
        return res.status(201).json({ message: 'Producto vinculado como tratamiento', data: data[0] });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

export const desvincularProducto = async (req, res) => {
    try {
        const { id, productoId } = req.params;
        const { error } = await desasociarProducto(id, productoId);
        if (error) return res.status(500).json({ error: 'Error al desvincular el producto' });
        return res.status(200).json({ message: 'Producto desvinculado' });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

// POST /enfermedades/recomendar-productos
// Body: { nombre, descripcion, sintomas, tratamiento, cultivos }
// Responde: { ids: [...] } con ids de productos que EXISTEN en el catálogo.
export const recomendarProductos = async (req, res) => {
    try {
        const { nombre, descripcion, sintomas, tratamiento, cultivos } = req.body;
        if (!nombre) return res.status(400).json({ error: 'El nombre de la enfermedad es requerido' });

        const { data: productos, error } = await supabase
            .from('productos')
            .select('id, nombre, categoria, descripcion');
        if (error) return res.status(500).json({ error: 'Error al consultar el catálogo' });
        if (!productos || productos.length === 0) return res.status(200).json({ ids: [] });

        const catalogo = productos
            .map(p => `${p.id} | ${p.nombre} | ${p.categoria ?? ''} | ${p.descripcion ?? ''}`)
            .join('\n');

        const systemPrompt = `Eres un asesor agronómico de TecnoAgro.
Te doy una enfermedad de cultivos y el catálogo de productos de la tienda.
Elige SOLO productos del catálogo que sirvan para tratar o prevenir esa enfermedad.
Responde ÚNICAMENTE con un JSON con este formato exacto: {"ids":[1,2]}
Usa los ids exactos del catálogo (primera columna). Máximo 5 productos.
Si ningún producto aplica, responde {"ids":[]}. No agregues texto extra.`;

        const userPrompt = `ENFERMEDAD: ${nombre}
DESCRIPCIÓN: ${descripcion || '-'}
SÍNTOMAS: ${sintomas || '-'}
TRATAMIENTO: ${tratamiento || '-'}
CULTIVOS: ${cultivos || '-'}

CATÁLOGO (id | nombre | categoría | descripción):
${catalogo}`;

        const completion = await groq.chat.completions.create({
            model: GROQ_MODEL,
            messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user', content: userPrompt }
            ],
            temperature: 0.2,
            max_tokens: 1000
        });

        const texto = completion.choices[0]?.message?.content ?? '';
        const coincidencia = texto.match(/\{[\s\S]*\}/);
        let sugeridos = [];
        if (coincidencia) {
            try {
                const parsed = JSON.parse(coincidencia[0]);
                if (Array.isArray(parsed.ids)) sugeridos = parsed.ids;
            } catch {
                sugeridos = [];
            }
        }

        // Solo se devuelven ids que existen de verdad en el catálogo.
        const validos = new Map(productos.map(p => [String(p.id), p.id]));
        const ids = [...new Set(sugeridos.map(String))]
            .filter(id => validos.has(id))
            .map(id => validos.get(id));

        return res.status(200).json({ ids });
    } catch (error) {
        console.error('Error en recomendarProductos:', error);
        return res.status(500).json({ error: error.message });
    }
};