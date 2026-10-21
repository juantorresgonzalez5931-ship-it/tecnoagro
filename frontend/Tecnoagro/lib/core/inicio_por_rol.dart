import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/admin/admin_dashboard_page.dart';
import '/pages/home.dart';

Future<Widget> pantallaInicioPorRol() async {
  final prefs = await SharedPreferences.getInstance();
  final rol = prefs.getString('user_rol');
  final token = prefs.getString('jwt_token') ?? '';
  return rol == 'admin' ? AdminDashboardPage(token: token) : const HomeScreen();
}