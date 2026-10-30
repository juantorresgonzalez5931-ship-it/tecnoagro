class NotificacionModel {
  final int id;
  final int usuarioId;
  final String tipo;
  final String titulo;
  final String mensaje;
  final int? productoId;
  final bool leida;
  final DateTime? fecha;

  NotificacionModel({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.productoId,
    required this.leida,
    this.fecha,
  });

  factory NotificacionModel.fromJson(
      Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id'],
      usuarioId: json['usuario_id'],
      tipo: json['tipo'] ?? '',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      productoId: json['producto_id'],
      leida: json['leida'] ?? false,
      fecha: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}