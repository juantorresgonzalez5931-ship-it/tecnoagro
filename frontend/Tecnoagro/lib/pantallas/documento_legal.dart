import 'package:flutter/material.dart';
import 'package:frontend/core/colores.dart';

// ⚠️ Completa estos datos antes de publicar la app.
const _nombreResponsable = 'TecnoAgro';
const _correoContacto = '[tu correo de contacto]';
const _fechaActualizacion = 'Noviembre de 2026';

/// Abre la pantalla con los Términos y Condiciones.
void abrirTerminos(BuildContext context) => _abrir(context, 'Términos y condiciones', _terminos);

/// Abre la pantalla con la Política de Privacidad.
void abrirPrivacidad(BuildContext context) => _abrir(context, 'Política de privacidad', _privacidad);

void _abrir(BuildContext context, String titulo, List<(String, String)> secciones) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _DocumentoLegalScreen(titulo: titulo, secciones: secciones)),
  );
}

class _DocumentoLegalScreen extends StatelessWidget {
  final String titulo;
  final List<(String, String)> secciones;
  const _DocumentoLegalScreen({required this.titulo, required this.secciones});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.verdePrimario),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(titulo,
            style: TextStyle(color: AppColors.textoPrincipal, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          children: [
            Text('Última actualización: $_fechaActualizacion',
                style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
            const SizedBox(height: 18),
            for (var i = 0; i < secciones.length; i++) ...[
              Text('${i + 1}. ${secciones[i].$1}',
                  style: TextStyle(color: AppColors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(secciones[i].$2,
                  style: TextStyle(color: AppColors.textoPrincipal, fontSize: 14.5, height: 1.5)),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('ENTENDIDO')),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Textos. Son un borrador general: pídele a un abogado que los revise
// y ajústalos a cómo funciona realmente tu negocio antes de publicar.
// ---------------------------------------------------------------------------

final List<(String, String)> _terminos = [
  (
    'Aceptación',
    'Al crear una cuenta o usar TecnoAgro aceptas estos términos. Si no estás de acuerdo con ellos, no uses la aplicación.'
  ),
  (
    'Qué ofrece TecnoAgro',
    'TecnoAgro es una aplicación para consultar un catálogo de productos agrícolas, recibir orientación de un asesor inteligente y armar tu carrito de compras.'
  ),
  (
    'Tu cuenta',
    'Debes dar datos verdaderos y mantenerlos actualizados, y ser mayor de edad para registrarte. Eres responsable de tu contraseña y de lo que ocurra con tu cuenta. Avísanos si sospechas que alguien más la está usando.'
  ),
  (
    'Productos y precios',
    'La información, las imágenes y los precios son de referencia y pueden cambiar sin previo aviso. La disponibilidad depende del inventario. Agregar un producto al carrito no es una compra confirmada.'
  ),
  (
    'Uso responsable de los productos',
    'Los productos agrícolas, en especial los agroquímicos, deben usarse siguiendo la etiqueta del fabricante, las normas de seguridad y la guía de un profesional. Eres responsable del uso que hagas de ellos.'
  ),
  (
    'Asesor inteligente',
    'Las respuestas del asesor se generan automáticamente y son solo orientativas; pueden contener errores. No reemplazan la recomendación de un ingeniero agrónomo. Verifica siempre la dosis y la forma de uso en la etiqueta del producto.'
  ),
  (
    'Conducta',
    'No uses la aplicación para actividades ilegales, para intentar entrar a cuentas ajenas, para afectar el servicio ni para copiar su contenido sin permiso.'
  ),
  (
    'Propiedad intelectual',
    'El nombre, el logo, el diseño y los contenidos de TecnoAgro pertenecen a $_nombreResponsable o a quienes nos los licencian. No puedes copiarlos ni usarlos sin autorización.'
  ),
  (
    'Limitación de responsabilidad',
    'Hacemos lo posible por mantener la aplicación disponible y la información correcta, pero no garantizamos que funcione sin interrupciones ni errores. En la medida que permita la ley, no respondemos por daños derivados del uso de la aplicación o de decisiones tomadas con base en su contenido.'
  ),
  (
    'Cambios en estos términos',
    'Podemos actualizar estos términos. Si los cambios son importantes, te avisaremos en la aplicación. Seguir usándola después de un cambio significa que lo aceptas.'
  ),
  (
    'Ley aplicable y contacto',
    'Estos términos se rigen por las leyes de la República de Colombia. Si tienes dudas, escríbenos a $_correoContacto.'
  ),
];

final List<(String, String)> _privacidad = [
  (
    'Responsable de tus datos',
    '$_nombreResponsable es el responsable del tratamiento de tus datos personales. Puedes contactarnos en $_correoContacto.'
  ),
  (
    'Qué datos recogemos',
    'Tu nombre, fecha de nacimiento, correo electrónico, teléfono y contraseña (que guardamos cifrada). Si entras con Google, recibimos tu nombre y tu correo de esa cuenta. También usamos los mensajes que le escribes al asesor inteligente para poder responderte.'
  ),
  (
    'Para qué usamos tus datos',
    'Para crear y administrar tu cuenta, permitirte iniciar sesión y recuperar tu contraseña (te enviamos un código a tu correo), mostrarte productos y atender tus pedidos, responder tus consultas al asesor, mejorar la aplicación y cumplir obligaciones legales.'
  ),
  (
    'Con quién los compartimos',
    'No vendemos tus datos. Usamos proveedores que nos ayudan a operar la aplicación, como el almacenamiento de datos, el envío de correos, el inicio de sesión con Google y el servicio de inteligencia artificial del asesor. Ellos solo reciben lo necesario para prestar su servicio. También podemos compartir información si una autoridad competente lo exige.'
  ),
  (
    'Seguridad',
    'Guardamos tu contraseña cifrada y aplicamos medidas razonables para proteger tus datos. Ningún sistema es completamente seguro, así que te recomendamos usar una contraseña propia y no compartirla.'
  ),
  (
    'Tus derechos',
    'Según la Ley 1581 de 2012, puedes conocer, actualizar y rectificar tus datos, pedir prueba de tu autorización, saber cómo los usamos, revocar tu autorización, solicitar que los eliminemos y presentar quejas ante la Superintendencia de Industria y Comercio. Para ejercer estos derechos escríbenos a $_correoContacto.'
  ),
  (
    'Cuánto tiempo los conservamos',
    'Mientras tu cuenta esté activa y el tiempo necesario para cumplir obligaciones legales. Si pides eliminar tu cuenta, borraremos tus datos, salvo los que la ley nos obligue a conservar.'
  ),
  (
    'Cambios en esta política',
    'Podemos actualizar esta política. Si los cambios son importantes, te avisaremos en la aplicación.'
  ),
  (
    'Tu autorización',
    'Al registrarte y aceptar esta política, autorizas el tratamiento de tus datos personales en los términos aquí descritos.'
  ),
];