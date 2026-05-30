import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente_model.dart';
import '../models/consumo_model.dart';
import '../models/producto_model.dart';
import 'mesa_service.dart';

class ClienteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _col(String negocioId) =>
      _db.collection('negocios').doc(negocioId).collection('clientes');

  CollectionReference _ventas(String negocioId) =>
      _db.collection('negocios').doc(negocioId).collection('ventas');

  CollectionReference _turnos(String negocioId) =>
      _db.collection('negocios').doc(negocioId).collection('turnos');

  // ─────────────────────────────────────────────
  // STREAMS
  // ─────────────────────────────────────────────

  Stream<List<ClienteModel>> getClientesTurno(
      String negocioId, String turnoId) {
    return _col(negocioId)
        .where('turnoId', isEqualTo: turnoId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) =>
              ClienteModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.nombre.compareTo(b.nombre));
      return list;
    });
  }

  Stream<ClienteModel?> streamCliente(String negocioId, String clienteId) {
    return _col(negocioId).doc(clienteId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClienteModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  Stream<List<ConsumoModel>> getConsumos(
      String negocioId, String clienteId) {
    return _col(negocioId)
        .doc(clienteId)
        .collection('consumos')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) =>
              ConsumoModel.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
      return list;
    });
  }

  // ─────────────────────────────────────────────
  // CREAR CLIENTE
  // ─────────────────────────────────────────────

  Future<String> crearCliente({
    required String negocioId,
    required String turnoId,
    required String nombre,
    required String telefono,
    required String creadoPor,
    required String creadoPorId,
  }) async {
    final ref = await _col(negocioId).add({
      'nombre': nombre.trim(),
      'telefono': telefono.trim(),
      'creadoPor': creadoPor,
      'creadoPorId': creadoPorId,
      'turnoId': turnoId,
      'totalCuenta': 0.0,
      'creadoEn': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ─────────────────────────────────────────────
  // AGREGAR VARIOS CONSUMOS DE UNA VEZ (batch)
  // ─────────────────────────────────────────────

  Future<void> agregarConsumos({
    required String negocioId,
    required String clienteId,
    required String turnoId,
    required String mesera,
    required String meseraId,
    required List<ProductoModel> productos,
    required Map<String, int> cantidades, // productoId → cantidad
  }) async {
    if (productos.isEmpty) return;
    final batch = _db.batch();
    double totalGeneral = 0;

    for (final producto in productos) {
      final cantidad = cantidades[producto.id] ?? 0;
      if (cantidad <= 0) continue;
      final subtotal = producto.precio * cantidad;
      totalGeneral += subtotal;

      final ventaRef = _ventas(negocioId).doc();
      batch.set(ventaRef, {
        'turnoId': turnoId,
        'meseraId': meseraId,
        'mesera': mesera,
        'productoId': producto.id,
        'productoNombre': producto.nombre,
        'tipo': producto.tipo,
        'cantidad': cantidad,
        'precioUnitario': producto.precio,
        'total': subtotal,
        'fecha': FieldValue.serverTimestamp(),
      });

      final consumoRef =
          _col(negocioId).doc(clienteId).collection('consumos').doc();
      batch.set(consumoRef, {
        'ventaId': ventaRef.id,
        'productoId': producto.id,
        'productoNombre': producto.nombre,
        'productoTipo': producto.tipo,
        'cantidad': cantidad,
        'precioUnitario': producto.precio,
        'subtotal': subtotal,
        'creadoEn': FieldValue.serverTimestamp(),
      });

      if (producto.esFisico) {
        batch.update(
          _db
              .collection('negocios')
              .doc(negocioId)
              .collection('productos')
              .doc(producto.id),
          {'stockActual': FieldValue.increment(-cantidad)},
        );
      }
    }

    batch.update(_col(negocioId).doc(clienteId), {
      'totalCuenta': FieldValue.increment(totalGeneral),
    });

    batch.update(_turnos(negocioId).doc(turnoId), {
      'totalVentas': FieldValue.increment(totalGeneral),
    });

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // AGREGAR CONSUMO  (+ registro permanente en ventas/)
  // ─────────────────────────────────────────────

  Future<void> agregarConsumo({
    required String negocioId,
    required String clienteId,
    required String turnoId,
    required String mesera,
    required String meseraId,
    required ProductoModel producto,
    required int cantidad,
  }) async {
    final subtotal = producto.precio * cantidad;
    final batch = _db.batch();

    // 1. Registro permanente en ventas/ (para reportes)
    final ventaRef = _ventas(negocioId).doc();
    batch.set(ventaRef, {
      'turnoId': turnoId,
      'meseraId': meseraId,
      'mesera': mesera,
      'productoId': producto.id,
      'productoNombre': producto.nombre,
      'tipo': producto.tipo,
      'cantidad': cantidad,
      'precioUnitario': producto.precio,
      'total': subtotal,
      'fecha': FieldValue.serverTimestamp(),
    });

    // 2. Consumo bajo el cliente (con referencia a la venta)
    final consumoRef =
        _col(negocioId).doc(clienteId).collection('consumos').doc();
    batch.set(consumoRef, {
      'ventaId': ventaRef.id,
      'productoId': producto.id,
      'productoNombre': producto.nombre,
      'productoTipo': producto.tipo,
      'cantidad': cantidad,
      'precioUnitario': producto.precio,
      'subtotal': subtotal,
      'creadoEn': FieldValue.serverTimestamp(),
    });

    // 3. Actualizar total del cliente
    batch.update(_col(negocioId).doc(clienteId), {
      'totalCuenta': FieldValue.increment(subtotal),
    });

    // 4. Actualizar totalVentas del turno
    batch.update(_turnos(negocioId).doc(turnoId), {
      'totalVentas': FieldValue.increment(subtotal),
    });

    // 5. Descontar stock si físico
    if (producto.esFisico) {
      batch.update(
        _db
            .collection('negocios')
            .doc(negocioId)
            .collection('productos')
            .doc(producto.id),
        {'stockActual': FieldValue.increment(-cantidad)},
      );
    }

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // ELIMINAR CONSUMO (producto equivocado)
  // ─────────────────────────────────────────────

  Future<void> eliminarConsumo({
    required String negocioId,
    required String clienteId,
    required String turnoId,
    required ConsumoModel consumo,
  }) async {
    final batch = _db.batch();

    // 1. Borrar consumo
    batch.delete(
      _col(negocioId).doc(clienteId).collection('consumos').doc(consumo.id),
    );

    // 2. Borrar venta permanente (se revierte la venta)
    if (consumo.ventaId.isNotEmpty) {
      batch.delete(_ventas(negocioId).doc(consumo.ventaId));
    }

    // 3. Restar del total del cliente
    batch.update(_col(negocioId).doc(clienteId), {
      'totalCuenta': FieldValue.increment(-consumo.subtotal),
    });

    // 4. Restar del totalVentas del turno
    batch.update(_turnos(negocioId).doc(turnoId), {
      'totalVentas': FieldValue.increment(-consumo.subtotal),
    });

    // 5. Devolver stock si físico
    if (consumo.esFisico) {
      batch.update(
        _db
            .collection('negocios')
            .doc(negocioId)
            .collection('productos')
            .doc(consumo.productoId),
        {'stockActual': FieldValue.increment(consumo.cantidad)},
      );
    }

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // COBRAR Y ELIMINAR (las ventas quedan para reportes)
  // ─────────────────────────────────────────────

  Future<void> cobrarYEliminar(String negocioId, String clienteId,
      String turnoId) async {
    final consumosSnap = await _col(negocioId)
        .doc(clienteId)
        .collection('consumos')
        .get();

    final batch = _db.batch();

    // Borrar consumos operativos (las ventas permanentes se conservan)
    for (final doc in consumosSnap.docs) {
      batch.delete(doc.reference);
    }

    // Borrar cliente
    batch.delete(_col(negocioId).doc(clienteId));

    // Sumar cliente atendido al turno
    batch.update(_turnos(negocioId).doc(turnoId), {
      'clientesAtendidos': FieldValue.increment(1),
    });

    await batch.commit();
    // Liberar mesa si el cliente tenía una asignada
    await MesaService().liberarMesaPorCliente(negocioId, clienteId);
  }

  // ─────────────────────────────────────────────
  // ELIMINAR CLIENTE (sin cobrar — revierte ventas)
  // ─────────────────────────────────────────────

  Future<void> eliminarCliente(String negocioId, String clienteId,
      String turnoId, double totalCuenta) async {
    final consumosSnap = await _col(negocioId)
        .doc(clienteId)
        .collection('consumos')
        .get();

    final batch = _db.batch();

    for (final doc in consumosSnap.docs) {
      batch.delete(doc.reference);
      // Borrar venta permanente también (no se cobró)
      final ventaId =
          (doc.data())['ventaId'] as String? ?? '';
      if (ventaId.isNotEmpty) {
        batch.delete(_ventas(negocioId).doc(ventaId));
      }
    }

    batch.delete(_col(negocioId).doc(clienteId));

    // Revertir totalVentas del turno
    if (totalCuenta > 0) {
      batch.update(_turnos(negocioId).doc(turnoId), {
        'totalVentas': FieldValue.increment(-totalCuenta),
      });
    }

    await batch.commit();
    // Liberar mesa si el cliente tenía una asignada
    await MesaService().liberarMesaPorCliente(negocioId, clienteId);
  }
}
