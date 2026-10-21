import { obtenerDatosEstadisticas } from '../models/estadisticasModel.js';

const STOCK_BAJO = 5;

export const getEstadisticas = async (req, res) => {
  try {
    const { usuarios, productos, pedidos, detalles } = await obtenerDatosEstadisticas();

    const fallo = [usuarios, productos, pedidos, detalles].find(r => r.error);
    if (fallo) {
      console.error('Error al obtener estadísticas:', fallo.error);
      return res.status(500).json({ error: 'Error al obtener las estadísticas' });
    }

    const listaPedidos = pedidos.data || [];
    const listaProductos = productos.data || [];

    // Ventas totales y del mes actual
    const ahora = new Date();
    const inicioMes = new Date(ahora.getFullYear(), ahora.getMonth(), 1);

    const ventasTotales = listaPedidos.reduce((acc, p) => acc + Number(p.total || 0), 0);
    const ventasMes = listaPedidos
      .filter(p => new Date(p.creado_en) >= inicioMes)
      .reduce((acc, p) => acc + Number(p.total || 0), 0);

    // Pedidos por estado
    const pedidosPorEstado = {};
    listaPedidos.forEach(p => {
      const estado = p.estado || 'pendiente';
      pedidosPorEstado[estado] = (pedidosPorEstado[estado] || 0) + 1;
    });

    // Productos más vendidos
    const acumulado = {};
    (detalles.data || []).forEach(d => {
      if (!d.producto) return;
      const key = d.producto.id;
      if (!acumulado[key]) {
        acumulado[key] = { id: key, nombre: d.producto.nombre, unidades: 0, ingresos: 0 };
      }
      acumulado[key].unidades += Number(d.cantidad || 0);
      acumulado[key].ingresos += Number(d.subtotal || 0);
    });
    const topProductos = Object.values(acumulado)
      .sort((a, b) => b.unidades - a.unidades)
      .slice(0, 5);

    // Stock bajo
    const stockBajo = listaProductos
      .filter(p => Number(p.stock) <= STOCK_BAJO)
      .sort((a, b) => a.stock - b.stock)
      .map(p => ({ id: p.id, nombre: p.nombre, stock: p.stock }));

    return res.status(200).json({
      resumen: {
        total_usuarios: (usuarios.data || []).length,
        total_productos: listaProductos.length,
        total_pedidos: listaPedidos.length,
        ventas_totales: ventasTotales,
        ventas_mes: ventasMes
      },
      pedidos_por_estado: pedidosPorEstado,
      top_productos: topProductos,
      stock_bajo: stockBajo,
      ultimos_pedidos: listaPedidos.slice(0, 5)
    });
  } catch (error) {
    console.error('Error inesperado en getEstadisticas:', error);
    return res.status(500).json({ error: error.message });
  }
};
