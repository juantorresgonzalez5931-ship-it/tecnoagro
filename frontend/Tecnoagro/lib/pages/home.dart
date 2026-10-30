import 'package:flutter/material.dart';
import 'package:frontend/Ia_screeen/asesor_ia_screen.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/producto_models.dart';
import 'package:frontend/pantallas/login.dart';
import 'package:frontend/admin/productos_screen.dart';
import 'package:frontend/service/services/carrito_service.dart';
import 'package:frontend/widgets/banner_producto.dart';
import 'package:frontend/widgets/barra_navegacion.dart';
import 'package:frontend/service/services/producto_service.dart';
import 'package:frontend/widgets/burbuja_ia.dart';
import 'package:frontend/widgets/perfil_sheet.dart';
import 'package:frontend/widgets/producto_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/navegacion.dart';
import 'package:frontend/pantallas/enfermedades.dart';
import 'package:frontend/pantallas/busqueda.dart';
import 'package:frontend/pantallas/notificaciones_screen.dart';
import 'package:frontend/service/services/notificacion_service.dart';
import 'package:frontend/pantallas/bienvenido.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _verdeSuave = Color(0xFFE6F2E6);
  String? _nombre; // null = no ha iniciado sesión
  final _productoService = ProductoService();
  final _notificacionService = NotificacionService();
  int _noLeidas = 0;
  List<ProductoModels> _productos = []; // el más nuevo va primero
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNombre();
    _cargarProductos();
    _cargarNotificaciones();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _productoService.listarProductos();
      if (mounted) setState(() => _productos = lista);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarNotificaciones() async {
    try {
      final cantidad = await _notificacionService.obtenerCantidadNoLeidas();

      if (!mounted) return;

      setState(() {
        _noLeidas = cantidad;
      });
    } catch (_) {}
  }

  TextStyle _estilo(
    double size, {
    Color? color,
    FontWeight peso = FontWeight.bold,
  }) => TextStyle(
    color: color ?? AppColors.textoPrincipal,
    fontSize: size,
    fontWeight: peso,
  );

  BoxDecoration get _tarjeta => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.borde),
  );

  Future<void> _cargarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = (prefs.getString('user_name') ?? '').trim();
    if (!mounted) return;
    final conSesion =
        (prefs.getString('jwt_token') ?? '').isNotEmpty && nombre.isNotEmpty;
    setState(() => _nombre = conSesion ? nombre.split(' ').first : null);
    // Al cambiar de sesión, refresca también el contador de notificaciones
    _cargarNotificaciones();
  }

  /// Mi Perfil: sin sesión abre el login; con sesión muestra el perfil.
  Future<void> _abrirPerfil() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    if ((prefs.getString('jwt_token') ?? '').isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    mostrarPerfil(context, prefs.getString('user_name') ?? 'Usuario', () async {
      await prefs.remove('jwt_token');
      await prefs.remove('user_name');
      await prefs.remove('user_rol');
      await prefs.remove('user_id');

      CarritoService.instancia.vaciar();

      if (mounted) {
        setState(() {
          _nombre = null;
          _noLeidas = 0;
        });
      }

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BienvenidoScreen()),
        (route) => false,
      );
    });
  }

  /// Abre la lista de productos (con botón "Crear producto" si es admin).
  /// Al volver, recarga el banner y "Más Buscados".
  Future<void> _irAProductos() async {
    await abrirCatalogo(context);
    if (!mounted) return;
    _cargarNombre();
    _cargarProductos();
  }

  Future<void> _irAChatBotIA() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AsesorIAScreen()),
    );
    if (!mounted) return;
    _cargarNombre();
  }

  Future<void> _irAEnfermedades() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EnfermedadesScreen()),
    );
    if (!mounted) return;
    _cargarNombre();
  }

  void _proximamente(String seccion) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$seccion estará disponible pronto'),
          backgroundColor: AppColors.verdePrimario,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _circulo(IconData icono, VoidCallback onTap) => Material(
    color: Colors.white,
    shape: CircleBorder(side: BorderSide(color: AppColors.borde)),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icono, color: AppColors.textoPrincipal, size: 22),
      ),
    ),
  );

  Widget _titulo(String texto) => Text(texto, style: _estilo(18));

  Widget _canal(IconData icono, String texto, [VoidCallback? onTap]) =>
      Expanded(
        child: Container(
          decoration: _tarjeta,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap ?? () => _proximamente(texto),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _verdeSuave,
                    child: Icon(icono, color: AppColors.verdePrimario),
                  ),
                  const SizedBox(height: 12),
                  Text(texto, textAlign: TextAlign.center, style: _estilo(13)),
                ],
              ),
            ),
          ),
        ),
      );

  /// Campana de notificaciones con el contador de no leídas.
  Widget _campanaNotificaciones() => Stack(
    clipBehavior: Clip.none,
    children: [
      _circulo(Icons.notifications_none, () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
        );

        _cargarNotificaciones();
      }),
      if (_noLeidas > 0)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _noLeidas > 99 ? '99+' : _noLeidas.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
    ],
  );

  /// Barra superior fija: buscar, logo y notificaciones. No se mueve con el scroll.
  Widget _barraSuperior() => Container(
    color: AppColors.fondoCrema,
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
    child: Row(
      children: [
        _circulo(
          Icons.search,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BusquedaScreen()),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo-tecnoagro.png',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 10),
              Text(
                'TecnoAgro',
                style: _estilo(22, color: AppColors.verdeOscuro),
              ),
            ],
          ),
        ),
        _campanaNotificaciones(),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const BurbujaIA(),
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: Column(
          children: [
            _barraSuperior(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _nombre == null ? 'Hola 👋' : 'Hola, $_nombre 👋',
                      style: _estilo(26),
                    ),
                    Text(
                      '¿Qué necesitas hoy?',
                      style: _estilo(
                        16,
                        color: AppColors.textoSecundario,
                        peso: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    BannerNuevoProducto(
                      producto: _productos.isEmpty ? null : _productos.first,
                    ),
                    const SizedBox(height: 26),
                    _titulo('Explora TecnoAgro'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _canal(
                          Icons.shopping_bag_outlined,
                          'Productos',
                          _irAProductos,
                        ),
                        const SizedBox(width: 12),
                        _canal(
                          Icons.eco_outlined,
                          'Enfermedades',
                          _irAEnfermedades,
                        ),
                        const SizedBox(width: 12),
                        _canal(
                          Icons.chat_bubble_outline,
                          'Asesor Inteligente',
                          _irAChatBotIA,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _titulo('Más Buscados'),
                        GestureDetector(
                          onTap: _irAProductos,
                          child: Text(
                            'Ver todo',
                            style: _estilo(13, color: AppColors.verdeTexto),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_cargando)
                      Center(
                        child: CircularProgressIndicator(
                          color: AppColors.verdePrimario,
                        ),
                      )
                    else if (_error != null)
                      TextButton(
                        onPressed: _cargarProductos,
                        child: Text('$_error. Toca para reintentar'),
                      )
                    else if (_productos.isEmpty)
                      Text(
                        'Aún no hay productos',
                        style: _estilo(14, color: AppColors.textoSecundario),
                      )
                    else
                      for (final p in _productos.take(3))
                        ProductoTile(producto: p),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraNavegacion(
        actual: 0,
        onTap: (i) {
          if (i == 1) {
            _irAProductos();
          } else if (i == 2) {
            abrirCarrito(context);
          } else if (i == 3) {
            _abrirPerfil();
          }
        },
      ),
    );
  }
}