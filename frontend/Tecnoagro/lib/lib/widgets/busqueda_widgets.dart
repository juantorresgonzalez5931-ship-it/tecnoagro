import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/widgets/producto_tile.dart' show formatearPrecio;

TextStyle estiloTexto(double t, Color c, {bool b = false}) =>
    TextStyle(fontSize: t, color: c, fontWeight: b ? FontWeight.bold : FontWeight.normal);

Widget tituloSeccion(String t) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 6), child: Text(t, style: estiloTexto(16, AppColors.textoPrincipal, b: true)));

class CampoBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final bool escuchando;
  final ValueChanged<String> onChanged, onSubmitted;
  final VoidCallback onLimpiar, onVoz;
  const CampoBusqueda({super.key, required this.controller, required this.escuchando, required this.onChanged,
      required this.onSubmitted, required this.onLimpiar, required this.onVoz});

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.borde));
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(children: [
        const BackButton(),
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: escuchando ? 'Escuchando…' : '¿Qué estás buscando?',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                if (controller.text.isNotEmpty) IconButton(icon: const Icon(Icons.close, size: 20), onPressed: onLimpiar),
                IconButton(
                  icon: Icon(escuchando ? Icons.mic : Icons.mic_none, color: escuchando ? Colors.red : AppColors.verdePrimario),
                  onPressed: onVoz,
                ),
              ]),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: borde,
              enabledBorder: borde,
            ),
          ),
        ),
      ]),
    );
  }
}

class BusquedaInicio extends StatelessWidget {
  final List<String> recientes, sugerencias;
  final ValueChanged<String> onElegir, onBorrar;
  const BusquedaInicio(
      {super.key, required this.recientes, required this.sugerencias, required this.onElegir, required this.onBorrar});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      if (recientes.isNotEmpty) ...[
        tituloSeccion('Búsquedas recientes'),
        for (final r in recientes)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: Text(r),
            trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => onBorrar(r)),
            onTap: () => onElegir(r),
          ),
      ],
      tituloSeccion('Sugerencias'),
      Wrap(spacing: 8, children: [for (final s in sugerencias) ActionChip(label: Text(s), onPressed: () => onElegir(s))]),
    ]);
  }
}

class BusquedaVacia extends StatelessWidget {
  final String consulta;
  final VoidCallback onAsesor;
  const BusquedaVacia({super.key, required this.consulta, required this.onAsesor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(children: [
        Opacity(opacity: .5, child: Image.asset('assets/images/logo-tecnoagro.png', width: 90, height: 90)),
        const SizedBox(height: 12),
        Text('No encontramos resultados para "$consulta"',
            textAlign: TextAlign.center, style: estiloTexto(16, AppColors.textoPrincipal, b: true)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAsesor,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Preguntar al Asesor Inteligente'),
          ),
        ),
      ]),
    );
  }
}

class FilaResultado extends StatelessWidget {
  final String titulo;
  final String? sub, extra, url;
  final IconData icono;
  final BoxFit ajuste;
  final VoidCallback onTap;
  const FilaResultado(this.titulo, this.sub, this.extra, this.url, this.icono, this.ajuste, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    final vacio = Container(color: const Color(0xFFE8EFE6), child: Icon(icono, color: AppColors.verdePrimario));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borde)),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: (url ?? '').isEmpty ? vacio : Image.network(url!, fit: ajuste, errorBuilder: (_, _, _) => vacio),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: estiloTexto(15, AppColors.textoPrincipal, b: true)),
                  if ((sub ?? '').isNotEmpty)
                    Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: estiloTexto(12.5, AppColors.textoSecundario)),
                  if (extra != null)
                    Text(extra!, maxLines: 1, overflow: TextOverflow.ellipsis, style: estiloTexto(13, AppColors.verdeTexto, b: true)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

typedef FiltrosProductos = ({String? categoria, RangeValues? rango});

/// Hoja de filtros (categoría y precio). Devuelve null si se cierra sin aplicar.
Future<FiltrosProductos?> mostrarFiltros(
    BuildContext context, List<String> categorias, double min, double max, FiltrosProductos actual) async {
  var cat = actual.categoria;
  var rango = actual.rango ?? RangeValues(min, max);
  final ok = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.fondoCrema,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Filtrar productos', style: estiloTexto(18, AppColors.textoPrincipal, b: true)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final c in [null, ...categorias])
              ChoiceChip(label: Text(c ?? 'Todas'), selected: cat == c, onSelected: (_) => set(() => cat = c)),
          ]),
          if (max > min) ...[
            const SizedBox(height: 12),
            Text('Precio: ${formatearPrecio(rango.start)} - ${formatearPrecio(rango.end)}'),
            RangeSlider(values: rango, min: min, max: max, onChanged: (v) => set(() => rango = v)),
          ],
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => set(() {
                  cat = null;
                  rango = RangeValues(min, max);
                }),
                child: const Text('Limpiar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aplicar'))),
          ]),
        ]),
      ),
    ),
  );
  if (ok != true) return null;
  return (categoria: cat, rango: rango.start <= min && rango.end >= max ? null : rango);
}