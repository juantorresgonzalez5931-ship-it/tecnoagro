import express from 'express';
import {
    listarEnfermedades,
    obtenerEnfermedad,
    crear,
    editar,
    eliminar,
    vincularProducto,
    desvincularProducto
} from '../controllers/enfermedadControllers.js';
import { verificarToken, verificarAdmin } from '../middleware/authMiddleware.js';
import { upload } from '../config/cloudinary.js';

const router = express.Router();

// Rutas públicas
router.get('/enfermedades', listarEnfermedades);
router.get('/enfermedades/:id', obtenerEnfermedad);

// Rutas privadas (solo admin)
router.post('/enfermedades', verificarToken, verificarAdmin, upload.single('imagen'), crear);
router.put('/enfermedades/:id', verificarToken, verificarAdmin, editar);
router.delete('/enfermedades/:id', verificarToken, verificarAdmin, eliminar);
router.post('/enfermedades/:id/productos', verificarToken, verificarAdmin, vincularProducto);
router.delete('/enfermedades/:id/productos/:productoId', verificarToken, verificarAdmin, desvincularProducto);

export default router;