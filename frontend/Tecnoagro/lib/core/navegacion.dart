import 'package:flutter/material.dart';
import 'package:frontend/pantallas/productos.dart';
import 'package:frontend/productos_admin/productos_screen.dart';
import 'package:frontend/service/services/sesion_service.dart';

/// Abre el catálogo que le corresponde al usuario: el de administrador o el de usuario común.
Future<void> abrirCatalogo(BuildContext context) async {
  final admin = await SesionService.esAdmin();
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => admin ? const ProductosAdminScreen() : const ProductosScreen()),
  );
}