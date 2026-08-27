import express from 'express';
import {
    enviarMensaje,
    misConversaciones,
    mensajesDeConversacion,
    borrarConversacion
} from '../controllers/chatControllers.js';
import { verificarToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/chat/mensaje', verificarToken, enviarMensaje);
router.get('/chat/conversaciones', verificarToken, misConversaciones);
router.get('/chat/conversaciones/:id/mensajes', verificarToken, mensajesDeConversacion);
router.delete('/chat/conversaciones/:id', verificarToken, borrarConversacion);

export default router;