import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/colores.dart';

class PerfilAdminPage extends StatefulWidget {
  final VoidCallback onCerrarSesion;
  const PerfilAdminPage({super.key, required this.onCerrarSesion});

  @override
  State<PerfilAdminPage> createState() => _PerfilAdminPageState();
}

class _PerfilAdminPageState extends State<PerfilAdminPage> {
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _nombre = prefs.getString('user_name') ?? '');
  }

  Widget _fila(IconData icono, String titulo, String detalle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, color: AppColors.verdePrimario, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo,
                style: TextStyle(
                    color: AppColors.textoPrincipal, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(detalle, style: TextStyle(color: AppColors.textoSecundario, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _nombre.isEmpty ? 'Administrador' : _nombre;
    final inicial = nombre[0].toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        title: const Text('Cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.verdePrimario,
              child: Text(inicial,
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 14),
          Text('Hola, $nombre',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textoPrincipal, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.verdePrimario.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.admin_panel_settings, size: 18, color: AppColors.verdePrimario),
                const SizedBox(width: 6),
                Text('Perfil administrativo',
                    style: TextStyle(
                        color: AppColors.verdePrimario, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borde),
            ),
            child: Column(children: [
              _fila(Icons.badge_outlined, 'Rol', 'Administrador de TecnoAgro'),
              Divider(height: 1, color: AppColors.borde),
              _fila(Icons.inventory_2_outlined, 'Tus permisos',
                  'Crear, editar y eliminar productos, y consultar pedidos y estadísticas.'),
              Divider(height: 1, color: AppColors.borde),
              _fila(Icons.timer_outlined, 'Sesión',
                  'Activa. Por seguridad dura 1 hora; después tendrás que iniciar sesión de nuevo.'),
            ]),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: widget.onCerrarSesion,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdePrimario,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}