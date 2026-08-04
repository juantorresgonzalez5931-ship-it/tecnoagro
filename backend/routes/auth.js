import express from 'express';
import { registro } from '../controllers/auth.js';
const router = express.Router();

router.post('/registro', registro);

export default router;
