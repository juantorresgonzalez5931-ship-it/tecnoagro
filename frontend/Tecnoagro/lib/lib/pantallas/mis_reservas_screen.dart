import 'package:flutter/material.dart';
import 'package:frontend/service/services/pedido_service.dart';
import 'detalle_reserva_screen.dart';

class MisReservasScreen
    extends StatelessWidget {
  const MisReservasScreen({
    super.key,
  });

  Color colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;

      case 'entregado':
        return Colors.green;

      case 'cancelado':
        return Colors.red;

      case 'vencido':
        return Colors.grey;

      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis reservas'),
      ),
      body: FutureBuilder(
        future:
            PedidoService().obtenerMisPedidos(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final reservas =
              snapshot.data as List;

          if (reservas.isEmpty) {
            return const Center(
              child: Text(
                'No tienes reservas',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount:
                reservas.length,
            itemBuilder:
                (context, index) {
              final reserva =
                  reservas[index];

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 14,
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets
                          .all(12),
                  leading:
                      CircleAvatar(
                    backgroundColor:
                        colorEstado(
                      reserva['estado'],
                    ),
                    child:
                        const Icon(
                      Icons.inventory,
                      color:
                          Colors.white,
                    ),
                  ),
                  title: Text(
                    reserva['codigo'],
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                  subtitle: Text(
                    reserva['estado']
                        .toUpperCase(),
                  ),
                  trailing:
                      const Icon(
                    Icons
                        .arrow_forward_ios,
                  ),
                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetalleReservaScreen(
                          idReserva:
                              reserva[
                                  'id'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}