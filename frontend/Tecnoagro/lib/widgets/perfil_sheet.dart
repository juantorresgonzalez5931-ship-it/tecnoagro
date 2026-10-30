import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/pantallas/bienvenido.dart';
import 'package:frontend/pantallas/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pantallas/mis_reservas_screen.dart';
import 'package:frontend/service/services/carrito_service.dart';

/// Mi Perfil: sin sesión abre el login; con sesión muestra el panel del perfil.
/// [alCerrarSesion] se ejecuta después de borrar la sesión (por ejemplo, para refrescar el inicio).
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
  MaterialPageRoute(
    builder: (_) => const BienvenidoScreen(),
  ),
  (route) => false,
);
    }
  });
}

/// Pregunta antes de cerrar sesión. Devuelve true si el usuario confirma.
Future<bool> _confirmarCierre(BuildContext context) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Cerrar sesión',
        style: TextStyle(
          color: AppColors.textoPrincipal,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        '¿Seguro que quieres cerrar sesión?',
        style: TextStyle(color: AppColors.textoSecundario),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textoSecundario),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Cerrar sesión',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmado == true;
}

/// Panel de "Mi Perfil" para el usuario con sesión iniciada.
/// [onCerrarSesion] borra los datos guardados y refresca la pantalla.
void mostrarPerfil(
  BuildContext context,
  String nombre,
  Future<void> Function() onCerrarSesion,
) {
  final inicial = nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();
  bool cerrando = false;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.fondoCrema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => StatefulBuilder(
      builder: (_, setSheet) => PopScope(
        canPop:
            !cerrando, // no se puede cerrar el panel mientras se cierra la sesión
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra de arrastre
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borde,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                // Avatar con la inicial del usuario
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.verdePrimario,
                  child: Text(
                    inicial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mi perfil',
                  style: TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: AppColors.borde, height: 1),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text(
                      'MIS RESERVAS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdePrimario,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheet);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MisReservasScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: cerrando
                        ? null
                        : () async {
                            final ok = await _confirmarCierre(sheet);
                            if (!ok || !sheet.mounted) return;
                            setSheet(() => cerrando = true);
                            try {
                              await onCerrarSesion();
                            } finally {
                              if (sheet.mounted) {
                                setSheet(() {
                                  cerrando = false;
                                });
                              }
                            }
                          },
                    icon: cerrando
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red.shade700,
                            ),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: const Text(
                      'CERRAR SESIÓN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      backgroundColor: Colors.red.shade50,
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
