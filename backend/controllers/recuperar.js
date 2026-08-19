import bcrypt from 'bcrypt';
import { obtenerPorEmail, actualizarContrasena } from '../models/user.js';
import { crearCodigo, obtenerCodigoValido, marcarCodigoUsado } from '../models/recoveryModel.js';
import { enviarCorreo } from '../utils/mailer.js';

const generarCodigo = () => Math.floor(100000 + Math.random() * 900000).toString();

export const forgotPassword = async (req, res) => {
    try {
        const { correo_electronico } = req.body;

        if (!correo_electronico) {
            return res.status(400).json({ error: "El correo es obligatorio" });
        }

        const { data: usuario } = await obtenerPorEmail(correo_electronico);
        if (!usuario) {
            return res.status(404).json({ error: "No existe una cuenta con ese correo" });
        }

        const codigo = generarCodigo();
        const expira_en = new Date(Date.now() + 15 * 60 * 1000); // 15 minutos

        const { error } = await crearCodigo(usuario.id, codigo, expira_en);
        if (error) {
            console.error("Error al crear código:", error);
            return res.status(500).json({ error: "Error al generar el código" });
        }

        await enviarCorreo(
            correo_electronico,
            "Código de recuperación - TecnoAgro",
            `<p>Tu código de recuperación es: <strong>${codigo}</strong></p><p>Expira en 15 minutos.</p>`
        );

        return res.status(200).json({ message: "Código enviado al correo" });

    } catch (error) {
        console.error("Error en forgotPassword:", error);
        return res.status(500).json({ error: error.message });
    }
};

export const verifyCode = async (req, res) => {
    try {
        const { correo_electronico, codigo, nueva_contrasena } = req.body;

        if (!correo_electronico || !codigo || !nueva_contrasena) {
            return res.status(400).json({ error: "Faltan datos obligatorios" });
        }

        const { data: usuario } = await obtenerPorEmail(correo_electronico);
        if (!usuario) {
            return res.status(404).json({ error: "Usuario no encontrado" });
        }

        const { data: codigoValido } = await obtenerCodigoValido(usuario.id, codigo);
        if (!codigoValido) {
            return res.status(400).json({ error: "Código inválido o ya usado" });
        }

        if (new Date(codigoValido.expira_en) < new Date()) {
            return res.status(400).json({ error: "El código ha expirado" });
        }

        const hashedPassword = await bcrypt.hash(nueva_contrasena, 10);
        const { error } = await actualizarContrasena(usuario.id, hashedPassword);
        if (error) {
            return res.status(500).json({ error: "Error al actualizar la contraseña" });
        }

        await marcarCodigoUsado(codigoValido.id);

        return res.status(200).json({ message: "Contraseña actualizada correctamente" });

    } catch (error) {
        console.error("Error en verifyCode:", error);
        return res.status(500).json({ error: error.message });
    }
};