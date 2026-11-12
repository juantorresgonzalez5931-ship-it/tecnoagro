import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/core/navegacion.dart';
import 'package:frontend/pantallas/login.dart';
import 'package:frontend/service/services/api_config.dart';
import 'package:frontend/service/services/carrito_service.dart';

String get _chatUrl => '${ApiConfig.apiBaseUrl}/chat/mensaje';

String _dinero(dynamic valor) {
  final n = (num.tryParse('$valor') ?? 0).round();
  return '\$${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';
}

class _Mensaje {
  final String texto;
  final bool esUsuario;
  final bool verCatalogo; // true = debajo se muestra el botón "Ver productos"
  final List<Map<String, dynamic>> productos; // recomendados: botón "Añadir al carrito"
  _Mensaje(this.texto, this.esUsuario, {this.verCatalogo = false, this.productos = const []});
}

class AsesorIAScreen extends StatefulWidget {
  const AsesorIAScreen({super.key});

  @override
  State<AsesorIAScreen> createState() => _AsesorIAScreenState();
}

class _AsesorIAScreenState extends State<AsesorIAScreen> {
  final _controlador = TextEditingController();
  final _scroll = ScrollController();
  final List<_Mensaje> _mensajes = [];
  String? _conversationId;
  bool _cargando = false;
  bool _cargandoSesion = true;
  int? _usuarioId; // null = sin sesión
  String _nombre = '';

  static const _sugerencias = [
    '¿Qué producto sirve para plagas?',
    '¿Cómo cuido mi cultivo en época de lluvia?',
  ];

  @override
  void initState() {
    super.initState();
    _cargarSesion();
  }

