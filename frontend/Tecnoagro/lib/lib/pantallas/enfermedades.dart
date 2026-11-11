import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/core/navegacion.dart';
import 'package:frontend/models/enfermedad_model.dart';
import 'package:frontend/pantallas/detalle_enfermedad.dart';
import 'package:frontend/pantallas/formulario_enfermedad.dart';
import 'package:frontend/service/services/enfermedad_service.dart';
import 'package:frontend/service/services/sesion_service.dart';
import 'package:frontend/widgets/barra_navegacion.dart';
import 'package:frontend/widgets/cabecera_pantalla.dart';

/// Acciones de la barra inferior dentro de Enfermedades y su detalle.
void navegarDesdeEnfermedades(BuildContext context, int i) {
  if (i == 1) {
    abrirCatalogo(context);
  } else {
    navegarDesdeCatalogo(context, i);
  }
}

class EnfermedadesScreen extends StatefulWidget {
  /// En el panel de admin se pasa false: la barra inferior la pone el panel.
  final bool mostrarBarra;
  const EnfermedadesScreen({super.key, this.mostrarBarra = true});

  @override
  State<EnfermedadesScreen> createState() => _EnfermedadesScreenState();
}

class _EnfermedadesScreenState extends State<EnfermedadesScreen> {
  final _servicio = EnfermedadService();
  final _busquedaCtrl = TextEditingController();
  List<EnfermedadModel> _todas = [];
  bool _cargando = true;
  bool _esAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final admin = await SesionService.esAdmin();
      final lista = await _servicio.listar();
      if (!mounted) return;
      setState(() {
        _esAdmin = admin;
        _todas = lista;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    if (mounted) setState(() => _cargando = false);
  }

  List<EnfermedadModel> get _filtradas {
    final q = _busquedaCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _todas;
    return _todas
        .where((e) =>
            e.nombre.toLowerCase().contains(q) ||
            e.descripcion.toLowerCase().contains(q) ||
            e.sintomas.toLowerCase().contains(q) ||
            e.cultivos.toLowerCase().contains(q))
        .toList();
  }

  void _aviso(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _abrirFormulario([EnfermedadModel? e]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormularioEnfermedadScreen(enfermedadId: e?.id)),
    );
    if (guardado == true) {
      _aviso(e == null ? 'Enfermedad creada' : 'Enfermedad actualizada');
      _cargar();
    }
  }

  Future<void> _eliminar(EnfermedadModel e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar enfermedad'),
        content: Text('¿Seguro que quieres eliminar "${e.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _servicio.eliminar(e.id);
      if (!mounted) return;
      setState(() => _todas.removeWhere((x) => x.id == e.id));
      _aviso('Enfermedad eliminada');
    } catch (_) {
      _aviso('No se pudo eliminar la enfermedad', error: true);
    }
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
    final lista = _filtradas;
    if (lista.isEmpty) {
      return Center(
        child: Text(_todas.isEmpty ? 'Aún no hay enfermedades' : 'Sin resultados',
            style: TextStyle(color: AppColors.textoSecundario)),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 4, 16, _esAdmin ? 90 : 16),
        itemCount: lista.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _TarjetaEnfermedad(
          enfermedad: lista[i],
          esAdmin: _esAdmin,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetalleEnfermedadScreen(enfermedadId: lista[i].id)),
          ),
          onEditar: () => _abrirFormulario(lista[i]),
          onEliminar: () => _eliminar(lista[i]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      floatingActionButton: _esAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              backgroundColor: AppColors.verdePrimario,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nueva enfermedad'),
            )
          : null,
      body: SafeArea(
        child: Column(children: [
          const CabeceraPantalla(titulo: 'Enfermedades'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _busquedaCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '¿Cuál es el cultivo a tratar?',
                hintStyle: TextStyle(color: AppColors.textoSecundario, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.textoSecundario),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.borde),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.borde),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.verdePrimario),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Enfermedades comunes',
                  style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(child: _cuerpo()),
        ]),
      ),
      bottomNavigationBar: widget.mostrarBarra
          ? BarraNavegacion(actual: 0, onTap: (i) => navegarDesdeEnfermedades(context, i))
          : null,
    );
  }
}

class _TarjetaEnfermedad extends StatelessWidget {
  final EnfermedadModel enfermedad;
  final bool esAdmin;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaEnfermedad({
    required this.enfermedad,
    required this.esAdmin,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final vacio = Container(
      color: const Color(0xFFE8EFE6),
      child: Icon(Icons.eco_outlined, color: AppColors.verdePrimario, size: 28),
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 62,
                height: 62,
                child: enfermedad.imagenUrl == null
                    ? vacio
                    : Image.network(enfermedad.imagenUrl!,
                        fit: BoxFit.cover, errorBuilder: (_, _, _) => vacio),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(enfermedad.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textoPrincipal, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(enfermedad.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
              ]),
            ),
            if (esAdmin)
              PopupMenuButton<String>(
                onSelected: (v) => v == 'editar' ? onEditar() : onEliminar(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
              ),
          ]),
        ),
      ),
    );
  }
}