import express, { Router } from "express";
import {registro, login, verificarCuenta} from "../controllers/auth.js";
import { forgotPassword, verifyCode } from "../controllers/recuperar.js";
import { autenticarConGoogle } from "../controllers/googleAuth.controller.js";


const router = express.Router();

//Rutas de autenticacion
router.post('/register', registro);
router.post('/login', login);

//Ruta para recuperar contraseña
router.post('/forgot-password', forgotPassword);
router.post('/verify-code', verifyCode);

// Endpoint: POST /api/auth/google
router.post("/google", autenticarConGoogle);

//verificar cuenta
router.post('/verificar-cuenta', verificarCuenta);

export default router;
