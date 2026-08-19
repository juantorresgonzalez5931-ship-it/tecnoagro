import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { crearUsuario, obtenerPorEmail } from '../models/user.js';

export const registro = async (req, res) => {
    try {
        const { nombre, correo_electronico, contrasena, telefono, fecha_nacimiento } = req.body;

        if (!nombre || !correo_electronico || !contrasena) {
            return res.status(400).json({ error: "Faltan datos obligatorios" });
        }

        const { data: usuarioExiste } = await obtenerPorEmail(correo_electronico);
        if (usuarioExiste) {
            return res.status(400).json({ error: "El correo ya está registrado" });
        }

        const hashedPassword = await bcrypt.hash(contrasena, 10);
        const rolPorDefecto = "usuario";

        const { data: nuevoUsuario, error } = await crearUsuario(
            nombre, correo_electronico, hashedPassword, telefono, fecha_nacimiento, rolPorDefecto
        );

        if (error) {
            console.error("Error de Supabase al crear usuario:", error);
            return res.status(500).json({ error: error.message });
        }

        return res.status(201).json({
            message: "Usuario registrado exitosamente",
            usuario: {
                id: nuevoUsuario[0].id,
                nombre: nuevoUsuario[0].nombre,
                correo_electronico: nuevoUsuario[0].correo_electronico,
                rol: nuevoUsuario[0].rol
            }
        });

    } catch (error) {
        console.log("Error en el registro:", error);
        return res.status(500).json({ error: error.message });
    }
};

export const login = async (req, res) => {
    try {
        const { correo_electronico, contrasena } = req.body;

        if (!correo_electronico || !contrasena) {
            return res.status(400).json({ error: "todos los campos son requeridos: correo_electronico y contrasena" });
        }

        const { data: usuario } = await obtenerPorEmail(correo_electronico);
        if (!usuario) {
            return res.status(400).json({ error: "El correo no está registrado" });
        }

        const contrasenaValida = await bcrypt.compare(contrasena, usuario.contrasena);
        if (!contrasenaValida) {
            return res.status(400).json({ error: "Contraseña incorrecta" });
        }

        const token = jwt.sign(
            {
                id: usuario.id,
                nombre: usuario.nombre,
                correo_electronico: usuario.correo_electronico,
                rol: usuario.rol
            },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        return res.status(200).json({
            message: 'Inicio de sesión exitoso',
            token,
            usuario: {
                id: usuario.id,
                nombre: usuario.nombre,
                correo_electronico: usuario.correo_electronico,
                rol: usuario.rol
            }
        });

    } catch (error) {
        console.error("Error en el login:", error);
        return res.status(500).json({ error: error.message });
    }
};