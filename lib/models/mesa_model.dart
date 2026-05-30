import 'package:cloud_firestore/cloud_firestore.dart';

class MesaModel {
  final String id;
  final int numero;
  final String tipo; // 'billar' | 'ping-pong' | 'futbolín' | 'otro'
  final String estado; // 'libre' | 'ocupada'
  final String? clienteId;
  final String? clienteNombre;
  final String? turnoId;
  final String? meseraId;
  final String? meseraNombre;
  final DateTime? inicioUso;
  final bool activa;

  const MesaModel({
    required this.id,
    required this.numero,
    required this.tipo,
    required this.estado,
    this.clienteId,
    this.clienteNombre,
    this.turnoId,
    this.meseraId,
    this.meseraNombre,
    this.inicioUso,
    this.activa = true,
  });

  bool get estaLibre => estado == 'libre';
  bool get estaOcupada => estado == 'ocupada';

  String tiempoEnUsoStr() {
    if (inicioUso == null) return '';
    final diff = DateTime.now().difference(inicioUso!);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  factory MesaModel.fromMap(String id, Map<String, dynamic> map) {
    return MesaModel(
      id: id,
      numero: (map['numero'] ?? 0).toInt(),
      tipo: map['tipo'] ?? 'billar',
      estado: map['estado'] ?? 'libre',
      clienteId: map['clienteId'] as String?,
      clienteNombre: map['clienteNombre'] as String?,
      turnoId: map['turnoId'] as String?,
      meseraId: map['meseraId'] as String?,
      meseraNombre: map['meseraNombre'] as String?,
      inicioUso: (map['inicioUso'] as Timestamp?)?.toDate(),
      activa: (map['activa'] ?? true) as bool,
    );
  }
}
