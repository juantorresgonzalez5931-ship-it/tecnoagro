import { supabase } from '../config/supabase.js';

export const crearConversacion = async (usuario_id, title = 'Nueva conversación') => {
    const { data, error } = await supabase
        .from('conversations')
        .insert({ user_id: usuario_id, title })
        .select();
    return { data, error };
};


export const obtenerConversacionesPorUsuario = async (usuario_id) => {
    const { data, error } = await supabase
        .from('conversations')
        .select('*')
        .eq('user_id', usuario_id)
        .order('created_at', { ascending: false });
    return { data, error };
};

// Obtener una conversación por su ID
export const obtenerConversacionPorId = async (id) => {
    const { data, error } = await supabase
        .from('conversations')
        .select('*')
        .eq('id', id)
        .single();
    return { data, error };
};

//Eliminar conversacion
export const eliminarConversacion = async (id) => {
    const { error } = await supabase
        .from('conversations')
        .delete()
        .eq('id', id);
    return { error };
};

//Crear el mensaje
export const crearMensaje = async (conversation_id, sender, content) => {
    const { data, error } = await supabase
        .from('messages')
        .insert({ conversation_id, sender, content })
        .select();
    return { data, error };
};


// Obtener mensajes por conversación
export const obtenerMensajesPorConversacion = async (conversation_id) => {
    const { data, error } = await supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversation_id)
        .order('created_at', { ascending: true });
    return { data, error };
};