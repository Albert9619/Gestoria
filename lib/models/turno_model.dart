import 'package:cloud_firestore/cloud_firestore.dart';

class TurnoModel {
  final String id;
  final String meseraId;
  final String mesera; // nombre de la mesera
  final DateTime inicio;
  final DateTime? fin;
  final String estado; // activo | cerrado
  final double base;
  final double totalVentas;
  final double? totalEntregado;
  final double? diferencia; // positivo = faltante, negativo = sobrante
  final String? nota;
  final int clientesAtendidos;

  TurnoModel({
    required this.id,
    required this.meseraId,
    required this.mesera,
    required this.inicio,
    this.fin,
    required this.estado,
    required this.base,
    required this.totalVentas,
    this.totalEntregado,
    this.diferencia,
    this.nota,
    this.clientesAtendidos = 0,
  });

  /// Lo que la mesera debe entregar = ventas del turno + base recibida
  double get debeEntregar => totalVentas + base;

  bool get estaActivo => estado == 'activo';
  bool get estaCerrado => estado == 'cerrado';

  factory TurnoModel.fromMap(String id, Map<String, dynamic> map) {
    return TurnoModel(
      id: id,
      meseraId: map['meseraId'] ?? '',
      mesera: map['mesera'] ?? '',
      inicio: (map['inicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fin: (map['fin'] as Timestamp?)?.toDate(),
      estado: map['estado'] ?? 'activo',
      base: (map['base'] ?? 0).toDouble(),
      totalVentas: (map['totalVentas'] ?? 0).toDouble(),
      totalEntregado: (map['totalEntregado'] as num?)?.toDouble(),
      diferencia: (map['diferencia'] as num?)?.toDouble(),
      nota: map['nota'],
      clientesAtendidos: (map['clientesAtendidos'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'meseraId': meseraId,
        'mesera': mesera,
        'inicio': Timestamp.fromDate(inicio),
        'fin': fin != null ? Timestamp.fromDate(fin!) : null,
        'estado': estado,
        'base': base,
        'totalVentas': totalVentas,
        'totalEntregado': totalEntregado,
        'diferencia': diferencia,
        'nota': nota,
      };
}
