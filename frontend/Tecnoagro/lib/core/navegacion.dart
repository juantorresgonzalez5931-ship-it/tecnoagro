import 'package:flutter/material.dart';
import 'package:frontend/pantallas/carrito.dart';
import 'package:frontend/pantallas/productos.dart';
import 'package:frontend/productos_admin/productos_screen.dart';

import 'package:frontend/service/services/sesion_service.dart';

/// Abre el catálogo que le corresponde al usuario: el de administrador o el de usuario común.
Future<void> abrirCatalogo(BuildContext context) async {
  final admin = await SesionService.esAdmin();
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ProductosScreen()),
  );
}

/// Igual que [abrirCatalogo], pero reemplaza la pantalla actual (se usa desde el carrito).
Future<void> reemplazarPorCatalogo(BuildContext context) async {
  final admin = await SesionService.esAdmin();
  if (!context.mounted) return;
  await Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => admin ? const ProductosAdminScreen() : const ProductosScreen()),
  );
}

/// Abre el carrito. [desdeCatalogo] indica si se llegó desde la lista de productos.
Future<void> abrirCarrito(BuildContext context, {bool desdeCatalogo = false}) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CarritoScreen(desdeCatalogo: desdeCatalogo)),
  );
}