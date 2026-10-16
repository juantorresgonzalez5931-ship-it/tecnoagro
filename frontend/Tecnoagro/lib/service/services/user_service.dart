import 'dart:convert';
import 'package:http/http.dart' as http;
import '/models/user_models.dart';
import 'api_config.dart';

class UserService {
  /// Crea una cuenta nueva. Devuelve la respuesta del backend: {message, emailEnviado, usuario}.
  Future<Map<String, dynamic>> crearCuenta({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
    String? fechaNacimiento,
  }) async {
    final url = Uri.parse('${ApiConfig.authBaseUrl}/register');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
          'telefono': telefono,
          'fecha_nacimiento': fechaNacimiento, // hoy el backend la ignora
        }),
      );
      final esJson = (response.headers['content-type'] ?? '').contains('application/json');
      final datos = esJson ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{};

      if (response.statusCode == 200 || response.statusCode == 201) return datos;
      throw Exception(datos['error'] ?? datos['message'] ?? 'No se pudo crear la cuenta (código ${response.statusCode})');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<UserModels> registrarUsuario(UserModels usuario) async {
    final url = Uri.parse('${ApiConfig.authBaseUrl}/register');

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

  // Peticion POST para iniciar sesion
  Future<Map<String, dynamic>> loginUsuario(
    String email,
    String password,
  ) async {
    final url = Uri.parse('${ApiConfig.authBaseUrl}/login');

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      final contentType = response.headers['content-type'] ?? '';

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        if (contentType.contains('application/json')) {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
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