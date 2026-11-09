import 'dart:async';
import 'dart:math' as m;
import 'package:flutter/material.dart';
import 'package:frontend/Ia_screeen/asesor_ia_screen.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/enfermedad_model.dart';
import 'package:frontend/models/producto_models.dart';
import 'package:frontend/pantallas/detalle_enfermedad.dart';
import 'package:frontend/pantallas/detalle_producto.dart';
import 'package:frontend/service/services/enfermedad_service.dart';
import 'package:frontend/service/services/producto_service.dart';
import 'package:frontend/service/services/voz_service.dart';
import 'package:frontend/widgets/busqueda_widgets.dart';
import 'package:frontend/widgets/producto_tile.dart' show formatearPrecio;
import 'package:shared_preferences/shared_preferences.dart';

String _plano(String s) {
  const con = 'áàäâéèëêíìïîóòöôúùüûñ', sin = 'aaaaeeeeiiiioooouuuun';
  return s
      .toLowerCase()
      .split('')
      .map((c) => con.contains(c) ? sin[con.indexOf(c)] : c)
      .join();
}

class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({super.key});

  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  final _ctrl = TextEditingController();
  final _voz = VozService();
  Timer? _pausa;
  List<ProductoModels> _productos = [];
  List<EnfermedadModel> _enfermedades = [];
  List<String> _recientes = [];
  bool _cargando = true, _escuchando = false;
  String? _error, _categoria;
  String _consulta = '';
  int _seccion = 0; // 0 todo, 1 productos, 2 enfermedades
  RangeValues? _rango;
  double _min = 0, _max = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _pausa?.cancel();
    _voz.cancelar();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        ProductoService().listarProductos(),
        EnfermedadService().listar(),
      ]);
      _productos = r[0] as List<ProductoModels>;
      _enfermedades = r[1] as List<EnfermedadModel>;
      final precios = _productos.map((p) => p.precio.toDouble());
      if (precios.isNotEmpty) {
        _min = precios.reduce(m.min).floorToDouble();
        _max = precios.reduce(m.max).ceilToDouble();
      }
      _recientes =
          (await SharedPreferences.getInstance()).getStringList('recientes') ??
          [];
    } catch (e) {
      _error = '$e'.replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _setRecientes(List<String> l) async {
    setState(() => _recientes = l);
    (await SharedPreferences.getInstance()).setStringList('recientes', l);
  }

  void _guardar(String t) {
    t = t.trim();
    if (t.length > 1)
      _setRecientes(
        [
          t,
          ..._recientes.where((r) => _plano(r) != _plano(t)),
        ].take(5).toList(),
      );
  }

  void _poner(String t) {
    _pausa?.cancel();
    _ctrl.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
    setState(() => _consulta = t);
    _guardar(t);
  }

  void _ir(Widget pantalla) {
    _guardar(_consulta);
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  bool _ok(String texto) {
    final t = _plano(texto);
    return _plano(
      _consulta,
    ).split(' ').where((w) => w.isNotEmpty).every(t.contains);
  }

  bool _pasa(ProductoModels p) =>
      (_categoria == null || p.categoria == _categoria) &&
      (_rango == null ||
          (p.precio >= _rango!.start && p.precio <= _rango!.end));

  Future<void> _alternarVoz() async {
    if (_escuchando) return _voz.detener();
    setState(() => _escuchando = true);
    final ok = await _voz.escuchar((t, fin) {
      _ctrl.text = t;
      if (mounted) setState(() => _consulta = t);
      if (fin) _guardar(t);
    }, () => mounted ? setState(() => _escuchando = false) : null);
    if (!ok && mounted) {
      setState(() => _escuchando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo activar el micrófono')),
      );
    }
  }

  Future<void> _filtros() async {
    final cats = {
      for (final p in _productos) p.categoria,
    }.whereType<String>().where((c) => c.isNotEmpty).toList()..sort();
    final r = await mostrarFiltros(context, cats, _min, _max, (
      categoria: _categoria,
      rango: _rango,
    ));
    if (r != null) {
      setState(() {
        _categoria = r.categoria;
        _rango = r.rango;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sugerencias = [
      ...{
        for (final p in _productos) p.categoria,
      }.whereType<String>().where((c) => c.isNotEmpty).take(4),
      ...{for (final e in _enfermedades) ...e.listaCultivos}.take(3),
    ];
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: Column(
          children: [
            CampoBusqueda(
              controller: _ctrl,
              escuchando: _escuchando,
              onSubmitted: _guardar,
              onLimpiar: () => _poner(''),
              onVoz: _alternarVoz,
              onChanged: (v) {
                setState(() {});
                _pausa?.cancel();
                _pausa = Timer(
                  const Duration(milliseconds: 300),
                  () => mounted ? setState(() => _consulta = v) : null,
                );
              },
            ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: TextButton(
                        onPressed: _cargar,
                        child: Text('$_error. Toca para reintentar'),
                      ),
                    )
                  : _consulta.trim().isEmpty
                  ? BusquedaInicio(
                      recientes: _recientes,
                      sugerencias: sugerencias,
                      onElegir: _poner,
                      onBorrar: (r) => _setRecientes(
                        _recientes.where((x) => x != r).toList(),
                      ),
                    )
                  : _resultados(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultados() {
    final prods = _productos
        .where(
          (p) =>
              _ok('${p.nombre} ${p.categoria ?? ''} ${p.descripcion ?? ''}') &&
              _pasa(p),
        )
        .toList();
    final enfs = _enfermedades
        .where(
          (e) =>
              _ok('${e.nombre} ${e.descripcion} ${e.sintomas} ${e.cultivos}'),
        )
        .toList();
    final ids = prods.map((p) => '${p.id}').toSet();
    final recom =
        <
          (ProductoModels, String)
        >[]; // productos vinculados a las enfermedades encontradas
    for (final e in enfs) {
      for (final r in e.productos) {
        final p = _productos.where((x) => '${x.id}' == '${r.id}').firstOrNull;
        if (p != null && _pasa(p) && ids.add('${p.id}'))
          recom.add((p, e.nombre));
      }
    }
    final verP = _seccion != 2, verE = _seccion != 1;
    final nada =
        (!verP || (prods.isEmpty && recom.isEmpty)) && (!verE || enfs.isEmpty);
    final etiquetas = [
      'Todo',
      'Productos (${prods.length + recom.length})',
      'Enfermedades (${enfs.length})',
    ];

    Widget fila(ProductoModels p, [String? para]) => FilaResultado(
      p.nombre,
      p.categoria,
      formatearPrecio(p.precio) + (para == null ? '' : '  ·  Para $para'),
      p.imagenUrl,
      Icons.inventory_2_outlined,
      BoxFit.contain,
      () => _ir(DetalleProductoScreen(producto: p)),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final (i, t) in etiquetas.indexed)
              ChoiceChip(
                label: Text(t),
                selected: _seccion == i,
                onSelected: (_) => setState(() => _seccion = i),
              ),
            if (verP)
              ActionChip(
                avatar: const Icon(Icons.tune, size: 18),
                label: Text(
                  _categoria != null || _rango != null
                      ? 'Filtros •'
                      : 'Filtros',
                ),
                onPressed: _filtros,
              ),
          ],
        ),
        if (nada)
          BusquedaVacia(
            consulta: _consulta.trim(),
            onAsesor: () => _ir(const AsesorIAScreen()),
          )
        else ...[
          if (verP && prods.isNotEmpty) ...[
            tituloSeccion('Productos (${prods.length})'),
            for (final p in prods) fila(p),
          ],
          if (verP && recom.isNotEmpty) ...[
            tituloSeccion('Recomendados para tu búsqueda'),
            for (final r in recom) fila(r.$1, r.$2),
          ],
          if (verE && enfs.isNotEmpty) ...[
            tituloSeccion('Enfermedades (${enfs.length})'),
            for (final x in enfs)
              FilaResultado(
                x.nombre,
                x.descripcion,
                x.listaCultivos.isEmpty
                    ? null
                    : 'Cultivos: ${x.listaCultivos.join(', ')}',
                x.imagenUrl,
                Icons.eco_outlined,
                BoxFit.cover,
                () => _ir(DetalleEnfermedadScreen(enfermedadId: x.id)),
              ),
          ],
        ],
      ],
    );
  }
}
