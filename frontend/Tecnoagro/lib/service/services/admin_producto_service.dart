import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'sesion_service.dart';

class AdminProductoService {
  Uri _uri([String extra = '']) => Uri.parse('${ApiConfig.apiBaseUrl}/productos$extra');

  Future<Map<String, String>> _headers(String tokenRespaldo) async {
    final token = (await SesionService.token()) ?? tokenRespaldo;
    if (token.isEmpty) throw Exception('No hay sesión activa');
    return {...ApiConfig.headers, 'Authorization': 'Bearer $token'};
  }

  String _error(http.Response r, String porDefecto) {
    try {
      final d = jsonDecode(utf8.decode(r.bodyBytes));
      return (d['error'] ?? d['message'] ?? '$porDefecto (Código ${r.statusCode})').toString();
    } catch (_) {
      return '$porDefecto (Código ${r.statusCode})';
    }
  }

  Future<T> _run<T>(Future<T> Function() accion) async {
    try {
      return await accion().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado en responder');
    } on http.ClientException {
      throw Exception('No se pudo conectar con el servidor');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<Map<String, dynamic>>> listar(String token) => _run(() async {
        final r = await http.get(_uri(), headers: await _headers(token));
        if (r.statusCode != 200) throw Exception(_error(r, 'No se pudieron cargar los productos'));
        final body = jsonDecode(utf8.decode(r.bodyBytes));
        final lista = body is List ? body : (body['productos'] ?? body['data'] ?? []);
        return List<Map<String, dynamic>>.from(lista);
      });

  Future<void> actualizar(String token, dynamic id, Map<String, dynamic> campos) => _run(() async {
        final r = await http.put(_uri('/$id'), headers: await _headers(token), body: jsonEncode(campos));
        if (r.statusCode != 200) throw Exception(_error(r, 'No se pudo actualizar el producto'));
      });

  Future<void> eliminar(String token, dynamic id) => _run(() async {
        final r = await http.delete(_uri('/$id'), headers: await _headers(token));
        if (r.statusCode != 200) throw Exception(_error(r, 'No se pudo eliminar el producto'));
      });
}