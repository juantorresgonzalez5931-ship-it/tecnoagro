import jwt from "jsonwebtoken";
import { OAuth2Client } from "google-auth-library";
import { obtenerPorEmail, crearUsuarioGoogle, actualizarUsuario } from "../models/User.js";

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

export const autenticarConGoogle = async (req, res) => {
    try {
        const { idToken } = req.body;

        if (!idToken) {
            return res.status(400).json({ error: 'El idToken de Google es requerido' });
        }

        // 1. Validar el token con Google
        const ticket = await client.verifyIdToken({
            idToken,
            audience: process.env.GOOGLE_CLIENT_ID
        });
        const payload = ticket.getPayload();
        const { sub: googleId, email, name: nombre, picture: avatar } = payload;

        // 2. Comprobar si el usuario ya existe en Supabase
        const { data: usuarioExistente } = await obtenerPorEmail(email);

        let usuarioFinal = null;

        if (usuarioExistente) {
            // --- LOGIN: el usuario ya existe, vinculamos datos de Google si faltan ---
            usuarioFinal = usuarioExistente;

            const camposActualizar = {};
            if (!usuarioExistente.googleId) camposActualizar.googleId = googleId;
            if (!usuarioExistente.avatar && avatar) camposActualizar.avatar = avatar;
            if (!usuarioExistente.isVerified) camposActualizar.isVerified = true;

            if (Object.keys(camposActualizar).length > 0) {
                await actualizarUsuario(usuarioExistente.id, camposActualizar);
            }
        } else {
            // --- REGISTRO: usuario nuevo vía Google ---
            const { data: nuevoUsuario, error: errorCrear } = await crearUsuarioGoogle({
                nombre,
                email,
                googleId,
                avatar,
                rol: 'usuario'
            });

            if (errorCrear) {
                return res.status(500).json({
                    error: 'Error al registrar el usuario en Supabase',
                    detalle: errorCrear.message
                });
            }

            usuarioFinal = Array.isArray(nuevoUsuario) ? nuevoUsuario[0] : nuevoUsuario;
        }

        // 3. Generar token de sesión JWT
        const token = jwt.sign(
            { id: usuarioFinal.id, rol: usuarioFinal.rol },
            process.env.JWT_SECRET,
            { expiresIn: '1d' }
        );

        return res.status(200).json({
            message: usuarioExistente ? 'Inicio de sesión exitoso con Google' : 'Registro exitoso con Google',
            token,
            usuario: {
                id: usuarioFinal.id,
                nombre: usuarioFinal.nombre,
                email: usuarioFinal.email,
                rol: usuarioFinal.rol,
                avatar: usuarioFinal.avatar || avatar
            }
        });

    } catch (error) {
        console.error('Error en autenticarConGoogle:', error);
        return res.status(401).json({ error: 'Token de Google inválido o expirado' });
    }
};