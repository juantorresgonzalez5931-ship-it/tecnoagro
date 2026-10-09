import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/service/services/api_config.dart';

String get _chatUrl => '${ApiConfig.apiBaseUrl}/chat/mensaje';

class _Mensaje {
  final String texto;
  final bool esUsuario;
  _Mensaje(this.texto, this.esUsuario);
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
  int? _usuarioId;
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
    if (token.isEmpty || !mounted) return;
    try {
      final payload = token.split('.')[1];
      final datos = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload))));
      setState(() {
        _usuarioId = datos['id'];
        _nombre = (datos['nombre'] ?? '').toString().split(' ').first;
      });
    } catch (_) {
      _mostrarError('Sesión inválida, inicia sesión de nuevo');
    }
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
      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (res.statusCode == 200) {
        _conversationId = data['conversation_id'].toString();
        setState(() => _mensajes.add(_Mensaje(data['respuesta'], false)));
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
        child: Column(
          children: [
            Expanded(child: _mensajes.isEmpty ? _bienvenida() : _lista()),
            _barraEscritura(),
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
        return Align(
          alignment: m.esUsuario ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
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