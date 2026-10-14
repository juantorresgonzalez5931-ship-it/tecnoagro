import 'package:flutter/material.dart';
import 'colores.dart';

/// Medidas globales de TecnoAgro.
/// Cambia estos valores y se actualizan TODOS los botones de la app.
class AppRadius {
  AppRadius._();

  /// Radio de las esquinas de los botones (menor = más cuadrado).
  static const double boton = 16;

  /// Alto de los botones principales.
  static const double botonAlto = 56;
}

/// Temas de botones basados en el botón "GUARDAR PRODUCTO".
class AppButtonThemes {
  AppButtonThemes._();

  static final RoundedRectangleBorder _forma = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.boton),
  );

  static const TextStyle _texto = TextStyle(fontSize: 15, fontWeight: FontWeight.bold);

  static const Size _tamanoMinimo = Size(64, AppRadius.botonAlto);

  static final ElevatedButtonThemeData elevated = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.verdePrimario,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.verdePrimario.withValues(alpha: 0.5),
      disabledForegroundColor: Colors.white70,
      minimumSize: _tamanoMinimo,
      shape: _forma,
      textStyle: _texto,
      elevation: 0,
    ),
  );

  static final FilledButtonThemeData filled = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.verdePrimario,
      foregroundColor: Colors.white,
      minimumSize: _tamanoMinimo,
      shape: _forma,
      textStyle: _texto,
    ),
  );

  static final OutlinedButtonThemeData outlined = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.verdePrimario,
      side: const BorderSide(color: AppColors.verdePrimario, width: 1.5),
      minimumSize: _tamanoMinimo,
      shape: _forma,
      textStyle: _texto,
    ),
  );

  /// Los TextButton son enlaces: solo comparten color y forma, no el alto.
  static final TextButtonThemeData text = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.verdePrimario,
      shape: _forma,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}