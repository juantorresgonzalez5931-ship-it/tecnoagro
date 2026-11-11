import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/widgets/cabecera_pantalla.dart';
import 'package:frontend/widgets/producto_tile.dart' show formatearPrecio;

/// Miniatura cuadrada de un producto (con ícono si no hay imagen).
class MiniaturaProducto extends StatelessWidget {
  final String? url;
  final double tamano;
  const MiniaturaProducto({super.key, this.url, this.tamano = 60});

  @override
  Widget build(BuildContext context) {
    final vacio = Container(
      color: const Color(0xFFE8EFE6),
      child: Icon(Icons.inventory_2_outlined, color: AppColors.verdePrimario, size: tamano * 0.45),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: (url == null || url!.isEmpty)
            ? vacio
            : Image.network(url!, fit: BoxFit.contain, errorBuilder: (_, _, _) => vacio),
      ),
    );
  }
}

/// Pantalla para elegir productos con su imagen. Devuelve el Set de ids (como texto).
class SelectorProductosScreen extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  final Set<String> seleccionados;
  const SelectorProductosScreen({super.key, required this.productos, required this.seleccionados});

  @override
  State<SelectorProductosScreen> createState() => _SelectorProductosScreenState();
}

class _SelectorProductosScreenState extends State<SelectorProductosScreen> {
  late final Set<String> _sel = {...widget.seleccionados};
  final _busquedaCtrl = TextEditingController();

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtrados {
    final q = _busquedaCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.productos;
    return widget.productos
        .where((p) =>
            '${p['nombre'] ?? ''}'.toLowerCase().contains(q) ||
            '${p['categoria'] ?? ''}'.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: Column(children: [
          const CabeceraPantalla(titulo: 'Elegir productos'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _busquedaCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar producto',
                prefixIcon: Icon(Icons.search, color: AppColors.textoSecundario),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.borde),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.borde),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.verdePrimario),
                ),
              ),
            ),
          ),
          Expanded(
            child: lista.isEmpty
                ? Center(child: Text('Sin resultados', style: TextStyle(color: AppColors.textoSecundario)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = lista[i];
                      final id = '${p['id']}';
                      final elegido = _sel.contains(id);
                      final categoria = '${p['categoria'] ?? ''}';
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => elegido ? _sel.remove(id) : _sel.add(id)),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: elegido ? AppColors.verdePrimario : AppColors.borde,
                                width: elegido ? 2 : 1,
                              ),
                            ),
                            child: Row(children: [
                              MiniaturaProducto(url: p['imagen_url']?.toString(), tamano: 64),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${p['nombre'] ?? ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: AppColors.textoPrincipal,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  if (categoria.isNotEmpty)
                                    Text(categoria,
                                        style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
                                  const SizedBox(height: 2),
                                  Text(formatearPrecio(num.tryParse('${p['precio']}') ?? 0),
                                      style: TextStyle(
                                          color: AppColors.verdeTexto,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                ]),
                              ),
                              Icon(
                                elegido ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: elegido ? AppColors.verdePrimario : AppColors.textoSecundario,
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _sel),
                child: Text('LISTO (${_sel.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}