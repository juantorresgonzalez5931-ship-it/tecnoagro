import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { crearUsuario, obtenerPorEmail } from '../models/user.js';

export const registro = async (req, res) => {
    try {
        const { nombre, email, password, telefono, } = req.body;

        if (!nombre || !email || !password) {
            return res.status(400).json({ error: "Faltan datos obligatorios" });
        }

        const { data: usuarioExiste } = await obtenerPorEmail(email);
        if (usuarioExiste) {
            return res.status(400).json({ error: "El correo ya está registrado" });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const rolPorDefecto = "usuario";

        const { data: nuevoUsuario, error } = await crearUsuario(
            nombre, email, hashedPassword, telefono, rolPorDefecto
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
                email: nuevoUsuario[0].email,
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
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: "todos los campos son requeridos: email y password" });
        }

        const { data: usuario } = await obtenerPorEmail(email);
        if (!usuario) {
            return res.status(400).json({ error: "El correo no está registrado" });
        }

        const passwordValida = await bcrypt.compare(password, usuario.password);
        if (!passwordValida) {
            return res.status(400).json({ error: "Contraseña incorrecta" });
        }

        const token = jwt.sign(
            {
                id: usuario.id,
                nombre: usuario.nombre,
                email: usuario.email,
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
                email: usuario.email,
                rol: usuario.rol
            }
        });

    } catch (error) {
        console.error("Error en el login:", error);
        return res.status(500).json({ error: error.message });
    }
};