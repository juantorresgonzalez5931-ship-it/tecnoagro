import 'package:flutter/material.dart';
import 'package:frontend/service/services/pedido_service.dart';

class DetalleReservaScreen extends StatelessWidget {
  final int idReserva;

  const DetalleReservaScreen({
    super.key,
    required this.idReserva,
  });

  Color _estadoColor(String estado) {
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
        title: const Text('Detalle de reserva'),
      ),
      body: FutureBuilder(
        future: PedidoService().obtenerPedido(
          idReserva,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final pedido =
              snapshot.data as Map<String, dynamic>;

          final detalles =
              pedido['detalles'] as List;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              Text(
                pedido['codigo'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _estadoColor(
                    pedido['estado'],
                  ).withOpacity(.12),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      color: _estadoColor(
                        pedido['estado'],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      pedido['estado']
                          .toString()
                          .toUpperCase(),
                      style: TextStyle(
                        color: _estadoColor(
                          pedido['estado'],
                        ),
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Total: \$${pedido['total']}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Productos reservados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              ...detalles.map((detalle) {
                final producto =
                    detalle['producto'];

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    child: Row(
                      children: [

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          child: Image.network(
                            producto[
                                'imagen_url'],
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [

                              Text(
                                producto[
                                    'nombre'],
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Cantidad: ${detalle['cantidad']}',
                              ),

                              Text(
                                'Precio: \$${detalle['precio_unitario']}',
                              ),

                              Text(
                                'Subtotal: \$${detalle['subtotal']}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}