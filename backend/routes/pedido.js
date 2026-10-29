import express from 'express';
import {
  crearPedidoConDetalles,
  obtenerPedidoUsuario,
  misPedidos,
  buscarPedidoPorCodigo,
  cambiarEstadoPedido,
  listarReservas,
} from '../controllers/pedido.js';
import { verificarToken, verificarAdmin } from '../middleware/authMiddleware.js'; 

const router = express.Router();

// POST - Crear reserva (usuario logueado)
router.post('/pedidos', verificarToken, crearPedidoConDetalles);

// GET - Mis reservas (salen del token)
router.get('/mis-pedidos', verificarToken, misPedidos);

// GET - Buscar reserva por código (solo admin)
router.get('/pedidos/codigo/:codigo', verificarToken, verificarAdmin, buscarPedidoPorCodigo);

// GET - Obtener reserva por ID (dueño o admin)
router.get('/pedidos/:id', verificarToken, obtenerPedidoUsuario);

// PATCH - Cambiar estado (solo admin)
router.patch('/pedidos/:id/estado', verificarToken, verificarAdmin, cambiarEstadoPedido);
 
router.get('/pedidos',verificarToken, verificarAdmin , listarReservas
);

export default router;