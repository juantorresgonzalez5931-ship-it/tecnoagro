import { supabase } from '../config/supabase.js';

//Crear pedido
export const crearPedido = async (pedidoData) => {
  const { data, error } = await supabase
    .from('pedidos')
    .insert(pedidoData)
    .select();

  return { data, error };
};

//Obtener pedido por id
export const obtenerPedidoConDetalles = async (id) => {
  const { data, error } = await supabase
    .from('pedidos')
    .select(`
      *,
      usuario:usuario_id(
        id,
        nombre,
        email
      ),
      detalles:detalle_pedidos(
        id,
        cantidad,
        precio_unitario,
        subtotal,
        producto:producto_id(
          id,
          nombre,
          imagen_url
        )
      )
    `)
    .eq('id', id)
    .single();

  return { data, error };
};

//Obtener pedidos por usuario
export const obtenerPedidosPorUsuario = async (usuarioId) => {
  const { data, error } = await supabase
    .from('pedidos')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('creado_en', { ascending: false });

  return { data, error };
};

//Actualizar estado del pedido
export const actualizarEstadoPedido = async (id, estado) => {
  const { data, error } = await supabase
    .from('pedidos')
    .update({
      estado,
      actualizado_en: new Date()
    })
    .eq('id', id)
    .select();

  return { data, error };
};

//Crear detalle del pedido
export const crearDetallePedido = async (detalleData) => {
  const { data, error } = await supabase
    .from('detalle_pedidos')
    .insert(detalleData)
    .select();

  return { data, error };
};