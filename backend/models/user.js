import { supabase } from "../config/supabase.js";

// crear el usuario
export const crearUsuario = async (nombre, correo_electronico, contrasena, telefono, fecha_nacimiento, rol) => {
    const { data, error } = await supabase
        .from('usuarios')
        .insert({
            nombre,
            correo_electronico,
            contrasena,
            telefono,
            fecha_nacimiento,
            rol: rol || 'usuario'
        })
        .select('id, nombre, correo_electronico, telefono, fecha_nacimiento, rol, contrasena');

    if (error) {
        console.error("Error en Supabase:", error);
    }

    return { data, error };
};

// obtener todos los usuarios
export const obtenerUsuarios = async () => {
    const { data, error } = await supabase
        .from('usuarios')
        .select('id, nombre, correo_electronico, telefono, fecha_nacimiento, rol');
    return { data, error };
};

// buscar el usuario por correo para el login
export const obtenerPorEmail = async (correo_electronico) => {
    const { data, error } = await supabase
        .from('usuarios')
        .select('id, nombre, correo_electronico, telefono, fecha_nacimiento, rol, contrasena')
        .eq('correo_electronico', correo_electronico)
        .single();
    return { data, error };
};

// obtener un usuario por ID
export const obtenerPorId = async (id) => {
    const { data, error } = await supabase
        .from('usuarios')
        .select('id, nombre, correo_electronico, telefono, fecha_nacimiento, rol')
        .eq('id', id)
        .single();
    return { data, error };
};

// actualizar un usuario
export const actualizarUsuario = async (id, campos) => {
    const { data, error } = await supabase
        .from('usuarios')
        .update(campos)
        .eq('id', id)
        .select('id, nombre, correo_electronico, telefono, fecha_nacimiento, rol');
    return { data, error };
};

// eliminar un usuario
export const eliminarUsuario = async (id) => {
    const { data, error } = await supabase
        .from('usuarios')
        .delete()
        .eq('id', id)
        .select('id, nombre, correo_electronico, rol');
    return { data, error };
};