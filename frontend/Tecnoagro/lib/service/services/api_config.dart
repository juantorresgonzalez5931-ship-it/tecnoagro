import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const bool useRemoteServer = false;

  static const String remoteServerUrl =
      'https://tecnoagro.onrender.com';

  static String get baseUrl {
    if (useRemoteServer) {
      return remoteServerUrl;
    }
    return _root;
  }

  static String get _root {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    }

    return 'http://localhost:3000';
  }

  static String get authBaseUrl => '$baseUrl/auth';

  static String get apiBaseUrl => '$baseUrl/api';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}