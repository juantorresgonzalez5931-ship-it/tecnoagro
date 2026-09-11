import 'package:flutter/material.dart';
import '/models/user_models.dart';
import '../service/services/user_service.dart';
class Formulario extends StatefulWidget {
  const Formulario({super.key});

  @override
  State<Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<Formulario> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      _mostrarMensaje('Por favor, completa todos los campos', esError: true);
      return;
    }

    setState(() => _isLoading = true);

    final nuevoUsuario = UserModels(
      nombre: nombre,
      email: email,
      contrasena: password,
    );

    try {
      final usuarioCreado = await _userService.registrarUsuario(nuevoUsuario);

      if (!mounted) return;

      _mostrarMensaje('Usuario registrado con éxito');
      _mostrarDialogoExito(usuarioCreado);
      _limpiarFormulario();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error al registrar: $e', esError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  void _mostrarDialogoExito(UserModels usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('¡Registro Exitoso!'),
        content: Text('El usuario ${usuario.nombre} fue registrado con éxito.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0x000A0A0A),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(""),
              Text(""),
              Text(
                "Registro de Usuario",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),

              SizedBox(height: 30),
              Text("   Nombres"),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    hintText: 'Digite su Nombre',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              SizedBox(height: 30),
              Text("   Email"),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Digite su Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              SizedBox(height: 30),
              Text("   Contraseña"),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Digite su Contraseña',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              Text(""),
              Text(""),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Color de fondo
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(
                        fontSize: 20,
                      ), // Color del texto o icono
                    ),
                    onPressed: _isLoading ? null : _registrar,
                    child: Text('Guardar'),
                  ),

                  SizedBox(width: 20),

                  // Espacio entre los botones
                  OutlinedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Color de fondo
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(
                        fontSize: 20,
                      ), // Color del texto o icono
                    ),
                    onPressed: () {
                      // Acción del botón
                    },
                    child: Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
