import 'package:flutter/material.dart';

class DraggableFloatingActionButton extends StatefulWidget {
  final VoidCallback onTap;
  const DraggableFloatingActionButton({super.key, required this.onTap});

  @override
  State<DraggableFloatingActionButton> createState() =>
      _DraggableFloatingActionButtonState();
}

class _DraggableFloatingActionButtonState
    extends State<DraggableFloatingActionButton> {
  Offset _posicion = const Offset(0, 0);
  bool _arrastrando = false;

  @override
  Widget build(BuildContext context) {
    final tamanoPantalla = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Fondo invisible que captura los toques
        Positioned.fill(
          child: GestureDetector(
            onPanUpdate: (detalles) {
              setState(() {
                _posicion += detalles.delta;
                // Limitar dentro de la pantalla
                _posicion = Offset(
                  _posicion.dx
                    .clamp(0, tamanoPantalla.width - 56)
                    .toDouble(),
                  _posicion.dy
                    .clamp(0, tamanoPantalla.height - 56)
                    .toDouble(),
                );
              });
            },
            onPanStart: (_) => setState(() => _arrastrando = true),
            onPanEnd: (_) => setState(() => _arrastrando = false),
            child: const SizedBox.expand(),
          ),
        ),

        // El botón
        Positioned(
          left: _posicion.dx,
          top: _posicion.dy,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _arrastrando ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: FloatingActionButton.extended(
                onPressed: widget.onTap,
                backgroundColor: Colors.green,
                icon: const Icon(Icons.add),
                label: const Text('Crear producto'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
  