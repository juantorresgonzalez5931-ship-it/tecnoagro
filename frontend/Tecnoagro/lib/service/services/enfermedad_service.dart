import 'dart:convert';
import 'package:frontend/models/enfermedad_model.dart';
import 'package:frontend/service/services/api_config.dart';
import 'package:frontend/service/services/sesion_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EnfermedadService {
  Uri _url([String extra = '']) => Uri.parse('${ApiConfig.apiBaseUrl}/enfermedades$extra');

  Future<Map<String, String>> _auth() async =>
      {'Authorization': 'Bearer ${await SesionService.token() ?? ''}'};

  Future<List<EnfermedadModel>> listar() async {
    final res = await http.get(_url(), headers: ApiConfig.headers);
    if (res.statusCode != 200) throw 'No se pudieron cargar las enfermedades';
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return [for (final e in data) EnfermedadModel.fromJson(Map<String, dynamic>.from(e))];
  }

  Future<EnfermedadModel> obtener(int id) async {
    final res = await http.get(_url('/$id'), headers: ApiConfig.headers);
    if (res.statusCode != 200) throw 'No se pudo cargar la enfermedad';
    return EnfermedadModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// Crea (id == null) o edita. Va en multipart porque la ruta usa Multer (imagen).
  Future<void> guardar({int? id, required Map<String, String> campos, XFile? imagen}) async {
    final req = http.MultipartRequest(id == null ? 'POST' : 'PUT', _url(id == null ? '' : '/$id'))
      ..headers.addAll(await _auth())
      ..fields.addAll(campos);
    if (imagen != null) req.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw 'No se pudo guardar (${res.statusCode})';
    }
  }

  Future<void> eliminar(int id) async {
    final res = await http.delete(_url('/$id'), headers: await _auth());
    if (res.statusCode != 200 && res.statusCode != 204) throw 'No se pudo eliminar';
  }

  /// Pide a la IA qué productos del catálogo sirven para esta enfermedad.
  /// Devuelve los ids (como texto) de productos que existen en la tienda.
  Future<List<String>> recomendarProductos({
    required String nombre,
    String descripcion = '',
    String sintomas = '',
    String tratamiento = '',
    String cultivos = '',
  }) async {
    final res = await http.post(
      _url('/recomendar-productos'),
      headers: {
        ...ApiConfig.headers,
        ...await _auth(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'sintomas': sintomas,
        'tratamiento': tratamiento,
        'cultivos': cultivos,
      }),
    );
    if (res.statusCode != 200) {
      var detalle = '';
      try {
        detalle = jsonDecode(utf8.decode(res.bodyBytes))['error']?.toString() ?? '';
      } catch (_) {}
      throw 'IA (${res.statusCode}): ${detalle.isEmpty ? 'sin detalle' : detalle}';
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final ids = data['ids'];
    return ids is List ? [for (final i in ids) '$i'] : <String>[];
  }
}