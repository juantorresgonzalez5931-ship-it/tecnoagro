import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/widgets/perfil_sheet.dart';

class BarraNavegacion extends StatelessWidget {
  final int actual;
  final ValueChanged<int> onTap;
  const BarraNavegacion({super.key, required this.actual, required this.onTap});

  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Inicio'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag, 'Productos'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Asesor IA'),
    (Icons.person_outline, Icons.person, 'Mi Perfil'),
  ];

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
        items: [for (final t in _tabs) BottomNavigationBarItem(icon: Icon(t.$1), activeIcon: Icon(t.$2), label: t.$3)],
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
    // Si cierra sesión aquí, vuelve al inicio para no dejar abiertos los controles de administrador.
    abrirPerfil(context, alCerrarSesion: () {
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }
}