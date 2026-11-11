import 'dart:convert';
import 'package:frontend/service/services/api_config.dart';
import 'package:frontend/service/services/sesion_service.dart';
import 'package:http/http.dart' as http;

class ResultadoPerfil {
  final bool ok;
  final String mensaje;
  const ResultadoPerfil(this.ok, this.mensaje);
}

class PerfilService {
  PerfilService._();

  static Future<ResultadoPerfil> eliminarCuenta() async {
    try {
      final token = await SesionService.token();
      final response = await http.delete(
        Uri.parse('${ApiConfig.authBaseUrl}/cuenta'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
        },
      );
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      return ResultadoPerfil(
        ok,
        body['message']?.toString() ??
            body['error']?.toString() ??
            (ok ? 'Cuenta eliminada' : 'No se pudo eliminar la cuenta'),
      );
    } catch (_) {
      return const ResultadoPerfil(
        false,
        'No se pudo conectar con el servidor. Inténtalo nuevamente.',
      );
    }
  }
}