  @override
  void dispose() {
    _controlador.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Lee id y nombre desde el JWT guardado al iniciar sesión.
  Future<void> _cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    int? id;
    var nombre = '';
    if (token.isNotEmpty) {
      try {
        final payload = token.split('.')[1];
        final datos = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload))));
        final exp = datos['exp'];
        final vencido =
            exp is int && DateTime.fromMillisecondsSinceEpoch(exp * 1000).isBefore(DateTime.now());
        if (!vencido) {
          id = datos['id'] is int ? datos['id'] : int.tryParse('${datos['id']}');
          nombre = (datos['nombre'] ?? '').toString().split(' ').first;
        }
      } catch (_) {
        id = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _usuarioId = id;
      _nombre = nombre;
      _cargandoSesion = false;
    });
  }

  Future<void> _irAlLogin() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (!mounted) return;
    _cargarSesion();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _enviar([String? sugerencia]) async {
    final texto = (sugerencia ?? _controlador.text).trim();
    if (texto.isEmpty || _cargando || _usuarioId == null) return;

    _controlador.clear();
    setState(() {
      _mensajes.add(_Mensaje(texto, true));
      _cargando = true;
    });
    _bajar();

    try {
      final res = await http.post(
        Uri.parse(_chatUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'usuario_id': _usuarioId,
          'conversation_id': _conversationId,
          'mensaje': texto,
        }),
      );
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;

      if (res.statusCode == 200) {
        _conversationId = data['conversation_id'].toString();
        final productos = data['productos'] is List
            ? List<Map<String, dynamic>>.from(
                (data['productos'] as List).map((p) => Map<String, dynamic>.from(p as Map)))
            : <Map<String, dynamic>>[];
        setState(() => _mensajes.add(_Mensaje(
              data['respuesta'],
              false,
              verCatalogo: data['accion'] == 'ver_catalogo',
              productos: productos,
            )));
      } else {
        _mostrarError(data['error'] ?? 'No se pudo obtener respuesta');
      }
    } catch (_) {
      if (mounted) _mostrarError('Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _cargando = false);
      _bajar();
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red.shade700),
    );
  }

  // ───────────── Carrito ─────────────
  // Recibe el producto que recomendó la IA: { id, nombre, categoria, precio, stock, imagen_url }.
  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final id = '${producto['id']}';
    final stock = int.tryParse('${producto['stock']}') ?? 0;
    final carrito = CarritoService.instancia;
    final enCarrito = carrito.items.where((i) => i.id == id).firstOrNull?.cantidad ?? 0;

    if (enCarrito >= stock) {
      _avisoCarrito('Ya tienes todas las unidades disponibles de ${producto['nombre']}', error: true);
      return;
    }

    carrito.agregar(CarritoItem(
      id: id,
      nombre: '${producto['nombre']}',
      categoria: '${producto['categoria'] ?? ''}',
      precio: num.tryParse('${producto['precio']}') ?? 0,
      imagen: producto['imagen_url']?.toString(),
    ));
    _avisoCarrito(enCarrito == 0
        ? '${producto['nombre']} añadido al carrito'
        : 'Sumaste otra unidad de ${producto['nombre']}');
  }

  void _avisoCarrito(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        backgroundColor: error ? Colors.orange.shade800 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        action: error
            ? null
            : SnackBarAction(
                label: 'VER CARRITO',
                textColor: Colors.white,
                onPressed: () => abrirCarrito(context),
              ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        backgroundColor: AppColors.fondoCrema,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textoPrincipal,
        title: const Text('Asesor IA', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _cargandoSesion
            ? const Center(child: CircularProgressIndicator(color: AppColors.verdePrimario))
            : _usuarioId == null
                ? _sinSesion()
                : Column(
                    children: [
                      Expanded(child: _mensajes.isEmpty ? _bienvenida() : _lista()),
                      _barraEscritura(),
                    ],
                  ),
      ),
    );
  }

  Widget _sinSesion() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFE6F2E6),
              child: Icon(Icons.lock_outline, size: 34, color: AppColors.verdePrimario),
            ),
            const SizedBox(height: 20),
            const Text(
              'Esta función solo está disponible después de iniciar sesión',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textoPrincipal),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para hablar con el asesor inteligente de TecnoAgro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _irAlLogin,
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bienvenida() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Hola $_nombre, ¿en qué puedo ayudarte hoy?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textoPrincipal)),
          const SizedBox(height: 6),
          const Text('Puedes preguntarme cualquier cosa sobre tu cultivo',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textoSecundario)),
          const SizedBox(height: 16),
          for (final s in _sugerencias)
            Semantics(
              button: true,
              label: 'Sugerencia: $s',
              child: GestureDetector(
                onTap: () => _enviar(s),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: Text(s, style: const TextStyle(color: AppColors.textoPrincipal)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Texto del mensaje: el usuario en texto plano, la IA con formato (negritas, listas, tablas).
  Widget _texto(_Mensaje m) {
    if (m.esUsuario) {
      return SelectableText(m.texto, style: const TextStyle(color: AppColors.blanco));
    }
    const base = TextStyle(color: AppColors.textoPrincipal, fontSize: 14.5, height: 1.4);
    return MarkdownBody(
      data: m.texto,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: base,
        strong: base.copyWith(fontWeight: FontWeight.bold),
        listBullet: base,
        h1: base.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        h2: base.copyWith(fontSize: 16.5, fontWeight: FontWeight.bold),
        h3: base.copyWith(fontSize: 15.5, fontWeight: FontWeight.bold),
        tableBorder: TableBorder.all(color: AppColors.borde),
        tableHead: base.copyWith(fontWeight: FontWeight.bold),
        tableBody: base,
        tableCellsPadding: const EdgeInsets.all(6),
      ),
    );
  }

  /// Tarjeta de un producto recomendado con su botón "Añadir al carrito".
  Widget _tarjetaProducto(Map<String, dynamic> p) {
    final stock = int.tryParse('${p['stock']}') ?? 0;
    final agotado = stock <= 0;
    final imagen = p['imagen_url']?.toString();
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            child: imagen == null || imagen.isEmpty
                ? ColoredBox(color: Colors.grey.shade200, child: const Icon(Icons.inventory_2_outlined))
                : Image.network(imagen,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p['nombre']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textoPrincipal, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(agotado ? 'Agotado' : _dinero(p['precio']),
                style: TextStyle(
                    color: agotado ? Colors.red.shade700 : AppColors.verdePrimario,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: agotado ? null : () => _agregarAlCarrito(p),
          icon: const Icon(Icons.add_shopping_cart, size: 17),
          label: const Text('Añadir'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.verdePrimario,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ]),
    );
  }

  Widget _lista() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: _mensajes.length + (_cargando ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _mensajes.length) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.verdePrimario),
              ),
            ),
          );
        }
        final m = _mensajes[i];
        final burbuja = Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: m.esUsuario ? AppColors.verdePrimario : AppColors.blanco,
            borderRadius: BorderRadius.circular(14),
            border: m.esUsuario ? null : Border.all(color: AppColors.borde),
          ),
          child: _texto(m),
        );
        return Align(
          alignment: m.esUsuario ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: m.esUsuario ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              burbuja,
              for (final p in m.productos) _tarjetaProducto(p),
              if (m.verCatalogo)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 6),
                  child: FilledButton.icon(
                    onPressed: () => abrirCatalogo(context),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: const Text('Ver productos'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.verdePrimario),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _barraEscritura() {
    OutlineInputBorder borde(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: color),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controlador,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviar(),
              decoration: InputDecoration(
                hintText: '¿Preguntas?, ¿inquietudes?',
                hintStyle: const TextStyle(color: AppColors.textoPlaceholder),
                filled: true,
                fillColor: AppColors.blanco,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: borde(AppColors.borde),
                enabledBorder: borde(AppColors.borde),
                focusedBorder: borde(AppColors.verdeMedio),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Enviar mensaje',
            onPressed: _cargando ? null : () => _enviar(),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.verdePrimario,
              minimumSize: const Size(52, 52),
            ),
            icon: const Icon(Icons.send_outlined, color: AppColors.blanco),
          ),
        ],
      ),
    );
  }
}