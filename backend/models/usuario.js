import { supabase } from '../config/supabase.js';

// Crear un nuevo usuario en la tabla 'usuarios'
export const crearUsuario = async (nombre, email, passwordHash) => {
    const { data, error } = await supabase
        .from('usuarios')
        .insert([{ nombre, email, password: passwordHash }])
        .select()
        .single();

    if (error) {
        throw new Error(error.message);
    }

    return data;
};

// Buscar un usuario por su email
export const obtenerPorEmail = async (email) => {
    const { data, error } = await supabase
        .from('usuarios')
        .select('*')
        .eq('email', email)
        .maybeSingle();

    if (error) {
        throw new Error(error.message);
    }

    return data;
};