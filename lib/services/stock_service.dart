import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/entrada_stock_model.dart';

class StockService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _entradas(String negocioId) =>
      _db.collection('negocios').doc(negocioId).collection('entradas_stock');

  DocumentReference _producto(String negocioId, String productoId) =>
      _db
          .collection('negocios')
          .doc(negocioId)
          .collection('productos')
          .doc(productoId);

  /// Stream del historial de entradas de stock (más reciente primero)
  Stream<List<EntradaStockModel>> getEntradas(String negocioId) {
    return _entradas(negocioId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EntradaStockModel.fromMap(
                d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  /// Registra una entrada de stock y actualiza el stock del producto
  Future<void> registrarEntrada({
    required String negocioId,
    required String productoId,
    required String productoNombre,
    required int cantidad,
    required String registradoPor,
  }) async {
    final batch = _db.batch();

    // 1. Crear documento de entrada
    final entradaRef = _entradas(negocioId).doc();
    batch.set(entradaRef, {
      'productoId': productoId,
      'productoNombre': productoNombre,
      'cantidad': cantidad,
      'fecha': FieldValue.serverTimestamp(),
      'registradoPor': registradoPor,
    });

    // 2. Incrementar stockActual del producto
    batch.update(_producto(negocioId, productoId), {
      'stockActual': FieldValue.increment(cantidad),
    });

    await batch.commit();
  }
}
