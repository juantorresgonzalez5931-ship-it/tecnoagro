import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/Ia_screeen/asesor_ia_screen.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/enfermedad_model.dart';
import 'package:frontend/models/producto_models.dart';
import 'package:frontend/pantallas/detalle_enfermedad.dart';
import 'package:frontend/pantallas/detalle_producto.dart';
import 'package:frontend/service/services/enfermedad_service.dart';
import 'package:frontend/service/services/producto_service.dart';
import 'package:frontend/widgets/producto_tile.dart' show formatearPrecio;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum _Seccion { todo, productos, enfermedades }

const _acentos = 'áàäâãéèëêíìïîóòöôõúùüûñç';
const _sinAcentos = 'aaaaaeeeeiiiiooooouuuunc';

/// Minúsculas y sin tildes: "Café" y "cafe" se consideran iguales.
String _plano(String s) {
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = _acentos.indexOf(c);
    b.write(i < 0 ? c : _sinAcentos[i]);
  }
  return b.toString();
}

/// Búsqueda global: productos, enfermedades y cultivos en una sola pantalla.
class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({super.key});

  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  static const _claveRecientes = 'busquedas_recientes';

  final _ctrl = TextEditingController();
  final _voz = stt.SpeechToText();
  Timer? _pausa;

  List<ProductoModels> _productos = [];
  List<EnfermedadModel> _enfermedades = [];
  List<String> _recientes = [];
  bool _cargando = true;
  String? _error;

  String _consulta = '';
  _Seccion _seccion = _Seccion.todo;
  String? _categoria;
  RangeValues? _rango;
  double _min = 0;
  double _max = 0;

  bool _vozLista = false;
  bool _escuchando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarRecientes();
  }

  @override
  void dispose() {
    _pausa?.cancel();
    _voz.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  // ───────────── Datos ─────────────

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await Future.wait([ProductoService().listarProductos(), EnfermedadService().listar()]);
      _productos = r[0] as List<ProductoModels>;
      _enfermedades = r[1] as List<EnfermedadModel>;
      if (_productos.isNotEmpty) {
        final precios = _productos.map((p) => p.precio.toDouble());
        _min = precios.reduce((a, b) => a < b ? a : b).floorToDouble();
        _max = precios.reduce((a, b) => a > b ? a : b).ceilToDouble();
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarRecientes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) setState(() => _recientes = prefs.getStringList(_claveRecientes) ?? []);
    } catch (_) {}
  }

  Future<void> _guardarReciente(String texto) async {
    final t = texto.trim();
    if (t.length < 2) return;
    final lista = [t, ..._recientes.where((r) => _plano(r) != _plano(t))].take(5).toList();
    if (mounted) setState(() => _recientes = lista);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_claveRecientes, lista);
    } catch (_) {}
  }

  Future<void> _borrarReciente(String texto) async {
    final lista = _recientes.where((r) => r != texto).toList();
    setState(() => _recientes = lista);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_claveRecientes, lista);
    } catch (_) {}
  }

  // ───────────── Búsqueda ─────────────

  List<String> get _tokens => _plano(_consulta).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  bool _coincide(String texto) {
    final t = _plano(texto);
    return _tokens.every(t.contains);
  }

  bool _pasaFiltros(ProductoModels p) {
    if (_categoria != null && p.categoria != _categoria) return false;
    final r = _rango;
    if (r != null && (p.precio < r.start || p.precio > r.end)) return false;
    return true;
  }

  bool get _hayFiltros => _categoria != null || _rango != null;

  List<ProductoModels> get _productosDirectos => _productos
      .where((p) => _coincide('${p.nombre} ${p.categoria ?? ''} ${p.descripcion ?? ''}') && _pasaFiltros(p))
      .toList();

  List<EnfermedadModel> get _enfermedadesDirectas => _enfermedades
      .where((e) => _coincide('${e.nombre} ${e.descripcion} ${e.sintomas} ${e.cultivos}'))
      .toList();

  /// Productos vinculados a las enfermedades encontradas (que no salgan ya como resultado directo).
  List<(ProductoModels, String)> _recomendados(List<ProductoModels> directos, List<EnfermedadModel> enfs) {
    final yaEstan = directos.map((p) => '${p.id}').toSet();
    final salida = <(ProductoModels, String)>[];
    for (final e in enfs) {
      for (final r in e.productos) {
        final id = '${r.id}';
        if (yaEstan.contains(id)) continue;
        final completo = _productos.where((p) => '${p.id}' == id).firstOrNull;
        if (completo == null || !_pasaFiltros(completo)) continue;
        yaEstan.add(id);
        salida.add((completo, e.nombre));
      }
    }
    return salida;
  }

  /// Cultivos que coinciden con lo escrito, con cuántas enfermedades tiene cada uno.
  List<(String, int)> _cultivosCoinciden() {
    final nombres = <String, String>{};
    final cuentas = <String, int>{};
    for (final e in _enfermedades) {
      for (final c in e.listaCultivos) {
        final k = _plano(c);
        nombres.putIfAbsent(k, () => c);
        cuentas[k] = (cuentas[k] ?? 0) + 1;
      }
    }
    final actual = _plano(_consulta.trim());
    return [
      for (final k in nombres.keys)
        if (_coincide(nombres[k]!) && k != actual) (nombres[k]!, cuentas[k]!),
    ];
  }

  void _alEscribir(String v) {
    setState(() {}); // refresca el botón de borrar al instante
    _pausa?.cancel();
    _pausa = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _consulta = v);
    });
  }

  void _ponerConsulta(String texto) {
    _pausa?.cancel();
    _ctrl.value = TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
    setState(() => _consulta = texto);
    _guardarReciente(texto);
  }

  // ───────────── Voz ─────────────

  Future<String?> _localeEspanol() async {
    final locales = await _voz.locales();
    for (final pref in ['es_CO', 'es-CO']) {
      for (final l in locales) {
        if (l.localeId == pref) return l.localeId;
      }
    }
    for (final l in locales) {
      if (l.localeId.toLowerCase().startsWith('es')) return l.localeId;
    }
    return null;
  }

  Future<void> _alternarVoz() async {
    if (_escuchando) {
      await _voz.stop();
      if (mounted) setState(() => _escuchando = false);
      return;
    }
    if (!_vozLista) {
      _vozLista = await _voz.initialize(
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) setState(() => _escuchando = false);
        },
        onError: (_) {
          if (mounted) setState(() => _escuchando = false);
        },
      );
    }
    if (!_vozLista) {
      _aviso('No se pudo activar el micrófono. Revisa el permiso de la app.');
      return;
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _escuchando = true);
    await _voz.listen(
      localeId: await _localeEspanol(),
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 20),
      listenOptions: stt.SpeechListenOptions(partialResults: true, cancelOnError: true),
      onResult: (r) {
        final texto = r.recognizedWords;
        _pausa?.cancel();
        _ctrl.value = TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
        if (mounted) setState(() => _consulta = texto);
        if (r.finalResult) _guardarReciente(texto);
      },
    );
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        backgroundColor: AppColors.verdePrimario,
        behavior: SnackBarBehavior.floating,
      ));
  }

  // ───────────── Navegación ─────────────

  void _abrirProducto(ProductoModels p) {
    _guardarReciente(_consulta);
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoScreen(producto: p)));
  }

  void _abrirEnfermedad(EnfermedadModel e) {
    _guardarReciente(_consulta);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleEnfermedadScreen(enfermedadId: e.id)),
    );
  }

  void _abrirAsesor() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AsesorIAScreen()));
  }

  // ───────────── Filtros ─────────────

  Future<void> _abrirFiltros() async {
    final categorias = {
      for (final p in _productos)
        if ((p.categoria ?? '').isNotEmpty) p.categoria!,
    }.toList()
      ..sort();
    String? cat = _categoria;
    var rango = _rango ?? RangeValues(_min, _max);

    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondoCrema,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Filtrar productos',
                  style: TextStyle(color: AppColors.textoPrincipal, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Categoría', style: TextStyle(color: AppColors.textoPrincipal, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: cat == null,
                  onSelected: (_) => setSheet(() => cat = null),
                ),
                for (final c in categorias)
                  ChoiceChip(
                    label: Text(c),
                    selected: cat == c,
                    onSelected: (_) => setSheet(() => cat = c),
                  ),
              ]),
              if (_max > _min) ...[
                const SizedBox(height: 16),
                Text('Precio: ${formatearPrecio(rango.start)} - ${formatearPrecio(rango.end)}',
                    style: TextStyle(color: AppColors.textoPrincipal, fontWeight: FontWeight.w600)),
                RangeSlider(
                  values: rango,
                  min: _min,
                  max: _max,
                  activeColor: AppColors.verdePrimario,
                  labels: RangeLabels(formatearPrecio(rango.start), formatearPrecio(rango.end)),
                  onChanged: (v) => setSheet(() => rango = v),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setSheet(() {
                      cat = null;
                      rango = RangeValues(_min, _max);
                    }),
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aplicar')),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );

    if (aplicar == true && mounted) {
      setState(() {
        _categoria = cat;
        _rango = (rango.start <= _min && rango.end >= _max) ? null : rango;
      });
    }
  }

  // ───────────── Pantalla ─────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: Column(children: [
          _buscador(),
          Expanded(child: _cuerpo()),
        ]),
      ),
    );
  }

  Widget _buscador() {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.borde),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borde),
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textoPrincipal),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _alEscribir,
            onSubmitted: _guardarReciente,
            decoration: InputDecoration(
              hintText: _escuchando ? 'Escuchando…' : '¿Qué estás buscando?',
              hintStyle: TextStyle(color: AppColors.textoSecundario, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: AppColors.textoSecundario),
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_ctrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _pausa?.cancel();
                      _ctrl.clear();
                      setState(() => _consulta = '');
                    },
                  ),
                IconButton(
                  tooltip: 'Buscar por voz',
                  icon: Icon(_escuchando ? Icons.mic : Icons.mic_none,
                      color: _escuchando ? Colors.red.shade600 : AppColors.verdePrimario),
                  onPressed: _alternarVoz,
                ),
              ]),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: borde,
              enabledBorder: borde,
              focusedBorder: borde.copyWith(borderSide: BorderSide(color: AppColors.verdePrimario)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
        ]),
      );
    }
    return _consulta.trim().isEmpty ? _inicio() : _resultados();
  }

  // ── Sin texto: recientes y sugerencias ──

  Widget _inicio() {
    final categorias = {
      for (final p in _productos)
        if ((p.categoria ?? '').isNotEmpty) p.categoria!,
    }.take(4);
    final cultivos = {for (final e in _enfermedades) ...e.listaCultivos}.take(3);
    final enfermedades = _enfermedades.map((e) => e.nombre).toSet().take(2);
    final sugerencias = [...categorias, ...cultivos, ...enfermedades];

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      if (_recientes.isNotEmpty) ...[
        _titulo('Búsquedas recientes'),
        for (final r in _recientes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.history, color: AppColors.textoSecundario),
            title: Text(r, style: TextStyle(color: AppColors.textoPrincipal)),
            trailing: IconButton(
              icon: Icon(Icons.close, size: 18, color: AppColors.textoSecundario),
              onPressed: () => _borrarReciente(r),
            ),
            onTap: () => _ponerConsulta(r),
          ),
        const SizedBox(height: 16),
      ],
      if (sugerencias.isNotEmpty) ...[
        _titulo('Sugerencias'),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in sugerencias)
            ActionChip(
              label: Text(s),
              backgroundColor: Colors.white,
              side: BorderSide(color: AppColors.borde),
              labelStyle: TextStyle(color: AppColors.verdeTexto, fontWeight: FontWeight.w600),
              onPressed: () => _ponerConsulta(s),
            ),
        ]),
      ],
      const SizedBox(height: 24),
      Center(
        child: Text('Busca productos, enfermedades o cultivos.\nTambién puedes usar el micrófono.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textoSecundario, fontSize: 13)),
      ),
    ]);
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Text(texto, style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
      );

  // ── Con texto: resultados agrupados ──

  Widget _resultados() {
    final directos = _productosDirectos;
    final enfs = _enfermedadesDirectas;
    final recom = _recomendados(directos, enfs);
    final cultivos = _cultivosCoinciden();

    final verProductos = _seccion != _Seccion.enfermedades;
    final verEnfermedades = _seccion != _Seccion.productos;
    final hay = (verProductos && (directos.isNotEmpty || recom.isNotEmpty)) ||
        (verEnfermedades && enfs.isNotEmpty) ||
        (_seccion == _Seccion.todo && cultivos.isNotEmpty);

    final tokens = _tokens;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      _barraFiltros(directos.length + recom.length, enfs.length),
      if (!hay)
        _vacio()
      else ...[
        if (_seccion == _Seccion.todo && cultivos.isNotEmpty) ...[
          _titulo('Cultivos'),
          for (final c in cultivos) _FilaCultivo(nombre: c.$1, cantidad: c.$2, onTap: () => _ponerConsulta(c.$1)),
        ],
        if (verProductos && directos.isNotEmpty) ...[
          _titulo('Productos (${directos.length})'),
          for (final p in directos) _FilaProducto(producto: p, tokens: tokens, onTap: () => _abrirProducto(p)),
        ],
        if (verProductos && recom.isNotEmpty) ...[
          _titulo('Recomendados para tu búsqueda'),
          for (final r in recom)
            _FilaProducto(
              producto: r.$1,
              tokens: tokens,
              etiqueta: 'Para ${r.$2}',
              onTap: () => _abrirProducto(r.$1),
            ),
        ],
        if (verEnfermedades && enfs.isNotEmpty) ...[
          _titulo('Enfermedades (${enfs.length})'),
          for (final e in enfs) _FilaEnfermedad(enfermedad: e, tokens: tokens, onTap: () => _abrirEnfermedad(e)),
        ],
      ],
    ]);
  }

  Widget _barraFiltros(int nProductos, int nEnfermedades) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final (seccion, texto) in [
            (_Seccion.todo, 'Todo'),
            (_Seccion.productos, 'Productos ($nProductos)'),
            (_Seccion.enfermedades, 'Enfermedades ($nEnfermedades)'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(texto),
                selected: _seccion == seccion,
                selectedColor: AppColors.verdePrimario,
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColors.borde),
                labelStyle: TextStyle(
                  color: _seccion == seccion ? Colors.white : AppColors.textoPrincipal,
                  fontWeight: FontWeight.w600,
                ),
                showCheckmark: false,
                onSelected: (_) => setState(() => _seccion = seccion),
              ),
            ),
          if (_seccion != _Seccion.enfermedades)
            ActionChip(
              avatar: Icon(Icons.tune, size: 18, color: _hayFiltros ? Colors.white : AppColors.verdePrimario),
              label: Text(_hayFiltros ? 'Filtros •' : 'Filtros'),
              backgroundColor: _hayFiltros ? AppColors.verdePrimario : Colors.white,
              side: BorderSide(color: AppColors.borde),
              labelStyle: TextStyle(
                color: _hayFiltros ? Colors.white : AppColors.textoPrincipal,
                fontWeight: FontWeight.w600,
              ),
              onPressed: _abrirFiltros,
            ),
        ]),
      ),
    );
  }

  Widget _vacio() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Column(children: [
        Opacity(opacity: 0.5, child: Image.asset('assets/images/logo-tecnoagro.png', width: 90, height: 90)),
        const SizedBox(height: 16),
        Text('No encontramos resultados para "${_consulta.trim()}"',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          _hayFiltros
              ? 'Prueba quitando los filtros o con otro nombre.'
              : 'Prueba con el nombre del cultivo, un síntoma o la categoría del producto.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 13.5),
        ),
        const SizedBox(height: 20),
        if (_hayFiltros)
          TextButton(
            onPressed: () => setState(() {
              _categoria = null;
              _rango = null;
            }),
            child: const Text('Quitar filtros'),
          ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _abrirAsesor,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Preguntar al Asesor Inteligente'),
          ),
        ),
      ]),
    );
  }
}

