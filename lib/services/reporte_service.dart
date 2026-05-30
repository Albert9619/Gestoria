import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/turno_model.dart';
import '../models/venta_model.dart';

// ─────────────────────────────────────────────
// MODELOS DE DATOS PARA REPORTES
// ─────────────────────────────────────────────

class ReporteMesera {
  final String nombre;
  double totalVentas;
  int clientesAtendidos;

  ReporteMesera({
    required this.nombre,
    this.totalVentas = 0,
    this.clientesAtendidos = 0,
  });
}

class ReporteProducto {
  final String nombre;
  int cantidad;
  double totalVentas;

  ReporteProducto({
    required this.nombre,
    this.cantidad = 0,
    this.totalVentas = 0,
  });
}

class ReporteData {
  final DateTime fecha;
  final double totalVentas;
  final int totalClientesAtendidos;
  final int totalTurnos;
  final List<ReporteMesera> porMesera;
  final List<ReporteProducto> topProductos;
  final List<TurnoModel> turnos;

  ReporteData({
    required this.fecha,
    required this.totalVentas,
    required this.totalClientesAtendidos,
    required this.totalTurnos,
    required this.porMesera,
    required this.topProductos,
    required this.turnos,
  });

  bool get sinDatos => totalVentas == 0 && turnos.isEmpty;
}

// ─────────────────────────────────────────────
// SERVICIO
// ─────────────────────────────────────────────

class ReporteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<ReporteData> getReporte(String negocioId, DateTime fecha) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin =
        DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999);

    // Consultas en paralelo
    final results = await Future.wait([
      _db
          .collection('negocios')
          .doc(negocioId)
          .collection('ventas')
          .where('fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(fin))
          .get(),
      _db
          .collection('negocios')
          .doc(negocioId)
          .collection('turnos')
          .where('inicio',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
          .where('inicio', isLessThanOrEqualTo: Timestamp.fromDate(fin))
          .get(),
    ]);

    final ventas = (results[0] as QuerySnapshot)
        .docs
        .map((d) => VentaModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();

    final turnos = (results[1] as QuerySnapshot)
        .docs
        .map((d) =>
            TurnoModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.inicio.compareTo(a.inicio));

    // Total vendido
    final totalVentas = ventas.fold(0.0, (s, v) => s + v.total);

    // Clientes atendidos (suma de todos los turnos del día)
    final totalClientes =
        turnos.fold(0, (s, t) => s + t.clientesAtendidos);

    // Agrupado por mesera
    final byMesera = <String, ReporteMesera>{};
    for (final v in ventas) {
      byMesera.putIfAbsent(
          v.meseraId, () => ReporteMesera(nombre: v.mesera));
      byMesera[v.meseraId]!.totalVentas += v.total;
    }
    for (final t in turnos) {
      byMesera.putIfAbsent(
          t.meseraId, () => ReporteMesera(nombre: t.mesera));
      byMesera[t.meseraId]!.clientesAtendidos += t.clientesAtendidos;
    }
    final porMesera = byMesera.values.toList()
      ..sort((a, b) => b.totalVentas.compareTo(a.totalVentas));

    // Agrupado por producto
    final byProducto = <String, ReporteProducto>{};
    for (final v in ventas) {
      byProducto.putIfAbsent(
          v.productoNombre, () => ReporteProducto(nombre: v.productoNombre));
      byProducto[v.productoNombre]!.cantidad += v.cantidad;
      byProducto[v.productoNombre]!.totalVentas += v.total;
    }
    final topProductos = byProducto.values.toList()
      ..sort((a, b) => b.cantidad.compareTo(a.cantidad));

    return ReporteData(
      fecha: fecha,
      totalVentas: totalVentas,
      totalClientesAtendidos: totalClientes,
      totalTurnos: turnos.length,
      porMesera: porMesera,
      topProductos: topProductos,
      turnos: turnos,
    );
  }
}
