import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { supabase } from '../config/supabase.js';
import { crearUsuario, obtenerPorEmail } from '../models/user.js';
import { enviarCodigoVerificacion } from '../services/emailService.js';

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

        // Generar codigo de 6 digitos y fecha de expiracion (15 minutos)
        const codigoVerificacion = Math.floor(100000 + Math.random() * 900000).toString();
        const codigoVerificacionExpiracion = new Date(Date.now() + 15 * 60 * 1000).toISOString();

        const { data: nuevoUsuario, error } = await crearUsuario(
            nombre, email, hashedPassword, telefono, rolPorDefecto,
            codigoVerificacion, codigoVerificacionExpiracion
        );

        if (error) {
            console.error("Error de Supabase al crear usuario:", error);
            return res.status(500).json({ error: error.message });
        }

        // Enviar el correo con el codigo de 6 digitos usando Brevo
        const resultadoEnvio = await enviarCodigoVerificacion(email, nombre, codigoVerificacion);

        const usuarioRespuesta = {
            id: nuevoUsuario[0].id,
            nombre: nuevoUsuario[0].nombre,
            email: nuevoUsuario[0].email,
            rol: nuevoUsuario[0].rol
        };

        // Si Brevo fallo, el usuario ya quedo creado, pero avisamos que el correo no llego
        if (!resultadoEnvio.exito) {
            return res.status(201).json({
                message: "Tu cuenta fue creada, pero hubo un problema enviando el codigo de verificacion a tu correo. Intenta iniciar sesion mas tarde o contacta soporte.",
                emailEnviado: false,
                usuario: usuarioRespuesta
            });
        }

        return res.status(201).json({
            message: "Usuario registrado exitosamente. Hemos enviado un codigo de 6 digitos a tu correo.",
            emailEnviado: true,
            usuario: usuarioRespuesta
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

        // Verificar si el usuario ha sido verificado
        if (!usuario.isVerified) {
            return res.status(403).json({
                error: "Tu cuenta no ha sido verificada. Por favor ingresa el codigo enviado a tu correo antes de iniciar sesion."
            });
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

// VERIFICAR CUENTA CON CODIGO DE 6 DIGITOS
export const verificarCuenta = async (req, res) => {
    try {
        const { email, codigo } = req.body;

        if (!email || !codigo) {
            return res.status(400).json({ error: "El email y el codigo de verificacion son requeridos" });
        }

        // 1. Buscar al usuario en Supabase
        const { data: usuario, error: errorUsuario } = await supabase
            .from('usuarios')
            .select('id, email, isVerified, codigoVerificacion, codigoVerificacionExpiracion')
            .eq('email', email)
            .single();

        if (errorUsuario || !usuario) {
            return res.status(404).json({ error: "Usuario no encontrado" });
        }

        // 2. Revisar si ya esta activo
        if (usuario.isVerified) {
            return res.status(400).json({ error: "La cuenta ya se encuentra verificada" });
        }

        // 3. Comparar el codigo
        if (String(usuario.codigoVerificacion).trim() !== String(codigo).trim()) {
            return res.status(400).json({ error: "El codigo de verificacion es incorrecto" });
        }

        // 4. Validar expiracion (15 minutos)
        const ahora = new Date();
        const expiracion = new Date(usuario.codigoVerificacionExpiracion);

        if (ahora > expiracion) {
            return res.status(400).json({ error: "El codigo ha expirado. Por favor solicita uno nuevo" });
        }

        // 5. Activar la cuenta
        const { error: errorUpdate } = await supabase
            .from('usuarios')
            .update({
                isVerified: true,
                codigoVerificacion: null,
                codigoVerificacionExpiracion: null
            })
            .eq('email', email);

        if (errorUpdate) {
            return res.status(500).json({ error: "Error al actualizar el estado de verificacion" });
        }

        return res.status(200).json({
            message: "Cuenta verificada exitosamente. Ya puedes iniciar sesion."
        });

    } catch (error) {
        console.error("Error en verificarCuenta:", error);
        return res.status(500).json({ error: error.message });
    }
};