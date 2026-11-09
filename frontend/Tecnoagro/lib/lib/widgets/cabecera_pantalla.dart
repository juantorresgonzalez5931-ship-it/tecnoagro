import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';

/// Cabecera de las pantallas internas: botón de volver + título centrado.
class CabeceraPantalla extends StatelessWidget {
  final String titulo;
  const CabeceraPantalla({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borde),
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textoPrincipal),
          ),
        ),
        Expanded(
          child: Text(
            titulo,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textoPrincipal, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 40),
      ]),
    );
  }
}