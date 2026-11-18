import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/pantallas/bienvenido.dart';
import 'package:frontend/service/services/carrito_service.dart';
import '../core/colores.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();

    // Si la sesión sigue guardada, recupera el carrito de esa cuenta.
    CarritoService.instancia.cargarCarritoUsuario();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BienvenidoScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/logo-tecnoagro.png",
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  color: AppColors.verdePrimario,
                  backgroundColor: AppColors.verdePrimario.withOpacity(0.2),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}