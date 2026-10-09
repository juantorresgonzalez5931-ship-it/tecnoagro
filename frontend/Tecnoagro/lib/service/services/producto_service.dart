import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/models/producto_models.dart';
import 'api_config.dart';
import 'sesion_service.dart';

class ProductoService {
  /// GET /api/productos (ruta pública, no necesita token).
  /// Devuelve la lista con el producto más nuevo primero.
  Future<List<ProductoModels>> listarProductos() async {
    final url = Uri.parse('${ApiConfig.apiBaseUrl}/productos');

    try {
      final response = await http
          .get(url, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 20));

      final contentType = response.headers['content-type'] ?? '';

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        var lista = data
            .map((e) => ProductoModels.fromJson(e as Map<String, dynamic>))
            .toList();

        // Más nuevo primero: por fecha si existe; si no, el último insertado.
        if (lista.isNotEmpty && lista.every((p) => p.creadoEn != null)) {
          lista.sort((a, b) => b.creadoEn!.compareTo(a.creadoEn!));
        } else {
          lista = lista.reversed.toList();
        }
        return lista;
      }

      if (contentType.contains('application/json')) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ??
              errorData['message'] ??
              'No se pudieron cargar los productos',
        );
      }
      throw Exception(
        'Servidor no disponible o ruta no encontrada (Codigo ${response.statusCode})',
      );
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder');
    } on http.ClientException {
      throw Exception('No se pudo conectar con el servidor');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// POST /api/productos (solo administrador). Se envía como formulario con la foto
  /// en el campo 'imagen'; el backend la sube a Cloudinary y guarda la URL.
  Future<void> crearProducto({
    required Map<String, String> campos,
    required String rutaImagen,
  }) async {
    final url = Uri.parse('${ApiConfig.apiBaseUrl}/productos');

    try {
      final token = await SesionService.token();
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer ${token ?? ''}'
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(campos)
        ..files.add(await http.MultipartFile.fromPath('imagen', rutaImagen));

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) return;

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/json')) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ??
              errorData['message'] ??
              'No se pudo crear el producto',
        );
      }
      throw Exception(
        'Servidor no disponible o ruta no encontrada (Codigo ${response.statusCode})',
      );
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder');
    } on http.ClientException {
      throw Exception('No se pudo conectar con el servidor');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}