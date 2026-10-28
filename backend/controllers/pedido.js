import crypto from 'crypto';
import { supabase } from '../config/supabase.js';
import {
  crearPedido,
  obtenerPedidoConDetalles,
  obtenerPedidosPorUsuario,
  actualizarEstadoPedido,
  obtenerPedidoPorCodigo,
} from '../models/pedidoModel.js';
import { obtenerPorId } from '../models/user.js';
import { enviarConfirmacionPedido } from '../utils/sendEmail.js';

const ESTADOS_VALIDOS = ['pendiente', 'entregado', 'cancelado', 'vencido'];
const HORAS_LIMITE = 48;

const generarCodigo = () =>
  'RES-' + crypto.randomBytes(3).toString('hex').toUpperCase(); // ej: RES-A3F9C1

// ---------- Crear reserva ----------
export const crearPedidoConDetalles = async (req, res) => {
  try {
    const { usuario_id, telefono, detalles } = req.body;

    if (!usuario_id || !Array.isArray(detalles) || detalles.length === 0) {
      return res.status(400).json({ error: 'Datos incompletos' });
    }

    // Precio y stock reales desde la BD (no se confía en el cliente)
    const ids = detalles.map((d) => d.producto_id);
    const { data: productos, error: errProd } = await supabase
      .from('productos')
      .select('id, precio, stock')
      .in('id', ids);

    if (errProd) return res.status(500).json({ error: 'Error al consultar productos' });

    let total = 0;
    const filas = [];
    for (const d of detalles) {
      const cantidad = Number(d.cantidad);
      if (!Number.isInteger(cantidad) || cantidad < 1) {
        return res.status(400).json({ error: 'Cantidad invalida' });
      }
      const p = productos.find((x) => x.id === d.producto_id);
      if (!p) return res.status(400).json({ error: `El producto ${d.producto_id} no existe` });
      if (p.stock < cantidad) {
        return res.status(400).json({ error: `Stock insuficiente para el producto ${p.id}` });
      }
      const subtotal = p.precio * cantidad;
      total += subtotal;
      filas.push({ producto_id: p.id, cantidad, precio_unitario: p.precio, subtotal });
    }

    const fecha_limite = new Date(Date.now() + HORAS_LIMITE * 60 * 60 * 1000);

    const { data: pedido, error: errorPedido } = await crearPedido({
      usuario_id,
      telefono,
      total,
      estado: 'pendiente',
      codigo: generarCodigo(),
      fecha_limite,
    });

    if (errorPedido || !pedido) {
      console.log('Error al crear pedido:', errorPedido);
      return res.status(500).json({ error: 'Error al crear la reserva' });
    }

    const pedidoId = pedido[0].id;

    const { error: errDet } = await supabase
      .from('detalle_pedidos')
      .insert(filas.map((f) => ({ ...f, pedido_id: pedidoId })));

    if (errDet) {
      console.log('Error al crear detalles:', errDet);
      await supabase.from('pedidos').delete().eq('id', pedidoId); // rollback manual
      return res.status(500).json({ error: 'Error al guardar los productos de la reserva' });
    }

    // Descontar stock al reservar
    for (const f of filas) {
      const p = productos.find((x) => x.id === f.producto_id);
      await supabase
        .from('productos')
        .update({ stock: p.stock - f.cantidad })
        .eq('id', f.producto_id);
    }

    // Correo de confirmacion (si falla, la reserva ya quedo creada)
    try {
      const { data: usuario } = await obtenerPorId(usuario_id);
      if (usuario && usuario.email) {
        await enviarConfirmacionPedido(
          usuario.email,
          usuario.nombre,
          pedidoId,
          total,
          pedido[0].codigo,
          pedido[0].fecha_limite
        );
      }
    } catch (e) {
      console.log('No se pudo enviar el correo:', e.message);
    }

    return res.status(201).json({
      message: 'Reserva creada',
      pedido: pedido[0],
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

// ---------- Consultas ----------
export const obtenerPedidoUsuario = async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await obtenerPedidoConDetalles(id);
    if (error || !data) return res.status(404).json({ error: 'Reserva no encontrada' });
    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

export const misPedidos = async (req, res) => {
  try {
    const { usuario_id } = req.query;
    if (!usuario_id) return res.status(400).json({ error: 'usuario_id requerido' });
    const { data, error } = await obtenerPedidosPorUsuario(usuario_id);
    if (error) return res.status(500).json({ error: 'Error al obtener reservas' });
    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

// ---------- Tienda: buscar por codigo ----------
export const buscarPedidoPorCodigo = async (req, res) => {
  try {
    const codigo = req.params.codigo.trim().toUpperCase();
    const { data, error } = await obtenerPedidoPorCodigo(codigo);
    if (error || !data) return res.status(404).json({ error: 'Codigo no encontrado' });
    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

// ---------- Tienda: cambiar estado ----------
export const cambiarEstadoPedido = async (req, res) => {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!ESTADOS_VALIDOS.includes(estado)) {
      return res.status(400).json({ error: `Estado invalido. Usa: ${ESTADOS_VALIDOS.join(', ')}` });
    }

    const { data: pedido, error: errPedido } = await obtenerPedidoConDetalles(id);
    if (errPedido || !pedido) return res.status(404).json({ error: 'Reserva no encontrada' });

    if (pedido.estado !== 'pendiente') {
      return res.status(400).json({ error: `La reserva ya esta en estado "${pedido.estado}"` });
    }

    const { data, error } = await actualizarEstadoPedido(id, estado);
    if (error) return res.status(500).json({ error: 'Error al actualizar el estado' });

    // Si se cancela o vence, el stock vuelve al inventario
    if (estado === 'cancelado' || estado === 'vencido') {
      for (const d of pedido.detalles) {
        const { data: prod } = await supabase
          .from('productos')
          .select('stock')
          .eq('id', d.producto.id)
          .single();
        if (prod) {
          await supabase
            .from('productos')
            .update({ stock: prod.stock + d.cantidad })
            .eq('id', d.producto.id);
        }
      }
    }

    return res.status(200).json({ message: 'Estado actualizado', pedido: data[0] });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};