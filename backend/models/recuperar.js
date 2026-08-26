import { supabase } from '../config/supabase.js';

// Crear un nuevo código de recuperación
export const crearCodigo = async (usuario_id, codigo, expires_at) => {
    const { data, error } = await supabase
        .from('recovery_codes')
        .insert({ usuario_id, codigo, expires_at, usado: false })
        .select();
    return { data, error };
};

// Buscar un código válido (no usado) para ese usuario
export const obtenerCodigoValido = async (usuario_id, codigo) => {
    const { data, error } = await supabase
        .from('recovery_codes')
        .select('*')
        .eq('usuario_id', usuario_id)
        .eq('codigo', codigo)
        .eq('usado', false)
        .single();
    return { data, error };
};

// Marcar el código como usado una vez se valida
export const marcarCodigoUsado = async (id) => {
    const { data, error } = await supabase
        .from('recovery_codes')
        .update({ usado: true })
        .eq('id', id)
        .select();
    return { data, error };
};