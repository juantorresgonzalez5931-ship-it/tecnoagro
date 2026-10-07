/// Producto tal como lo devuelve GET /api/productos.
class ProductoModels {
  final dynamic id;
  final String nombre;
  final String? descripcion;
  final String? categoria;
  final num precio;
  final String? imagenUrl;
  final DateTime? creadoEn;

  const ProductoModels({
    required this.id,
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.categoria,
    this.imagenUrl,
    this.creadoEn,
  });

  factory ProductoModels.fromJson(Map<String, dynamic> json) {
    return ProductoModels(
      id: json['id'],
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: json['descripcion']?.toString(),
      categoria: json['categoria']?.toString(),
      // El precio puede llegar como número o como texto.
      precio: num.tryParse('${json['precio']}') ?? 0,
      imagenUrl: json['imagen_url']?.toString(),
      // Solo existe si tu tabla tiene created_at (Supabase la crea por defecto).
      creadoEn: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }
}