import express from 'express';
import { listarProductos, obtenerProducto, obtenerPorCat, crear, editar, eliminar } from '../controllers/productoControllers.js';
import { verificarToken, verificarAdmin } from '../middleware/authMiddleware.js';
import { upload } from '../config/cloudinary.js';

const router = express.Router();

// GET - Obtener todos
router.get('/productos', listarProductos);

// GET - Obtener por categoría
// (debe ir ANTES de /productos/:id, o Express tomaría "categoria" como un id)
router.get('/productos/categoria/:categoria', obtenerPorCat);

// GET - Obtener por ID
router.get('/productos/:id', obtenerProducto);

// Rutas privadas
// POST - Crear producto
router.post('/productos', verificarToken, verificarAdmin, upload.single('imagen'), crear);

// PUT - Actualizar producto
router.put('/productos/:id', verificarToken, verificarAdmin, upload.single('imagen'), editar);

// DELETE - Eliminar producto
router.delete('/productos/:id', verificarToken, verificarAdmin, eliminar);

export default router;