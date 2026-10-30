import {
  listarNotificacionesUsuario,
  contarNoLeidas,
  marcarComoLeida,
} from '../models/notificacionModel.js';

export const obtenerMisNotificaciones = async (req, res) => {
  try {
    const usuario_id = req.usuario.id;

    const { data, error } =
      await listarNotificacionesUsuario(usuario_id);

    if (error) {
      return res.status(500).json({
        error: 'Error al obtener notificaciones',
      });
    }

    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({
      error: error.message,
    });
  }
};

export const obtenerCantidadNoLeidas = async (req, res) => {
  try {
    const usuario_id = req.usuario.id;

    const { count, error } =
      await contarNoLeidas(usuario_id);

    if (error) {
      return res.status(500).json({
        error: 'Error al contar notificaciones',
      });
    }

    return res.status(200).json({
      cantidad: count ?? 0,
    });
  } catch (error) {
    return res.status(500).json({
      error: error.message,
    });
  }
};

export const marcarLeida = async (req, res) => {
  try {
    const usuario_id = req.usuario.id;
    const { id } = req.params;

    const { error } = await marcarComoLeida(
      id,
      usuario_id,
    );

    if (error) {
      return res.status(500).json({
        error: 'Error al actualizar notificación',
      });
    }

    return res.status(200).json({
      message: 'Notificación actualizada',
    });
  } catch (error) {
    return res.status(500).json({
      error: error.message,
    });
  }
};