// ───────────── Piezas de resultados ─────────────

/// Texto con las palabras buscadas resaltadas.
class _Resaltado extends StatelessWidget {
  final String texto;
  final List<String> tokens;
  final TextStyle estilo;
  final int maxLines;
  const _Resaltado({required this.texto, required this.tokens, required this.estilo, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final plano = _plano(texto);
    if (tokens.isEmpty || plano.length != texto.length) {
      return Text(texto, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: estilo);
    }
    final marca = List<bool>.filled(texto.length, false);
    for (final t in tokens) {
      var i = plano.indexOf(t);
      while (i >= 0) {
        for (var k = i; k < i + t.length; k++) {
          marca[k] = true;
        }
        i = plano.indexOf(t, i + t.length);
      }
    }
    final spans = <TextSpan>[];
    var ini = 0;
    for (var i = 1; i <= texto.length; i++) {
      if (i == texto.length || marca[i] != marca[ini]) {
        spans.add(TextSpan(
          text: texto.substring(ini, i),
          style: marca[ini]
              ? TextStyle(
                  color: AppColors.verdePrimario,
                  fontWeight: FontWeight.bold,
                  backgroundColor: const Color(0xFFE6F2E6),
                )
              : null,
        ));
        ini = i;
      }
    }
    return Text.rich(
      TextSpan(style: estilo, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Fila extends StatelessWidget {
  final Widget imagen;
  final List<Widget> textos;
  final VoidCallback onTap;
  const _Fila({required this.imagen, required this.textos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 58, height: 58, child: imagen)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: textos)),
              Icon(Icons.chevron_right, color: AppColors.textoSecundario),
            ]),
          ),
        ),
      ),
    );
  }
}

