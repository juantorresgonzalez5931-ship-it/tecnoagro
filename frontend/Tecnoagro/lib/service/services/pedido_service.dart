import 'dart:convert';
import 'package:frontend/service/services/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/service/services/carrito_service.dart';
import 'package:frontend/service/services/api_config.dart'; // ajusta la ruta real de ApiConfig

// ajusta la ruta real de ApiConfig

class PedidoService {
  /// Crea la reserva con lo que hay en el carrito y devuelve el pedido (con su código).
  Future<Map<String, dynamic>> crearReserva({String? telefono}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final usuarioId = prefs.getInt('user_id');

    if (token.isEmpty || usuarioId == null) {
      throw Exception('Debes iniciar sesión para reservar');
    }

    final items = CarritoService.instancia.items;
    if (items.isEmpty) throw Exception('El carrito está vacío');

    final respuesta = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/pedidos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usuario_id': usuarioId,
        'telefono': telefono,
        'detalles': items
            .map(
              (i) => {
                'producto_id': int.tryParse(i.id) ?? i.id,
                'cantidad': i.cantidad,
              },
            )
            .toList(),
      }),
    );

    final data = jsonDecode(respuesta.body);
    if (respuesta.statusCode != 201) {
      throw Exception(data['error'] ?? 'No se pudo crear la reserva');
    }
    return Map<String, dynamic>.from(data['pedido']);
  }
}
