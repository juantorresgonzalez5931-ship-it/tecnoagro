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
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        title: const Text('Panel de administración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: cargarEstadisticas),
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
                Text(i[1] as String,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(i[0] as String,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _titulo(String t) => Text(t,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));

  Widget _seccionPedidosPorEstado() {
    final estados = Map<String, dynamic>.from(stats!['pedidos_por_estado']);
    final total = estados.values.fold<int>(0, (a, b) => a + (b as int));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Pedidos por estado'),
        const SizedBox(height: 8),
        if (estados.isEmpty) const Text('Aún no hay pedidos'),
        ...estados.entries.map((e) => Padding(
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
            )),
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
        ...lista.asMap().entries.map((e) => ListTile(
              dense: true,
              leading: CircleAvatar(child: Text('${e.key + 1}')),
              title: Text(e.value['nombre'] ?? ''),
              subtitle: Text('${e.value['unidades']} unidades'),
              trailing: Text(_moneda(e.value['ingresos'])),
            )),
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
        ...lista.map((p) => ListTile(
              dense: true,
              leading: const Icon(Icons.warning_amber, color: Colors.red),
              title: Text(p['nombre'] ?? ''),
              trailing: Text('${p['stock']} uds',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            )),
      ],
    );
  }

  Widget _seccionUltimosPedidos() {
    final lista = List<Map<String, dynamic>>.from(stats!['ultimos_pedidos']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Últimos pedidos'),
        if (lista.isEmpty) const Text('Sin pedidos'),
        ...lista.map((p) => ListTile(
              dense: true,
              leading: const Icon(Icons.receipt),
              title: Text(p['usuario']?['nombre'] ?? 'Cliente'),
              subtitle: Text('${p['estado'] ?? 'pendiente'}'),
              trailing: Text(_moneda(p['total'])),
            )),
      ],
    );
  }
}
