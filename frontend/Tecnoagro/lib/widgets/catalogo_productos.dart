import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/producto_models.dart';
import 'package:frontend/widgets/filtro_categorias.dart';
import 'package:frontend/service/services/producto_service.dart';
import 'package:frontend/widgets/producto_card.dart';

/// Buscador, filtro por categoría y cuadrícula de productos (datos de GET /api/productos).
/// [accionExtra] se muestra entre el buscador y la cuadrícula; el administrador lo usa
/// para el botón "Añadir producto".
class CatalogoProductos extends StatefulWidget {
  final Widget? accionExtra;
  const CatalogoProductos({super.key, this.accionExtra});

  @override
  State<CatalogoProductos> createState() => CatalogoProductosState();
}

class CatalogoProductosState extends State<CatalogoProductos> {
  final _servicio = ProductoService();
  final _busquedaCtrl = TextEditingController();
  List<ProductoModels> _productos = [];
  bool _cargando = true;
  String? _error;
  String? _categoria; // null = todas

  @override
  void initState() {
    super.initState();
    recargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  /// Vuelve a pedir los productos al backend.
  Future<void> recargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _servicio.listarProductos();
      if (mounted) setState(() => _productos = lista);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Aplica la búsqueda (nombre, categoría y descripción) y la categoría elegida.
  List<ProductoModels> get _filtrados {
    final q = _busquedaCtrl.text.trim().toLowerCase();
    return _productos.where((p) {
      if (_categoria != null && p.categoria != _categoria) return false;
      if (q.isEmpty) return true;
      return '${p.nombre} ${p.categoria ?? ''} ${p.descripcion ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _abrirFiltros() async {
    final categorias = _productos
        .map((p) => p.categoria)
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final elegida = await elegirCategoria(context, categorias, _categoria);
    if (elegida != null && mounted) setState(() => _categoria = elegida.$1);
  }

  Widget _mensaje(String texto, {bool reintentar = false}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(texto,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textoSecundario, fontSize: 15)),
            if (reintentar)
              TextButton(
                onPressed: recargar,
                child: Text('Reintentar',
                    style: TextStyle(color: AppColors.verdePrimario, fontWeight: FontWeight.bold)),
              ),
          ]),
        ),
      );

  Widget _contenido() {
    if (_cargando) return Center(child: CircularProgressIndicator(color: AppColors.verdePrimario));
    if (_error != null) return _mensaje('$_error', reintentar: true);
    final lista = _filtrados;
    if (lista.isEmpty) {
      return _mensaje(_productos.isEmpty ? 'Aún no hay productos' : 'No encontramos productos con esa búsqueda');
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: lista.length,
      itemBuilder: (_, i) => ProductoCard(producto: lista[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: AppColors.borde),
    );
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _busquedaCtrl,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar agroquímicos, abonos...',
                hintStyle: TextStyle(color: AppColors.textoPlaceholder, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.textoSecundario),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: borde,
                enabledBorder: borde,
                focusedBorder: borde.copyWith(borderSide: BorderSide(color: AppColors.verdePrimario, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.verdePrimario,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _productos.isEmpty ? null : _abrirFiltros,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  // El punto naranja avisa que hay una categoría elegida.
                  child: Badge(
                    smallSize: 10,
                    isLabelVisible: _categoria != null,
                    backgroundColor: AppColors.naranjaSol,
                    child: const Icon(Icons.tune, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
      if (widget.accionExtra != null)
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: widget.accionExtra),
      const SizedBox(height: 16),
      Expanded(child: _contenido()),
    ]);
  }
}