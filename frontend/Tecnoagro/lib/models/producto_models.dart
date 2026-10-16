/// Producto tal como lo devuelve GET /api/productos.
class ProductoModels {
  final dynamic id;
  final String nombre;
  final String? descripcion;
  final String? categoria;
  final String? principioActivo;
  final num precio;
  final int? stock;
  final String? imagenUrl;
  final DateTime? creadoEn;

  const ProductoModels({
    required this.id,
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.categoria,
    this.principioActivo,
    this.stock,
    this.imagenUrl,
    this.creadoEn,
  });

  factory ProductoModels.fromJson(Map<String, dynamic> json) {
    return ProductoModels(
      id: json['id'],
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: json['descripcion']?.toString(),
      categoria: json['categoria']?.toString(),
      principioActivo: json['principio_activo']?.toString(),
      // El precio puede llegar como número o como texto.
      precio: num.tryParse('${json['precio']}') ?? 0,
      stock: num.tryParse('${json['stock']}')?.toInt(),
      imagenUrl: json['imagen_url']?.toString(),
      // En tu tabla la columna se llama creado_en.
      creadoEn: DateTime.tryParse('${json['creado_en'] ?? json['created_at'] ?? ''}'),
    );
  }
}