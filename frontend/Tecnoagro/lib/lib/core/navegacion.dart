import 'package:flutter/material.dart';
import 'package:frontend/admin/admin_productos_page.dart';
import 'package:frontend/pantallas/carrito.dart';
import 'package:frontend/pantallas/productos.dart';
import 'package:frontend/service/services/sesion_service.dart';
import 'package:frontend/Ia_screeen/asesor_ia_screen.dart';


/// Devuelve el catÃ¡logo que le corresponde al usuario: el de administrador o el de usuario comÃºn.
Future<Widget> _catalogoSegunRol() async {
  final admin = await SesionService.esAdmin();
  if (!admin) return const ProductosScreen();
  final token = await SesionService.token() ?? '';
  return AdminProductosPage(token: token);
}

/// Abre el catÃ¡logo que le corresponde al usuario: el de administrador o el de usuario comÃºn.
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

/// Abre el carrito. [desdeCatalogo] indica si se llegÃ³ desde la lista de productos.
Future<void> abrirCarrito(BuildContext context, {bool desdeCatalogo = false}) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CarritoScreen(desdeCatalogo: desdeCatalogo)),
  );
}


/// Abre el chat con la IA.
Future<void> abrirChatBotIA(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AsesorIAScreen()), // ajusta el nombre
  );
}


/// Abre el chat de la IA como panel desde abajo.
Future<void> abrirChatBurbuja(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: const AsesorIAScreen(), // ajusta el nombre
      ),
    ),
  );
}
