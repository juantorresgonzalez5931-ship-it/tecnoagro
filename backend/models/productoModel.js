import { supabase } from '../config/supabase.js';

export const obtenerTodos = async () => {
  const { data, error } = await supabase
    .from('productos')
    .select('*');
  return { data, error };
};

// Obtener un producto por ID
export const obtenerPorId = async (id) => {
  const { data, error } = await supabase
    .from('productos')
    .select('*')
    .eq('id', id)
    .single();
  return { data, error };
};

// Obtener productos por categoría
export const obtenerPorCategoria = async (categoria) => {
  const { data, error } = await supabase
    .from('productos')
    .select('*')
    .eq('categorias', categoria);
  return { data, error };
};

// Crear un nuevo producto
export const crearProducto = async (producto) => {
  const { data, error } = await supabase
    .from('productos')
    .insert(producto)
    .select();
  return { data, error };
};

//Actualizar un producto existente
export const actualizarProducto = async (id, cambios) => {
  const { data, error } = await supabase
    .from('productos')
    .update(cambios)
    .eq('id', id)
    .select();
  return { data, error };
};

//Eliminar un producto existente
export const eliminarProducto = async (id) => {
  const { error } = await supabase
    .from('productos')
    .delete()
    .eq('id', id);
  return { error };
};