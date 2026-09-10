import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_models.dart';
import 'api_config.dart';

class UserService {
  Future<UserModels> registrarUsuario(UserModels usuario) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/register');

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(usuario.toJson()),
      );

      print('==============================');
      print('URL: $url');
      print('STATUS CODE: ${response.statusCode}');
      print('HEADERS: ${response.headers}');
      print('BODY: ${response.body}');
      print('==============================');

      final contentType = response.headers['content-type'] ?? '';

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        return UserModels.fromJson(responseData);
      } else {
        if (contentType.contains('application/json')) {
          final Map<String, dynamic> errorData = jsonDecode(response.body);

          final String mensajeError =
              errorData['message'] ??
              errorData['error'] ??
              'Error desconocido en el servidor';

          throw Exception(mensajeError);
        } else {
          throw Exception(
            'Error del servidor. Código: ${response.statusCode}. '
            'Respuesta: ${response.body}',
          );
        }
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Peticion POST para iniciar sesion (NUEVO, dentro de la misma clase)
  Future<Map<String, dynamic>> loginUsuario(
    String email,
    String password,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/login');

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      final contentType = response.headers['content-type'] ?? '';

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // Devuelve el mapa completo con 'token' y 'usuario' tal como responde el backend
        return responseData;
      } else {
        if (contentType.contains('application/json')) {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          // El backend Express envia el mensaje en la clave 'error'
          final String mensajeError =
              errorData['error'] ??
              errorData['message'] ??
              'Credenciales incorrectas';
          throw Exception(mensajeError);
        } else {
          throw Exception(
            'Servidor no disponible o ruta no encontrada (Codigo ${response.statusCode})',
          );
        }
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
