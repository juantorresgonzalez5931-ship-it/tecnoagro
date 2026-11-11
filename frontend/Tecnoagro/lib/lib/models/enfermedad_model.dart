class ProductoRecomendado {
  final Object id;
  final String nombre;
  final String? categoria;
  final String? imagenUrl;
  final num precio;

  const ProductoRecomendado({
    required this.id,
    required this.nombre,
    required this.precio,
    this.categoria,
    this.imagenUrl,
  });

  factory ProductoRecomendado.fromJson(Map<String, dynamic> j) => ProductoRecomendado(
        id: j['id'] as Object,
        nombre: '${j['nombre'] ?? ''}',
        categoria: j['categoria']?.toString(),
        imagenUrl: j['imagen_url']?.toString(),
        precio: num.tryParse('${j['precio']}') ?? 0,
      );
}

class EnfermedadModel {
  final int id;
  final String nombre;
  final String descripcion;
  final String sintomas;
  final String tratamiento;
  final String cultivos;
  final String? imagenUrl;
  final List<ProductoRecomendado> productos;

  const EnfermedadModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.sintomas,
    required this.tratamiento,
    this.cultivos = '',
    this.imagenUrl,
    this.productos = const [],
  });

  factory EnfermedadModel.fromJson(Map<String, dynamic> j) {
    final relacion = j['enfermedad_producto'];
    final productos = <ProductoRecomendado>[];
    if (relacion is List) {
      for (final r in relacion) {
        final p = r is Map ? r['producto'] : null;
        if (p is Map) productos.add(ProductoRecomendado.fromJson(Map<String, dynamic>.from(p)));
      }
    }
    return EnfermedadModel(
      id: (j['id'] as num).toInt(),
      nombre: '${j['nombre'] ?? ''}',
      descripcion: '${j['descripcion'] ?? ''}',
      sintomas: '${j['sintomas'] ?? ''}',
      tratamiento: '${j['tratamiento'] ?? ''}',
      cultivos: '${j['cultivos'] ?? ''}',
      imagenUrl: (j['imagen_url'] ?? '').toString().isEmpty ? null : j['imagen_url'].toString(),
      productos: productos,
    );
  }

  List<String> get listaSintomas => _lineas(sintomas);
  List<String> get listaTratamiento => _lineas(tratamiento);

  List<String> get listaCultivos => cultivos
      .split(RegExp(r'[,\r\n]+'))
      .map((c) => c.trim().replaceFirst(RegExp(r'^[-•*]\s*'), ''))
      .where((c) => c.isNotEmpty)
      .toList();

  static List<String> _lineas(String texto) => texto
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim().replaceFirst(RegExp(r'^[-•*]\s*'), ''))
      .where((l) => l.isNotEmpty)
      .toList();
}