import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SesionService {
  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, dynamic>?> datosToken() async {
    final jwt = await token();

    if (jwt == null || jwt.isEmpty) {
      return null;
    }

    final partes = jwt.split('.');

    if (partes.length != 3) {
      return null;
    }

    try {
      return jsonDecode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(partes[1]),
          ),
        ),
      ) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<int?> usuarioId() async {
    final datos = await datosToken();

    if (datos == null) {
      return null;
    }

    final id = datos['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse('$id');
  }

  static Future<String?> nombre() async {
    final datos = await datosToken();

    if (datos == null) {
      return null;
    }

    final nombre = datos['nombre'];
    return nombre == null ? null : '$nombre';
  }

  static Future<String?> email() async {
    final datos = await datosToken();

    if (datos == null) {
      return null;
    }

    final email = datos['email'];
    return email == null ? null : '$email';
  }

  static Future<String?> rol() async {
    final datos = await datosToken();

    if (datos == null) {
      return null;
    }

    final rol = datos['rol'];
    return rol == null ? null : '$rol'.trim();
  }

  static Future<bool> esAdmin() async {
    final datos = await datosToken();

    if (datos == null) {
      return false;
    }

    final exp = datos['exp'];

    if (exp is int) {
      final expiracion =
          DateTime.fromMillisecondsSinceEpoch(exp * 1000);

      if (expiracion.isBefore(DateTime.now())) {
        return false;
      }
    }

    return '${datos['rol'] ?? ''}'.trim() == 'admin';
  }

  static Future<bool> haySesion() async {
    final jwt = await token();
    return jwt != null && jwt.isNotEmpty;
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    await prefs.remove('user_rol');
  }
}