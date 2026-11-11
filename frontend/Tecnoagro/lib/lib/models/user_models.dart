class UserModels {
  final String? id;
  final String? nombre;
  final String? email;
  final String? contrasena;
  final String rol;

  UserModels({
    this.id,
    required this.nombre,
    required this.email,
    required this.contrasena,
    this.rol ='usuario',

  });

  factory UserModels.fromJson(Map<String, dynamic> json) {
    return UserModels(
      id: json['id']?.toString(),
      nombre: json['nombre'] ??'',
      email: json['email'] ??'',
      contrasena: json['contrasena'] ??'',
      rol: json['rol'] ??'usuario',

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'password': contrasena,
      'rol': rol,
    };
  }
}