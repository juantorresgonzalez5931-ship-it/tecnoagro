import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/service/services/api_config.dart';
import 'package:http/http.dart' as http; // ajusta la ruta a tu ApiConfig
import '../core/colores.dart';
import 'package:image_picker/image_picker.dart';

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

  Map<String, String> get _headers => {
    ...ApiConfig.headers,
    'Authorization': 'Bearer ${widget.token}',
  };

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void _msg(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/productos'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final lista = data is List
            ? data
            : (data['productos'] ?? data['data'] ?? []);
        productos = List<Map<String, dynamic>>.from(lista);
      } else {
        error = 'Error ${res.statusCode}';
      }
    } catch (e) {
      debugPrint('Error productos: $e');
      error = 'No se pudo conectar con el servidor';
    }
    if (mounted) setState(() => cargando = false);
  }

  Future<void> eliminar(Map<String, dynamic> p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${p['nombre']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.apiBaseUrl}/productos/${p['id']}'),
        headers: _headers,
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() => productos.removeWhere((x) => x['id'] == p['id']));
        _msg('Producto eliminado');
      } else {
        debugPrint('DELETE producto: ${res.statusCode} ${res.body}');
        _msg('No se pudo eliminar (${res.statusCode})', esError: true);
      }
    } catch (e) {
      if (mounted) _msg('Error de conexión', esError: true);
    }
  }

  Future<void> editar(Map<String, dynamic> p) async {
    final nombreCtrl = TextEditingController(text: '${p['nombre'] ?? ''}');
    final precioCtrl = TextEditingController(text: '${p['precio'] ?? ''}');
    final stockCtrl = TextEditingController(text: '${p['stock'] ?? ''}');
    final descCtrl = TextEditingController(text: '${p['descripcion'] ?? ''}');

    final guardar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: precioCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio'),
              ),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
              ),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (guardar != true) return;

    try {
      // Multipart porque la ruta usa Multer (upload.single('imagen'))
      final req = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiConfig.apiBaseUrl}/productos/${p['id']}'),
      );
      req.headers['Authorization'] = 'Bearer ${widget.token}';
      req.fields['nombre'] = nombreCtrl.text.trim();
      req.fields['precio'] = precioCtrl.text.trim();
      req.fields['stock'] = stockCtrl.text.trim();
      req.fields['descripcion'] = descCtrl.text.trim();
      if (p['categoria'] != null) req.fields['categoria'] = '${p['categoria']}';

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      if (!mounted) return;
      if (res.statusCode == 200) {
        _msg('Producto actualizado');
        cargar();
      } else {
        debugPrint('PUT producto: ${res.statusCode} ${res.body}');
        _msg('No se pudo actualizar (${res.statusCode})', esError: true);
      }
    } catch (e) {
      if (mounted) _msg('Error de conexión', esError: true);
    }
  }

  String? _imagen(Map<String, dynamic> p) =>
      (p['imagen_url'] ??
              p['imagen'] ??
              p['imagen_principal'] ??
              p['image_url'])
          ?.toString();

  Future<void> crearProducto() async {
    final nombreCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final categoriaCtrl = TextEditingController();

    XFile? imagenSeleccionada;

    final formularioKey = GlobalKey<FormState>();

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, actualizarDialogo) {
            return AlertDialog(
              title: const Text('Crear producto'),
              content: SingleChildScrollView(
                child: Form(
                  key: formularioKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa el nombre'
                            : null,
                      ),
                      TextFormField(
                        controller: precioCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Precio'),
                        validator: (v) {
                          final precio = double.tryParse(
                            (v ?? '').trim().replaceAll(',', '.'),
                          );
                          if (precio == null || precio <= 0) {
                            return 'Ingresa un precio válido';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        validator: (v) {
                          final stock = int.tryParse((v ?? '').trim());
                          if (stock == null || stock < 0) {
                            return 'Ingresa un stock válido';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: categoriaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                        ),
                      ),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final imagen = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (imagen != null) {
                            actualizarDialogo(() {
                              imagenSeleccionada = imagen;
                            });
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: Text(
                          imagenSeleccionada == null
                              ? 'Seleccionar imagen'
                              : 'Cambiar imagen',
                        ),
                      ),
                      if (imagenSeleccionada != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            imagenSeleccionada!.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formularioKey.currentState!.validate()) {
                      Navigator.pop(dialogContext, {
                        'nombre': nombreCtrl.text.trim(),
                        'precio': precioCtrl.text.trim().replaceAll(',', '.'),
                        'stock': stockCtrl.text.trim(),
                        'categoria': categoriaCtrl.text.trim(),
                        'descripcion': descCtrl.text.trim(),
                        'imagen': imagenSeleccionada,
                      });
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (datos == null) return;

    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.apiBaseUrl}/productos'),
      );

      req.headers.addAll(_headers);

      req.fields['nombre'] = datos['nombre'] as String;
      req.fields['precio'] = datos['precio'] as String;
      req.fields['stock'] = datos['stock'] as String;
      req.fields['descripcion'] = datos['descripcion'] as String;
      req.fields['categoria'] = datos['categoria'] as String;

      final imagen = datos['imagen'] as XFile?;

      if (imagen != null) {
        req.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));
      }

      final respuesta = await req.send();
      final res = await http.Response.fromStream(respuesta);

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        _msg('Producto creado correctamente');
        await cargar();
      } else {
        debugPrint('POST producto: ${res.statusCode} ${res.body}');
        _msg('No se pudo crear el producto (${res.statusCode})', esError: true);
      }
    } catch (e) {
      debugPrint('Error al crear producto: $e');
      if (mounted) {
        _msg('Error de conexión al crear el producto', esError: true);
      }
    } finally {
      nombreCtrl.dispose();
      precioCtrl.dispose();
      stockCtrl.dispose();
      descCtrl.dispose();
      categoriaCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        backgroundColor: AppColors.fondoCrema,
        appBar: AppBar(
          title: const Text('Gestión de productos'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: cargar),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: crearProducto,
                icon: const Icon(Icons.add),
                label: const Text('Crear producto'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.verdePrimario,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      
        body: cargando
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: Text(error!))
            : productos.isEmpty
            ? const Center(child: Text('No hay productos'))
            : RefreshIndicator(
                onRefresh: cargar,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: productos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = productos[i];
                    final img = _imagen(p);
                    return Card(
                      child: ListTile(
                        leading: img == null
                            ? const Icon(Icons.inventory_2, size: 36)
                            : Image.network(
                                img,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                        title: Text('${p['nombre'] ?? ''}'),
                        subtitle: Text(
                          '\$${p['precio'] ?? 0}  •  Stock: ${p['stock'] ?? '-'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: AppColors.verdePrimario,
                              ),
                              onPressed: () => editar(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => eliminar(p),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
