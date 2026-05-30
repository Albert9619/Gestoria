import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/negocio_model.dart';

class SuperAdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _negocios => _db.collection('negocios');

  // ─────────────────────────────────────────────
  // STREAM DE TODOS LOS NEGOCIOS
  // ─────────────────────────────────────────────

  Stream<List<NegocioModel>> getNegociosStream() {
    return _negocios
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                NegocioModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  // ─────────────────────────────────────────────
  // EXTENDER SUSCRIPCIÓN
  // ─────────────────────────────────────────────

  Future<void> extenderSuscripcion(
      String negocioId, int dias, DateTime? actual) async {
    // Si ya venció (o no tiene fecha), se extiende desde hoy
    final base = (actual != null && actual.isAfter(DateTime.now()))
        ? actual
        : DateTime.now();
    final nueva = base.add(Duration(days: dias));
    await _negocios.doc(negocioId).update({
      'suscripcionHasta': Timestamp.fromDate(nueva),
      'activo': true,
    });
  }

  // ─────────────────────────────────────────────
  // ACTIVAR / BLOQUEAR NEGOCIO
  // ─────────────────────────────────────────────

  Future<void> setActivo(String negocioId, bool activo) async {
    await _negocios.doc(negocioId).update({'activo': activo});
  }

  // ─────────────────────────────────────────────
  // CAMBIAR PLAN
  // ─────────────────────────────────────────────

  Future<void> cambiarPlan(String negocioId, String plan) async {
    await _negocios.doc(negocioId).update({'plan': plan});
  }
}
