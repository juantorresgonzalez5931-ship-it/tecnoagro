import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/lib/pantallas/login.dart';
import 'package:frontend/lib/service/services/carrito_service.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/service/services/sesion_service.dart';
// import 'package:frontend/.../carrito_service.dart';   // ajusta la ruta
// import 'package:frontend/.../login_screen.dart';      // ajusta la ruta

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _dialogoAbierto = false;

/// Devuelve true si la respuesta fue de sesión expirada (y ya mostró el diálogo).
Future<bool> revisarSesionExpirada(http.Response response) async {
  if (response.statusCode != 401) return false;

  try {
    final body = jsonDecode(response.body);
    if (body['code'] != 'TOKEN_EXPIRED' && body['code'] != 'TOKEN_MISSING') {
      return false;
    }
  } catch (_) {
    return false;
  }

  await _mostrarDialogoSesionExpirada();
  return true;
}

Future<void> _mostrarDialogoSesionExpirada() async {
  if (_dialogoAbierto) return;
  final contexto = navigatorKey.currentContext;
  if (contexto == null) return;

  _dialogoAbierto = true;

  await showDialog(
    context: contexto,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('La sesión expiró'),
      content: const Text('Vuelve a iniciar sesión para continuar.'),
      actions: [
        ElevatedButton(
          onPressed: () async {
            await SesionService.cerrarSesion();
            CarritoService.instancia.vaciar();
            navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()), // tu pantalla de login
              (ruta) => false,
            );
          },
          child: const Text('Iniciar sesión'),
        ),
      ],
    ),
  );

  _dialogoAbierto = false;
}