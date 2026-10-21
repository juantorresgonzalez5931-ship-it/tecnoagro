import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/service/services/google_service.dart';

/// Botón "Continuar con Google": abre el selector de cuentas y entra a la app.
/// Sirve tanto en iniciar sesión como en registrarse.
class BotonGoogle extends StatefulWidget {
  const BotonGoogle({super.key});

  @override
  State<BotonGoogle> createState() => _BotonGoogleState();
}

class _BotonGoogleState extends State<BotonGoogle> {
  bool _cargando = false;

  void _mensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        backgroundColor: esError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _entrar() async {
    setState(() => _cargando = true);
    try {
      final nombre = await GoogleService().iniciarSesion();
      if (!mounted) return;
      _mensaje('¡Bienvenido, $nombre!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on GoogleCancelado {
      // La persona cerró el selector: no mostramos nada.
    } catch (e) {
      if (mounted) _mensaje(e.toString().replaceAll('Exception: ', ''), esError: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _cargando ? null : _entrar,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.verdeOscuro,
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: _cargando
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('assets/images/logo-google.png', width: 20, height: 20),
              const SizedBox(width: 10),
              const Text('Continuar con Google'),
            ]),
    );
  }
}