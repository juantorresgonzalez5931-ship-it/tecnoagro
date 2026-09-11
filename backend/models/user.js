import { supabase } from "../config/supabase.js";

// 1. Crear usuario básico
export const crearUsuario = async (nombre, email, password, telefono, rol, codigoVerificacion, codigoVerificacionExpiracion) => {
    const { data, error } = await supabase
        .from('usuarios')
        .insert({ nombre, email, password, telefono, rol, isVerified: false, codigoVerificacion, codigoVerificacionExpiracion })
        .select('id, nombre, email, rol')
        .single();

    return { data, error };
};

// 2. Crear usuario autenticado con Google
export const crearUsuarioGoogle = async ({ nombre, email, googleId, avatar = null, rol = 'cliente' }) => {
    const { data, error } = await supabase
        .from('usuarios')
        .insert({
            nombre,
            email,
            password: null,        // No requiere contraseña
            rol,
            isVerified: true,      // Google ya validó este correo
            googleId,
            avatar,
            codigoVerificacion: null,
            codigoVerificacionExpiracion: null
        })
        .select('id, nombre, email, rol, avatar')
        .single();

    return { data, error };
};

// 3. Obtener todos los usuarios
export const obtenerUsuarios = async () => {
    const { data, error } = await supabase
        .from('usuarios')
        .select('*');
    return { data, error };
};

// 4. Buscar usuario por email (usamos maybeSingle() para evitar excepciones si no existe)
export const obtenerPorEmail = async (email) => {
    const { data, error } = await supabase 
        .from("usuarios")
        .select("*")
        .eq('email', email)
        .maybeSingle();
    return { data, error };
};

// 5. Obtener un usuario por ID
export const obtenerPorId = async (id) => {
    const { data, error } = await supabase
        .from('usuarios')
        .select('id, nombre, email, rol')
        .eq('id', id)
        .single();
    return { data, error };
};

// 6. Actualizar un usuario
export const actualizarUsuario = async (id, campos) => {
    const { data, error } = await supabase
        .from('usuarios')
        .update(campos)
        .eq('id', id)
        .select()
        .single();
    return { data, error };
};

// 7. Actualizar contraseña
export const actualizarContrasena = async (id, nuevoPassword) => {
    const { data, error } = await supabase
        .from('usuarios')
        .update({ password: nuevoPassword })
        .eq('id', id)
        .select('id, nombre, email');
    return { data, error };
};

// 8. Eliminar un usuario
export const eliminarUsuario = async (id) => {
    const { data, error } = await supabase
        .from('usuarios')
        .delete()
        .eq('id', id)
        .select('id, nombre, email, rol');
    return { data, error };
};