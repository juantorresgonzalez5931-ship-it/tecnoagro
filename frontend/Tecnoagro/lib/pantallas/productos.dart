import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/widgets/barra_navegacion.dart';
import 'package:frontend/widgets/catalogo_productos.dart';
import 'package:frontend/widgets/encabezado_catalogo.dart';

/// Catálogo para el usuario común: puede ver, buscar y filtrar productos.
/// Toda la lógica está en CatalogoProductos, que comparte con la pantalla del administrador.
class ProductosScreen extends StatelessWidget {
  const ProductosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: const SafeArea(
        child: Column(children: [
          EncabezadoCatalogo(),
          Expanded(child: CatalogoProductos()),
        ]),
      ),
      bottomNavigationBar: BarraNavegacion(actual: 1, onTap: (i) => navegarDesdeCatalogo(context, i)),
    );
  }
}