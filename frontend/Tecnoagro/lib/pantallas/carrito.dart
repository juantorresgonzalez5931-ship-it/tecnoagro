import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/core/navegacion.dart';
import 'package:frontend/core/tema.dart';
import 'package:frontend/service/services/carrito_service.dart';
import 'package:frontend/widgets/barra_navegacion.dart';
import 'package:frontend/widgets/burbuja_ia.dart';
import 'package:frontend/widgets/producto_tile.dart' show formatearPrecio;

/// Pantalla del carrito: lista de productos, cantidades, total y mensaje de carrito vacío.
class CarritoScreen extends StatelessWidget {
  /// true si se abrió desde el catálogo (así "Productos" solo vuelve atrás).
  final bool desdeCatalogo;
  const CarritoScreen({super.key, this.desdeCatalogo = false});

  static const _verdeSuave = Color(0xFFE6F2E6);

  CarritoService get _carrito => CarritoService.instancia;

  void _irAProductos(BuildContext context) {
    if (desdeCatalogo) {
      Navigator.pop(context);
    } else {
      reemplazarPorCatalogo(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _carrito,
          builder: (context, _) => Column(children: [
            _encabezado(context),
            Expanded(child: _carrito.vacio ? _vacio(context) : _lista()),
            if (!_carrito.vacio) _resumen(context),
          ]),
        ),
      ),
      bottomNavigationBar: BarraNavegacion(
        actual: 3,
        onTap: (i) => navegarDesdeCarrito(context, i, desdeCatalogo: desdeCatalogo),
      ),
    );
  }

  Widget _encabezado(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.verdePrimario),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Carrito',
                  style: TextStyle(color: AppColors.textoPrincipal, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 44), // equilibra el botón de volver para centrar el título
        ]),
      );

  // ---------- Carrito vacío ----------

  Widget _vacio(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(color: _verdeSuave, shape: BoxShape.circle),
              child: Icon(Icons.shopping_cart_outlined, size: 52, color: AppColors.verdePrimario),
            ),
            const SizedBox(height: 20),
            Text('Tu carrito está vacío',
                style: TextStyle(color: AppColors.textoPrincipal, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Agrega productos desde el catálogo para verlos aquí.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textoSecundario, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => _irAProductos(context), child: const Text('VER PRODUCTOS')),
          ]),
        ),
      );

  // ---------- Lista de productos ----------

  Widget _lista() {
    final items = _carrito.items;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final item = items[i];
        // Deslizar hacia la izquierda también elimina el producto.
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _carrito.quitar(item.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          child: _tarjeta(item),
        );
      },
    );
  }

  Widget _tarjeta(CarritoItem item) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borde),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 72, height: 72, child: _imagen(item.imagen)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(item.categoria, style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
              const SizedBox(height: 4),
              Text('${formatearPrecio(item.precio)} Uni.',
                  style: TextStyle(color: AppColors.verdeTexto, fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(
              tooltip: 'Quitar del carrito',
              onPressed: () => _carrito.quitar(item.id),
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(height: 6),
            _selectorCantidad(item),
          ]),
        ]),
      );

  Widget _imagen(String? url) {
    final vacio = Container(
      color: _verdeSuave,
      child: Icon(Icons.image_outlined, color: AppColors.verdePrimario),
    );
    if (url == null || url.isEmpty) return vacio;
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => vacio);
  }

  Widget _selectorCantidad(CarritoItem item) => Container(
        decoration: BoxDecoration(
          color: AppColors.fondoCrema,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borde),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _paso(Icons.remove, item.cantidad > 1 ? () => _carrito.disminuir(item.id) : null),
          SizedBox(
            width: 24,
            child: Text('${item.cantidad}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textoPrincipal, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          _paso(Icons.add, () => _carrito.aumentar(item.id)),
        ]),
      );

  Widget _paso(IconData icono, VoidCallback? onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icono, size: 18, color: onTap == null ? AppColors.textoPlaceholder : AppColors.textoPrincipal),
        ),
      );

  // ---------- Resumen y botón comprar ----------

  Widget _resumen(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borde),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Subtotal', style: TextStyle(color: AppColors.textoSecundario, fontSize: 14)),
                Text(formatearPrecio(_carrito.total),
                    style: TextStyle(color: AppColors.textoPrincipal, fontSize: 14, fontWeight: FontWeight.bold)),
              ]),
              Divider(height: 24, color: AppColors.borde),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total',
                    style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(formatearPrecio(_carrito.total),
                    style: TextStyle(color: AppColors.verdeOscuro, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          // El estilo del botón viene del tema global (core/tema.dart)
          SizedBox(
            height: AppRadius.botonAlto,
            child: ElevatedButton(
              onPressed: () => mostrarProximamente(context, 'La compra'),
              child: const Text('COMPRAR'),
            ),
          ),
        ]),
      );
}