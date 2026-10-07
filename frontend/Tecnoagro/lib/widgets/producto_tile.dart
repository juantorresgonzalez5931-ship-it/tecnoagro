import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/producto_models.dart';

/// 70000 -> $70.000
String formatearPrecio(num valor) {
  final texto = valor.round().toString();
  return '\$${texto.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
}

/// Tarjeta de producto de la lista "Más Buscados".
class ProductoTile extends StatelessWidget {
  final ProductoModels producto;
  const ProductoTile({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final vacio = Container(
      color: const Color(0xFFE8EFE6),
      child: Icon(Icons.inventory_2_outlined, color: AppColors.verdePrimario, size: 28),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 64,
            height: 64,
            child: producto.imagenUrl == null
                ? vacio
                : Image.network(producto.imagenUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => vacio),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(producto.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(formatearPrecio(producto.precio),
                style: TextStyle(color: AppColors.verdeTexto, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }
}