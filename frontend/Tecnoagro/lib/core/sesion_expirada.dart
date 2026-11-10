import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/service/services/carrito_service.dart';
// OJO: ajusta este import al archivo real de tu pantalla de login
// (la que contiene la clase LoginScreen).
import 'package:frontend/pantallas/login.dart';

/// Llave global del Navigator. Se conecta en main.dart:
///   MaterialApp(navigatorKey: navegadorGlobal, ...)
final GlobalKey<NavigatorState> navegadorGlobal = GlobalKey<NavigatorState>();

/// Se lanza cuando el servidor responde 401 (token vencido o inválido).
/// Las pantallas la usan para NO mostrar el mensaje rojo, porque el manejo
/// de la sesión ya se hizo solo.
class SesionExpiradaException implements Exception {
  @override
  String toString() => 'La sesión expiró, por favor inicia sesión nuevamente';
}

bool _redirigiendo = false;

/// Borra la sesión guardada, limpia el carrito en memoria y lleva al login.
/// Se puede llamar desde cualquier servicio, sin necesidad de un BuildContext.
Future<void> manejarSesionExpirada() async {
  if (_redirigiendo) return; // evita ejecutarse varias veces seguidas
  _redirigiendo = true;

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    await prefs.remove('user_rol');
    await prefs.remove('user_id');

    // Sin user_id, esto vacía el carrito EN MEMORIA y no toca el guardado
    // en disco: al volver a entrar, el carrito del usuario se recupera.
    await CarritoService.instancia.cargarCarritoUsuario();

    navegadorGlobal.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );

    // Aviso amable (no rojo) ya en la pantalla de login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navegadorGlobal.currentContext;
      if (ctx == null) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Tu sesión expiró. Inicia sesión de nuevo para continuar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  } finally {
    // Pequeña pausa para no redirigir dos veces por peticiones simultáneas.
    Future.delayed(const Duration(seconds: 2), () => _redirigiendo = false);
  }
}