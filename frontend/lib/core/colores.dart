import 'package:flutter/material.dart';

/// Paleta de colores centralizada de TecnoAgro.
/// Importa este archivo en cualquier pantalla con:
/// import '../core/colores.dart';
class AppColors {
  AppColors._();

  // Verdes principales
  static const Color verdeOscuro = Color(0xFF1F4A2A);
  static const Color verdePrimario = Color(0xFF2C5E32);
  static const Color verdeMedio = Color(0xFF3B7042);
  static const Color verdeClaro = Color(0xFF4CAF50);
  static const Color verdeTexto = Color(0xFF2E7D32);

  // Fondo y superficies
  static const Color fondoCrema = Color(0xFFFAF9F4);
  static const Color blanco = Color(0xFFFFFFFF);

  // Textos
  static const Color textoPrincipal = Color(0xFF1A1A1A);
  static const Color textoSecundario = Color(0xFF6B7280);
  static const Color textoPlaceholder = Color(0xFF9CA3AF);

  // Bordes y detalles
  static const Color borde = Color(0xFFE5E7EB);
  static const Color naranjaSol = Color(0xFFF2A93B);

  // Gradiente de la pantalla de bienvenida
  static const LinearGradient gradienteBienvenida = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [verdeMedio, verdeOscuro],
  );
}