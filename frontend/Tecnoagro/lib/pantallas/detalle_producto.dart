import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/core/navegacion.dart';
import 'package:frontend/models/producto_models.dart';
import 'package:frontend/service/services/carrito_service.dart';
import 'package:frontend/widgets/producto_tile.dart' show formatearPrecio;

/// Detalle de un producto: foto, precio, disponibilidad, cantidad e información.
class DetalleProductoScreen extends StatefulWidget {
  final ProductoModels producto;
  const DetalleProductoScreen({super.key, required this.producto});

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  static const _verdeSuave = Color(0xFFE6F2E6);
  int _cantidad = 1;

  ProductoModels get p => widget.producto;
  bool get _agotado => p.stock != null && p.stock! <= 0;
  int get _maximo => p.stock ?? 99;

  /// Texto y color del estado de disponibilidad según el stock.
  (String, Color) get _estado {
    final s = p.stock;
    if (s == null) return ('Disponible', AppColors.verdePrimario);
    if (s <= 0) return ('Agotado', Colors.red.shade400);
    if (s <= 10) return ('Pocas unidades ($s)', AppColors.naranjaSol);
    return ('Disponible ($s)', AppColors.verdePrimario);
  }

  void _aviso(String texto, {bool verCarrito = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texto),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.verdePrimario,
        behavior: SnackBarBehavior.floating,
        action: verCarrito
            ? SnackBarAction(
                label: 'VER CARRITO',
                textColor: Colors.white,
                onPressed: () => abrirCarrito(context),
              )
            : null,
      ),
    );
}

  void _cambiar(int delta) {
    final nueva = _cantidad + delta;
    if (nueva < 1) return;
    if (nueva > _maximo) {
      _aviso('Solo hay $_maximo unidades disponibles');
      return;
    }
    setState(() => _cantidad = nueva);
  }

  /// Manda el producto y la cantidad elegida al carrito.
  void _agregar() {
    CarritoService.instancia.agregar(CarritoItem(
      id: '${p.id}',
      nombre: p.nombre,
      categoria: p.categoria ?? '',
      precio: p.precio,
      imagen: p.imagenUrl,
      cantidad: _cantidad,
    ));
    _aviso('Agregaste $_cantidad × ${p.nombre} al carrito', verCarrito: true);
  }

  Widget _tarjeta({required Widget child, EdgeInsets padding = const EdgeInsets.all(18)}) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borde),
        ),
        child: child,
      );

  Widget _chip(String texto, Color fondo, Color letra) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
        child: Text(texto, style: TextStyle(color: letra, fontSize: 12.5, fontWeight: FontWeight.bold)),
      );

  Widget _encabezado() => Row(children: [
        Material(
          color: Colors.white,
          shape: CircleBorder(side: BorderSide(color: AppColors.borde)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: SizedBox(
                width: 44, height: 44, child: Icon(Icons.chevron_left, color: AppColors.textoPrincipal, size: 28)),
          ),
        ),
        Expanded(
          child: Text(p.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textoPrincipal, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 44),
      ]);

  Widget _imagen() {
    final vacio = Container(
      color: const Color(0xFFE8EFE6),
      child: Icon(Icons.inventory_2_outlined, color: AppColors.verdePrimario, size: 64),
    );
    return Hero(
      tag: 'producto_${p.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 260,
          width: double.infinity,
          child: p.imagenUrl == null
              ? vacio
              : Image.network(p.imagenUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => vacio),
        ),
      ),
    );
  }

  Widget _resumen() {
    final (textoEstado, colorEstado) = _estado;
    return _tarjeta(
      child: Column(spacing: 6, children: [
        _imagen(),
        const SizedBox(height: 8),
        Text(p.nombre,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textoPrincipal, fontSize: 22, fontWeight: FontWeight.bold)),
        if ((p.categoria ?? '').isNotEmpty)
          Text(p.categoria!, style: TextStyle(color: AppColors.textoSecundario, fontSize: 14)),
        Text(formatearPrecio(p.precio),
            style: TextStyle(color: AppColors.verdeTexto, fontSize: 28, fontWeight: FontWeight.bold)),
        _chip(textoEstado, colorEstado.withValues(alpha: 0.14), colorEstado),
      ]),
    );
  }

  Widget _boton(IconData icono, VoidCallback onTap) => Material(
        color: Colors.white,
        shape: CircleBorder(side: BorderSide(color: AppColors.borde)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _agotado ? null : onTap,
          child: SizedBox(width: 40, height: 40, child: Icon(icono, color: AppColors.verdePrimario, size: 20)),
        ),
      );

  Widget _selectorCantidad() => _tarjeta(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(children: [
          Text('Cantidad',
              style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          _boton(Icons.remove, () => _cambiar(-1)),
          SizedBox(
            width: 52,
            child: Text('${_agotado ? 0 : _cantidad}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textoPrincipal, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _boton(Icons.add, () => _cambiar(1)),
        ]),
      );

  Widget _dato(IconData icono, String titulo, String valor) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 18, backgroundColor: _verdeSuave, child: Icon(icono, size: 18, color: AppColors.verdePrimario)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
            Text(valor, style: TextStyle(color: AppColors.textoPrincipal, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]);

  Widget _informacion() {
    final desc = (p.descripcion ?? '').trim();
    final activo = (p.principioActivo ?? '').trim();
    return _tarjeta(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 14, children: [
        Text('Información',
            style: TextStyle(color: AppColors.textoPrincipal, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(desc.isEmpty ? 'Este producto aún no tiene descripción.' : desc,
            style: TextStyle(color: AppColors.textoPrincipal, fontSize: 15, height: 1.45)),
        Divider(color: AppColors.borde, height: 4),
        if (activo.isNotEmpty) _dato(Icons.science_outlined, 'Principio activo', activo),
        if ((p.categoria ?? '').isNotEmpty) _dato(Icons.category_outlined, 'Categoría', p.categoria!),
        if (p.stock != null) _dato(Icons.inventory_2_outlined, 'Unidades en stock', '${p.stock}'),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(spacing: 14, children: [_encabezado(), _resumen(), _selectorCantidad(), _informacion()]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _agotado ? null : _agregar,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(_agotado ? 'Producto agotado' : 'Agregar al carrito · ${formatearPrecio(p.precio * _cantidad)}'),
            ),
          ),
        ),
      ),
    );
  }
}