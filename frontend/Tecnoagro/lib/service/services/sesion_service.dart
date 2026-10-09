import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SesionService {
  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
  
  static Future<bool> esAdmin() async {
    final partes = ((await token()) ?? '').split('.');
    if (partes.length != 3) return false;
    try {
      final datos = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))))
          as Map<String, dynamic>;
      final exp = datos['exp'];
      if (exp is int && DateTime.fromMillisecondsSinceEpoch(exp * 1000).isBefore(DateTime.now())) {
        return false;
      }
      return datos['rol'] == 'admin';
    } catch (_) {
      return false;
    }
  }
}