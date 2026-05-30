import 'package:cloud_firestore/cloud_firestore.dart';

class EntradaStockModel {
  final String id;
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final DateTime fecha;
  final String registradoPor; // nombre del admin

  EntradaStockModel({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.fecha,
    required this.registradoPor,
  });

  factory EntradaStockModel.fromMap(String id, Map<String, dynamic> map) {
    return EntradaStockModel(
      id: id,
      productoId: map['productoId'] ?? '',
      productoNombre: map['productoNombre'] ?? '',
      cantidad: (map['cantidad'] ?? 0).toInt(),
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      registradoPor: map['registradoPor'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'productoId': productoId,
        'productoNombre': productoNombre,
        'cantidad': cantidad,
        'fecha': Timestamp.fromDate(fecha),
        'registradoPor': registradoPor,
      };
}
