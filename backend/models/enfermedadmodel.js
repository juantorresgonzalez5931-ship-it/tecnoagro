import { supabase } from '../config/supabase.js';

export const obtenerEnfermedades = async () => {
    const { data, error } = await supabase
        .from('enfermedades')
        .select('*');
    return { data, error };
};

export const obtenerEnfermedadPorId = async (id) => {
    const { data, error } = await supabase
        .from('enfermedades')
        .select(`
            *,
            enfermedad_producto (
                producto:producto_id (
                    id, nombre, precio, imagen_url
                )
            )
        `)
        .eq('id', id)
        .single();
    return { data, error };
};

export const crearEnfermedad = async (enfermedad) => {
    const { data, error } = await supabase
        .from('enfermedades')
        .insert(enfermedad)
        .select();
    return { data, error };
};

export const actualizarEnfermedad = async (id, cambios) => {
    const { data, error } = await supabase
        .from('enfermedades')
        .update(cambios)
        .eq('id', id)
        .select();
    return { data, error };
};

export const eliminarEnfermedad = async (id) => {
    const { error } = await supabase
        .from('enfermedades')
        .delete()
        .eq('id', id);
    return { error };
};

export const asociarProducto = async (enfermedad_id, producto_id) => {
    const { data, error } = await supabase
        .from('enfermedad_producto')
        .insert({ enfermedad_id, producto_id })
        .select();
    return { data, error };
};

export const desasociarProducto = async (enfermedad_id, producto_id) => {
    const { error } = await supabase
        .from('enfermedad_producto')
        .delete()
        .eq('enfermedad_id', enfermedad_id)
        .eq('producto_id', producto_id);
    return { error };
};