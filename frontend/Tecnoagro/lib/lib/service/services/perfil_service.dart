import 'dart:convert';
import 'package:frontend/lib/service/services/api_config.dart';
import 'package:http/http.dart' as http; // ajusta la ruta de tu ApiConfig
import 'package:frontend/service/services/sesion_service.dart';

class ResultadoApi {
  final bool ok;
  final String mensaje;
  const ResultadoApi(this.ok, this.mensaje);
}

class PerfilService {
  PerfilService._();

  static Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await SesionService.token() ?? ''}',
      };

  static ResultadoApi _resultado(http.Response r, String okMsg) {
    String msg = okMsg;
    try {
      final body = jsonDecode(r.body);
      if (body is Map && body['mensaje'] != null) msg = body['mensaje'].toString();
    } catch (_) {}
    return ResultadoApi(r.statusCode >= 200 && r.statusCode < 300, msg);
  }

  static Future<ResultadoApi> actualizarNombre(String nombre) async {
    try {
      final r = await http.put(
        Uri.parse('${ApiConfig.authBaseUrl}/perfil'),
        headers: await _headers(),
        body: jsonEncode({'nombre': nombre}),
      );
      return _resultado(r, 'Perfil actualizado');
    } catch (_) {
      return const ResultadoApi(false, 'No se pudo conectar con el servidor');
    }
  }

  static Future<ResultadoApi> cambiarPassword(String actual, String nueva) async {
    try {
      final r = await http.put(
        Uri.parse('${ApiConfig.authBaseUrl}/cambiar-password'),
        headers: await _headers(),
        body: jsonEncode({'actual': actual, 'nueva': nueva}),
      );
      return _resultado(r, 'Contraseña actualizada');
    } catch (_) {
      return const ResultadoApi(false, 'No se pudo conectar con el servidor');
    }
  }

  static Future<ResultadoApi> eliminarCuenta(String contrasena) async {
    try {
      final r = await http.delete(
        Uri.parse('${ApiConfig.authBaseUrl}/cuenta'),
        headers: await _headers(),
        body: jsonEncode({'contrasena': contrasena}),
      );
      return _resultado(r, 'Cuenta eliminada');
    } catch (_) {
      return const ResultadoApi(false, 'No se pudo conectar con el servidor');
    }
  }
}