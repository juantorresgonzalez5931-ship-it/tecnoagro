import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/pantallas/verificar_codigo.dart';
import 'package:frontend/service/services/recuperar_service.dart';
import 'package:frontend/widgets/app_text_field.dart';

class RecuperarScreen extends StatefulWidget {
  const RecuperarScreen({super.key});

  @override
  State<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends State<RecuperarScreen> {
  final _emailController = TextEditingController();
  final _recuperarService = RecuperarService();
  bool _isLoading = false;

  static final _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _mostrarMensaje('Ingresa tu correo electrónico', esError: true);
      return;
    }
    if (!_regexEmail.hasMatch(email)) {
      _mostrarMensaje('Ingresa un correo válido', esError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _recuperarService.enviarCodigo(email);
      if (!mounted) return;
      _mostrarMensaje('Te enviamos un código a tu correo');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerificarCodigoScreen(email: email)),
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje(e.toString().replaceAll('Exception: ', ''), esError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: esError ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.verdePrimario),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset('assets/images/logo-tecnoagro.png',
                    width: 100, height: 100, fit: BoxFit.contain),
              ),
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [AppColors.verdeClaro, AppColors.verdeOscuro],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(b),
                child: const Text('Recuperar contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 22),
              Text(
                'Ingresa el correo electrónico asociado a tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textoPrincipal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Correo electrónico',
                hint: 'Ej: usuario@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                enabled: !_isLoading,
                onSubmitted: (_) => _continuar(),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Te enviaremos un código de 6 dígitos para verificar tu identidad.',
                  style: TextStyle(color: AppColors.textoSecundario, fontSize: 12),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _continuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdePrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('CONTINUAR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: AppColors.textoSecundario, fontSize: 13.5),
                    children: [
                      const TextSpan(text: '¿Ya recordaste tu contraseña? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text('INICIAR SESIÓN',
                              style: TextStyle(color: AppColors.verdePrimario, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}