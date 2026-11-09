import 'package:flutter/material.dart';
import 'package:frontend/lib/service/services/perfil_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/pantallas/bienvenido.dart';
import 'package:frontend/service/services/carrito_service.dart';
import 'package:frontend/service/services/sesion_service.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String _nombre = '';
  String _email = '';
  bool _notificaciones = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final email = await SesionService.email();
    if (!mounted) return;
    setState(() {
      _nombre = prefs.getString('user_name') ?? '';
      _email = email ?? '';
      _notificaciones = prefs.getBool('notificaciones') ?? true;
    });
  }

  void _aviso(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? AppColors.error : AppColors.verdePrimario,
    ));
  }

  /// Diálogo genérico con campos de texto. Devuelve los valores o null si cancela.
  Future<List<String>?> _dialogo({
    required String titulo,
    String? descripcion,
    required List<({String label, bool oculto, String inicial})> campos,
    required String textoBoton,
    Color? colorBoton,
  }) {
    final controllers =
        campos.map((c) => TextEditingController(text: c.inicial)).toList();
    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titulo,
            style: const TextStyle(
                color: AppColors.textoPrincipal, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (descripcion != null) ...[
              Text(descripcion,
                  style: const TextStyle(color: AppColors.textoSecundario)),
              const SizedBox(height: 12),
            ],
            for (var i = 0; i < campos.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: controllers[i],
                  obscureText: campos[i].oculto,
                  decoration: InputDecoration(labelText: campos[i].label),
                ),
              ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textoSecundario)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, controllers.map((c) => c.text.trim()).toList()),
            child: Text(textoBoton,
                style: TextStyle(
                    color: colorBoton ?? AppColors.verdePrimario,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _editarNombre() async {
    final r = await _dialogo(
      titulo: 'Editar perfil',
      campos: [(label: 'Nombre', oculto: false, inicial: _nombre)],
      textoBoton: 'Guardar',
    );
    if (r == null) return;
    if (r[0].isEmpty) return _aviso('El nombre es obligatorio', error: true);

    final res = await PerfilService.actualizarNombre(r[0]);
    if (!mounted) return;
    if (res.ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', r[0]);
      if (!mounted) return;
      setState(() => _nombre = r[0]);
    }
    _aviso(res.mensaje, error: !res.ok);
  }

  Future<void> _cambiarPassword() async {
    final r = await _dialogo(
      titulo: 'Cambiar contraseña',
      campos: [
        (label: 'Contraseña actual', oculto: true, inicial: ''),
        (label: 'Nueva contraseña', oculto: true, inicial: ''),
        (label: 'Confirmar nueva contraseña', oculto: true, inicial: ''),
      ],
      textoBoton: 'Cambiar',
    );
    if (r == null) return;
    if (r[1].length < 6) {
      return _aviso('La nueva contraseña debe tener mínimo 6 caracteres', error: true);
    }
    if (r[1] != r[2]) return _aviso('Las contraseñas no coinciden', error: true);

    final res = await PerfilService.cambiarPassword(r[0], r[1]);
    if (!mounted) return;
    _aviso(res.mensaje, error: !res.ok);
  }

  Future<void> _eliminarCuenta() async {
    final r = await _dialogo(
      titulo: 'Eliminar cuenta',
      descripcion:
          'Esta acción no se puede deshacer. Escribe tu contraseña para confirmar.',
      campos: [(label: 'Contraseña', oculto: true, inicial: '')],
      textoBoton: 'Eliminar',
      colorBoton: AppColors.error,
    );
    if (r == null) return;
    if (r[0].isEmpty) return _aviso('Escribe tu contraseña', error: true);

    final res = await PerfilService.eliminarCuenta(r[0]);
    if (!mounted) return;
    if (!res.ok) return _aviso(res.mensaje, error: true);

    final prefs = await SharedPreferences.getInstance();
    for (final k in ['jwt_token', 'user_name', 'user_rol', 'user_id']) {
      await prefs.remove(k);
    }
    CarritoService.instancia.vaciar();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BienvenidoScreen()),
      (route) => false,
    );
  }

  void _comoFuncionanReservas() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cómo funcionan las reservas?',
            style: TextStyle(
                color: AppColors.textoPrincipal, fontWeight: FontWeight.bold)),
        content: const Text(
          '1. Agrega productos y confirma tu reserva.\n'
          '2. Recibirás un código con formato RES-XXXXXX.\n'
          '3. Tienes 48 horas para pasar por la tienda y reclamarlo.\n'
          '4. Pasado ese plazo la reserva vence y el stock se libera.\n\n'
          'Puedes cancelar una reserva pendiente desde "Mis reservas".',
          style: TextStyle(color: AppColors.textoSecundario),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  // ---------- UI ----------

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Text(
          titulo.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textoSecundario,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      );

  Widget _tarjeta(List<Widget> hijos) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borde),
        ),
        child: Column(children: hijos),
      );

  Widget _item(
    IconData icono,
    String titulo, {
    String? subtitulo,
    VoidCallback? onTap,
    Color? color,
    Widget? trailing,
  }) =>
      ListTile(
        leading: Icon(icono, color: color ?? AppColors.verdePrimario),
        title: Text(titulo,
            style: TextStyle(
                color: color ?? AppColors.textoPrincipal,
                fontWeight: FontWeight.w600)),
        subtitle: subtitulo == null
            ? null
            : Text(subtitulo,
                style: const TextStyle(color: AppColors.textoSecundario)),
        trailing: trailing ??
            (onTap == null
                ? null
                : const Icon(Icons.chevron_right, color: AppColors.textoPlaceholder)),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        backgroundColor: AppColors.fondoCrema,
        elevation: 0,
        foregroundColor: AppColors.textoPrincipal,
        title: const Text('Ajustes',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _seccion('Cuenta'),
          _tarjeta([
            _item(Icons.person_outline, 'Editar perfil',
                subtitulo: _nombre, onTap: _editarNombre),
            const Divider(height: 1, color: AppColors.borde),
            _item(Icons.lock_outline, 'Cambiar contraseña', onTap: _cambiarPassword),
            const Divider(height: 1, color: AppColors.borde),
            _item(Icons.email_outlined, 'Correo', subtitulo: _email),
          ]),
          _seccion('Preferencias'),
          _tarjeta([
            SwitchListTile(
              secondary:
                  const Icon(Icons.notifications_none, color: AppColors.verdePrimario),
              activeColor: AppColors.verdePrimario,
              title: const Text('Avisos de reservas',
                  style: TextStyle(
                      color: AppColors.textoPrincipal, fontWeight: FontWeight.w600)),
              subtitle: const Text('Recordatorio antes de que venza tu reserva',
                  style: TextStyle(color: AppColors.textoSecundario)),
              value: _notificaciones,
              onChanged: (v) async {
                setState(() => _notificaciones = v);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notificaciones', v);
              },
            ),
          ]),
          _seccion('Ayuda'),
          _tarjeta([
            _item(Icons.help_outline, '¿Cómo funcionan las reservas?',
                onTap: _comoFuncionanReservas),
            const Divider(height: 1, color: AppColors.borde),
            _item(Icons.info_outline, 'Acerca de TecnoAgro', onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'TecnoAgro',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Insumos Suaza',
              );
            }),
          ]),
          _seccion('Zona de peligro'),
          _tarjeta([
            _item(Icons.delete_forever_outlined, 'Eliminar cuenta',
                color: AppColors.error, onTap: _eliminarCuenta),
          ]),
        ],
      ),
    );
  }
}