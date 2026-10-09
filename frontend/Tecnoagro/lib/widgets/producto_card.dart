import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/producto_models.dart';
import 'package:frontend/widgets/producto_tile.dart' show formatearPrecio;

/// Tarjeta de producto de la cuadrícula del catálogo.
class ProductoCard extends StatelessWidget {
  final ProductoModels producto;
  const ProductoCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final vacio = Container(
      color: const Color(0xFFE8EFE6),
      child: Icon(Icons.inventory_2_outlined, color: AppColors.verdePrimario, size: 36),
    );
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              // Cambia contain por cover si prefieres que la foto llene todo el recuadro.
              child: p.imagenUrl == null
                  ? vacio
                  : Image.network(p.imagenUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => vacio),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(p.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textoPrincipal, fontSize: 15, fontWeight: FontWeight.bold)),
        if ((p.categoria ?? '').isNotEmpty)
          Text(p.categoria!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
        const SizedBox(height: 2),
        Text(formatearPrecio(p.precio),
            style: TextStyle(color: AppColors.verdeTexto, fontSize: 17, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}