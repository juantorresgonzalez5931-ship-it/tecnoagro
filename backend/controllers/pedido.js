import { crearPedido, obtenerPedidoConDetalles, obtenerPedidosPorUsuario, actualizarEstadoPedido, crearDetallePedido } from '../models/pedidoModels.js';

export const crearPedidoConDetalles = async (req, res) => {
    try {
        const { usuario_id, direccion_entrega, telefono, notas, detalles } = req.body;

        if (!usuario_id || !detalles || detalles.length === 0) {
            return res.status(400).json({ error: 'Datos incompletos' });
        }

        // Calcular total
        let total = 0;
        detalles.forEach(d => {
            total += d.subtotal;
        });

        // 1. Crear pedido
        const { data: pedido, error: errorPedido } = await crearPedido({
            usuario_id, direccion_entrega, telefono, notas, total
        });

        if (errorPedido || !pedido) {
            return res.status(500).json({ error: 'Error al crear pedido' });
        }

        // 2. Crear detalles del pedido
        const detallesConPedido = detalles.map(d => ({
            ...d, pedido_id: pedido[0].id
        }));
        for (let detalle of detallesConPedido) {
            await crearDetallePedido(detalle);
        }

        // 3. Obtener info del usuario para el correo
        const { data: usuario } = await obtenerUsuarios(usuario_id);

        // 4. ENVIAR CORREO DE CONFIRMACIÓN
        if (usuario && usuario.email) {
            await enviarConfirmacionPedido(
                usuario.email,
                usuario.nombre,
                pedido[0].id,
                total
            );
        }

        return res.status(201).json({
            message: 'Pedido creado y correo enviado',
            pedido: pedido[0]
        });

    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

export const obtenerPedidoUsuario = async (req, res) => {
    try {
        const { id } = req.params;
        const { data, error } = await obtenerPedidoConDetalles(id);
        if (error || !data) return res.status(404).json({ error: 'Pedido no encontrado' });
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

export const misPedidos = async (req, res) => {
    try {
        const { usuario_id } = req.query;
        if (!usuario_id) return res.status(400).json({ error: 'usuario_id requerido' });
        const { data, error } = await obtenerPedidosPorUsuario(usuario_id);
        if (error) return res.status(500).json({ error: 'Error al obtener pedidos' });
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

