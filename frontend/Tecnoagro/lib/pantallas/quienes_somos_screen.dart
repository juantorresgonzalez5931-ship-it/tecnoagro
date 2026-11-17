import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:url_launcher/url_launcher.dart';

/// Datos del almacén. Si algo cambia, se edita solo aquí.
class _Local {
  static const nombre = 'Insumos Suaza';
  static const direccion = 'Calle 5 #7-29 Suaza-huila';
  static const barrio = 'Barrio Tarquino Beltrán';
  static const horario = 'Lunes a domingo, de 7:00 a. m. a 6:30 p. m.';
  static const imagen = 'assets/images/local_suaza.png';
  static const mapa = 'https://maps.app.goo.gl/NhkVEcsCzv3Y16hG7';
  static const telefonos = ['312 587 9355', '320 220 7265'];
  static const creadores = [
    'Juan Carlos Rivera Torrez',
    'Juan Esteban Torres Gonzalez',
  ];
}

class QuienesSomosScreen extends StatelessWidget {
  const QuienesSomosScreen({super.key});

  Future<void> _abrir(BuildContext context, Uri uri) async {
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('No se pudo abrir el enlace'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  BoxDecoration get _tarjeta => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      );

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(
          texto,
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _fila(IconData icono, String titulo, String detalle,
          {VoidCallback? onTap}) =>
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE6F2E6),
              child: Icon(icono, color: AppColors.verdePrimario, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 12,
                      )),
                  const SizedBox(height: 2),
                  Text(detalle,
                      style: const TextStyle(
                        color: AppColors.textoPrincipal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textoPlaceholder),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        backgroundColor: AppColors.fondoCrema,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textoPrincipal),
        title: const Text('Quiénes somos',
            style: TextStyle(
              color: AppColors.textoPrincipal,
              fontWeight: FontWeight.bold,
            )),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            // Foto del local
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  _Local.imagen,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.borde,
                    alignment: Alignment.center,
                    child: const Icon(Icons.storefront_outlined,
                        size: 48, color: AppColors.textoPlaceholder),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(_Local.nombre,
                style: TextStyle(
                  color: AppColors.verdeOscuro,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 4),
            const Text('Almacén de insumos agrícolas',
                style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 14,
                )),

            _titulo('Visítanos'),
            Container(
              decoration: _tarjeta,
              child: Column(children: [
                _fila(Icons.place_outlined, 'Dirección',
                    '${_Local.direccion}\n${_Local.barrio}'),
                Divider(height: 1, color: AppColors.borde),
                _fila(Icons.schedule_outlined, 'Horario', _Local.horario),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdePrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _abrir(context, Uri.parse(_Local.mapa)),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Cómo llegar',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),

            _titulo('Contacto'),
            Container(
              decoration: _tarjeta,
              child: Column(children: [
                for (var i = 0; i < _Local.telefonos.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppColors.borde),
                  _fila(
                    Icons.phone_outlined,
                    'Llamar',
                    _Local.telefonos[i],
                    onTap: () => _abrir(
                      context,
                      Uri(
                        scheme: 'tel',
                        path: _Local.telefonos[i].replaceAll(' ', ''),
                      ),
                    ),
                  ),
                ],
              ]),
            ),

            _titulo('Creadores de la app'),
            Container(
              decoration: _tarjeta,
              child: Column(children: [
                for (var i = 0; i < _Local.creadores.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppColors.borde),
                  _fila(Icons.code_rounded, 'Desarrollador',
                      _Local.creadores[i]),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}