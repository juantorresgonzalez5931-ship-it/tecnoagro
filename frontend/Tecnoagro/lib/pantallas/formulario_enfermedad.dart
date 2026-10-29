import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/enfermedad_model.dart';
import 'package:frontend/pantallas/selector_productos.dart';
import 'package:frontend/service/services/api_config.dart';
import 'package:frontend/service/services/enfermedad_service.dart';
import 'package:frontend/widgets/cabecera_pantalla.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Crear (enfermedadId == null) o editar una enfermedad, con foto y productos recomendados.
class FormularioEnfermedadScreen extends StatefulWidget {
  final int? enfermedadId;
  const FormularioEnfermedadScreen({super.key, this.enfermedadId});

  @override
  State<FormularioEnfermedadScreen> createState() => _FormularioEnfermedadScreenState();
}

class _FormularioEnfermedadScreenState extends State<FormularioEnfermedadScreen> {
  final _servicio = EnfermedadService();
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _sintomas = TextEditingController();
  final _tratamiento = TextEditingController();
  final _cultivos = TextEditingController();

  List<Map<String, dynamic>> _productos = [];
  final Set<String> _seleccionados = {}; // ids como texto
  String? _fotoActual;
  XFile? _imagen;
  bool _cargando = true;
  bool _guardando = false;
  bool _sugiriendo = false;
  String? _error;

  bool get _editando => widget.enfermedadId != null;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    for (final c in [_nombre, _descripcion, _sintomas, _tratamiento, _cultivos]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final res = await http.get(Uri.parse('${ApiConfig.apiBaseUrl}/productos'), headers: ApiConfig.headers);
      if (res.statusCode != 200) throw 'No se pudieron cargar los productos';
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final lista = data is List ? data : (data['productos'] ?? data['data'] ?? []);
      _productos = List<Map<String, dynamic>>.from(lista);

      if (_editando) {
        final EnfermedadModel e = await _servicio.obtener(widget.enfermedadId!);
        _nombre.text = e.nombre;
        _descripcion.text = e.descripcion;
        _sintomas.text = e.sintomas;
        _tratamiento.text = e.tratamiento;
        _cultivos.text = e.cultivos;
        _fotoActual = e.imagenUrl;
        _seleccionados.addAll(e.productos.map((p) => '${p.id}'));
      }
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _aviso(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _elegirImagen() async {
    final foto = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (foto != null && mounted) setState(() => _imagen = foto);
  }

  Future<void> _elegirProductos() async {
    final resultado = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectorProductosScreen(
          productos: _productos,
          seleccionados: _seleccionados,
        ),
      ),
    );
    if (resultado != null && mounted) {
      setState(() {
        _seleccionados
          ..clear()
          ..addAll(resultado);
      });
    }
  }

