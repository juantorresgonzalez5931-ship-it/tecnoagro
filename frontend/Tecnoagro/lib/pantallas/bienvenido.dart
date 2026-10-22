import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/admin/admin_home_page.dart';
import '../core/colores.dart';
import '../pages/home.dart';

class BienvenidoScreen extends StatelessWidget {
  const BienvenidoScreen({super.key});

  /// Si hay una sesión de administrador guardada, entra al panel admin;
  /// si no, entra a la pantalla de usuario.
  Future<void> _entrar(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString('jwt_token') ?? '').trim();
    final rol = prefs.getString('user_rol') ?? '';
    if (!context.mounted) return;

    final Widget destino = (token.isNotEmpty && rol == 'admin')
        ? AdminHomePage(token: token)
        : const HomeScreen();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destino),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.gradienteBienvenida,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.verdeOscuro.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Image.asset(
                    'assets/images/logo-tecnoagro.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          AppColors.verdeClaro,
                          AppColors.verdeOscuro,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Text(
                        'Bienvenido a\nTecnoAgro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Puedes acceder a nuestro catálogo TecnoAgro, '
                      'resolver tus dudas acerca del tema agrícola con '
                      'nuestra inteligencia artificial y también separar '
                      'tus productos desde la app.',
                      style: TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _entrar(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdePrimario,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '¡VAMOS!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LogoTecnoAgro extends StatelessWidget {
  final double size;
  const LogoTecnoAgro({super.key, this.size = 70});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo-tecnoagro.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}