Widget _imagenRed(String? url, IconData icono, BoxFit ajuste) {
  final vacio = Container(
    color: const Color(0xFFE8EFE6),
    child: Icon(icono, color: AppColors.verdePrimario, size: 26),
  );
  if (url == null || url.isEmpty) return vacio;
  return Image.network(url, fit: ajuste, errorBuilder: (_, _, _) => vacio);
}

class _FilaProducto extends StatelessWidget {
  final ProductoModels producto;
  final List<String> tokens;
  final String? etiqueta;
  final VoidCallback onTap;
  const _FilaProducto({required this.producto, required this.tokens, required this.onTap, this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return _Fila(
      onTap: onTap,
      imagen: _imagenRed(producto.imagenUrl, Icons.inventory_2_outlined, BoxFit.contain),
      textos: [
        _Resaltado(
          texto: producto.nombre,
          tokens: tokens,
          estilo: TextStyle(color: AppColors.textoPrincipal, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        if ((producto.categoria ?? '').isNotEmpty)
          _Resaltado(
            texto: producto.categoria!,
            tokens: tokens,
            estilo: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5),
          ),
        const SizedBox(height: 2),
        Row(children: [
          Text(formatearPrecio(producto.precio),
              style: TextStyle(color: AppColors.verdeTexto, fontSize: 15, fontWeight: FontWeight.bold)),
          if (etiqueta != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(etiqueta!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textoSecundario, fontSize: 12, fontStyle: FontStyle.italic)),
            ),
          ],
        ]),
      ],
    );
  }
}

