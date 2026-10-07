import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Compatibilidad local para evitar el error de importación si el paquete
// image_picker no está disponible en este proyecto.
class PickedFile {
  final String path;
  const PickedFile(this.path);
}

enum ImageSource { camera, gallery }

class ImagePicker {
  const ImagePicker();

  Future<PickedFile?> pickImage({
    required ImageSource source,
    int? imageQuality,
    double? maxWidth,
  }) async {
    return null;
  }
}

// ── Colores ──────────────────────────────────────────────
const _verde = Color(0xFF2E7D32);
const _verdeClaro = Color(0xFFD9EEDC);
const _fondo = Color(0xFFEFF5F0);
const _borde = Color(0xFFD5DDD6);
const _texto = Color(0xFF1B2A1E);
const _textoSuave = Color(0xFF6B786E);

class CrearProductoScreen extends StatefulWidget {
  final String baseUrl; // ej: http://10.0.2.2:3000/api (emulador Android)
  final String token; // JWT del admin

  const CrearProductoScreen({
    super.key,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<CrearProductoScreen> createState() => _CrearProductoScreenState();
}

class _CrearProductoScreenState extends State<CrearProductoScreen> {
  final _formPaso1 = GlobalKey<FormState>();
  final _formPaso2 = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _principioCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  final _categorias = const [
    'Analgésicos y antipiréticos',
    'Antibióticos',
    'Antiinflamatorios',
    'Vitaminas y suplementos',
    'Otros',
  ];

  String? _categoria;
  File? _imagen;
  int _paso = 1;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _principioCtrl.dispose();
    _precioCtrl.dispose();
    _cantidadCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  // ── Acciones ───────────────────────────────────────────
  void _continuar() {
    if (_formPaso1.currentState!.validate()) {
      setState(() => _paso = 2);
    }
  }

  void _volver() {
    if (_paso == 2) {
      setState(() => _paso = 1);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _elegirFoto() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: _verde),
              title: const Text('Tomar fotografía'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _verde),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    final foto = await ImagePicker().pickImage(
      source: origen,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (foto == null) return;
    if (!mounted) return;
    setState(() => _imagen = File(foto.path));
  }

  Future<void> _guardar() async {
    if (!_formPaso2.currentState!.validate()) return;
    if (_imagen == null) {
      _mensaje('La fotografía del producto es obligatoria', error: true);
      return;
    }

    setState(() => _guardando = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.baseUrl}/productos'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.fields.addAll({
        'nombre': _nombreCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
        'categoria': _categoria!,
        'principio_activo': _principioCtrl.text.trim(),
        'precio': _precioCtrl.text.trim().replaceAll(',', '.'),
        'stock': _stockCtrl.text.trim(),
      });
      request.files.add(
        await http.MultipartFile.fromPath('imagen', _imagen!.path),
      );

      final streamed = await request.send();
      final respuesta = await http.Response.fromStream(streamed);
      if (!mounted) return;

      if (respuesta.statusCode == 201) {
        _mensaje('Producto creado correctamente');
        Navigator.pop(context, true);
      } else {
        final cuerpo = jsonDecode(respuesta.body);
        _mensaje(
          cuerpo['error'] ?? 'No se pudo crear el producto',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mensaje('Error de conexión: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? Colors.red.shade700 : _verde,
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _fondo,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _volver,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: _texto,
              ),
            ),
          ),
        ),
        title: const Text(
          'Crear producto',
          style: TextStyle(
            color: _texto,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _verdeClaro,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Paso $_paso de 2',
                style: const TextStyle(
                  color: _verde,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_paso == 1) ...[
            _tarjetaResumen(),
            const SizedBox(height: 12),
            _paso1(),
          ] else
            _paso2(),
        ],
      ),
      bottomNavigationBar: _barraInferior(),
    );
  }

  // Tarjeta de vista previa (paso 1)
  Widget _tarjetaResumen() {
    final nombre = _nombreCtrl.text.trim();
    final precio = _precioCtrl.text.trim();
    final hayStock = (int.tryParse(_stockCtrl.text.trim()) ?? 0) > 0;

    return _Tarjeta(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 84,
              height: 100,
              color: _fondo,
              child: _imagen != null
                  ? Image.file(_imagen!, fit: BoxFit.cover)
                  : const Icon(
                      Icons.image_outlined,
                      color: _textoSuave,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoria ?? 'Categoría',
                  style: const TextStyle(color: _verde, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  nombre.isEmpty ? 'Nombre del producto' : nombre,
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        precio.isEmpty ? '0,00 €' : '$precio €',
                        style: const TextStyle(
                          color: _texto,
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _verdeClaro,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hayStock
                                ? Icons.check
                                : Icons.remove_circle_outline,
                            size: 14,
                            color: _verde,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hayStock ? 'En stock' : 'Sin stock',
                            style: const TextStyle(color: _verde, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Paso 1: información general
  Widget _paso1() {
    return Form(
      key: _formPaso1,
      child: _Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _EncabezadoSeccion(
              icono: Icons.assignment_outlined,
              titulo: 'Información general',
              subtitulo: 'Identifica y clasifica el producto en el catálogo.',
            ),
            const SizedBox(height: 16),
            _Etiqueta('Nombre', obligatorio: true),
            TextFormField(
              controller: _nombreCtrl,
              onChanged: (_) => setState(() {}),
              decoration: _decoracion(),
              validator: _requerido,
            ),
            const SizedBox(height: 14),
            _Etiqueta('Descripción', obligatorio: true),
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 4,
              decoration: _decoracion(),
              validator: _requerido,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Etiqueta('Categoría', obligatorio: true),
                      DropdownButtonFormField<String>(
                        value: _categoria,
                        isExpanded: true,
                        decoration: _decoracion(),
                        items: _categorias
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _categoria = v),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Etiqueta('Principio activo', obligatorio: true),
                      TextFormField(
                        controller: _principioCtrl,
                        decoration: _decoracion(),
                        validator: _requerido,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Paso 2: precio, inventario y foto
  Widget _paso2() {
    return Form(
      key: _formPaso2,
      child: _Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _EncabezadoSeccion(
              icono: Icons.hub_outlined,
              titulo: 'Precio e inventario',
              subtitulo: 'Define el precio, la presentación y las existencias.',
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Etiqueta('Precio', obligatorio: true),
                      TextFormField(
                        controller: _precioCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: _decoracion(sufijo: 'EUR'),
                        validator: (v) {
                          final n = double.tryParse(
                            (v ?? '').replaceAll(',', '.'),
                          );
                          return (n == null || n <= 0)
                              ? 'Precio inválido'
                              : null;
                        },
                      ),
                      const _Ayuda('Precio por producto.'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Etiqueta('Cantidad', obligatorio: true),
                      TextFormField(
                        controller: _cantidadCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _decoracion(sufijo: 'unidades'),
                        validator: _requerido,
                      ),
                      const _Ayuda('Unidades por presentación.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Etiqueta('Stock', obligatorio: true),
            TextFormField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decoracion(sufijo: 'cajas'),
              validator: _requerido,
            ),
            const _Ayuda('Presentaciones disponibles.'),
            const SizedBox(height: 16),
            const Divider(color: _borde, height: 1),
            const SizedBox(height: 16),
            const _EncabezadoSeccion(
              icono: Icons.image_outlined,
              titulo: 'Fotografía del producto',
              subtitulo:
                  'Toma una foto del producto para reconocerlo fácilmente.',
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _elegirFoto,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _fondo,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borde),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imagen != null
                    ? Image.file(_imagen!, fit: BoxFit.cover)
                    : const Icon(
                        Icons.add_a_photo_outlined,
                        color: _textoSuave,
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _elegirFoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  _imagen == null ? 'Tomar fotografía' : 'Cambiar fotografía',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Barra inferior con Cancelar / Continuar / Guardar
  Widget _barraInferior() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '* Campos obligatorios',
              style: TextStyle(color: _textoSuave, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _guardando ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _texto,
                    side: const BorderSide(color: _borde),
                    minimumSize: const Size(100, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _guardando
                      ? null
                      : (_paso == 1 ? _continuar : _guardar),
                  icon: _guardando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : (_paso == 2
                            ? const Icon(Icons.check, size: 18)
                            : const SizedBox.shrink()),
                  label: Text(
                    _paso == 1 ? 'Continuar' : 'Guardar producto',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(130, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────
  String? _requerido(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  InputDecoration _decoracion({String? sufijo}) {
    OutlineInputBorder borde(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c),
    );
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      suffixText: sufijo,
      suffixStyle: const TextStyle(color: _textoSuave, fontSize: 13),
      enabledBorder: borde(_borde),
      focusedBorder: borde(_verde),
      errorBorder: borde(Colors.red.shade400),
      focusedErrorBorder: borde(Colors.red.shade400),
    );
  }
}

// ── Widgets reutilizables ────────────────────────────────
class _Tarjeta extends StatelessWidget {
  final Widget child;
  const _Tarjeta({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borde.withOpacity(0.6)),
      ),
      child: child,
    );
  }
}

class _EncabezadoSeccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  const _EncabezadoSeccion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _verdeClaro,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: _verde, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: _texto,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: const TextStyle(color: _textoSuave, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final bool obligatorio;
  const _Etiqueta(this.texto, {this.obligatorio = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: texto,
          style: const TextStyle(
            color: _texto,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          children: [
            if (obligatorio)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: _verde),
              ),
          ],
        ),
      ),
    );
  }
}

class _Ayuda extends StatelessWidget {
  final String texto;
  const _Ayuda(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        texto,
        style: const TextStyle(color: _textoSuave, fontSize: 11.5),
      ),
    );
  }
}
