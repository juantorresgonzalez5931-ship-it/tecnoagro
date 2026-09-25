import 'package:flutter/material.dart';
import 'package:frontend/widgets/app_text_field.dart';
import '/service/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/user_models.dart';
import '/pages/home.dart';
import '/pantallas/formulario.dart';
import '/pantallas/bienvenido.dart';
import '/core/colores.dart';

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
  bool _isLoadingGoogle = false;
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('user_name', usuario.nombre ?? 'Usuario');
      if (!mounted) return;
      _mostrarMensaje('!Bienvenido, ${usuario.nombre}!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje(e.toString(), esError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continuarConGoogle() async {
    setState(() => _isLoadingGoogle = true);
    try {
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje(e.toString(), esError: true);
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
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
                child: const Text('Inicia sesion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 26),
              AppTextField(label: 'Correo electronico', hint: 'Ej: usuario@gmail.com', controller: _emailController),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Contrasena',
                hint: '',
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey.shade500),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, 
                  style: TextButton.styleFrom(foregroundColor: AppColors.verdePrimario, padding: EdgeInsets.zero),
                  child: const Text('¿Olvidaste tu contrasena?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdePrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('INICIAR SESION', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o continua con', style: TextStyle(color: AppColors.textoSecundario, fontSize: 13)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _isLoadingGoogle ? null : _continuarConGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoadingGoogle
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/logo-google.png', width: 20, height: 20),
                            const SizedBox(width: 10),
                            const Text('Continuar con Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: AppColors.textoSecundario, fontSize: 13.5),
                    children: [
                      const TextSpan(text: '¿No tienes cuenta? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Formulario())),
                          child: Text('REGISTRATE AQUI',
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