class _FilaEnfermedad extends StatelessWidget {
  final EnfermedadModel enfermedad;
  final List<String> tokens;
  final VoidCallback onTap;
  const _FilaEnfermedad({required this.enfermedad, required this.tokens, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Fila(
      onTap: onTap,
      imagen: _imagenRed(enfermedad.imagenUrl, Icons.eco_outlined, BoxFit.cover),
      textos: [
        _Resaltado(
          texto: enfermedad.nombre,
          tokens: tokens,
          estilo: TextStyle(color: AppColors.textoPrincipal, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        if (enfermedad.descripcion.isNotEmpty)
          _Resaltado(
            texto: enfermedad.descripcion,
            tokens: tokens,
            maxLines: 2,
            estilo: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5),
          ),
        if (enfermedad.listaCultivos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _Resaltado(
              texto: 'Cultivos: ${enfermedad.listaCultivos.join(', ')}',
              tokens: tokens,
              estilo: TextStyle(color: AppColors.verdeTexto, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _FilaCultivo extends StatelessWidget {
  final String nombre;
  final int cantidad;
  final VoidCallback onTap;
  const _FilaCultivo({required this.nombre, required this.cantidad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Fila(
      onTap: onTap,
      imagen: Container(
        color: const Color(0xFFE6F2E6),
        child: Icon(Icons.grass, color: AppColors.verdePrimario, size: 28),
      ),
      textos: [
        Text(nombre, style: TextStyle(color: AppColors.textoPrincipal, fontSize: 15, fontWeight: FontWeight.bold)),
        Text(cantidad == 1 ? '1 enfermedad registrada' : '$cantidad enfermedades registradas',
            style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
      ],
    );
  }
}