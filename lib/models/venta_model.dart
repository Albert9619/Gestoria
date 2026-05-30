import 'package:cloud_firestore/cloud_firestore.dart';

class VentaModel {
  final String id;
  final String turnoId;
  final String meseraId;
  final String mesera; // nombre de la mesera
  final String productoId;
  final String productoNombre;
  final String tipo; // fisico | servicio
  final int cantidad;
  final double precioUnitario;
  final double total;
  final DateTime fecha;

  VentaModel({
    required this.id,
    required this.turnoId,
    required this.meseraId,
    required this.mesera,
    required this.productoId,
    required this.productoNombre,
    required this.tipo,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    required this.fecha,
  });

  factory VentaModel.fromMap(String id, Map<String, dynamic> map) {
    return VentaModel(
      id: id,
      turnoId: map['turnoId'] ?? '',
      meseraId: map['meseraId'] ?? '',
      mesera: map['mesera'] ?? '',
      productoId: map['productoId'] ?? '',
      productoNombre: map['productoNombre'] ?? '',
      tipo: map['tipo'] ?? 'fisico',
      cantidad: (map['cantidad'] ?? 0).toInt(),
      precioUnitario: (map['precioUnitario'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'turnoId': turnoId,
        'meseraId': meseraId,
        'productoId': productoId,
        'productoNombre': productoNombre,
        'tipo': tipo,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'total': total,
        'fecha': Timestamp.fromDate(fecha),
      };
}
