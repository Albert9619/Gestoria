import 'package:cloud_firestore/cloud_firestore.dart';

class ProductoModel {
  final String id;
  final String nombre;
  final String tipo; // fisico | servicio
  final double precio;
  final int stockActual;
  final bool activo;
  final DateTime? creadoEn;

  ProductoModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.precio,
    required this.stockActual,
    required this.activo,
    this.creadoEn,
  });

  bool get esFisico => tipo == 'fisico';
  bool get esServicio => tipo == 'servicio';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductoModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory ProductoModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductoModel(
      id: id,
      nombre: map['nombre'] ?? '',
      tipo: map['tipo'] ?? 'fisico',
      precio: (map['precio'] ?? 0).toDouble(),
      stockActual: (map['stockActual'] ?? 0).toInt(),
      activo: map['activo'] ?? true,
      creadoEn: (map['creadoEn'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'tipo': tipo,
        'precio': precio,
        'stockActual': stockActual,
        'activo': activo,
        'creadoEn': FieldValue.serverTimestamp(),
      };
}
