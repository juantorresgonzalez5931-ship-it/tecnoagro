import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/core/tema.dart';
import 'package:frontend/productos_admin/crear_producto.dart';
import 'package:frontend/widgets/barra_navegacion.dart';
import 'package:frontend/widgets/catalogo_productos.dart';
import 'package:frontend/widgets/encabezado_catalogo.dart';

/// Catálogo del administrador: lo mismo que ve el usuario común, más el botón "Añadir producto".
class ProductosAdminScreen extends StatefulWidget {
  const ProductosAdminScreen({super.key});

  @override
  State<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends State<ProductosAdminScreen> {
  final _catalogo = GlobalKey<CatalogoProductosState>();

  Future<void> _anadirProducto() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CrearProductoScreen()),
    );
    if (creado == true) _catalogo.currentState?.recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: Column(children: [
          const EncabezadoCatalogo(subtitulo: 'Administrador'),
          Expanded(
            child: CatalogoProductos(
              key: _catalogo,
              accionExtra: SizedBox(
                width: double.infinity,
                height: AppRadius.botonAlto,
                child: ElevatedButton.icon(
                  onPressed: _anadirProducto,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir producto'),
                ),
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: BarraNavegacion(actual: 1, onTap: (i) => navegarDesdeCatalogo(context, i)),
    );
  }
}