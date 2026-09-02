import express from 'express';
import dotenv from 'dotenv';
import { conectaDB, supabase } from './config/supabase.js';
import authRoutes from './routes/auth.js';
import pedidoRoutes from './routes/pedido.js';
import productoRoutes from './routes/producto.js';
import userRoutes from './routes/user.js';
import enfermedadRoutes from './routes/enfermedad.js'; // 👈 NUEVO
import chatRoutes from './routes/chat.js'; // 👈 NUEVO

// CARGAR VARIABLES
dotenv.config();
conectaDB();

// CREAMOS LA APLICACION DE EXPRESS
const app = express();

// LEER EL JSON
app.use(express.json());

// CREAMOS LA RUTA
app.get('/', (req, res) => {
    res.json({
        Mensaje: "Bienvenido al BACKEND de TECNOAGRO",
        Estado: "En linea",
        Version: "1.0.0"
    });
});

// RUTAS DE AUTENTICACION
app.use('/auth', authRoutes);
// RUTAS DE USUARIOS
app.use('/users', userRoutes);
// RUTA DE PRODUCTOS
app.use('/api', productoRoutes);
// RUTA DE PEDIDOS
app.use('/api', pedidoRoutes);
// RUTA DE ENFERMEDADES 
app.use('/api', enfermedadRoutes);
// RUTA DE CHAT IA 
app.use('/api', chatRoutes);

// Manejador de errores 
app.use((err, req, res, next) => {
    console.error('ERROR CAPTURADO:', err);
    res.status(500).json({ 
        error: err.message || 'Error interno del servidor',
        detalle: err.name || 'Error desconocido'
    });
});

// CONFIGURAMOS EL PUERTO
const PORT = process.env.PORT || 3000;

// PONER A ESCUCHAR EL SERVIDOR
app.listen(PORT, () => {
    console.log(`Servidor escuchando el puerto ${PORT}`);
    console.log(`http://localhost:${PORT}`);
});