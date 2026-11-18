import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'carrito_service.dart';

/// Se lanza cuando la persona cierra el selector de cuentas sin elegir ninguna.
class GoogleCancelado implements Exception {}

class GoogleService {
  /// ID de cliente de tipo "Aplicación web" de Google Cloud (el mismo GOOGLE_CLIENT_ID del backend).
  static const _webClientId = '249343116517-a0ea8tfablp3f6tullkshqcjt0gb9iqe.apps.googleusercontent.com';

  static Future<void>? _inicio;

  static Future<void> _inicializar() =>
      _inicio ??= GoogleSignIn.instance.initialize(serverClientId: _webClientId);

  /// Abre el selector de cuentas de Google, valida el token con el backend y guarda la sesión.
  /// Sirve igual para iniciar sesión y para registrarse. Devuelve el nombre del usuario.
  Future<String> iniciarSesion() async {
    await _inicializar();

    final GoogleSignInAccount cuenta;
    try {
      // No llamar signOut() antes de authenticate().
      // En Android, signOut() limpia la credencial de Credential Manager y
      // puede provocar "Account reauth failed" al seleccionar una cuenta.
      cuenta = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In: ${e.code} ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) throw GoogleCancelado();
      throw Exception('No se pudo iniciar con Google (${e.code.name})');
    }

    final idToken = cuenta.authentication.idToken;
    if (idToken == null) throw Exception('Google no entregó el token. Revisa el ID de cliente web.');

    final response = await http.post(
      Uri.parse('${ApiConfig.authBaseUrl}/google'),
      headers: ApiConfig.headers,
      body: jsonEncode({'idToken': idToken}),
    ).timeout(
      const Duration(seconds: 25),
      onTimeout: () => throw Exception(
        'El servidor está tardando demasiado. Intenta nuevamente en unos segundos.',
      ),
    );
    final esJson = (response.headers['content-type'] ?? '').contains('application/json');
    final datos = esJson ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{};
    if (response.statusCode != 200) {
      throw Exception(datos['error'] ?? 'No se pudo iniciar sesión (código ${response.statusCode})');
    }

    final usuario = datos['usuario'] as Map<String, dynamic>;
    final nombre = '${usuario['nombre'] ?? 'Usuario'}';
    final rol = '${usuario['rol'] ?? 'usuario'}'.trim();

    final idRaw = usuario['id'];
    final idUsuario = idRaw is int ? idRaw : int.tryParse('$idRaw');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', '${datos['token']}');
    await prefs.setString('user_name', nombre);
    await prefs.setString('user_rol', rol);
    if (idUsuario != null) {
      await prefs.setInt('user_id', idUsuario);
      // Recupera el carrito guardado de esta cuenta.
      await CarritoService.instancia.cargarCarritoUsuario();
    }
    return nombre;
  }
}