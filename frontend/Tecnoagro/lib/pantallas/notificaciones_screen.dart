import 'package:flutter/material.dart';

import '../models/notificacion_model.dart';
import '../service/services/notificacion_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() =>
      _NotificacionesScreenState();
}

class _NotificacionesScreenState
    extends State<NotificacionesScreen> {
  final _service = NotificacionService();

  List<NotificacionModel> _notificaciones = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista =
          await _service.obtenerNotificaciones();

      if (!mounted) return;

      setState(() {
        _notificaciones = lista;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _abrir(
    NotificacionModel n,
  ) async {
    if (!n.leida) {
      await _service.marcarLeida(n.id);
    }

    if (!mounted) return;

    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount:
                  _notificaciones.length,
              itemBuilder: (context, index) {
                final n =
                    _notificaciones[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        n.leida
                            ? Colors.grey
                            : Colors.green,
                    child: Icon(
                      n.tipo == 'producto'
                          ? Icons.inventory_2
                          : Icons.receipt_long,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    n.titulo,
                  ),
                  subtitle: Text(
                    n.mensaje,
                  ),
                  trailing:
                      !n.leida
                          ? const Icon(
                              Icons.circle,
                              size: 12,
                              color:
                                  Colors.red,
                            )
                          : null,
                  onTap: () => _abrir(n),
                );
              },
            ),
    );
  }
}