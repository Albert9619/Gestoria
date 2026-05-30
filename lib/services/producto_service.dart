import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';

class ProductoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _col(String negocioId) =>
      _db.collection('negocios').doc(negocioId).collection('productos');

  /// Stream de todos los productos (activos e inactivos)
  Stream<List<ProductoModel>> getProductos(String negocioId) {
    return _col(negocioId)
        .orderBy('nombre')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                ProductoModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream de productos activos (para la mesera)
  Stream<List<ProductoModel>> getProductosActivos(String negocioId) {
    return _col(negocioId)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) =>
                  ProductoModel.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => a.nombre.compareTo(b.nombre));
          return list;
        });
  }

  /// Crea un nuevo producto
  Future<void> crearProducto({
    required String negocioId,
    required String nombre,
    required String tipo,
    required double precio,
  }) async {
    await _col(negocioId).add({
      'nombre': nombre,
      'tipo': tipo,
      'precio': precio,
      'stockActual': 0,
      'activo': true,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Edita el nombre de un producto
  Future<void> editarNombre(
      String negocioId, String productoId, String nuevoNombre) async {
    await _col(negocioId).doc(productoId).update({'nombre': nuevoNombre});
  }

  /// Edita el precio de un producto
  Future<void> editarPrecio(
      String negocioId, String productoId, double nuevoPrecio) async {
    await _col(negocioId).doc(productoId).update({'precio': nuevoPrecio});
  }

  /// Activa o desactiva un producto
  Future<void> toggleActivo(
      String negocioId, String productoId, bool activo) async {
    await _col(negocioId).doc(productoId).update({'activo': activo});
  }

  /// Elimina un producto (solo si no tiene ventas asociadas)
  Future<void> eliminarProducto(String negocioId, String productoId) async {
    await _col(negocioId).doc(productoId).delete();
  }
}
