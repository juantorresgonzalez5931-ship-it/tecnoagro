import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/admin/admin_home_page.dart';
import '/pages/home.dart';

Future<Widget> pantallaInicioPorRol() async {
  final prefs = await SharedPreferences.getInstance();

  final rol = prefs.getString('user_rol');
  final token = prefs.getString('jwt_token') ?? '';

  if (rol == 'admin') {
    return AdminHomePage(token: token);
  }

  return const HomeScreen();
}
