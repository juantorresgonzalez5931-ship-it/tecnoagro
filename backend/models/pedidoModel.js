import { supabase } from '../config/supabase.js';

export const crearPedido = async (pedidoData) => {
  const { data, error } = await supabase
    .from('pedidos')
    .insert(pedidoData)
    .select();

  return { data, error };
};

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
      detalles:detalle_pedido(
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

export const obtenerPedidosPorUsuario = async (usuarioId) => {
  const { data, error } = await supabase
    .from('pedidos')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha_pedido', { ascending: false });

  return { data, error };
};

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

export const crearDetallePedido = async (detalleData) => {
  const { data, error } = await supabase
    .from('detalle_pedido')
    .insert(detalleData)
    .select();

  return { data, error };
};