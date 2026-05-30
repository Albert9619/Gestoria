import 'package:cloud_firestore/cloud_firestore.dart';

class ClienteModel {
  final String id;
  final String nombre;
  final String telefono;
  final String creadoPor;
  final String creadoPorId;
  final String turnoId;
  final double totalCuenta;
  final DateTime creadoEn;

  ClienteModel({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.creadoPor,
    required this.creadoPorId,
    required this.turnoId,
    required this.totalCuenta,
    required this.creadoEn,
  });

  factory ClienteModel.fromMap(String id, Map<String, dynamic> map) {
    return ClienteModel(
      id: id,
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      creadoPor: map['creadoPor'] ?? '',
      creadoPorId: map['creadoPorId'] ?? '',
      turnoId: map['turnoId'] ?? '',
      totalCuenta: (map['totalCuenta'] ?? 0).toDouble(),
      creadoEn: (map['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
