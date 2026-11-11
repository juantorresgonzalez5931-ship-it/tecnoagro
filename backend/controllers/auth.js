import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { supabase } from '../config/supabase.js';
import { crearUsuario, obtenerPorEmail, actualizarUsuario, eliminarUsuario } from '../models/user.js';

// Duración de la sesión. Cámbiala aquí si quieres más o menos tiempo.
const DURACION_TOKEN = '7d';

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

        // La columna `rol` puede venir con espacios al final; se limpia aquí.
        const rol = typeof usuario.rol === 'string' ? usuario.rol.trim() : usuario.rol;

        const token = jwt.sign(
            {
                id: usuario.id,
                nombre: usuario.nombre,
                email: usuario.email,
                rol
            },
            process.env.JWT_SECRET,
            { expiresIn: DURACION_TOKEN }
        );

        return res.status(200).json({
            message: 'Inicio de sesión exitoso',
            token,
            usuario: {
                id: usuario.id,
                nombre: usuario.nombre,
                email: usuario.email,
                rol
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

// Actualiza únicamente los datos permitidos del usuario autenticado.
export const actualizarMiPerfil = async (req, res) => {
    try {
        const id = req.usuario?.id;
        if (!id) return res.status(401).json({ error: "Sesión inválida" });

        const nombre = typeof req.body?.nombre === "string" ? req.body.nombre.trim() : "";
        const telefono = typeof req.body?.telefono === "string" ? req.body.telefono.trim() : "";

        if (!nombre) {
            return res.status(400).json({ error: "El nombre es obligatorio" });
        }
        if (telefono && !/^[0-9]{7,15}$/.test(telefono)) {
            return res.status(400).json({ error: "El teléfono no es válido" });
        }

        const { data, error } = await actualizarUsuario(id, { nombre, telefono });
        if (error) {
            console.error("Error al actualizar perfil:", error);
            return res.status(500).json({ error: "No se pudo actualizar el perfil" });
        }
        if (!data) return res.status(404).json({ error: "Usuario no encontrado" });

        return res.status(200).json({
            message: "Información personal actualizada",
            usuario: data
        });
    } catch (error) {
        console.error("Error en actualizarMiPerfil:", error);
        return res.status(500).json({ error: "Error interno al actualizar el perfil" });
    }
};

// Elimina exclusivamente la cuenta asociada al token presentado.
export const eliminarMiCuenta = async (req, res) => {
    try {
        const id = req.usuario?.id;
        if (!id) return res.status(401).json({ error: "Sesión inválida" });

        const { data: usuario, error: errorUsuario } = await obtenerPorEmail(req.usuario.email);
        if (errorUsuario || !usuario || String(usuario.id) !== String(id)) {
            return res.status(404).json({ error: "No se encontró la cuenta autenticada" });
        }

        const { data, error } = await eliminarUsuario(id);
        if (error) {
            console.error("Error al eliminar cuenta propia:", error);
            return res.status(409).json({
                error: "No fue posible eliminar la cuenta. Puede tener información relacionada que debe gestionarse primero."
            });
        }
        if (!data || data.length === 0) {
            return res.status(404).json({ error: "No se encontró la cuenta para eliminar" });
        }

        return res.status(200).json({ message: "Tu cuenta fue eliminada correctamente" });
    } catch (error) {
        console.error("Error en eliminarMiCuenta:", error);
        return res.status(500).json({ error: "Error interno al eliminar la cuenta" });
    }
};
