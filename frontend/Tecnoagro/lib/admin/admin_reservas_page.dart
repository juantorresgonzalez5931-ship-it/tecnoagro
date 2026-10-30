import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/colores.dart';
import '../service/services/api_config.dart';

class AdminReservasPage extends StatefulWidget {
  final String token;

  const AdminReservasPage({super.key, required this.token});

  @override
  State<AdminReservasPage> createState() => _AdminReservasPageState();
}

class _AdminReservasPageState extends State<AdminReservasPage> {
  final codigoController = TextEditingController();

  Map<String, dynamic>? pedido;

  List<dynamic> reservas = [];

  bool cargando = false;

  String filtroEstado = 'todos';
  @override
  void initState() {
    super.initState();

    cargarReservas();

    codigoController.addListener(() {
      if (codigoController.text.trim().isEmpty) {
        setState(() {
          pedido = null;
        });
      }
    });
  }

  Future<void> cargarReservas() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/pedidos'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          reservas = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error reservas: $e');
    }
  }

  Future<void> buscarReserva() async {
    if (codigoController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/pedidos/codigo/${codigoController.text.trim()}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          pedido = data;
        });
      } else {
        throw Exception(data['error']);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() {
      cargando = false;
    });
  }

  Future<void> cambiarEstado(String estado) async {
    if (pedido == null) return;

    final response = await http.patch(
      Uri.parse('${ApiConfig.apiBaseUrl}/pedidos/${pedido!['id']}/estado'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'estado': estado}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        pedido!['estado'] = estado;
      });

      await cargarReservas();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['error'])));
    }
  }

  Color estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return AppColors.naranjaSol;

      case 'entregado':
        return AppColors.verdePrimario;

      case 'cancelado':
        return Colors.red.shade700;
      case 'vencido':
        return AppColors.textoSecundario;

      default:
        return AppColors.verdeMedio;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservasFiltradas = filtroEstado == 'todos'
        ? reservas
        : reservas.where((r) {
            return r['estado'].toString().toLowerCase() == filtroEstado;
          }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Gestión de reservas',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textoPrincipal,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: codigoController,

              onChanged: (value) {
                if (value.trim().isEmpty) {
                  setState(() {
                    pedido = null;
                  });
                }
              },

              decoration: InputDecoration(
                labelText: 'Código de reserva',
                hintText: 'RES-EF80FD',

                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (codigoController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          codigoController.clear();

                          setState(() {
                            pedido = null;
                          });
                        },
                      ),

                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: buscarReserva,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (cargando) const CircularProgressIndicator(),

            if (pedido != null)
              Card(
                color: AppColors.blanco,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borde),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        pedido!['codigo'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text('Estado: ${pedido!['estado']}'),

                      Text('Total: \$${pedido!['total']}'),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: pedido!['estado'] == 'entregado'
                            ? null
                            : () {
                                cambiarEstado('entregado');
                              },
                        child: const Text('MARCAR COMO ENTREGADO'),
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdePrimario,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: pedido!['estado'] == 'cancelado'
                            ? null
                            : () {
                                cambiarEstado('cancelado');
                              },
                        child: const Text('CANCELAR'),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reservas recientes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: filtroEstado == 'todos',
                    onSelected: (_) {
                      setState(() {
                        filtroEstado = 'todos';
                      });
                    },
                  ),

                  const SizedBox(width: 8),

                  FilterChip(
                    label: const Text('Pendientes'),
                    selected: filtroEstado == 'pendiente',
                    onSelected: (_) {
                      setState(() {
                        filtroEstado = 'pendiente';
                      });
                    },
                  ),

                  const SizedBox(width: 8),

                  FilterChip(
                    label: const Text('Entregadas'),
                    selected: filtroEstado == 'entregado',
                    onSelected: (_) {
                      setState(() {
                        filtroEstado = 'entregado';
                      });
                    },
                  ),

                  const SizedBox(width: 8),

                  FilterChip(
                    label: const Text('Canceladas'),
                    selected: filtroEstado == 'cancelado',
                    onSelected: (_) {
                      setState(() {
                        filtroEstado = 'cancelado';
                      });
                    },
                  ),

                  const SizedBox(width: 8),

                  FilterChip(
                    label: const Text('Vencidas'),
                    selected: filtroEstado == 'vencido',
                    onSelected: (_) {
                      setState(() {
                        filtroEstado = 'vencido';
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: ListView.builder(
                itemCount: reservasFiltradas.length,
                itemBuilder: (context, index) {
                  final reserva = reservasFiltradas[index];

                  return Card(
                    color: AppColors.blanco,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.borde),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: estadoColor(reserva['estado']),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        reserva['codigo'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reserva['usuarios']?['nombre'] ?? 'Usuario'),
                          Text(
                            reserva['usuarios']?['email'] ?? '',
                            style: const TextStyle(
                              color: AppColors.textoSecundario,
                            ),
                          ),
                          Text(reserva['telefono']?.toString() ?? ''),
                          Text(
                            'Estado: ${reserva['estado']}',
                            style: const TextStyle(
                              color: AppColors.textoSecundario,
                            ),
                          ),
                          Text(
                            'Total: \$${reserva['total']}',
                            style: const TextStyle(
                              color: AppColors.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        codigoController.text = reserva['codigo'];

                        buscarReserva();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
