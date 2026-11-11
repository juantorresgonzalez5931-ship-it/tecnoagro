import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/pantallas/login.dart';
import 'package:frontend/service/services/sesion_service.dart';

/// Clave global para mostrar el aviso de sesión desde cualquier servicio.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Cliente HTTP pequeño que revisa las respuestas de las peticiones protegidas.
/// Úsalo solo en llamadas que envían el encabezado Authorization.
class ApiHttp {
  static bool _dialogoVisible = false;

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async => _revisar(await http.get(url, headers: headers));

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => _revisar(
        await http.post(url, headers: headers, body: body, encoding: encoding),
      );

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => _revisar(
        await http.put(url, headers: headers, body: body, encoding: encoding),
      );

  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => _revisar(
        await http.patch(url, headers: headers, body: body, encoding: encoding),
      );

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => _revisar(
        await http.delete(url, headers: headers, body: body, encoding: encoding),
      );

  /// Para solicitudes multipart (formularios con imágenes o archivos).
  static Future<http.Response> send(http.BaseRequest request) async {
    final streamed = await request.send();
    return _revisar(await http.Response.fromStream(streamed));
  }

  static Future<http.Response> _revisar(http.Response response) async {
    if (_esSesionExpirada(response)) {
      await _mostrarSesionExpirada();
    }
    return response;
  }

  static bool _esSesionExpirada(http.Response response) {
    if (response.statusCode == 401) return true;
    if (response.statusCode != 403) return false;

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) {
        final codigo = '${body['code'] ?? ''}'.toUpperCase();
        final error = '${body['error'] ?? body['message'] ?? ''}'.toLowerCase();
        return codigo == 'TOKEN_EXPIRED' ||
            error.contains('token inválido o expirado') ||
            error.contains('token invalido o expirado');
      }
    } catch (_) {
      // Si la respuesta no es JSON, no se considera automáticamente una sesión vencida.
    }
    return false;
  }

  static Future<void> _mostrarSesionExpirada() async {
    if (_dialogoVisible) return;
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    _dialogoVisible = true;
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Tu sesión ha expirado'),
            content: const Text(
              'Por seguridad, debes iniciar sesión nuevamente para continuar utilizando TecnoAgro.',
            ),
            actions: [
              FilledButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión e iniciar de nuevo'),
                onPressed: () async {
                  await SesionService.cerrarSesion();
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                  appNavigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      _dialogoVisible = false;
    }
  }
}
