import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';

/// Parte de arriba del catálogo: botón de atrás, título y un subtítulo opcional.
class EncabezadoCatalogo extends StatelessWidget {
  final String? subtitulo;
  const EncabezadoCatalogo({super.key, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(children: [
        Material(
          color: Colors.white,
          shape: CircleBorder(side: BorderSide(color: AppColors.borde)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.chevron_left, color: AppColors.textoPrincipal, size: 28)),
          ),
        ),
        Expanded(
          child: Column(children: [
            Text('Productos',
                style: TextStyle(color: AppColors.textoPrincipal, fontSize: 20, fontWeight: FontWeight.bold)),
            if (subtitulo != null)
              Text(subtitulo!, style: TextStyle(color: AppColors.textoSecundario, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 44), // equilibra el botón de atrás para centrar el título
      ]),
    );
  }
}