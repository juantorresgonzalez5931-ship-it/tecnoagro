import express from "express";
import { getUsuarios, getUsuarioPorId, updateUsuario, deleteUsuario } from "../controllers/user.js";
import { verificarToken, verificarAdmin } from "../middleware/authMiddleware.js";

const router = express.Router();

router.get('/', verificarToken, verificarAdmin, getUsuarios);
router.get('/:id', verificarToken, getUsuarioPorId);
router.put('/:id', verificarToken, updateUsuario);
router.delete('/:id', verificarToken, verificarAdmin, deleteUsuario);

export default router;