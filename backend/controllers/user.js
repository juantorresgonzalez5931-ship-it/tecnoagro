import { obtenerUsuarios, obtenerPorId, actualizarUsuario, eliminarUsuario } from "../models/user.js";

export const getUsuarios = async (req, res) => {
    try {
        const { data, error } = await obtenerUsuarios();
        if (error) return res.status(500).json({ error: "Error al obtener los usuarios" });
        return res.status(200).json({ usuarios: data });
    } catch (error) {
        console.error("Error al obtener los usuarios:", error);
        return res.status(500).json({ error: error.message });
    }
};

export const getUsuarioPorId = async (req, res) => {
    try {
        const { id } = req.params;
        const { data, error } = await obtenerPorId(id);
        if (error || !data) return res.status(404).json({ error: "Usuario no encontrado" });
        return res.status(200).json({ usuario: data });
    } catch (error) {
        console.error("Error al obtener el usuario:", error);
        return res.status(500).json({ error: error.message });
    }
};

export const updateUsuario = async (req, res) => {
    try {
        const { id } = req.params;
        const campos = req.body;

        if (!campos || Object.keys(campos).length === 0) {
            return res.status(400).json({ error: "No se enviaron campos para actualizar" });
        }

        delete campos.rol;
        delete campos.contrasena;

        const { data, error } = await actualizarUsuario(id, campos);
        if (error) return res.status(500).json({ error: "Error al actualizar el usuario" });
        if (!data || data.length === 0) return res.status(404).json({ error: "Usuario no encontrado" });

        return res.status(200).json({
            message: "Usuario actualizado exitosamente",
            usuario: data[0]
        });
    } catch (error) {
        console.error("Error al actualizar el usuario:", error);
        return res.status(500).json({ error: error.message });
    }
};

export const deleteUsuario = async (req, res) => {
    try {
        const { id } = req.params;

        const { data: existe } = await obtenerPorId(id);
        if (!existe) {
            return res.status(404).json({ error: "Usuario no encontrado" });
        }

        const { error } = await eliminarUsuario(id);
        if (error) return res.status(500).json({ error: "Error al eliminar el usuario" });

        return res.status(200).json({ message: `Usuario ${id} eliminado exitosamente` });

    } catch (error) {
        console.error("Error al eliminar el usuario:", error);
        return res.status(500).json({ error: error.message });
    }
};