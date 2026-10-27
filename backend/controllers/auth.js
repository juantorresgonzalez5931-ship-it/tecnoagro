import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { supabase } from '../config/supabase.js';
import { crearUsuario, obtenerPorEmail } from '../models/user.js';

export const registro = async (req, res) => {
    try {
        const { nombre, email, password, telefono } = req.body;

        if (!nombre || !email || !password) {
            return res.status(400).json({ error: "Faltan datos obligatorios" });
        }

        const { data: usuarioExiste } = await obtenerPorEmail(email);
        if (usuarioExiste) {
            return res.status(400).json({ error: "El correo ya está registrado" });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const rolPorDefecto = "usuario";

        // Ya no se genera ni se envía código de verificación al registrarse.
        // El código solo se usa para recuperar la contraseña (recuperarController).
        const { data: nuevoUsuario, error } = await crearUsuario(
            nombre, email, hashedPassword, telefono, rolPorDefecto,
            null, null
        );

        if (error) {
            console.error("Error de Supabase al crear usuario:", error);
            return res.status(500).json({ error: error.message });
        }

        // La cuenta queda activa desde el inicio.
        const { error: errorActivar } = await supabase
            .from('usuarios')
            .update({ isVerified: true })
            .eq('id', nuevoUsuario.id);

        if (errorActivar) {
            // No bloquea al usuario: el login ya no exige verificación.
            console.error("No se pudo marcar la cuenta como verificada:", errorActivar);
        }

        return res.status(201).json({
            message: "Tu cuenta fue creada con éxito. Ya puedes iniciar sesión.",
            usuario: {
                id: nuevoUsuario.id,
                nombre: nuevoUsuario.nombre,
                email: nuevoUsuario.email,
                rol: nuevoUsuario.rol
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

        // Ya no se exige verificación por correo para iniciar sesión.

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
// Ya no se usa en el registro. Se deja para no romper la ruta que la importa.
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