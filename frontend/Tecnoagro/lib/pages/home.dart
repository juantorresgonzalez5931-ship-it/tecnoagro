//lib/pages/home.dart
import 'package:flutter/material.dart';
import 'package:frontend/pantallas/login.dart';
import 'package:shared_preferences/shared_preferences.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  // Lee el nombre guardado en el login, para mostrarlo en pantalla
Future<void> _cargarUsuario() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    _nombre = prefs.getString('user_name') ?? 'Usuario';
  });
}

// Cierra sesión: borra el token guardado y regresa al Login
Future<void> _cerrarSesion() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Bienvenido, $_nombre',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}