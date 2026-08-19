import {
  obtenerTodos,
  obtenerPorId,
  obtenerPorCategoria,
  crearProducto,
  actualizarProducto,
  eliminarProducto
} from '../models/productoModel.js';

export const listarProductos = async (req, res) => {
  try {
    const { data, error } = await obtenerTodos();
    if (error) return res.status(500).json({ error: 'Error al obtener' });
    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

export const obtenerProducto = async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await obtenerPorId(id);
    if (error || !data) return res.status(404).json({ error: 'No encontrado' });
    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

export const obtenerPorCat = async (req, res) => {
  try {
    const { categoria } = req.params;
    const { data, error } = await obtenerPorCategoria(categoria);
    if (error) return res.status(500).json({ error: 'Error' });
    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

export const crear = async (req, res) => {
  try {
    const { nombre, descripcion, categorias, principio_activo, precio, existencias } = req.body;

    // Cloudinary almacena la url segura en req.file.path
    const imagen_url = req.file ? req.file.path : null;

    if (!nombre || !precio || !imagen_url) {
      return res.status(400).json({ error: 'Nombre, precio e imagen_url requeridos' });
    }

    const { data, error } = await crearProducto({
      nombre, descripcion, categorias, principio_activo, precio, existencias, imagen_url
    });

    if (error) {
      console.error('ERROR DE SUPABASE AL CREAR PRODUCTO:', error);
      return res.status(500).json({ error: 'Error al crear' });
    }

    return res.status(201).json({ message: 'Creado', producto: data[0] });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

export const editar = async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await actualizarProducto(id, req.body);
    if (error) return res.status(500).json({ error: 'Error al actualizar' });
    return res.status(200).json({ message: 'Actualizado', producto: data[0] });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

export const eliminar = async (req, res) => {
  try {
    const { id } = req.params;
    const { error } = await eliminarProducto(id);
    if (error) return res.status(500).json({ error: 'Error al eliminar' });
    return res.status(200).json({ message: 'Eliminado' });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};