  /// Pide a la IA productos recomendados y los suma a los que ya hay elegidos.
  Future<void> _sugerirConIA() async {
    if (_nombre.text.trim().isEmpty) {
      _aviso('Escribe primero el nombre de la enfermedad', error: true);
      return;
    }
    setState(() => _sugiriendo = true);
    try {
      final ids = await _servicio.recomendarProductos(
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        sintomas: _sintomas.text.trim(),
        tratamiento: _tratamiento.text.trim(),
        cultivos: _cultivos.text.trim(),
      );
      final existentes = _productos.map((p) => '${p['id']}').toSet();
      final nuevos = ids.where(existentes.contains).toList();
      if (!mounted) return;
      if (nuevos.isEmpty) {
        _aviso('La IA no encontró productos que apliquen. Puedes elegirlos tú.', error: true);
      } else {
        setState(() => _seleccionados.addAll(nuevos));
        _aviso('La IA sugirió ${nuevos.length} producto(s). Revísalos y ajusta lo que quieras.');
      }
    } catch (e) {
      _aviso('$e', error: true);
    }
    if (mounted) setState(() => _sugiriendo = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      // Se envían los ids tal como los tiene la base de datos (números si lo son).
      final ids = [
        for (final p in _productos)
          if (_seleccionados.contains('${p['id']}')) p['id'],
      ];
      await _servicio.guardar(
        id: widget.enfermedadId,
        campos: {
          'nombre': _nombre.text.trim(),
          'descripcion': _descripcion.text.trim(),
          'sintomas': _sintomas.text.trim(),
          'tratamiento': _tratamiento.text.trim(),
          'cultivos': _cultivos.text.trim(),
          'productos': jsonEncode(ids),
        },
        imagen: _imagen,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _aviso('$e', error: true);
    }
  }

  InputDecoration _decoracion(String etiqueta, {String? ayuda}) => InputDecoration(
        labelText: etiqueta,
        helperText: ayuda,
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borde)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borde)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.verdePrimario)),
      );

  Widget _tarjetaElegido(Map<String, dynamic> p) {
    final categoria = '${p['categoria'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(children: [
        MiniaturaProducto(url: p['imagen_url']?.toString(), tamano: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p['nombre'] ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textoPrincipal, fontSize: 14.5, fontWeight: FontWeight.bold)),
            if (categoria.isNotEmpty)
              Text(categoria, style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
          ]),
        ),
        IconButton(
          tooltip: 'Quitar',
          icon: Icon(Icons.close, color: AppColors.textoSecundario),
          onPressed: () => setState(() => _seleccionados.remove('${p['id']}')),
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
    final hayFoto = _imagen != null || _fotoActual != null;
    final elegidos = [
      for (final p in _productos)
        if (_seleccionados.contains('${p['id']}')) p,
    ];
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GestureDetector(
            onTap: _elegirImagen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 170,
                color: Colors.white,
                child: !hayFoto
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.verdePrimario),
                        const SizedBox(height: 6),
                        Text('Seleccionar imagen', style: TextStyle(color: AppColors.textoSecundario)),
                      ])
                    : _imagen != null
                        ? Image.file(File(_imagen!.path), fit: BoxFit.cover, width: double.infinity)
                        : Image.network(_fotoActual!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported)),
              ),
            ),
          ),
          if (hayFoto)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _elegirImagen,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Cambiar imagen'),
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombre,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoracion('Nombre'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Ingresa el nombre' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descripcion,
            maxLines: 3,
            decoration: _decoracion('Descripción'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sintomas,
            maxLines: 4,
            decoration: _decoracion('Cómo se ve (síntomas)', ayuda: 'Escribe un punto por línea'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tratamiento,
            maxLines: 4,
            decoration: _decoracion('Tratamiento', ayuda: 'Escribe un punto por línea'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cultivos,
            maxLines: 2,
            decoration: _decoracion('Cultivos donde sirve', ayuda: 'Sepáralos con coma. Ej: Café, Cacao, Plátano'),
          ),
          const SizedBox(height: 20),
          Text('Productos recomendados',
              style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_productos.isEmpty)
            Text('No hay productos creados todavía', style: TextStyle(color: AppColors.textoSecundario))
          else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _elegirProductos,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Elegir producto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.verdePrimario,
                  side: BorderSide(color: AppColors.verdePrimario),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.tonalIcon(
                onPressed: _sugiriendo ? null : _sugerirConIA,
                icon: _sugiriendo
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_sugiriendo ? 'Pensando...' : 'Sugerir con IA'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (elegidos.isEmpty)
              Text('Aún no has elegido productos', style: TextStyle(color: AppColors.textoSecundario, fontSize: 13))
            else
              for (final p in elegidos) _tarjetaElegido(p),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(_editando ? 'GUARDAR CAMBIOS' : 'CREAR ENFERMEDAD',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: Column(children: [
          CabeceraPantalla(titulo: _editando ? 'Editar enfermedad' : 'Nueva enfermedad'),
          Expanded(child: _cuerpo()),
        ]),
      ),
    );
  }
}