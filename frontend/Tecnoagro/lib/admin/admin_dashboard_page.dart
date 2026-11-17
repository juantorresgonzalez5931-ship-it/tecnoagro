import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/service/services/api_config.dart';
import 'package:http/http.dart' as http;
import '../core/colores.dart';

class AdminDashboardPage extends StatefulWidget {
  final String token;
  const AdminDashboardPage({super.key, required this.token});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? stats;
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarEstadisticas();
  }

  Future<void> cargarEstadisticas() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/admin/estadisticas'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (res.statusCode == 200) {
        stats = jsonDecode(res.body);
      } else {
        debugPrint('Estadísticas: ${res.statusCode} ${res.body}');
        error = 'Error ${res.statusCode}';
      }
    } catch (e) {
      debugPrint('Error estadísticas: $e');
      error = 'No se pudo conectar con el servidor';
    }
    if (mounted) setState(() => cargando = false);
  }

  String _moneda(dynamic v) =>
      '\$${(num.tryParse('$v') ?? 0).toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        backgroundColor: AppColors.fondoCrema,
        appBar: AppBar(
          title: const Text('Panel de administración'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: cargarEstadisticas,
            ),
          ],
        ),
        body: cargando
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: Text(error!))
            : RefreshIndicator(
                onRefresh: cargarEstadisticas,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _tarjetasResumen(),
                    const SizedBox(height: 20),
                    _seccionPedidosPorEstado(),
                    const SizedBox(height: 20),
                    _seccionTopProductos(),
                    const SizedBox(height: 20),
                    _seccionStockBajo(),
                    const SizedBox(height: 20),
                    _seccionUltimosPedidos(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _tarjetasResumen() {
    final r = stats!['resumen'];
    final items = [
      ['Ventas del mes', _moneda(r['ventas_mes']), Icons.attach_money],
      ['Ventas totales', _moneda(r['ventas_totales']), Icons.bar_chart],
      ['Pedidos', '${r['total_pedidos']}', Icons.receipt_long],
      ['Productos', '${r['total_productos']}', Icons.inventory_2],
      ['Usuarios', '${r['total_usuarios']}', Icons.people],
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.map((i) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(i[2] as IconData, color: AppColors.verdePrimario),
                const SizedBox(height: 6),
                Text(
                  i[1] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  i[0] as String,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _titulo(String t) => Text(
    t,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );

  Widget _seccionPedidosPorEstado() {
    final estados = Map<String, dynamic>.from(stats!['pedidos_por_estado']);
    final total = estados.values.fold<int>(0, (a, b) => a + (b as int));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Pedidos por estado'),
        const SizedBox(height: 8),
        if (estados.isEmpty) const Text('Aún no hay pedidos'),
        ...estados.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.key}: ${e.value}'),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : (e.value as int) / total,
                  minHeight: 8,
                  color: AppColors.verdePrimario,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _seccionTopProductos() {
    final lista = List<Map<String, dynamic>>.from(stats!['top_productos']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Productos más vendidos'),
        if (lista.isEmpty) const Text('Sin ventas registradas'),
        ...lista.asMap().entries.map(
          (e) => ListTile(
            dense: true,
            leading: CircleAvatar(child: Text('${e.key + 1}')),
            title: Text(e.value['nombre'] ?? ''),
            subtitle: Text('${e.value['unidades']} unidades'),
            trailing: Text(_moneda(e.value['ingresos'])),
          ),
        ),
      ],
    );
  }

  Widget _seccionStockBajo() {
    final lista = List<Map<String, dynamic>>.from(stats!['stock_bajo']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Stock bajo'),
        if (lista.isEmpty) const Text('Todo el inventario está bien'),
        ...lista.map(
          (p) => ListTile(
            dense: true,
            leading: const Icon(Icons.warning_amber, color: Colors.red),
            title: Text(p['nombre'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${p['stock']} uds',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 50),
                IconButton(
                  tooltip: 'Agregar stock',
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.verdePrimario,
                  ),
                  onPressed: () => _dialogoAgregarStock(p),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _dialogoAgregarStock(Map<String, dynamic> p) async {
    final controller = TextEditingController();
    final cantidad = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Agregar stock\n${p['nombre'] ?? ''}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Cantidad a agregar'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (cantidad == null || cantidad <= 0) return;

    final actual = int.tryParse('${p['stock']}') ?? 0;
    final ok = await _actualizarStock(p['id'], actual + cantidad);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Stock actualizado: ${p['nombre']}'
              : 'No se pudo actualizar el stock',
        ),
      ),
    );
    if (ok) cargarEstadisticas();
  }

  Future<bool> _actualizarStock(dynamic id, int nuevoStock) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}/productos/$id'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'stock': nuevoStock}),
      );
      if (res.statusCode != 200) {
        debugPrint('Actualizar stock: ${res.statusCode} ${res.body}');
      }
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error actualizar stock: $e');
      return false;
    }
  }

  Widget _seccionUltimosPedidos() {
    final lista = List<Map<String, dynamic>>.from(stats!['ultimos_pedidos']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Últimos pedidos'),
        if (lista.isEmpty) const Text('Sin pedidos'),
        ...lista.map(
          (p) => ListTile(
            dense: true,
            leading: const Icon(Icons.receipt),
            title: Text(p['usuario']?['nombre'] ?? 'Cliente'),
            subtitle: Text('${p['estado'] ?? 'pendiente'}'),
            trailing: Text(_moneda(p['total'])),
          ),
        ),
      ],
    );
  }
}
