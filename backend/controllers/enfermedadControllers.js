import {
    obtenerEnfermedades,
    obtenerEnfermedadPorId,
    crearEnfermedad,
    actualizarEnfermedad,
    eliminarEnfermedad,
    asociarProducto,
    desasociarProducto
} from '../models/enfermedadmodel.js';

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
        const { nombre, descripcion, sintomas, tratamiento } = req.body;
        const imagen_url = req.file ? req.file.path : null;

        if (!nombre) {
            return res.status(400).json({ error: 'El nombre es requerido' });
        }

        const { data, error } = await crearEnfermedad({
            nombre, descripcion, sintomas, tratamiento, imagen_url
        });
        if (error) return res.status(500).json({ error: 'Error al crear la enfermedad' });

        return res.status(201).json({ message: 'Enfermedad creada', enfermedad: data[0] });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

export const editar = async (req, res) => {
    try {
        const { id } = req.params;
        const { data, error } = await actualizarEnfermedad(id, req.body);
        if (error) return res.status(500).json({ error: 'Error al actualizar la enfermedad' });
        return res.status(200).json({ message: 'Enfermedad actualizada', enfermedad: data[0] });
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

// Asociar un producto (tratamiento) a una enfermedad
export const vincularProducto = async (req, res) => {
    try {
        const { id } = req.params; // id de la enfermedad
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