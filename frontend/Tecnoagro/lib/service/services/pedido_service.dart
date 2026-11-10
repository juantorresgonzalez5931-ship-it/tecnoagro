import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/service/services/api_config.dart';
import 'package:frontend/service/services/carrito_service.dart';
import 'package:frontend/core/sesion_expirada.dart';

class PedidoService {
  /// Si el servidor dice 401, cierra la sesión, manda al login y corta la ejecución.
  Future<void> _revisarSesion(http.Response response) async {
    if (response.statusCode == 401) {
      await manejarSesionExpirada();
      throw SesionExpiradaException();
    }
  }

  Future<Map<String, dynamic>> crearReserva({
    String? telefono,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('jwt_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Debes iniciar sesión para reservar');
    }

    final items = CarritoService.instancia.items;

    if (items.isEmpty) {
      throw Exception('El carrito está vacío');
    }

    final body = {
      'telefono': telefono ?? '',
      'detalles': items.map((item) {
        return {
          'producto_id': int.tryParse(item.id) ?? item.id,
          'cantidad': item.cantidad,
        };
      }).toList(),
    };

    final url = '${ApiConfig.apiBaseUrl}/pedidos';
    debugPrint('RESERVA -> POST $url');
    debugPrint('BODY ENVIADO: ${jsonEncode(body)}');

    final sw = Stopwatch()..start();

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      debugPrint('RESERVA falló a los ${sw.elapsedMilliseconds} ms: $e');
      throw Exception('No se pudo conectar con el servidor. Intenta de nuevo.');
    }

    debugPrint('RESERVA respondió en ${sw.elapsedMilliseconds} ms');
    await _revisarSesion(response);
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('RESPONSE: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['error'] ?? 'No se pudo crear la reserva',
      );
    }

    return Map<String, dynamic>.from(data['pedido']);
  }

  Future<List<dynamic>> obtenerMisPedidos() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('jwt_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Debe iniciar sesión');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}/mis-pedidos'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('MIS PEDIDOS STATUS: ${response.statusCode}');
    await _revisarSesion(response);

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['error'] ?? 'Error al obtener reservas',
      );
    }

    return data;
  }

  Future<Map<String, dynamic>> obtenerPedido(
    int id,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}/pedidos/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    await _revisarSesion(response);

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['error'] ?? 'Error al obtener reserva',
      );
    }

    return data;
  }
}