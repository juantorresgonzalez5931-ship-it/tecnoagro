import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/models/producto_models.dart';
import 'package:frontend/pantallas/login.dart';
import 'package:frontend/widgets/banner_producto.dart';
import 'package:frontend/service/services/producto_service.dart';
import 'package:frontend/widgets/perfil_sheet.dart';
import 'package:frontend/widgets/producto_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _verdeSuave = Color(0xFFE6F2E6);
  String? _nombre; // null = no ha iniciado sesión
  final _productoService = ProductoService();
  List<ProductoModels> _productos = []; // el más nuevo va primero
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNombre();
    _cargarProductos();
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
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  TextStyle _estilo(double size, {Color? color, FontWeight peso = FontWeight.bold}) =>
      TextStyle(color: color ?? AppColors.textoPrincipal, fontSize: size, fontWeight: peso);

  BoxDecoration get _tarjeta => BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borde));

  Future<void> _cargarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = (prefs.getString('user_name') ?? '').trim();
    if (!mounted || (prefs.getString('jwt_token') ?? '').isEmpty || nombre.isEmpty) return;
    setState(() => _nombre = nombre.split(' ').first);
  }

  /// Mi Perfil: sin sesión abre el login; con sesión muestra el perfil.
  Future<void> _abrirPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if ((prefs.getString('jwt_token') ?? '').isEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    mostrarPerfil(context, prefs.getString('user_name') ?? 'Usuario', () async {
      await prefs.remove('jwt_token');
      await prefs.remove('user_name');
      if (mounted) setState(() => _nombre = null);
    });
  }

  void _proximamente(String seccion) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$seccion estará disponible pronto'),
        backgroundColor: AppColors.verdePrimario,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Widget _circulo(IconData icono, VoidCallback onTap) => Material(
        color: Colors.white,
        shape: CircleBorder(side: BorderSide(color: AppColors.borde)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icono, color: AppColors.textoPrincipal, size: 22)),
        ),
      );

  Widget _titulo(String texto) => Text(texto, style: _estilo(18));

  Widget _canal(IconData icono, String texto) => Expanded(
        child: Container(
          decoration: _tarjeta,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _proximamente(texto),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
              child: Column(children: [
                CircleAvatar(
                    radius: 25, backgroundColor: _verdeSuave, child: Icon(icono, color: AppColors.verdePrimario)),
                const SizedBox(height: 12),
                Text(texto, textAlign: TextAlign.center, style: _estilo(13)),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (Icons.home_outlined, Icons.home, 'Inicio'),
      (Icons.shopping_bag_outlined, Icons.shopping_bag, 'Productos'),
      (Icons.chat_bubble_outline, Icons.chat_bubble, 'Asesor IA'),
      (Icons.person_outline, Icons.person, 'Mi Perfil'),
    ];
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              _circulo(Icons.search, () => _proximamente('La búsqueda')),
              Expanded(
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Image.asset('assets/images/logo-tecnoagro.png', width: 40, height: 40),
                  const SizedBox(width: 10),
                  Text('TecnoAgro', style: _estilo(22, color: AppColors.verdeOscuro)),
                ]),
              ),
              _circulo(Icons.notifications_none, () => _proximamente('Las notificaciones')),
            ]),
            const SizedBox(height: 24),
            Text(_nombre == null ? 'Hola 👋' : 'Hola, $_nombre 👋', style: _estilo(26)),
            Text('¿Qué necesitas hoy?',
                style: _estilo(16, color: AppColors.textoSecundario, peso: FontWeight.normal)),
            const SizedBox(height: 20),
            BannerNuevoProducto(producto: _productos.isEmpty ? null : _productos.first),
            const SizedBox(height: 26),
            _titulo('Nuestros Canales'),
            const SizedBox(height: 14),
            Row(children: [
              _canal(Icons.shopping_bag_outlined, 'Productos'),
              const SizedBox(width: 12),
              _canal(Icons.eco_outlined, 'Enfermedades'),
              const SizedBox(width: 12),
              _canal(Icons.chat_bubble_outline, 'ChatBot IA'),
            ]),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _titulo('Más Buscados'),
              GestureDetector(
                onTap: () => _proximamente('El catálogo'),
                child: Text('Ver todo', style: _estilo(13, color: AppColors.verdeTexto)),
              ),
            ]),
            const SizedBox(height: 14),
            if (_cargando)
              Center(child: CircularProgressIndicator(color: AppColors.verdePrimario))
            else if (_error != null)
              TextButton(onPressed: _cargarProductos, child: Text('$_error. Toca para reintentar'))
            else if (_productos.isEmpty)
              Text('Aún no hay productos', style: _estilo(14, color: AppColors.textoSecundario))
            else
              for (final p in _productos.take(3)) ProductoTile(producto: p),
          ]),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.borde))),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.verdePrimario,
          unselectedItemColor: AppColors.textoSecundario,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (i) => i == 3 ? _abrirPerfil() : (i == 0 ? null : _proximamente(tabs[i].$3)),
          items: [for (final t in tabs) BottomNavigationBarItem(icon: Icon(t.$1), activeIcon: Icon(t.$2), label: t.$3)],
        ),
      ),
    );
  }
}