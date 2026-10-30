import { supabase } from '../config/supabase.js';

export const crearNotificacion = async (notificacion) => {
  const { data, error } = await supabase
    .from('notificaciones')
    .insert(notificacion)
    .select();

  return { data, error };
};

export const listarNotificacionesUsuario = async (usuario_id) => {
  const { data, error } = await supabase
    .from('notificaciones')
    .select('*')
    .eq('usuario_id', usuario_id)
    .order('created_at', { ascending: false });

  return { data, error };
};

export const contarNoLeidas = async (usuario_id) => {
  const { count, error } = await supabase
    .from('notificaciones')
    .select('*', {
      count: 'exact',
      head: true,
    })
    .eq('usuario_id', usuario_id)
    .eq('leida', false);

  return { count, error };
};

export const marcarComoLeida = async (id, usuario_id) => {
  const { data, error } = await supabase
    .from('notificaciones')
    .update({
      leida: true,
    })
    .eq('id', id)
    .eq('usuario_id', usuario_id)
    .select();

  return { data, error };
};