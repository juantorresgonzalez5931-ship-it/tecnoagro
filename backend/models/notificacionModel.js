import { supabase } from '../config/supabase.js';

// Tabla "notificaciones": id, usuario_id, tipo ('producto' | 'reserva'), titulo, mensaje,
// producto_id (solo en las de producto), leida, created_at

export const crearNotificacion = async (notificacion) => {
    const { data, error } = await supabase
        .from('notificaciones')
        .insert(notificacion)
        .select();
    return { data, error };
};

// Inserta varias de una vez (por ejemplo, una por cada usuario).
export const crearNotificaciones = async (lista) => {
    if (!lista.length) return { error: null };
    const { error } = await supabase.from('notificaciones').insert(lista);
    return { error };
};

export const obtenerPorUsuario = async (usuario_id, limite = 50) => {
    const { data, error } = await supabase
        .from('notificaciones')
        .select('*')
        .eq('usuario_id', usuario_id)
        .order('created_at', { ascending: false })
        .limit(limite);
    return { data, error };
};

export const contarNoLeidas = async (usuario_id) => {
    const { count, error } = await supabase
        .from('notificaciones')
        .select('id', { count: 'exact', head: true })
        .eq('usuario_id', usuario_id)
        .eq('leida', false);
    return { count: count ?? 0, error };
};

// Solo marca la notificación si pertenece al usuario.
export const marcarComoLeida = async (id, usuario_id) => {
    const { data, error } = await supabase
        .from('notificaciones')
        .update({ leida: true })
        .eq('id', id)
        .eq('usuario_id', usuario_id)
        .select();
    return { data, error };
};

export const marcarTodasComoLeidas = async (usuario_id) => {
    const { error } = await supabase
        .from('notificaciones')
        .update({ leida: true })
        .eq('usuario_id', usuario_id)
        .eq('leida', false);
    return { error };
};