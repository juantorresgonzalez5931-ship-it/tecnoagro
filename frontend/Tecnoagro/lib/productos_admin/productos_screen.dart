import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/producto_models.dart';
import 'package:frontend/productos_admin/crear_producto.dart';
import 'package:frontend/service/services/producto_service.dart';
import 'package:frontend/widgets/producto_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Usa la misma URL base que tienes en ProductoService
const String kBaseUrl = 'http://10.0.2.2:3000/api';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _service = ProductoService();
  List<ProductoModels> _productos = [];
  bool _cargando = true;
  String? _error;
  bool _esAdmin = false;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _cargarSesion();
    _cargarProductos();
  }

  Future<void> _cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _token = prefs.getString('jwt_token') ?? '';
      _esAdmin = prefs.getString('user_rol') == 'admin';
    });
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _service.listarProductos();
      if (mounted) setState(() => _productos = lista);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _irACrear() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearProductoScreen(baseUrl: kBaseUrl, token: _token),
      ),
    );
    if (!mounted) return;
    if (creado == true) _cargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        backgroundColor: AppColors.fondoCrema,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textoPrincipal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Productos',
            style: TextStyle(
                color: AppColors.textoPrincipal, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: _esAdmin
          ? FloatingActionButton.extended(
              onPressed: _irACrear,
              backgroundColor: AppColors.verdePrimario,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add),
              label: const Text('Crear producto',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: AppColors.verdePrimario))
          : _error != null
              ? Center(
                  child: TextButton(
                    onPressed: _cargarProductos,
                    child: Text('$_error. Toca para reintentar'),
                  ),
                )
              : _productos.isEmpty
                  ? Center(
                      child: Text('Aún no hay productos',
                          style: TextStyle(color: AppColors.textoSecundario)))
                  : RefreshIndicator(
                      color: AppColors.verdePrimario,
                      onRefresh: _cargarProductos,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                        children: [for (final p in _productos) ProductoTile(producto: p)],
                      ),
                    ),
    );
  }
}