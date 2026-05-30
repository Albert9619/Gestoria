import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class MeseraService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _col(String negocioId) =>
      _db.collection('negocios').doc(negocioId).collection('usuarios');

  /// Stream de meseras activas del negocio
  Stream<List<UsuarioModel>> getMeseras(String negocioId) {
    return _col(negocioId)
        .where('rol', isEqualTo: 'mesera')
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) =>
                  UsuarioModel.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => a.nombre.compareTo(b.nombre));
          return list;
        });
  }

  /// Edita el nombre de una mesera en ambas colecciones
  Future<void> editarNombre(
      String negocioId, String meseraId, String nuevoNombre) async {
    final batch = _db.batch();
    batch.update(_col(negocioId).doc(meseraId), {'nombre': nuevoNombre});
    batch.update(
        _db.collection('usuarios').doc(meseraId), {'nombre': nuevoNombre});
    await batch.commit();
  }

  /// Desactiva una mesera (soft delete — no borra Firebase Auth)
  Future<void> desactivarMesera(String negocioId, String meseraId) async {
    final batch = _db.batch();
    // Desactiva en subcolección del negocio
    batch.update(
      _col(negocioId).doc(meseraId),
      {'activo': false},
    );
    // Desactiva en colección global
    batch.update(
      _db.collection('usuarios').doc(meseraId),
      {'activo': false},
    );
    await batch.commit();
  }

  /// Obtiene una mesera por ID
  Future<UsuarioModel?> getMesera(String negocioId, String meseraId) async {
    final doc = await _col(negocioId).doc(meseraId).get();
    if (!doc.exists) return null;
    return UsuarioModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
