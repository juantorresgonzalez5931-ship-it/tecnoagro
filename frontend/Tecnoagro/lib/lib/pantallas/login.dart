import 'package:flutter/material.dart';
import 'package:frontend/core/inicio_por_rol.dart';
import 'package:frontend/core/tema.dart';
import 'package:frontend/pantallas/recuperar.dart';
import 'package:frontend/widgets/app_text_field.dart';
import 'package:frontend/widgets/boton_google.dart';
import '/service/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/user_models.dart';
import '/pantallas/formulario.dart';
import '/pantallas/bienvenido.dart';
import '/core/colores.dart';
import 'package:frontend/service/services/carrito_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _mostrarMensaje('Ingresa tu correo y contrasena', esError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final respuesta = await _userService.loginUsuario(email, password);
      final String token = respuesta['token'];
      final usuario = UserModels.fromJson(respuesta['usuario']);
      debugPrint('ID USUARIO: ${usuario.id}');
      print('USUARIO COMPLETO: ${respuesta['usuario']}');
      print('ID USUARIO: ${usuario.id}');
      final String rol = respuesta['usuario']['rol'] ?? 'usuario';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('user_name', usuario.nombre ?? 'Usuario');
      await prefs.setString('user_rol', rol);
      final idUsuario = int.tryParse(usuario.id ?? '');

      debugPrint('ID LOGIN: ${usuario.id}');
      debugPrint('ID PARSEADO: $idUsuario');

      print('USUARIO LOGIN: ${usuario.nombre}');
      print('ID LOGIN: $idUsuario');

      if (idUsuario != null) {
        await prefs.setInt('user_id', idUsuario);

        debugPrint('USER_ID GUARDADO: $idUsuario');

        await CarritoService.instancia.cargarCarritoUsuario();
      }

      // Decide el inicio según el rol que se acaba de guardar (admin o usuario común).
      final destino = await pantallaInicioPorRol();
      if (!mounted) return;
      _mostrarMensaje('¡Bienvenido, ${usuario.nombre}!');
      // Borra toda la navegación anterior para no arrastrar pantallas de otra sesión.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destino),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje(e.toString(), esError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
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
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BienvenidoScreen()),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo-tecnoagro.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [AppColors.verdeClaro, AppColors.verdeOscuro],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(b),
                child: const Text(
                  'Inicia sesion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              AppTextField(
                label: 'Correo electronico',
                hint: 'Ej: usuario@gmail.com',
                controller: _emailController,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Contrasena',
                hint: '',
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecuperarScreen()),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    '¿Olvidaste tu contrasena?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // El estilo del botón viene del tema global (core/tema.dart)
              SizedBox(
                height: AppRadius.botonAlto,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _iniciarSesion,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('INICIAR SESION'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'o continua con',
                      style: TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 16),
              const BotonGoogle(),
              const SizedBox(height: 22),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 13.5,
                    ),
                    children: [
                      const TextSpan(text: '¿No tienes cuenta? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Formulario(),
                            ),
                          ),
                          child: Text(
                            'REGISTRATE AQUI',
                            style: TextStyle(
                              color: AppColors.verdePrimario,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
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
