import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/widgets/app_text_field.dart';
import '../service/services/user_service.dart';
import 'package:frontend/widgets/boton_google.dart';

/// Registro de cuenta nueva. Mismo estilo que el inicio de sesión.
class Formulario extends StatefulWidget {
  const Formulario({super.key});

  @override
  State<Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<Formulario> {
  final _nombreCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _userService = UserService();

  DateTime? _fecha;
  bool _cargando = false;
  bool _verPassword = false;

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _fechaCtrl, _emailCtrl, _telefonoCtrl, _passwordCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _mensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        backgroundColor: esError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _elegirFecha() async {
    FocusScope.of(context).unfocus();
    final ahora = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime(ahora.year - 25),
      firstDate: DateTime(1900),
      lastDate: ahora,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: AppColors.verdePrimario)),
        child: child!,
      ),
    );
    if (d == null) return;
    setState(() => _fecha = d);
    _fechaCtrl.text = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Devuelve el mensaje del primer error, o null si todo está bien.
  String? _validar() {
    if (_nombreCtrl.text.trim().length < 3) return 'Escribe tu nombre completo';
    if (_fecha == null) return 'Selecciona tu fecha de nacimiento';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailCtrl.text.trim())) {
      return 'Escribe un correo electrónico válido';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(_telefonoCtrl.text.trim())) return 'El teléfono debe tener 10 dígitos';
    if (_passwordCtrl.text.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  Future<void> _registrar() async {
    final error = _validar();
    if (error != null) {
      _mensaje(error, esError: true);
      return;
    }
    setState(() => _cargando = true);
    try {
      final respuesta = await _userService.crearCuenta(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        telefono: _telefonoCtrl.text.trim(),
        fechaNacimiento: _fecha!.toIso8601String().substring(0, 10),
      );
      if (!mounted) return;
      await _mostrarExito('${respuesta['message'] ?? 'Tu cuenta fue creada con éxito. Ya puedes iniciar sesión.'}');
      if (mounted) Navigator.pop(context); // vuelve al inicio de sesión
    } catch (e) {
      if (mounted) _mensaje(e.toString().replaceAll('Exception: ', ''), esError: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarExito(String texto) => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (d) => AlertDialog(
          backgroundColor: AppColors.fondoCrema,
          icon: Icon(Icons.check_circle_outline, color: AppColors.verdePrimario, size: 48),
          title: const Text('¡Cuenta creada!', textAlign: TextAlign.center),
          content: Text(texto, textAlign: TextAlign.center),
          actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Aceptar'))],
        ),
      );

  Widget _campoFecha() => GestureDetector(
        onTap: _elegirFecha,
        child: AbsorbPointer(
          child: AppTextField(
            label: 'Fecha de nacimiento',
            hint: 'DD/MM/AAAA',
            controller: _fechaCtrl,
            suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey.shade500, size: 20),
          ),
        ),
      );

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
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Image.asset('assets/images/logo-tecnoagro.png', width: 100, height: 100, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (b) => LinearGradient(
                colors: [AppColors.verdeClaro, AppColors.verdeOscuro],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(b),
              child: const Text('Regístrate',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            Column(spacing: 16, children: [
              AppTextField(
                label: 'Nombre completo',
                hint: 'Ej: Juan Esteban Rivera',
                controller: _nombreCtrl,
                textInputAction: TextInputAction.next,
              ),
              _campoFecha(),
              AppTextField(
                label: 'Correo electrónico',
                hint: 'Ej: usuario@gmail.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              AppTextField(
                label: 'Teléfono',
                hint: 'Ej: 3205244614',
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              AppTextField(
                label: 'Contraseña',
                hint: 'Mínimo 6 caracteres',
                controller: _passwordCtrl,
                obscureText: !_verPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _registrar(),
                suffixIcon: IconButton(
                  icon: Icon(_verPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.grey.shade500),
                  onPressed: () => setState(() => _verPassword = !_verPassword),
                ),
              ),
            ]),
            const SizedBox(height: 26),
            ElevatedButton(
              onPressed: _cargando ? null : _registrar,
              child: _cargando
                  ? const SizedBox(
                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('REGISTRARSE'),
            ),
            const SizedBox(height: 16),
            const BotonGoogle(),            const SizedBox(height: 22),
            Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: AppColors.textoSecundario, fontSize: 13.5),
                  children: [
                    const TextSpan(text: '¿Ya tienes cuenta? '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text('INICIAR SESIÓN',
                            style: TextStyle(
                                color: AppColors.verdePrimario, fontWeight: FontWeight.bold, fontSize: 13.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}