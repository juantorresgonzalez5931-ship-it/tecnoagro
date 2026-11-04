import 'dart:convert';
import 'package:frontend/service/services/api_config.dart';
import 'package:frontend/service/services/sesion_service.dart';
import 'package:http/http.dart' as http;

class NotificacionModel {
  final int id;
  final String tipo; // 'reserva' | 'producto'
  final String titulo;
  final String mensaje;
  final int? referenciaId;
  bool leida;
  final DateTime? creadoEn;

  NotificacionModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.referenciaId,
    this.leida = false,
    this.creadoEn,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> j) => NotificacionModel(
        id: (j['id'] as num).toInt(),
        tipo: '${j['tipo'] ?? ''}',
        titulo: '${j['titulo'] ?? ''}',
        mensaje: '${j['mensaje'] ?? ''}',
        referenciaId: (j['producto_id'] as num?)?.toInt(),
        leida: j['leida'] == true,
        creadoEn: DateTime.tryParse('${j['created_at'] ?? ''}')?.toLocal(),
      );
}

class NotificacionesResultado {
  final List<NotificacionModel> lista;
  final int noLeidas;
  const NotificacionesResultado(this.lista, this.noLeidas);
}

class NotificacionService {
  Uri _url([String extra = '']) => Uri.parse('${ApiConfig.apiBaseUrl}/notificaciones$extra');

  Future<Map<String, String>> _headers() async => {
        ...ApiConfig.headers,
        'Authorization': 'Bearer ${await SesionService.token() ?? ''}',
        'Content-Type': 'application/json',
      };

Future<NotificacionesResultado> listar() async {
  final res = await http.get(
    _url(),
    headers: await _headers(),
  );

  if (res.statusCode != 200) {
    throw 'No se pudieron cargar las notificaciones';
  }

  final List<dynamic> data =
      jsonDecode(utf8.decode(res.bodyBytes));

  final lista = data
      .map(
        (e) => NotificacionModel.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
      .toList();

  final noLeidas =
      lista.where((n) => !n.leida).length;

  return NotificacionesResultado(
    lista,
    noLeidas,
  );
}

  /// Solo el número de notificaciones sin leer (lo usa el contador de la campana).
  Future<int> obtenerCantidadNoLeidas() async => (await listar()).noLeidas;

Future<void> marcarLeida(int id) async {
  final res = await http.put(
    _url('/$id/leida'),
    headers: await _headers(),
  );

  if (res.statusCode != 200) {
    throw 'No se pudo marcar como leída';
  }
}

  Future<void> marcarTodasLeidas() async {
    final res = await http.patch(_url('/leer-todas'), headers: await _headers());
    if (res.statusCode != 200) throw 'No se pudieron marcar como leídas';
  }
}