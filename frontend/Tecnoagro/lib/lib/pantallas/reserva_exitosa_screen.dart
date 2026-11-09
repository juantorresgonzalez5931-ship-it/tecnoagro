import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'mis_reservas_screen.dart';

class ReservaExitosaScreen extends StatelessWidget {
  final Map<String, dynamic> pedido;

  const ReservaExitosaScreen({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    DateTime? fecha;

    try {
      fecha = DateTime.parse(pedido['fecha_limite'].toString());
    } catch (_) {}

    final fechaBonita = fecha != null
        ? DateFormat('dd/MM/yyyy • HH:mm').format(fecha.toLocal())
        : 'No disponible';

    return Scaffold(
      backgroundColor: const Color(0xffF8F8F5),
      appBar: AppBar(
        title: const Text('Reserva realizada'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.35),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 70),
              ),

              const SizedBox(height: 30),

              const Text(
                '¡Reserva confirmada!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                'Tu pedido fue registrado exitosamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),

              const SizedBox(height: 6),

              Text(
                'Presenta el siguiente código cuando retires tus productos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'CÓDIGO DE RESERVA',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SelectableText(
                      pedido['codigo'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(height: 1, color: Colors.grey.shade200),

                    const SizedBox(height: 18),

                    _dato(
                      icono: Icons.pending_actions_rounded,
                      color: Colors.orange,
                      titulo: 'Estado',
                      valor:
                          pedido['estado']?.toString().toUpperCase() ??
                          'PENDIENTE',
                    ),

                    const SizedBox(height: 12),

                    _dato(
                      icono: Icons.attach_money_rounded,
                      color: Colors.green,
                      titulo: 'Total',
                      valor: '\$${pedido['total']}',
                    ),

                    const SizedBox(height: 12),

                    _dato(
                      icono: Icons.schedule_rounded,
                      color: Colors.blue,
                      titulo: 'Recoger antes de',
                      valor: fechaBonita,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('VER MIS RESERVAS'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MisReservasScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('CONTINUAR COMPRANDO'),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ),

              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.content_copy),
                label: const Text('Copiar código de reserva'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dato({
    required IconData icono,
    required Color color,
    required String titulo,
    required String valor,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(.12),
          child: Icon(icono, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
