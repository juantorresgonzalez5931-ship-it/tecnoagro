import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/producto_models.dart';
import 'package:frontend/pantallas/detalle_producto.dart';
import 'package:frontend/widgets/producto_tile.dart' show formatearPrecio;

/// Tarjeta de producto de la cuadrícula del catálogo. Al tocarla abre el detalle.
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
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borde),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetalleProductoScreen(producto: p)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Expanded(
              child: Hero(
                tag: 'producto_${p.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: p.imagenUrl == null
                        ? vacio
                        : Image.network(p.imagenUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => vacio),
                  ),
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
        ),
      ),
    );
  }
}