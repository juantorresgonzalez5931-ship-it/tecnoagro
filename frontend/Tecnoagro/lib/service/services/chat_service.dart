import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ChatService {
  static String get _chatUrl => '${ApiConfig.apiBaseUrl}/chat/mensaje';

  static Future<String> enviarMensaje(String mensaje, {String? sesionId}) async {
    try {
      final response = await http.post(
        Uri.parse(_chatUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'mensaje': mensaje,
          'sesionId': sesionId ?? 'tecnoagro_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      final contentType = response.headers['content-type'] ?? '';

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['respuesta'] ??
            data['mensaje'] ??
            data['reply'] ??
            data['response'] ??
            'No se recibió respuesta del asesor.';
      } else {
        if (contentType.contains('application/json')) {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          final String mensajeError =
              errorData['error'] ??
              errorData['message'] ??
              'En este momento no pudimos procesar tu solicitud.';
          return mensajeError;
        }
        return 'En este momento no pudimos procesar tu solicitud (código ${response.statusCode}).';
      }
    } catch (e) {
      return 'Error de conexión con el servidor. Revisa que el backend esté encendido.';
    }
  }
}