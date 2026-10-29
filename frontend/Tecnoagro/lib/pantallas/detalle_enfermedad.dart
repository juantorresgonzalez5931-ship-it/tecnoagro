import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/enfermedad_model.dart';
import 'package:frontend/pantallas/enfermedades.dart' show navegarDesdeEnfermedades;
import 'package:frontend/service/services/enfermedad_service.dart';
import 'package:frontend/widgets/barra_navegacion.dart';
import 'package:frontend/widgets/cabecera_pantalla.dart';
import 'package:frontend/widgets/producto_tile.dart' show formatearPrecio;

class DetalleEnfermedadScreen extends StatefulWidget {
  final int enfermedadId;
  const DetalleEnfermedadScreen({super.key, required this.enfermedadId});

  @override
  State<DetalleEnfermedadScreen> createState() => _DetalleEnfermedadScreenState();
}

class _DetalleEnfermedadScreenState extends State<DetalleEnfermedadScreen> {
  EnfermedadModel? _enfermedad;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final e = await EnfermedadService().obtener(widget.enfermedadId);
      if (mounted) setState(() => _enfermedad = e);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Widget _cuerpo() {
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
        ]),
      );
    }
    final e = _enfermedad;
    if (e == null) return const Center(child: CircularProgressIndicator());

    final vacio = Container(
      color: const Color(0xFFE8EFE6),
      child: Icon(Icons.eco_outlined, color: AppColors.verdePrimario, size: 56),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 190,
            width: double.infinity,
            child: e.imagenUrl == null
                ? vacio
                : Image.network(e.imagenUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => vacio),
          ),
        ),
        const SizedBox(height: 16),
        if (e.descripcion.isNotEmpty) ...[
          Text(e.descripcion, style: TextStyle(color: AppColors.textoSecundario, fontSize: 14, height: 1.4)),
          const SizedBox(height: 16),
        ],
        _ListaConCirculos(titulo: 'Cómo se ve', items: e.listaSintomas),
        _ListaConCirculos(titulo: 'Tratamiento', items: e.listaTratamiento),
        _CultivosChips(cultivos: e.listaCultivos),
        if (e.productos.isNotEmpty) ...[
          Text('Productos recomendados',
              style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (final p in e.productos) _TarjetaRecomendado(producto: p),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: Column(children: [
          CabeceraPantalla(titulo: _enfermedad?.nombre ?? 'Enfermedad'),
          Expanded(child: _cuerpo()),
        ]),
      ),
      bottomNavigationBar: BarraNavegacion(actual: 0, onTap: (i) => navegarDesdeEnfermedades(context, i)),
    );
  }
}

class _ListaConCirculos extends StatelessWidget {
  final String titulo;
  final List<String> items;
  const _ListaConCirculos({required this.titulo, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final t in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.circle_outlined, size: 16, color: AppColors.verdePrimario),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(t, style: TextStyle(color: AppColors.textoPrincipal, fontSize: 14, height: 1.3))),
            ]),
          ),
      ]),
    );
  }
}

class _TarjetaRecomendado extends StatelessWidget {
  final ProductoRecomendado producto;
  const _TarjetaRecomendado({required this.producto});

  @override
  Widget build(BuildContext context) {
    final vacio = Container(
      color: const Color(0xFFE8EFE6),
      child: Icon(Icons.inventory_2_outlined, color: AppColors.verdePrimario, size: 26),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 60,
            height: 60,
            child: producto.imagenUrl == null
                ? vacio
                : Image.network(producto.imagenUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => vacio),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(producto.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textoPrincipal, fontSize: 15, fontWeight: FontWeight.bold)),
            if ((producto.categoria ?? '').isNotEmpty)
              Text(producto.categoria!, style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
            const SizedBox(height: 2),
            Text(formatearPrecio(producto.precio),
                style: TextStyle(color: AppColors.verdeTexto, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }
}

class _CultivosChips extends StatelessWidget {
  final List<String> cultivos;
  const _CultivosChips({required this.cultivos});

  @override
  Widget build(BuildContext context) {
    if (cultivos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Para qué cultivos sirve',
            style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in cultivos)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2E6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.eco_outlined, size: 15, color: AppColors.verdePrimario),
                const SizedBox(width: 6),
                Text(c,
                    style: TextStyle(
                        color: AppColors.verdeTexto, fontSize: 13.5, fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
      ]),
    );
  }
}