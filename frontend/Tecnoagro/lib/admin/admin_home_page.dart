import 'package:flutter/material.dart';
import 'package:frontend/pantallas/bienvenido.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/admin/perfil_admin_page.dart';
import '../core/colores.dart';
import 'admin_dashboard_page.dart';
import 'admin_productos_page.dart';
import 'admin_reservas_page.dart';
// ajusta la ruta a tu BienvenidoScreen

class AdminHomePage extends StatefulWidget {
  final String token;
  const AdminHomePage({super.key, required this.token});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _indice = 0;

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BienvenidoScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
   final paginas = [
  AdminDashboardPage(token: widget.token),
  AdminProductosPage(token: widget.token),
  AdminReservasPage(token: widget.token),
  PerfilAdminPage(onCerrarSesion: _cerrarSesion),
];

    return Scaffold(
      body: IndexedStack(index: _indice, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [

         NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Resumen',
  ),

        NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Productos',
  ),

         NavigationDestination(
        icon: Icon(Icons.inventory),
        selectedIcon: Icon(Icons.inventory),
        label: 'Reservas',
  ),

        NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Mi perfil',
  ),
],

      ),
    );
  }
}
