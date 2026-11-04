import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/core/navegacion.dart';
import 'package:frontend/service/services/notificacion_service.dart';
import 'package:frontend/widgets/cabecera_pantalla.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final _servicio = NotificacionService();
  List<NotificacionModel> _lista = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _servicio.listar();
      if (mounted) setState(() => _lista = r.lista);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    if (mounted) setState(() => _cargando = false);
  }

  bool get _hayNoLeidas => _lista.any((n) => !n.leida);

  Future<void> _marcarTodas() async {
    try {
      await _servicio.marcarTodasLeidas();
      if (mounted) setState(() => [for (final n in _lista) n.leida = true]);
    } catch (_) {}
  }

  Future<void> _tocar(NotificacionModel n) async {
    if (!n.leida) {
      setState(() => n.leida = true);
      try {
        await _servicio.marcarLeida(n.id);
      } catch (_) {}
    }
    if (!mounted) return;
    if (n.tipo == 'producto') {
      await abrirCatalogo(context);
    }
  }

  String _hace(DateTime? f) {
    if (f == null) return '';
    final d = DateTime.now().difference(f);
    if (d.inMinutes < 1) return 'Ahora';
    if (d.inMinutes < 60) return 'Hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'Hace ${d.inHours} h';
    return 'Hace ${d.inDays} d';
  }

  IconData _icono(String tipo) =>
      tipo == 'reserva' ? Icons.check_circle_outline : Icons.inventory_2_outlined;

  Widget _tarjeta(NotificacionModel n) {
    return Material(
      color: n.leida ? Colors.white : const Color(0xFFE6F2E6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _tocar(n),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(_icono(n.tipo), color: AppColors.verdePrimario),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(n.titulo,
                        style: TextStyle(
                          color: AppColors.textoPrincipal,
                          fontSize: 15,
                          fontWeight: n.leida ? FontWeight.w600 : FontWeight.bold,
                        )),
                  ),
                  if (!n.leida)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: AppColors.verdePrimario, shape: BoxShape.circle),
                    ),
                ]),
                const SizedBox(height: 3),
                Text(n.mensaje,
                    style: TextStyle(color: AppColors.textoPrincipal, fontSize: 13.5, height: 1.3)),
                const SizedBox(height: 6),
                Text(_hace(n.creadoEn), style: TextStyle(color: AppColors.textoSecundario, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
        ]),
      );
    }
    if (_lista.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(children: [
          const SizedBox(height: 120),
          Icon(Icons.notifications_none, size: 56, color: AppColors.textoSecundario),
          const SizedBox(height: 12),
          Center(
            child: Text('Aún no tienes notificaciones', style: TextStyle(color: AppColors.textoSecundario)),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: _lista.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _tarjeta(_lista[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: Column(children: [
          const CabeceraPantalla(titulo: 'Notificaciones'),
          if (_hayNoLeidas)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _marcarTodas,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Marcar todas como leídas'),
                ),
              ),
            ),
          Expanded(child: _cuerpo()),
        ]),
      ),
    );
  }
}