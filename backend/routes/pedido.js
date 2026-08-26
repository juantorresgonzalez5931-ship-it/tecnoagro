import express from 'express';
import {
  crearPedidoConDetalles,
  obtenerPedidoUsuario,
  misPedidos
} from '../controllers/pedido.js';


const router = express.Router();

// POST - Crear pedido (con correo automático)
router.post('/pedidos', crearPedidoConDetalles);

// GET - Mis pedidos (por usuario)
router.get('/mis-pedidos', misPedidos);

// GET - Obtener pedido por ID
router.get('/pedidos/:id', obtenerPedidoUsuario);



export default router;

