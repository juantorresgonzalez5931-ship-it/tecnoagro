import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';

class ManualUsuarioScreen extends StatelessWidget {
  const ManualUsuarioScreen({super.key});

  static const List<({IconData icono, String titulo, String contenido})>
      _manuales = [
    (
      icono: Icons.person_add_alt_1_outlined,
      titulo: 'Crear una cuenta e iniciar sesión',
      contenido:
          '1. Abre TecnoAgro y selecciona Registrarse.\n'
          '2. Completa tu nombre, correo, teléfono y contraseña.\n'
          '3. Si ya tienes una cuenta, entra en Iniciar sesión.\n'
          '4. También puedes utilizar el acceso con Google si está habilitado.'
    ),
    (
      icono: Icons.storefront_outlined,
      titulo: 'Explorar productos',
      contenido:
          '1. Entra en la sección Productos.\n'
          '2. Utiliza el buscador para encontrar un producto.\n'
          '3. Revisa su descripción, precio y disponibilidad.\n'
          '4. Abre el detalle para consultar la información antes de agregarlo al carrito.'
    ),
    (
      icono: Icons.shopping_cart_outlined,
      titulo: 'Usar el carrito y realizar una reserva',
      contenido:
          '1. Selecciona los productos que necesitas.\n'
          '2. Agrégalos al carrito y revisa las cantidades.\n'
          '3. Confirma la reserva siguiendo las indicaciones de la aplicación.\n'
          '4. Consulta el estado y los detalles desde Mis reservas.'
    ),
    (
      icono: Icons.local_florist_outlined,
      titulo: 'Consultar enfermedades',
      contenido:
          '1. Abre la sección Enfermedades.\n'
          '2. Busca el cultivo o el problema que deseas consultar.\n'
          '3. Lee los síntomas y la información disponible.\n'
          '4. Verifica las recomendaciones con un profesional agrícola antes de aplicar productos.'
    ),
    (
      icono: Icons.smart_toy_outlined,
      titulo: 'Consultar al asesor IA',
      contenido:
          '1. Abre el Asesor IA.\n'
          '2. Describe el cultivo y el problema con el mayor detalle posible.\n'
          '3. Indica los síntomas, ubicación y tiempo de evolución.\n'
          '4. Utiliza las respuestas como orientación; confirma decisiones de manejo con un técnico.'
    ),
    (
      icono: Icons.manage_accounts_outlined,
      titulo: 'Administrar tu perfil',
      contenido:
          'Desde Mi perfil puedes consultar tus reservas, editar tu nombre y teléfono, '
          'leer estos manuales, cerrar sesión o solicitar la eliminación de tu cuenta.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        title: const Text('Manuales de usuario'),
        backgroundColor: AppColors.fondoCrema,
        foregroundColor: AppColors.textoPrincipal,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.verdePrimario,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.menu_book_rounded, color: Colors.white, size: 34),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Guía de uso de TecnoAgro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final manual in _manuales)
            Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.borde),
              ),
              child: ExpansionTile(
                leading: Icon(manual.icono, color: AppColors.verdePrimario),
                title: Text(
                  manual.titulo,
                  style: const TextStyle(
                    color: AppColors.textoPrincipal,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                childrenPadding:
                    const EdgeInsets.fromLTRB(18, 0, 18, 18),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manual.contenido,
                    style: const TextStyle(
                      color: AppColors.textoSecundario,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
