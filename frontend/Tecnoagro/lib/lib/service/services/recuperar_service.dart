import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Conecta con los endpoints de recuperar contraseña del backend:
///   POST /forgot-password  { email }
///   POST /verify-code      { email, codigo, nueva_contrasena }
class RecuperarService {
  /// Envía el código de 6 dígitos al correo (expira en 15 minutos).
  Future<String> enviarCodigo(String email) {
    return _post('/forgot-password', {'email': email});
  }

  /// Verifica el código y cambia la contraseña en una sola petición.
  Future<String> restablecerContrasena({
    required String email,
    required String codigo,
    required String nuevaContrasena,
  }) {
    return _post('/verify-code', {
      'email': email,
      'codigo': codigo,
      'nueva_contrasena': nuevaContrasena,
    });
  }

  Future<String> _post(String ruta, Map<String, dynamic> cuerpo) async {
    final url = Uri.parse('${ApiConfig.authBaseUrl}$ruta');

    try {
      final response = await http
          .post(url, headers: ApiConfig.headers, body: jsonEncode(cuerpo))
          .timeout(const Duration(seconds: 20));

      final contentType = response.headers['content-type'] ?? '';

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return (data['message'] ?? 'Listo').toString();
      }

      if (contentType.contains('application/json')) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ??
              errorData['message'] ??
              'Ocurrió un error, intenta de nuevo',
        );
      }

      throw Exception(
        'Servidor no disponible o ruta no encontrada (Codigo ${response.statusCode})',
      );
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder');
    } on http.ClientException {
      throw Exception('No se pudo conectar con el servidor');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}