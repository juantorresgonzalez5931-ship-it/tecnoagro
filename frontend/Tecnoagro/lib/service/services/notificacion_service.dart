import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/notificacion_model.dart';
import 'api_config.dart';
import 'sesion_service.dart';

class NotificacionService {
  Future<List<NotificacionModel>>
      obtenerNotificaciones() async {
    final token = await SesionService.token();

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.apiBaseUrl}/notificaciones',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron obtener las notificaciones',
      );
    }

    final List<dynamic> data =
        jsonDecode(response.body);

    return data
        .map(
          (e) => NotificacionModel.fromJson(e),
        )
        .toList();
  }

  Future<int> obtenerCantidadNoLeidas() async {
    final token = await SesionService.token();

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.apiBaseUrl}/notificaciones/no-leidas',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return 0;
    }

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    return data['cantidad'] ?? 0;
  }

  Future<void> marcarLeida(int id) async {
    final token = await SesionService.token();

    await http.put(
      Uri.parse(
        '${ApiConfig.apiBaseUrl}/notificaciones/$id/leida',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}