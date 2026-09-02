import { supabase } from '../config/supabase.js';

export const obtenerEnfermedades = async () => {
    const { data, error } = await supabase
        .from('enfermedades')
        .select('*');
    return { data, error };
};

//Obtener enfermedad por id
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

//Crear enfermedad
export const crearEnfermedad = async (enfermedad) => {
    const { data, error } = await supabase
        .from('enfermedades')
        .insert(enfermedad)
        .select();
    return { data, error };
};


//Actualizar enfermedad
export const actualizarEnfermedad = async (id, cambios) => {
    const { data, error } = await supabase
        .from('enfermedades')
        .update(cambios)
        .eq('id', id)
        .select();
    return { data, error };
};

//Eliminar enfermedad
export const eliminarEnfermedad = async (id) => {
    const { error } = await supabase
        .from('enfermedades')
        .delete()
        .eq('id', id);
    return { error };
};

// Asociar un producto a una enfermedad
export const asociarProducto = async (enfermedad_id, producto_id) => {
    const { data, error } = await supabase
        .from('enfermedad_producto')
        .insert({ enfermedad_id, producto_id })
        .select();
    return { data, error };
};

// Desasociar un producto de una enfermedad
export const desasociarProducto = async (enfermedad_id, producto_id) => {
    const { error } = await supabase
        .from('enfermedad_producto')
        .delete()
        .eq('enfermedad_id', enfermedad_id)
        .eq('producto_id', producto_id);
    return { error };
};