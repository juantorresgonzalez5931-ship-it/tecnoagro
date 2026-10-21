import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/service/services/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/colores.dart';

const _categorias = ['Herbicida agrícola', 'Insecticida', 'Fungicida agrícola', 'Abono'];
const _stockBajo = 5;

String _dinero(dynamic valor) {
  final n = (num.tryParse('$valor') ?? 0).round();
  return '\$${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';
}

class AdminProductosPage extends StatefulWidget {
  final String token;
  const AdminProductosPage({super.key, required this.token});

  @override
  State<AdminProductosPage> createState() => _AdminProductosPageState();
}

class _AdminProductosPageState extends State<AdminProductosPage> {
  List<Map<String, dynamic>> productos = [];
  bool cargando = true;
  String? error;

  Map<String, String> get _headers => {...ApiConfig.headers, 'Authorization': 'Bearer ${widget.token}'};
  Uri _url([String extra = '']) => Uri.parse('${ApiConfig.apiBaseUrl}/productos$extra');

  @override
  void initState() {
    super.initState();
    cargar();
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

  // ───────────── Conexión con el servidor ─────────────

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final res = await http.get(_url(), headers: _headers);
      if (res.statusCode != 200) throw 'Error ${res.statusCode}';
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final lista = data is List ? data : (data['productos'] ?? data['data'] ?? []);
      productos = List<Map<String, dynamic>>.from(lista);
    } catch (e) {
      debugPrint('Error al cargar productos: $e');
      error = 'No se pudieron cargar los productos';
    }
    if (mounted) setState(() => cargando = false);
  }

  /// Crear (POST) o editar (PUT). Va en multipart porque la ruta usa Multer.
  Future<bool> _guardar(String metodo, String ruta, Map<String, String> campos, XFile? imagen) async {
    try {
      final req = http.MultipartRequest(metodo, _url(ruta))
        ..headers.addAll(_headers)
        ..fields.addAll(campos);
      if (imagen != null) req.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));
      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode == 200 || res.statusCode == 201) return true;
      debugPrint('$metodo producto: ${res.statusCode} ${res.body}');
      _aviso('No se pudo guardar (${res.statusCode})', error: true);
    } catch (_) {
      _aviso('Error de conexión', error: true);
    }
    return false;
  }

  Future<void> _eliminar(Map<String, dynamic> p) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${p['nombre']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    try {
      final res = await http.delete(_url('/${p['id']}'), headers: _headers);
      if (res.statusCode != 200 && res.statusCode != 204) throw res.statusCode;
      if (!mounted) return;
      setState(() => productos.removeWhere((x) => x['id'] == p['id']));
      _aviso('Producto eliminado');
    } catch (_) {
      _aviso('No se pudo eliminar el producto', error: true);
    }
  }

  // ───────────── Formulario (crear y editar) ─────────────

  Future<void> _formulario([Map<String, dynamic>? producto]) async {
    final editando = producto != null;
    final nombre = TextEditingController(text: '${producto?['nombre'] ?? ''}');
    final precio = TextEditingController(text: '${producto?['precio'] ?? ''}');
    final stock = TextEditingController(text: '${producto?['stock'] ?? ''}');
    final descripcion = TextEditingController(text: '${producto?['descripcion'] ?? ''}');
    String? categoria = producto?['categoria']?.toString();
    final opciones = {..._categorias, if (categoria != null) categoria}.toList();
    XFile? imagen;
    bool falta = false;
    final formKey = GlobalKey<FormState>();

    final aceptado = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogo) => AlertDialog(
          title: Text(editando ? 'Editar producto' : 'Nuevo producto'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Ingresa el nombre' : null,
                ),
                TextFormField(
                  controller: precio,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0
                      ? 'Ingresa un precio válido'
                      : null,
                ),
                TextFormField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: categoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [for (final o in opciones) DropdownMenuItem(value: o, child: Text(o))],
                  onChanged: (v) => categoria = v,
                ),
                TextFormField(
                  controller: descripcion,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                if (!editando) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image_outlined),
                    label: Text(imagen?.name ?? 'Seleccionar imagen', maxLines: 1, overflow: TextOverflow.ellipsis),
                    onPressed: () async {
                      final foto = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (foto != null) {
                        setDialogo(() {
                          imagen = foto;
                          falta = false;
                        });
                      }
                    },
                  ),
                  if (falta)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('La imagen es obligatoria',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                    ),
                ],
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                if (!editando && imagen == null) return setDialogo(() => falta = true);
                Navigator.pop(ctx, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    final campos = {
      'nombre': nombre.text.trim(),
      'precio': precio.text.trim().replaceAll(',', '.'),
      'stock': stock.text.trim(),
      'descripcion': descripcion.text.trim(),
      if (categoria != null) 'categoria': categoria!,
    };
    for (final c in [nombre, precio, stock, descripcion]) {
      c.dispose();
    }
    if (aceptado != true) return;

    final ok = await _guardar(editando ? 'PUT' : 'POST', editando ? '/${producto['id']}' : '', campos, imagen);
    if (ok) {
      _aviso(editando ? 'Producto actualizado' : 'Producto creado');
      cargar();
    }
  }

  // ───────────── Pantalla ─────────────

  Widget _cuerpo() {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: cargar, child: const Text('Reintentar')),
        ]),
      );
    }
    if (productos.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.textoSecundario),
          const SizedBox(height: 8),
          Text('Aún no hay productos', style: TextStyle(color: AppColors.textoSecundario)),
        ]),
      );
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('${productos.length} productos',
              style: TextStyle(color: AppColors.textoSecundario, fontWeight: FontWeight.w600)),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: cargar,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            itemCount: productos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _TarjetaProducto(
              producto: productos[i],
              onEditar: () => _formulario(productos[i]),
              onEliminar: () => _eliminar(productos[i]),
            ),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: cargar)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        backgroundColor: AppColors.verdePrimario,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: _cuerpo(),
    );
  }
}

/// Tarjeta de un producto: foto, datos y menú de acciones.
class _TarjetaProducto extends StatelessWidget {
  final Map<String, dynamic> producto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaProducto({required this.producto, required this.onEditar, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final stock = int.tryParse('${producto['stock']}') ?? 0;
    final colorStock = stock == 0
        ? Colors.red.shade700
        : stock <= _stockBajo
            ? Colors.orange.shade800
            : AppColors.verdePrimario;
    final imagen = (producto['imagen_url'] ?? producto['imagen'])?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 64,
            height: 64,
            child: imagen == null
                ? ColoredBox(color: Colors.grey.shade200, child: const Icon(Icons.inventory_2_outlined))
                : Image.network(imagen,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${producto['nombre'] ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textoPrincipal, fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${producto['categoria'] ?? 'Sin categoría'}',
                style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
            const SizedBox(height: 6),
            Row(children: [
              Text(_dinero(producto['precio']),
                  style: TextStyle(color: AppColors.verdePrimario, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorStock.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(stock == 0 ? 'Agotado' : 'Stock: $stock',
                    style: TextStyle(color: colorStock, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),
        PopupMenuButton<String>(
          onSelected: (v) => v == 'editar' ? onEditar() : onEliminar(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
          ],
        ),
      ]),
    );
  }
}