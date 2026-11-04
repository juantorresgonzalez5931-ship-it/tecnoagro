import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/core/navegacion.dart';
import 'package:frontend/pantallas/login.dart';
import 'package:frontend/service/services/api_config.dart';

String get _chatUrl => '${ApiConfig.apiBaseUrl}/chat/mensaje';

class _Mensaje {
  final String texto;
  final bool esUsuario;
  final bool verCatalogo; // true = debajo se muestra el botón "Ver productos"
  _Mensaje(this.texto, this.esUsuario, {this.verCatalogo = false});
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
  /// Si no hay token, o está vencido o dañado, el usuario queda sin sesión.
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
    _cargarSesion(); // al volver, revisa si ya inició sesión
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
        setState(() => _mensajes.add(_Mensaje(
              data['respuesta'],
              false,
              verCatalogo: data['accion'] == 'ver_catalogo',
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

  /// Pantalla que se muestra cuando el usuario no ha iniciado sesión.
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
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: m.esUsuario ? AppColors.verdePrimario : AppColors.blanco,
            borderRadius: BorderRadius.circular(14),
            border: m.esUsuario ? null : Border.all(color: AppColors.borde),
          ),
          child: SelectableText(
            m.texto,
            style: TextStyle(color: m.esUsuario ? AppColors.blanco : AppColors.textoPrincipal),
          ),
        );
        return Align(
          alignment: m.esUsuario ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: m.esUsuario ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              burbuja,
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