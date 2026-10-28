import express from "express";
import { registro, login, verificarCuenta } from "../controllers/auth.js";
import { forgotPassword, verifyCode } from "../controllers/recuperar.js";
import { autenticarConGoogle } from "../controllers/googleauth.controller.js";

const router = express.Router();

// Rutas de autenticación
router.post("/register", registro);
router.post("/login", login);

// Recuperar contraseña
router.post("/forgot-password", forgotPassword);
router.post("/verify-code", verifyCode);

// POST /api/auth/google
router.post("/google", autenticarConGoogle);

// Verificar cuenta
router.post("/verificar-cuenta", verificarCuenta);

export default router;