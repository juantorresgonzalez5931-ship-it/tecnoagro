import {
  obtenerTodos,
  obtenerPorId,
  obtenerPorCategoria,
  crearProducto,
  actualizarProducto,
  eliminarProducto
} from '../models/productoModel.js';


// GET - Listar todos los productos
export const listarProductos = async (req, res) => {
  try {
    const { data, error } = await obtenerTodos();

    if (error) {
      console.error('Error al listar productos:', error);
      return res.status(500).json({ error: 'Error al obtener los productos' });
    }

    return res.status(200).json(data);
  } catch (error) {
    console.error('Error inesperado en listarProductos:', error);
    return res.status(500).json({ error: error.message });
  }
};

// GET - Obtener un producto por ID
export const obtenerProducto = async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await obtenerPorId(id);

    if (error || !data) {
      return res.status(404).json({ error: 'Producto no encontrado' });
    }

    return res.status(200).json(data);
  } catch (error) {
    console.error('Error inesperado en obtenerProducto:', error);
    return res.status(500).json({ error: error.message });
  }
};

// GET - Obtener productos por categoría

export const obtenerPorCat = async (req, res) => {
  try {
    const { categoria } = req.params;
    const { data, error } = await obtenerPorCategoria(categoria);

    if (error) {
      console.error('Error al obtener productos por categoría:', error);
      return res.status(500).json({ error: 'Error al obtener los productos' });
    }

    return res.status(200).json(data);
  } catch (error) {
    console.error('Error inesperado en obtenerPorCat:', error);
    return res.status(500).json({ error: error.message });
  }
};


// POST - Crear un nuevo producto

export const crear = async (req, res) => {
  try {
    const { nombre, descripcion, categoria, principio_activo, precio, stock } = req.body;

    // Cloudinary almacena la URL segura en req.file.path
    const imagen_url = req.file ? req.file.path : null;


       

    if (!nombre || !precio || !imagen_url) { //validacion: ahora verificamos que req.file haya entregado la url
      return res.status(400).json({ error: 'Nombre, precio e imagen_url son requeridos' });
    }

    const { data, error } = await crearProducto({
      nombre,
      descripcion,
      categoria,
      principio_activo,
      precio,
      stock,
      imagen_url
    });

    if (error) {
      console.error('Error al crear producto:', error);
      return res.status(500).json({ error: 'Error al crear el producto' });
    }

    return res.status(201).json({ message: 'Producto creado', producto: data[0] });
  } catch (error) {
    console.error('Error inesperado en crear:', error);
    return res.status(500).json({ error: error.message || 'Error desconocido' });
}
};

// PUT/PATCH - Editar un producto existente
export const editar = async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await actualizarProducto(id, req.body);

    if (error) {
      console.error('Error al actualizar producto:', error);
      return res.status(500).json({ error: 'Error al actualizar el producto' });
    }

    return res.status(200).json({ message: 'Producto actualizado', producto: data[0] });
  } catch (error) {
    console.error('Error inesperado en editar:', error);
    return res.status(500).json({ error: error.message });
  }
};

// DELETE - Eliminar un producto
export const eliminar = async (req, res) => {
  try {
    const { id } = req.params;
    const { error } = await eliminarProducto(id);

    if (error) {
      console.error('Error al eliminar producto:', error);
      return res.status(500).json({ error: 'Error al eliminar el producto' });
    }

    return res.status(200).json({ message: 'Producto eliminado' });
  } catch (error) {
    console.error('Error inesperado en eliminar:', error);
    return res.status(500).json({ error: error.message });
  }
};