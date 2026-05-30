import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/turno_model.dart';

class TurnoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _col(String negocioId) =>
      _db.collection('negocios').doc(negocioId).collection('turnos');

  // ─────────────────────────────────────────────
  // STREAMS PARA EL ADMIN
  // ─────────────────────────────────────────────

  /// Todos los turnos del día actual (activos y cerrados)
  Stream<List<TurnoModel>> getTurnosHoy(String negocioId) {
    final now = DateTime.now();
    final inicioDia =
        Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final finDia = Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 23, 59, 59, 999));

    return _col(negocioId)
        .where('inicio', isGreaterThanOrEqualTo: inicioDia)
        .where('inicio', isLessThanOrEqualTo: finDia)
        .snapshots()
        .map((snap) => _mapSnap(snap));
  }

  /// Turnos activos (meseras trabajando ahora)
  Stream<List<TurnoModel>> getTurnosActivos(String negocioId) {
    return _col(negocioId)
        .where('estado', isEqualTo: 'activo')
        .snapshots()
        .map((snap) {
          final list = _mapSnap(snap);
          list.sort((a, b) => b.inicio.compareTo(a.inicio));
          return list;
        });
  }

  /// Historial de turnos cerrados
  Stream<List<TurnoModel>> getHistorial(String negocioId) {
    return _col(negocioId)
        .where('estado', isEqualTo: 'cerrado')
        .snapshots()
        .map((snap) {
          final list = _mapSnap(snap);
          list.sort((a, b) => b.inicio.compareTo(a.inicio));
          return list;
        });
  }

  // ─────────────────────────────────────────────
  // OPERACIONES DE TURNO
  // ─────────────────────────────────────────────

  /// Obtiene el turno activo de una mesera (null si no tiene)
  Future<TurnoModel?> getTurnoActivo(
      String negocioId, String meseraId) async {
    final snap = await _col(negocioId)
        .where('meseraId', isEqualTo: meseraId)
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return TurnoModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Stream del turno activo de una mesera (por meseraId)
  Stream<TurnoModel?> streamTurnoActivo(String negocioId, String meseraId) {
    return _col(negocioId)
        .where('meseraId', isEqualTo: meseraId)
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return TurnoModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  /// Stream de un turno específico por su ID
  Stream<TurnoModel?> streamTurnoPorId(String negocioId, String turnoId) {
    return _col(negocioId).doc(turnoId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TurnoModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  /// Crea un nuevo turno al iniciar sesión la mesera
  Future<String> crearTurno({
    required String negocioId,
    required String meseraId,
    required String mesera,
  }) async {
    final ref = _col(negocioId).doc();
    await ref.set({
      'meseraId': meseraId,
      'mesera': mesera,
      'inicio': FieldValue.serverTimestamp(),
      'fin': null,
      'estado': 'activo',
      'base': 0.0,
      'totalVentas': 0.0,
      'clientesAtendidos': 0,
      'totalEntregado': null,
      'diferencia': null,
      'nota': null,
    });
    return ref.id;
  }

  /// Asigna o actualiza la base de un turno
  Future<void> asignarBase(
      String negocioId, String turnoId, double base) async {
    await _col(negocioId).doc(turnoId).update({'base': base});
  }

  /// Cierra el turno y registra el cobro
  Future<void> cerrarTurno({
    required String negocioId,
    required String turnoId,
    required double totalEntregado,
    required double debeEntregar,
    String? nota,
  }) async {
    final diferencia = debeEntregar - totalEntregado;
    await _col(negocioId).doc(turnoId).update({
      'estado': 'cerrado',
      'fin': FieldValue.serverTimestamp(),
      'totalEntregado': totalEntregado,
      'diferencia': diferencia,
      'nota': nota,
    });
  }

  /// Actualiza el total de ventas de un turno (llamado por VentaService)
  Future<void> actualizarTotalVentas(
      String negocioId, String turnoId, double monto) async {
    await _col(negocioId).doc(turnoId).update({
      'totalVentas': FieldValue.increment(monto),
    });
  }

  // ─────────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────────

  List<TurnoModel> _mapSnap(QuerySnapshot snap) => snap.docs
      .map((d) => TurnoModel.fromMap(d.id, d.data() as Map<String, dynamic>))
      .toList();
}
