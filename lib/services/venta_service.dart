import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
import '../models/venta_model.dart';

class VentaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _col(String negocioId) =>
      _db.collection('negocios').doc(negocioId).collection('ventas');

  /// Stream de ventas de un turno específico
  Stream<List<VentaModel>> getVentasTurno(String negocioId, String turnoId) {
    return _col(negocioId)
        .where('turnoId', isEqualTo: turnoId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                VentaModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  /// Registra una venta:
  /// - Crea el documento de venta
  /// - Incrementa totalVentas del turno
  /// - Si es producto físico: decrementa el stock
  Future<void> registrarVenta({
    required String negocioId,
    required String turnoId,
    required String meseraId,
    required ProductoModel producto,
    required int cantidad,
  }) async {
    final total = producto.precio * cantidad;
    final batch = _db.batch();

    // 1. Crear venta
    final ventaRef = _col(negocioId).doc();
    batch.set(ventaRef, {
      'turnoId': turnoId,
      'meseraId': meseraId,
      'productoId': producto.id,
      'productoNombre': producto.nombre,
      'tipo': producto.tipo,
      'cantidad': cantidad,
      'precioUnitario': producto.precio,
      'total': total,
      'fecha': FieldValue.serverTimestamp(),
    });

    // 2. Actualizar totalVentas del turno
    final turnoRef = _db
        .collection('negocios')
        .doc(negocioId)
        .collection('turnos')
        .doc(turnoId);
    batch.update(turnoRef, {
      'totalVentas': FieldValue.increment(total),
    });

    // 3. Descontar stock si es producto físico
    if (producto.esFisico) {
      final prodRef = _db
          .collection('negocios')
          .doc(negocioId)
          .collection('productos')
          .doc(producto.id);
      batch.update(prodRef, {
        'stockActual': FieldValue.increment(-cantidad),
      });
    }

    await batch.commit();
  }
}
