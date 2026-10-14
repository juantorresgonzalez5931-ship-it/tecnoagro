import 'package:flutter/material.dart';
import 'package:frontend/pantallas/splashscreen.dart';
import 'core/colores.dart';
import 'core/tema.dart';
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
        fontFamily: 'GoogleSansFlex',
        scaffoldBackgroundColor: AppColors.fondoCrema,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.verdePrimario,
          primary: AppColors.verdePrimario,
        ),
        // Estilo global de botones (se edita en core/tema.dart)
        elevatedButtonTheme: AppButtonThemes.elevated,
        filledButtonTheme: AppButtonThemes.filled,
        outlinedButtonTheme: AppButtonThemes.outlined,
        textButtonTheme: AppButtonThemes.text,
        // Ajuste global del grosor de la letra
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontWeight: FontWeight.w600),
          labelLarge: TextStyle(fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      home: const Splashscreen(),
    );
  }
}