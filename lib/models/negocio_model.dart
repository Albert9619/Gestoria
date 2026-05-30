import 'package:cloud_firestore/cloud_firestore.dart';

class NegocioModel {
  final String id;
  final String nombre;
  final String email;
  final String codigo;
  final bool activo;
  final String plan;
  final DateTime creadoEn;
  final DateTime? suscripcionHasta;

  NegocioModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.codigo,
    required this.activo,
    required this.plan,
    required this.creadoEn,
    this.suscripcionHasta,
  });

  /// true si la suscripción está vigente (activo + fecha no vencida)
  bool get suscripcionVigente {
    if (!activo) return false;
    if (suscripcionHasta == null) return false;
    return suscripcionHasta!.isAfter(DateTime.now());
  }

  /// Días restantes (negativo = vencido hace N días)
  int get diasRestantes {
    if (suscripcionHasta == null) return 0;
    return suscripcionHasta!.difference(DateTime.now()).inDays;
  }

  factory NegocioModel.fromMap(String id, Map<String, dynamic> map) {
    return NegocioModel(
      id: id,
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      codigo: map['codigo'] ?? '',
      activo: map['activo'] ?? true,
      plan: map['plan'] ?? 'basico',
      creadoEn: (map['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      suscripcionHasta:
          (map['suscripcionHasta'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'email': email,
        'codigo': codigo,
        'activo': activo,
        'plan': plan,
        'creadoEn': Timestamp.fromDate(creadoEn),
        if (suscripcionHasta != null)
          'suscripcionHasta': Timestamp.fromDate(suscripcionHasta!),
      };
}
