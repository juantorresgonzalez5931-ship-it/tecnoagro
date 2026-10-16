import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/core/navegacion.dart';
import 'package:frontend/service/services/carrito_service.dart';
import 'package:frontend/widgets/perfil_sheet.dart';

/// Barra inferior: Inicio, Productos, Asesor IA, Carrito y Mi Perfil.
class BarraNavegacion extends StatelessWidget {
  final int actual;
  final ValueChanged<int> onTap;
  const BarraNavegacion({super.key, required this.actual, required this.onTap});

  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Inicio'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag, 'Productos'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Asesor IA'),
    (Icons.shopping_cart_outlined, Icons.shopping_cart, 'Carrito'),
    (Icons.person_outline, Icons.person, 'Mi Perfil'),
  ];

  static const _indiceCarrito = 3;

  /// El icono del carrito muestra un círculo rojo con la cantidad de productos.
  Widget _icono(IconData icono, bool esCarrito) {
    if (!esCarrito) return Icon(icono);
    return ListenableBuilder(
      listenable: CarritoService.instancia,
      builder: (context, _) {
        final cantidad = CarritoService.instancia.cantidadTotal;
        return Badge(
          isLabelVisible: cantidad > 0,
          label: Text('$cantidad'),
          backgroundColor: Colors.red.shade600,
          child: Icon(icono),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.borde))),
      child: BottomNavigationBar(
        currentIndex: actual,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppColors.verdePrimario,
        unselectedItemColor: AppColors.textoSecundario,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: onTap,
        items: [
          for (var i = 0; i < _tabs.length; i++)
            BottomNavigationBarItem(
              icon: _icono(_tabs[i].$1, i == _indiceCarrito),
              activeIcon: _icono(_tabs[i].$2, i == _indiceCarrito),
              label: _tabs[i].$3,
            ),
        ],
      ),
    );
  }
}

/// Aviso para las secciones que aún no existen.
void mostrarProximamente(BuildContext context, String seccion) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$seccion estará disponible pronto'),
      backgroundColor: AppColors.verdePrimario,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Acciones de la barra inferior cuando estás dentro del catálogo.
void navegarDesdeCatalogo(BuildContext context, int i) {
  if (i == 0) {
    Navigator.pop(context);
  } else if (i == 2) {
    mostrarProximamente(context, 'Asesor IA');
  } else if (i == 3) {
    abrirCarrito(context, desdeCatalogo: true);
  } else if (i == 4) {
    // Si cierra sesión aquí, vuelve al inicio para no dejar abiertos los controles de administrador.
    abrirPerfil(context, alCerrarSesion: () {
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }
}

/// Acciones de la barra inferior cuando estás dentro del carrito.
void navegarDesdeCarrito(BuildContext context, int i, {bool desdeCatalogo = false}) {
  if (i == 0) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  } else if (i == 1) {
    if (desdeCatalogo) {
      Navigator.pop(context);
    } else {
      reemplazarPorCatalogo(context);
    }
  } else if (i == 2) {
    mostrarProximamente(context, 'Asesor IA');
  } else if (i == 4) {
    abrirPerfil(context, alCerrarSesion: () {
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }
}