import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/producto_models.dart';

/// Banner verde del inicio. Muestra el producto más nuevo del catálogo;
/// si todavía no cargó (o no hay productos) muestra un texto general.
class BannerNuevoProducto extends StatelessWidget {
  final ProductoModels? producto;
  const BannerNuevoProducto({super.key, this.producto});

  @override
  Widget build(BuildContext context) {
    final vacio = Container(
      color: const Color(0xFFE8EFE6),
      child: Icon(Icons.eco_outlined, size: 44, color: AppColors.verdePrimario),
    );
    final url = producto?.imagenUrl;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.verdePrimario, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NUEVO PRODUCTO',
                style: TextStyle(color: AppColors.verdeClaro, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(producto?.nombre ?? 'Conoce lo nuevo en nuestro catálogo',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.25)),
            if (producto != null) ...[
              const SizedBox(height: 6),
              const Text('¡Ya llegó a TecnoAgro! Descúbrelo y dale lo mejor a tu cultivo 🌱',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.35)),
            ],
          ]),
        ),
        const SizedBox(width: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 108,
            height: 108,
            child: url == null
                ? vacio
                : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => vacio),
          ),
        ),
      ]),
    );
  }
}