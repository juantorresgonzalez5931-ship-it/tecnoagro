import express from 'express';
import { verificarToken } from '../middleware/authMiddleware.js'; // copia este import de routes/pedido.js
import {
  obtenerMisNotificaciones,
  obtenerCantidadNoLeidas,
  marcarLeida,
  marcarTodasLeidas,
} from '../controllers/notificacionController.js';

const router = express.Router();

router.get('/notificaciones', verificarToken, obtenerMisNotificaciones);
router.get('/notificaciones/no-leidas', verificarToken, obtenerCantidadNoLeidas);

// La ruta fija va ANTES de las que llevan /:id
router.patch('/notificaciones/leer-todas', verificarToken, marcarTodasLeidas);
router.put('/notificaciones/:id/leida', verificarToken, marcarLeida);

export default router;