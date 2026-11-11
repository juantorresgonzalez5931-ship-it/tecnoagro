import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/service/services/api_config.dart';
import 'package:frontend/service/services/sesion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  String _email = '';
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await SesionService.token();
    final id = prefs.get('user_id')?.toString();
    final datosToken = await SesionService.datosToken();
    _nombre.text = prefs.getString('user_name') ?? '';
    _email = datosToken?['email']?.toString() ?? '';

    if (id != null && token != null && token.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/users/$id'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final usuario = body['usuario'] as Map<String, dynamic>?;
          if (usuario != null) {
            _nombre.text = usuario['nombre']?.toString() ?? _nombre.text;
            _telefono.text = usuario['telefono']?.toString() ?? '';
            _email = usuario['email']?.toString() ?? _email;
          }
        }
      } catch (_) {
        // Se mantienen los datos del token si no se puede consultar el perfil.
      }
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _mensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor:
            error ? Colors.red.shade700 : AppColors.verdePrimario,
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final token = await SesionService.token();
      final response = await http.put(
        Uri.parse('${ApiConfig.authBaseUrl}/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
        },
        body: jsonEncode({
          'nombre': _nombre.text.trim(),
          'telefono': _telefono.text.trim(),
        }),
      );
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(body['error'] ?? 'No se pudieron guardar los cambios');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nombre.text.trim());
      if (!mounted) return;
      _mensaje('Información personal actualizada');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _mensaje(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        title: const Text('Información personal'),
        backgroundColor: AppColors.fondoCrema,
        foregroundColor: AppColors.textoPrincipal,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.verdePrimario,
                      child: Icon(Icons.person_outline,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa tu nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email.isEmpty
                          ? TextEditingController(text: 'No disponible')
                          : TextEditingController(text: _email),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        helperText: 'El correo no se modifica desde esta opción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefono,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isNotEmpty &&
                            !RegExp(r'^\d{7,15}$').hasMatch(value)) {
                          return 'Ingresa un teléfono válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdePrimario,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('GUARDAR CAMBIOS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
