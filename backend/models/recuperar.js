import { supabase } from '../config/supabase.js';

// Crear un nuevo código de recuperación
export const crearCodigo = async (usuario_id, codigo, expira_en) => {
    const { data, error } = await supabase
        .from('códigos_de_recuperación')
        .insert({ usuario_id, codigo, expira_en, usado: false })
        .select();
    return { data, error };
};

// Buscar un código válido (no usado) para ese usuario
export const obtenerCodigoValido = async (usuario_id, codigo) => {
    const { data, error } = await supabase
        .from('códigos_de_recuperación')
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
        .from('códigos_de_recuperación')
        .update({ usado: true })
        .eq('id', id)
        .select();
    return { data, error };
};