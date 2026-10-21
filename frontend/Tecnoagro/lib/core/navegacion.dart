import 'package:flutter/material.dart';
import 'package:frontend/pantallas/admin_productos_page.dart';
import 'package:frontend/pantallas/carrito.dart';
import 'package:frontend/pantallas/productos.dart';
import 'package:frontend/service/services/sesion_service.dart';

/// Devuelve el catálogo que le corresponde al usuario: el de administrador o el de usuario común.
Future<Widget> _catalogoSegunRol() async {
  final admin = await SesionService.esAdmin();
  if (!admin) return const ProductosScreen();
  final token = await SesionService.token() ?? '';
  return AdminProductosPage(token: token);
}

/// Abre el catálogo que le corresponde al usuario: el de administrador o el de usuario común.
Future<void> abrirCatalogo(BuildContext context) async {
  final pantalla = await _catalogoSegunRol();
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => pantalla),
  );
}

/// Igual que [abrirCatalogo], pero reemplaza la pantalla actual (se usa desde el carrito).
Future<void> reemplazarPorCatalogo(BuildContext context) async {
  final pantalla = await _catalogoSegunRol();
  if (!context.mounted) return;
  await Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => pantalla),
  );
}

/// Abre el carrito. [desdeCatalogo] indica si se llegó desde la lista de productos.
Future<void> abrirCarrito(BuildContext context, {bool desdeCatalogo = false}) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CarritoScreen(desdeCatalogo: desdeCatalogo)),
  );
}