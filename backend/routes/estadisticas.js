import express from 'express';
import { getEstadisticas } from '../controllers/estadisticasController.js';
import { verificarToken, verificarAdmin } from '../middleware/authMiddleware.js';

const router = express.Router();

// GET /api/admin/estadisticas  (solo admin)
router.get('/admin/estadisticas', verificarToken, verificarAdmin, getEstadisticas);

export default router;
