import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Un producto dentro del carrito, con la cantidad que el usuario quiere.
class CarritoItem {
  final String id;
  final String nombre;
  final String categoria;
  final num precio;
  final String? imagen; // URL de la foto
  int cantidad;

  CarritoItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    this.imagen,
    this.cantidad = 1,
  });

  num get subtotal => precio * cantidad;
}

/// Carrito de compras compartido por toda la app.
/// Se usa así: CarritoService.instancia.agregar(...)
/// Las pantallas se actualizan solas con ListenableBuilder.
/// Por ahora vive en memoria: se vacía al cerrar la app.
///
/// Para dar formato al precio usa formatearPrecio de widgets/producto_tile.dart.
class CarritoService extends ChangeNotifier {
  CarritoService._();
  static final CarritoService instancia = CarritoService._();

  static const int _maxPorProducto = 99;

  final List<CarritoItem> _items = [];

  List<CarritoItem> get items => List.unmodifiable(_items);
  bool get vacio => _items.isEmpty;

  /// Suma de todas las unidades (es el número que sale sobre el icono).
  int get cantidadTotal => _items.fold(0, (suma, i) => suma + i.cantidad);

  num get total => _items.fold<num>(0, (suma, i) => suma + i.subtotal);

  /// Agrega el producto con la cantidad indicada en [nuevo].
  /// Si ya estaba en el carrito, le suma esa cantidad.
  void agregar(CarritoItem nuevo) {
    final i = _items.indexWhere((e) => e.id == nuevo.id);
    if (i == -1) {
      nuevo.cantidad = math.min(math.max(nuevo.cantidad, 1), _maxPorProducto);
      _items.add(nuevo);
    } else {
      _items[i].cantidad = math.min(_items[i].cantidad + nuevo.cantidad, _maxPorProducto);
    }
    notifyListeners();
  }

  void aumentar(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1 || _items[i].cantidad >= _maxPorProducto) return;
    _items[i].cantidad++;
    notifyListeners();
  }

  /// Baja una unidad, pero nunca por debajo de 1 (para quitarlo se usa [quitar]).
  void disminuir(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1 || _items[i].cantidad <= 1) return;
    _items[i].cantidad--;
    notifyListeners();
  }

  void quitar(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void vaciar() {
    _items.clear();
    notifyListeners();
  }
}