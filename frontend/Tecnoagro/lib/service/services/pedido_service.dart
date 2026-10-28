import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/service/services/api_config.dart';
import 'package:frontend/service/services/carrito_service.dart';

class PedidoService {
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

    print('========== RESERVA ==========');
    print('TOKEN: $token');
    print('BODY ENVIADO:');
    print(jsonEncode(body));

    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/pedidos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');
    print('=============================');

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

    print('MIS PEDIDOS STATUS: ${response.statusCode}');
    print('MIS PEDIDOS RESPONSE: ${response.body}');

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

  final data = jsonDecode(response.body);

  if (response.statusCode != 200) {
    throw Exception(
      data['error'] ?? 'Error al obtener reserva',
    );
  }

  return data;
}
}