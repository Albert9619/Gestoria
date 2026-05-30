import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mesa_model.dart';

class MesaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _col(String negocioId) =>
      _db.collection('negocios').doc(negocioId).collection('mesas');

  /// Stream de todas las mesas activas, ordenadas por número
  Stream<List<MesaModel>> getMesas(String negocioId) {
    return _col(negocioId)
        .where('activa', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) =>
              MesaModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.numero.compareTo(b.numero));
      return list;
    });
  }

  /// Stream de mesas libres (para el selector de la mesera)
  Stream<List<MesaModel>> getMesasLibres(String negocioId) {
    return _col(negocioId)
        .where('activa', isEqualTo: true)
        .where('estado', isEqualTo: 'libre')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) =>
              MesaModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.numero.compareTo(b.numero));
      return list;
    });
  }

  /// Crea una nueva mesa
  Future<void> crearMesa({
    required String negocioId,
    required int numero,
    required String tipo,
  }) async {
    await _col(negocioId).add({
      'numero': numero,
      'tipo': tipo,
      'estado': 'libre',
      'clienteId': null,
      'clienteNombre': null,
      'turnoId': null,
      'meseraId': null,
      'meseraNombre': null,
      'inicioUso': null,
      'activa': true,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Marca una mesa como ocupada
  Future<void> ocuparMesa({
    required String negocioId,
    required String mesaId,
    required String clienteNombre,
    String? clienteId,
    String? turnoId,
    String? meseraId,
    String? meseraNombre,
  }) async {
    await _col(negocioId).doc(mesaId).update({
      'estado': 'ocupada',
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'turnoId': turnoId,
      'meseraId': meseraId,
      'meseraNombre': meseraNombre,
      'inicioUso': FieldValue.serverTimestamp(),
    });
  }

  /// Libera una mesa
  Future<void> liberarMesa(String negocioId, String mesaId) async {
    await _col(negocioId).doc(mesaId).update({
      'estado': 'libre',
      'clienteId': null,
      'clienteNombre': null,
      'turnoId': null,
      'meseraId': null,
      'meseraNombre': null,
      'inicioUso': null,
    });
  }

  /// Libera la mesa asociada a un cliente (llamado al cobrar o eliminar)
  Future<void> liberarMesaPorCliente(
      String negocioId, String clienteId) async {
    final snap = await _col(negocioId)
        .where('clienteId', isEqualTo: clienteId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;
    await liberarMesa(negocioId, snap.docs.first.id);
  }

  /// Edita número y tipo de una mesa
  Future<void> editarMesa({
    required String negocioId,
    required String mesaId,
    required int numero,
    required String tipo,
  }) async {
    await _col(negocioId).doc(mesaId).update({
      'numero': numero,
      'tipo': tipo,
    });
  }

  /// Elimina una mesa permanentemente
  Future<void> eliminarMesa(String negocioId, String mesaId) async {
    await _col(negocioId).doc(mesaId).delete();
  }
}
