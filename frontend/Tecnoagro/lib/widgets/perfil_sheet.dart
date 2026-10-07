import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';

/// Panel de "Mi Perfil" para el usuario con sesión iniciada.
/// [onCerrarSesion] borra los datos guardados y refresca el home.
void mostrarPerfil(BuildContext context, String nombre, Future<void> Function() onCerrarSesion) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.fondoCrema,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFE6F2E6),
              child: Icon(Icons.person, size: 36, color: AppColors.verdePrimario)),
          const SizedBox(height: 12),
          Text(nombre,
              style: TextStyle(color: AppColors.textoPrincipal, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () async {
                await onCerrarSesion();
                if (sheet.mounted) Navigator.pop(sheet);
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.verdePrimario,
                  side: BorderSide(color: AppColors.verdePrimario),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    ),
  );
}