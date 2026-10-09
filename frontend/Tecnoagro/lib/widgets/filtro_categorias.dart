import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';

/// Panel para elegir la categoría del catálogo. Devuelve la elegida dentro de un registro:
/// `(null,)` significa "Todas" y `null` significa que cerró el panel sin elegir.
Future<(String?,)?> elegirCategoria(BuildContext context, List<String> categorias, String? actual) {
  return showModalBottomSheet<(String?,)>(
    context: context,
    backgroundColor: AppColors.fondoCrema,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Filtrar por categoría',
              style: TextStyle(color: AppColors.textoPrincipal, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in <String?>[null, ...categorias])
              ChoiceChip(
                label: Text(c ?? 'Todas'),
                selected: actual == c,
                showCheckmark: false,
                selectedColor: AppColors.verdePrimario,
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColors.borde),
                labelStyle: TextStyle(
                  color: actual == c ? Colors.white : AppColors.textoPrincipal,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => Navigator.pop(sheet, (c,)),
              ),
          ]),
        ]),
      ),
    ),
  );
}