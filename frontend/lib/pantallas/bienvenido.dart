import 'package:flutter/material.dart';
import '../core/colores.dart';
import 'login.dart';

class BienvenidoScreen extends StatelessWidget {
  const BienvenidoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: Column(
          children: [
            // Etiqueta superior "PRIMERA VEZ"
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'PRIMERA VEZ',
                  style: TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bloque verde con el logo
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: AppColors.gradienteBienvenida,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.verdeOscuro.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: _LogoTecnoAgro(size: 90),
                ),
              ),
            ),

            // Contenido inferior
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido a\nTecnoAgro',
                      style: TextStyle(
                        color: AppColors.verdeTexto,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
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
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
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
          ],
        ),
      ),
    );
  }
}

/// Logo reutilizable (sol + colinas) usado en bienvenido y login.
class _LogoTecnoAgro extends StatelessWidget {
  final double size;
  const _LogoTecnoAgro({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = size.width * 0.28;

    // Sol
    final solPaint = Paint()..color = AppColors.naranjaSol;
    canvas.drawCircle(center, radius, solPaint);

    // Rayos del sol (triángulo blanco simple simulando destello)
    final rayoPaint = Paint()..color = Colors.white.withOpacity(0.9);
    final path = Path()
      ..moveTo(center.dx, center.dy - radius * 1.4)
      ..lineTo(center.dx - radius * 0.5, center.dy + radius * 0.1)
      ..lineTo(center.dx + radius * 0.5, center.dy + radius * 0.1)
      ..close();
    canvas.drawPath(path, rayoPaint);

    // Colinas verdes (dos curvas)
    final colinaPaint1 = Paint()..color = const Color(0xFF2E7D32);
    final colinaPath1 = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.55,
        size.width, size.height * 0.72,
      )
      ..lineTo(size.width, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.65,
        0, size.height * 0.82,
      )
      ..close();
    canvas.drawPath(colinaPath1, colinaPaint1);

    final colinaPaint2 = Paint()..color = const Color(0xFF4CAF50);
    final colinaPath2 = Path()
      ..moveTo(0, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.72,
        size.width, size.height * 0.88,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(colinaPath2, colinaPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LogoTecnoAgro extends StatelessWidget {
  final double size;
  const LogoTecnoAgro({super.key, this.size = 70});

  @override
  Widget build(BuildContext context) => _LogoTecnoAgro(size: size);
}