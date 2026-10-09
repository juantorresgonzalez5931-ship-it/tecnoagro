import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/core/tema.dart';
import 'package:frontend/service/services/producto_service.dart';
import 'package:frontend/widgets/app_text_field.dart';
import 'package:image_picker/image_picker.dart';

/// Formulario para que el administrador añada un producto al catálogo.
class CrearProductoScreen extends StatefulWidget {
  const CrearProductoScreen({super.key});

  @override
  State<CrearProductoScreen> createState() => _CrearProductoScreenState();
}

class _CrearProductoScreenState extends State<CrearProductoScreen> {
  // Cambia esta lista si manejas otras categorías.
  static const _categorias = ['Herbicida agrícola', 'Insecticida', 'Fungicida agrícola', 'Abono'];

  final _nombre = TextEditingController();
  final _principio = TextEditingController();
  final _descripcion = TextEditingController();
  final _precio = TextEditingController();
  final _stock = TextEditingController();
  final _servicio = ProductoService();
  String? _categoria;
  String? _imagen; // ruta de la foto elegida
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_nombre, _principio, _descripcion, _precio, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  void _aviso(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
  }

  int? _numero(String texto) => int.tryParse(texto.replaceAll(RegExp(r'\D'), ''));

  Future<void> _elegirOrigenImagen() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.boton)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: AppColors.verdePrimario),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: AppColors.verdePrimario),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (origen != null) await _elegirImagen(origen);
  }

  Future<void> _elegirImagen(ImageSource origen) async {
    try {
      final foto = await ImagePicker().pickImage(source: origen, maxWidth: 1600, imageQuality: 85);
      if (foto != null) setState(() => _imagen = foto.path);
    } catch (_) {
      if (mounted) _aviso('No se pudo abrir la cámara o la galería. Revisa los permisos.', error: true);
    }
  }

  Future<void> _guardar() async {
    final precio = _numero(_precio.text);
    final stock = _numero(_stock.text);
    if (_imagen == null || _nombre.text.trim().isEmpty || _categoria == null || precio == null || precio <= 0) {
      _aviso('Faltan datos por completar', error: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      await _servicio.crearProducto(
        campos: {
          'nombre': _nombre.text.trim(),
          'categoria': _categoria!,
          'precio': '$precio',
          if (_principio.text.trim().isNotEmpty) 'principio_activo': _principio.text.trim(),
          if (_descripcion.text.trim().isNotEmpty) 'descripcion': _descripcion.text.trim(),
          if (stock != null) 'stock': '$stock',
        },
        rutaImagen: _imagen!,
      );
      if (!mounted) return;
      _aviso('Producto creado');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _aviso(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _selectorImagen() => GestureDetector(
        onTap: _guardando ? null : _elegirOrigenImagen,
        child: Container(
          height: 170,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde),
          ),
          child: _imagen == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.verdePrimario),
                  const SizedBox(height: 8),
                  Text('Agregar foto del producto',
                      style: TextStyle(color: AppColors.textoSecundario, fontWeight: FontWeight.w600)),
                ])
              : Image.file(File(_imagen!), fit: BoxFit.contain),
        ),
      );

  Widget _selectorCategoria() {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Categoría',
          style: TextStyle(color: AppColors.textoSecundario, fontWeight: FontWeight.w600, fontSize: 13.5)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: _categoria,
        hint: const Text('Selecciona una categoría'),
        items: [for (final c in _categorias) DropdownMenuItem(value: c, child: Text(c))],
        onChanged: _guardando ? null : (v) => setState(() => _categoria = v),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: borde,
          enabledBorder: borde,
          focusedBorder: borde.copyWith(borderSide: BorderSide(color: AppColors.verdePrimario, width: 1.5)),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.verdePrimario),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Añadir producto',
            style: TextStyle(color: AppColors.textoPrincipal, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(spacing: 16, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _selectorImagen(),
            AppTextField(label: 'Nombre', hint: 'Ej: Cúspide X GL', controller: _nombre, enabled: !_guardando),
            _selectorCategoria(),
            AppTextField(
                label: 'Principio activo (opcional)', hint: 'Ej: Glifosato', controller: _principio, enabled: !_guardando),
            AppTextField(
                label: 'Descripción (opcional)',
                hint: 'Para qué sirve y cómo se usa',
                controller: _descripcion,
                enabled: !_guardando),
            Row(spacing: 12, children: [
              Expanded(
                child: AppTextField(
                    label: 'Precio',
                    hint: 'Ej: 70000',
                    controller: _precio,
                    keyboardType: TextInputType.number,
                    enabled: !_guardando),
              ),
              Expanded(
                child: AppTextField(
                    label: 'Stock (opcional)',
                    hint: 'Ej: 20',
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    enabled: !_guardando),
              ),
            ]),
            const SizedBox(height: 4),
            SizedBox(
              height: AppRadius.botonAlto,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('GUARDAR PRODUCTO'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}