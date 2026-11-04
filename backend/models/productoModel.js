import { supabase } from '../config/supabase.js';

export const obtenerTodos = async () => {
  const { data, error } = await supabase
    .from('productos')
    .select('*')
    .eq('activo', true);
  return { data, error };
};

export const obtenerPorId = async (id) => {
  const { data, error } = await supabase
    .from('productos')
    .select('*')
    .eq('id', id)
    .eq('activo', true)
    .single();
  return { data, error };
};

export const obtenerPorCategoria = async (categoria) => {
  const { data, error } = await supabase
    .from('productos')
    .select('*')
    .eq('categoria', categoria)
    .eq('activo', true);
  return { data, error };
};

export const crearProducto = async (producto) => {
  const { data, error } = await supabase
    .from('productos')
    .insert(producto)
    .select();
  return { data, error };
};

export const actualizarProducto = async (id, cambios) => {
  const { data, error } = await supabase
    .from('productos')
    .update(cambios)
    .eq('id', id)
    .select();
  return { data, error };
};

export const eliminarProducto = async (id) => {
  const { error } = await supabase
    .from('productos')
    .delete()
    .eq('id', id);
  return { error };
};

// Quita el producto de las listas de "recomendados" de las enfermedades
export const desvincularDeEnfermedades = async (id) => {
  const { error } = await supabase
    .from('enfermedad_producto')
    .delete()
    .eq('producto_id', id);
  return { error };
};

// Lo oculta sin borrarlo (para los que ya tienen pedidos)
export const archivarProducto = async (id) => {
  const { error } = await supabase
    .from('productos')
    .update({ activo: false })
    .eq('id', id);
  return { error };
};