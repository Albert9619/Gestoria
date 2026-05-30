import 'package:cloud_firestore/cloud_firestore.dart';

class ConsumoModel {
  final String id;
  final String ventaId; // referencia al registro permanente en ventas/
  final String productoId;
  final String productoNombre;
  final String productoTipo; // 'fisico' | 'servicio'
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final DateTime creadoEn;

  ConsumoModel({
    required this.id,
    required this.ventaId,
    required this.productoId,
    required this.productoNombre,
    required this.productoTipo,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.creadoEn,
  });

  bool get esFisico => productoTipo == 'fisico';

  factory ConsumoModel.fromMap(String id, Map<String, dynamic> map) {
    return ConsumoModel(
      id: id,
      ventaId: map['ventaId'] ?? '',
      productoId: map['productoId'] ?? '',
      productoNombre: map['productoNombre'] ?? '',
      productoTipo: map['productoTipo'] ?? 'fisico',
      cantidad: (map['cantidad'] ?? 1).toInt(),
      precioUnitario: (map['precioUnitario'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      creadoEn: (map['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
