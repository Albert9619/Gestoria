import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nombre;
  final String username;
  final String email;
  final String rol; // admin | mesera
  final bool activo;
  final DateTime? creadoEn;

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.username,
    required this.email,
    required this.rol,
    required this.activo,
    this.creadoEn,
  });

  bool get esMesera => rol == 'mesera';
  bool get esAdmin => rol == 'admin';

  factory UsuarioModel.fromMap(String id, Map<String, dynamic> map) {
    return UsuarioModel(
      id: id,
      nombre: map['nombre'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      rol: map['rol'] ?? 'mesera',
      activo: map['activo'] ?? true,
      creadoEn: (map['creadoEn'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'username': username,
        'email': email,
        'rol': rol,
        'activo': activo,
        'creadoEn': FieldValue.serverTimestamp(),
      };
}
