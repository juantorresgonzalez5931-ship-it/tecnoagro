import 'package:flutter/material.dart';
import 'core/colores.dart';
import 'pantallas/bienvenido.dart';

void main() {
  runApp(const TecnoAgroApp());
}

class TecnoAgroApp extends StatelessWidget {
  const TecnoAgroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TecnoAgro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.fondoCrema,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.verdePrimario,
          primary: AppColors.verdePrimario,
        ),
      ),
      home: const BienvenidoScreen(),
    );
  }
}