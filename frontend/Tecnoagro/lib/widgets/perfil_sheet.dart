import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/pantallas/bienvenido.dart';
import 'package:frontend/pantallas/login.dart';
import 'package:frontend/pantallas/mis_reservas_screen.dart';
import 'package:frontend/pantallas/editar_perfil_screen.dart';
import 'package:frontend/pantallas/manual_usuario_screen.dart';
import 'package:frontend/service/services/carrito_service.dart';
import 'package:frontend/service/services/perfil_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mi Perfil: conserva el acceso al login cuando no hay sesión.
Future<void> abrirPerfil(
  BuildContext context, {
  VoidCallback? alCerrarSesion,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return;
  if ((prefs.getString('jwt_token') ?? '').isEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return;
  }

  mostrarPerfil(context, prefs.getString('user_name') ?? 'Usuario', () async {
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    await prefs.remove('user_rol');
    await prefs.remove('user_id');
    CarritoService.instancia.vaciar();

    if (alCerrarSesion != null) {
      alCerrarSesion();
    } else {
      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BienvenidoScreen()),
        (route) => false,
      );
    }
  });
}

Future<bool> _confirmarCierre(BuildContext context) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Cerrar sesión',
          style: TextStyle(
            color: AppColors.textoPrincipal,
            fontWeight: FontWeight.bold,
          )),
      content: Text('¿Seguro que quieres cerrar sesión?',
          style: TextStyle(color: AppColors.textoSecundario)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancelar',
              style: TextStyle(color: AppColors.textoSecundario)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Cerrar sesión',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              )),
        ),
      ],
    ),
  );
  return confirmado == true;
}

Future<bool> _confirmarEliminacion(BuildContext context) async {
  final controller = TextEditingController();
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Eliminar cuenta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esta acción es permanente. Se cerrará tu sesión y se solicitará '
            'al servidor eliminar tu cuenta. Para confirmar, escribe ELIMINAR.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Escribe ELIMINAR',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            ctx,
            controller.text.trim().toUpperCase() == 'ELIMINAR',
          ),
          child: const Text('Eliminar cuenta',
              style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  controller.dispose();
  return confirmado == true;
}

void mostrarPerfil(
  BuildContext context,
  String nombre,
  Future<void> Function() onCerrarSesion,
) {
  final inicial = nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();
  bool cerrando = false;
  bool eliminando = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.fondoCrema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => StatefulBuilder(
      builder: (_, setSheet) => PopScope(
        canPop: !cerrando && !eliminando,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borde,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.verdePrimario,
                  child: Text(inicial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      )),
                ),
                const SizedBox(height: 10),
                Text(nombre,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textoPrincipal,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 3),
                Text('Mi perfil',
                    style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 13,
                    )),
                const SizedBox(height: 18),
                Divider(color: AppColors.borde, height: 1),
                const SizedBox(height: 10),
                _tituloGrupo('GESTIÓN DE CUENTA'),
                _opcion(
                  icono: Icons.person_outline_rounded,
                  titulo: 'Editar información personal',
                  subtitulo: 'Actualiza tus datos personales',
                  onTap: () {
                    Navigator.pop(sheet);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditarPerfilScreen(),
                      ),
                    );
                  },
                ),
                _opcion(
                  icono: Icons.inventory_2_outlined,
                  titulo: 'Mis reservas',
                  subtitulo: 'Consulta tus pedidos y reservas',
                  onTap: () {
                    Navigator.pop(sheet);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MisReservasScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 12),
                _tituloGrupo('AYUDA Y SOPORTE'),
                _opcion(
                  icono: Icons.menu_book_outlined,
                  titulo: 'Manuales de usuario',
                  subtitulo: 'Aprende a utilizar TecnoAgro',
                  onTap: () {
                    Navigator.pop(sheet);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManualUsuarioScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 12),
                _tituloGrupo('SESIÓN'),
                _opcion(
                  icono: Icons.logout_rounded,
                  titulo: cerrando ? 'Cerrando sesión...' : 'Cerrar sesión',
                  color: Colors.red.shade700,
                  onTap: cerrando || eliminando
                      ? null
                      : () async {
                          final ok = await _confirmarCierre(sheet);
                          if (!ok || !sheet.mounted) return;
                          setSheet(() => cerrando = true);
                          try {
                            await onCerrarSesion();
                          } finally {
                            if (sheet.mounted) {
                              setSheet(() => cerrando = false);
                            }
                          }
                        },
                ),
                _opcion(
                  icono: Icons.delete_outline_rounded,
                  titulo: eliminando ? 'Eliminando cuenta...' : 'Eliminar cuenta',
                  subtitulo: 'Esta acción no se puede deshacer',
                  color: Colors.red.shade700,
                  onTap: cerrando || eliminando
                      ? null
                      : () async {
                          final ok = await _confirmarEliminacion(sheet);
                          if (!ok || !sheet.mounted) return;
                          setSheet(() => eliminando = true);
                          final resultado =
                              await PerfilService.eliminarCuenta();
                          if (!sheet.mounted) return;
                          if (!resultado.ok) {
                            setSheet(() => eliminando = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(resultado.mensaje),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                            return;
                          }
                          final prefs = await SharedPreferences.getInstance();
                          for (final key in [
                            'jwt_token',
                            'user_name',
                            'user_rol',
                            'user_id',
                          ]) {
                            await prefs.remove(key);
                          }
                          CarritoService.instancia.vaciar();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BienvenidoScreen(),
                            ),
                            (_) => false,
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _tituloGrupo(String texto) => Align(
  alignment: Alignment.centerLeft,
  child: Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 5),
    child: Text(
      texto,
      style: const TextStyle(
        color: AppColors.textoSecundario,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  ),
);

Widget _opcion({
  required IconData icono,
  required String titulo,
  String? subtitulo,
  Color? color,
  VoidCallback? onTap,
}) => ListTile(
  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
  leading: Icon(icono, color: color ?? AppColors.verdePrimario),
  title: Text(titulo,
      style: TextStyle(
        color: color ?? AppColors.textoPrincipal,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      )),
  subtitle: subtitulo == null
      ? null
      : Text(subtitulo,
          style: const TextStyle(
            color: AppColors.textoSecundario,
            fontSize: 12,
          )),
  trailing: const Icon(Icons.chevron_right_rounded,
      color: AppColors.textoPlaceholder),
  onTap: onTap,
);
