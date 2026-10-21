import { supabase } from '../config/supabase.js'; // ajusta la ruta si tu cliente está en otro archivo

export const obtenerDatosEstadisticas = async () => {
  const [usuarios, productos, pedidos, detalles] = await Promise.all([
    supabase.from('usuarios').select('id, rol'),
    supabase.from('productos').select('id, nombre, categoria, stock, precio'),
    supabase
      .from('pedidos')
      .select('id, total, estado, creado_en, usuario:usuario_id(nombre, email)')
      .order('creado_en', { ascending: false }),
    supabase
      .from('detalle_pedidos')
      .select('cantidad, subtotal, producto:producto_id(id, nombre)')
  ]);

  return { usuarios, productos, pedidos, detalles };
};
