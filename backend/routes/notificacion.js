import express from 'express';

import {
  obtenerMisNotificaciones,
  obtenerCantidadNoLeidas,
  marcarLeida,
} from '../controllers/notificacionController.js';

import {
  verificarToken,
} from '../middleware/authMiddleware.js';

const router = express.Router();

router.get(
  '/notificaciones',
  verificarToken,
  obtenerMisNotificaciones,
);

router.get(
  '/notificaciones/no-leidas',
  verificarToken,
  obtenerCantidadNoLeidas,
);

router.put(
  '/notificaciones/:id/leida',
  verificarToken,
  marcarLeida,
);

export default router;