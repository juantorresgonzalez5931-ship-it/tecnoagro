import express from "express";
import { registro, login, verificarCuenta, actualizarMiPerfil, eliminarMiCuenta } from "../controllers/auth.js";
import { forgotPassword, verifyCode } from "../controllers/recuperar.js";
import { autenticarConGoogle } from "../controllers/googleauth.controller.js";
import { verificarToken } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/register", registro);
router.post("/login", login);
router.post("/forgot-password", forgotPassword);
router.post("/verify-code", verifyCode);
router.post("/google", autenticarConGoogle);
router.post("/verificar-cuenta", verificarCuenta);

// Operaciones limitadas al usuario autenticado (el ID se obtiene del token).
router.put("/perfil", verificarToken, actualizarMiPerfil);
router.delete("/cuenta", verificarToken, eliminarMiCuenta);

export default router;
