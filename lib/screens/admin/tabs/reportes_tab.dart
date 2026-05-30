import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme.dart';
import '../../../models/turno_model.dart';
import '../../../services/reporte_service.dart';
import '../../../widgets/widgets.dart';

class ReportesTab extends StatefulWidget {
  final String negocioId;
  final String negocioNombre;

  const ReportesTab({
    super.key,
    required this.negocioId,
    required this.negocioNombre,
  });

  @override
  State<ReportesTab> createState() => _ReportesTabState();
}

class _ReportesTabState extends State<ReportesTab> {
  DateTime _fecha = DateTime.now();
  ReporteData? _reporte;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r =
          await ReporteService().getReporte(widget.negocioId, _fecha);
      if (mounted) setState(() => _reporte = r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (picked != null && picked != _fecha) {
      setState(() => _fecha = picked);
      _cargar();
    }
  }

  static const _channel = MethodChannel('gestoria/pdf_share');

  Future<void> _exportarPdf() async {
    if (_reporte == null) return;

    // Mostrar loading
    setState(() => _cargando = true);
    try {
      final bytes = await _generarPdf(_reporte!, widget.negocioNombre);
      final fmt = DateFormat('dd-MM-yyyy');
      final nombre = 'reporte_${fmt.format(_fecha)}.pdf';

      // Llama al código nativo Android que guarda en Descargas y abre el share
      await _channel.invokeMethod('compartirPdf', {
        'bytes': bytes,
        'nombre': nombre,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmtFecha = DateFormat("EEEE d 'de' MMMM 'de' yyyy", 'es');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Selector de fecha
          Container(
            color: AppColors.surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fmtFecha.format(_fecha),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _elegirFecha,
                  child: const Text('Cambiar'),
                ),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style:
                                const TextStyle(color: AppColors.error)))
                    : _reporte == null || _reporte!.sinDatos
                        ? const EmptyState(
                            icon: Icons.bar_chart_outlined,
                            message: 'Sin datos para este día',
                            subMessage:
                                'Selecciona otra fecha o espera a que haya ventas',
                          )
                        : _Contenido(reporte: _reporte!),
          ),
        ],
      ),
      floatingActionButton: _reporte != null && !_reporte!.sinDatos
          ? FloatingActionButton.extended(
              onPressed: _exportarPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Exportar PDF'),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────
// CONTENIDO DEL REPORTE
// ─────────────────────────────────────────────
class _Contenido extends StatelessWidget {
  final ReporteData reporte;
  const _Contenido({required this.reporte});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // 1. Resumen total
        _seccion('RESUMEN DEL DÍA'),
        _ResumenCard(reporte: reporte),
        const SizedBox(height: 8),

        // 2. Por mesera
        if (reporte.porMesera.isNotEmpty) ...[
          _seccion('VENTAS POR MESERA'),
          ...reporte.porMesera.map((m) => _MeseraItem(m: m)),
          const SizedBox(height: 8),
        ],

        // 3. Top productos
        if (reporte.topProductos.isNotEmpty) ...[
          _seccion('PRODUCTOS MÁS VENDIDOS'),
          ...reporte.topProductos
              .take(10)
              .toList()
              .asMap()
              .entries
              .map((e) => _ProductoItem(pos: e.key + 1, p: e.value)),
          const SizedBox(height: 8),
        ],

        // 4. Turnos
        if (reporte.turnos.isNotEmpty) ...[
          _seccion('DETALLE DE TURNOS'),
          ...reporte.turnos.map((t) => _TurnoItem(turno: t)),
        ],
      ],
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _ResumenCard extends StatelessWidget {
  final ReporteData reporte;
  const _ResumenCard({required this.reporte});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total vendido',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              formatCOP(reporte.totalVentas),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Divider(color: Colors.white24, height: 24),
            Row(
              children: [
                _stat('Clientes atendidos',
                    '${reporte.totalClientesAtendidos}'),
                const SizedBox(width: 32),
                _stat('Turnos del día', '${reporte.totalTurnos}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
        ],
      );
}

class _MeseraItem extends StatelessWidget {
  final ReporteMesera m;
  const _MeseraItem({required this.m});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            m.nombre.isNotEmpty ? m.nombre[0].toUpperCase() : 'M',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(m.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${m.clientesAtendidos} clientes atendidos',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing: Text(
          formatCOP(m.totalVentas),
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ProductoItem extends StatelessWidget {
  final int pos;
  final ReporteProducto p;
  const _ProductoItem({required this.pos, required this.p});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: pos <= 3
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.divider,
          child: Text(
            '#$pos',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color:
                  pos <= 3 ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
        title: Text(p.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(formatCOP(p.totalVentas),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${p.cantidad} uds',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _TurnoItem extends StatelessWidget {
  final TurnoModel turno;
  const _TurnoItem({required this.turno});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    final diferencia = turno.diferencia ?? 0;
    final diferenciaColor = diferencia > 0
        ? AppColors.error
        : diferencia < 0
            ? AppColors.success
            : AppColors.textSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    turno.mesera,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                EstadoChip(
                  label: turno.estaActivo ? 'Activo' : 'Cerrado',
                  color: turno.estaActivo
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _dato('Inicio', fmt.format(turno.inicio)),
                if (turno.fin != null)
                  _dato('Fin', fmt.format(turno.fin!)),
                _dato('Clientes', '${turno.clientesAtendidos}'),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                _dato('Ventas', formatCOP(turno.totalVentas)),
                _dato('Base', formatCOP(turno.base)),
                if (turno.totalEntregado != null)
                  _dato('Entregó', formatCOP(turno.totalEntregado!)),
                if (turno.diferencia != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diferencia',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                      Text(
                        diferencia == 0
                            ? 'Cuadra ✓'
                            : diferencia > 0
                                ? '-${formatCOP(diferencia)}'
                                : '+${formatCOP(diferencia.abs())}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: diferenciaColor),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════
// GENERADOR DE PDF — DISEÑO PREMIUM GESTORIA
// ═══════════════════════════════════════════════════════════
Future<Uint8List> _generarPdf(ReporteData r, String negocioNombre) async {
  final pdf = pw.Document();

  // ── Paleta corporativa ──────────────────────────────────
  final azul    = PdfColor.fromHex('#0D3B66');
  final azulMed = PdfColor.fromHex('#1A5276');
  final verde   = PdfColor.fromHex('#4CAF50');
  final rojo    = PdfColor.fromHex('#E53935');
  final fondo   = PdfColor.fromHex('#F5F7FA');
  final gris    = PdfColor.fromHex('#6B7280');
  final linea   = PdfColor.fromHex('#E2E8F0');
  const blanco  = PdfColors.white;

  // ── Formatos ────────────────────────────────────────────
  final cop  = NumberFormat('\$#,##0', 'es_CO'); // → $59.000
  final hora = DateFormat('HH:mm');
  final fmtFecha   = DateFormat("d 'de' MMMM yyyy", 'es').format(r.fecha);
  final fmtGen     = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

  // ── Métricas derivadas ──────────────────────────────────
  final ticket = r.totalClientesAtendidos > 0
      ? r.totalVentas / r.totalClientesAtendidos
      : 0.0;
  final maxVenta = r.porMesera.isNotEmpty
      ? r.porMesera.map((m) => m.totalVentas).reduce((a, b) => a > b ? a : b)
      : 1.0;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => [

        // ╔══════════════════════════════════════════════╗
        // ║  HEADER  — banda azul oscura de ancho total  ║
        // ╚══════════════════════════════════════════════╝
        pw.Container(
          color: azul,
          padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Marca
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('GESTORIA',
                      style: pw.TextStyle(
                          color: blanco, fontSize: 28,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  pw.Text('Gestiona mejor. Crece más.',
                      style: pw.TextStyle(
                          color: PdfColor(0.9, 0.9, 0.9), fontSize: 10)),
                ],
              ),
              // Info negocio
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(negocioNombre.toUpperCase(),
                      style: pw.TextStyle(
                          color: blanco, fontSize: 13,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(fmtFecha,
                      style: pw.TextStyle(
                          color: PdfColor(0.8, 0.8, 0.8), fontSize: 10)),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColor(1, 1, 1, 0.15),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text('REPORTE DIARIO',
                        style: pw.TextStyle(
                            color: blanco, fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ╔══════════════════════════════════════════════╗
        // ║  KPI — 4 tarjetas de métricas principales    ║
        // ╚══════════════════════════════════════════════╝
        pw.Container(
          color: fondo,
          padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pdfLabel('RESUMEN EJECUTIVO', azul),
              pw.SizedBox(height: 14),
              pw.Row(
                children: [
                  // Total vendido — card principal grande
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(20),
                      decoration: pw.BoxDecoration(
                        color: azul,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('TOTAL VENDIDO',
                              style: pw.TextStyle(
                                  color: PdfColor(0.7, 0.85, 1),
                                  fontSize: 8, letterSpacing: 1.2)),
                          pw.SizedBox(height: 8),
                          pw.Text(cop.format(r.totalVentas),
                              style: pw.TextStyle(
                                  color: blanco, fontSize: 30,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text('Ingresos del día',
                              style: pw.TextStyle(
                                  color: PdfColor(0.7, 0.85, 1),
                                  fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // 3 cards secundarias
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      children: [
                        _pdfKpiSmall('Clientes atendidos',
                            '${r.totalClientesAtendidos}',
                            azul, fondo, linea),
                        pw.SizedBox(height: 10),
                        _pdfKpiSmall('Turnos del día',
                            '${r.totalTurnos}',
                            azul, fondo, linea),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(14),
                          decoration: pw.BoxDecoration(
                            color: verde,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Ticket promedio',
                                  style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 8, letterSpacing: 0.5)),
                              pw.SizedBox(height: 4),
                              pw.Text(cop.format(ticket),
                                  style: pw.TextStyle(
                                      color: blanco, fontSize: 15,
                                      fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ╔══════════════════════════════════════════════╗
        // ║  VENTAS POR MESERA                           ║
        // ╚══════════════════════════════════════════════╝
        if (r.porMesera.isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfLabel('RENDIMIENTO POR MESERA', azul),
                pw.SizedBox(height: 14),
                // Encabezado tabla
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: azul,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3,
                          child: _pdfTh('MESERA')),
                      pw.Expanded(flex: 2,
                          child: _pdfTh('CLIENTES', center: true)),
                      pw.Expanded(flex: 2,
                          child: _pdfTh('TOTAL VENDIDO', right: true)),
                      pw.Expanded(flex: 3,
                          child: _pdfTh('RENDIMIENTO', center: true)),
                    ],
                  ),
                ),
                // Filas
                ...r.porMesera.asMap().entries.map((e) {
                  final m = e.value;
                  final par = e.key.isEven;
                  final pct = maxVenta > 0 ? m.totalVentas / maxVenta : 0.0;
                  return pw.Container(
                    color: par ? blanco : fondo,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 3,
                            child: pw.Text(m.nombre,
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: azul))),
                        pw.Expanded(flex: 2,
                            child: pw.Center(
                                child: pw.Text('${m.clientesAtendidos}',
                                    style: pw.TextStyle(
                                        fontSize: 10, color: gris)))),
                        pw.Expanded(flex: 2,
                            child: pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(cop.format(m.totalVentas),
                                    style: pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold)))),
                        pw.Expanded(flex: 3,
                            child: pw.Padding(
                              padding:
                                  const pw.EdgeInsets.only(left: 12),
                              child: pw.LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final total =
                                      constraints?.maxWidth ?? 100.0;
                                  final filled = total * pct;
                                  final empty  = total - filled;
                                  return pw.Row(
                                    children: [
                                      pw.Container(
                                        width: filled.clamp(0, total),
                                        height: 8,
                                        decoration: pw.BoxDecoration(
                                          color: verde,
                                          borderRadius:
                                              pw.BorderRadius.circular(
                                                  4),
                                        ),
                                      ),
                                      if (empty > 0)
                                        pw.Container(
                                          width: empty,
                                          height: 8,
                                          decoration: pw.BoxDecoration(
                                            color: linea,
                                            borderRadius:
                                                pw.BorderRadius
                                                    .circular(4),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            )),
                      ],
                    ),
                  );
                }),
                // Borde inferior redondeado
                pw.Container(
                  height: 2,
                  decoration: pw.BoxDecoration(
                    color: linea,
                    borderRadius: const pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(8),
                      bottomRight: pw.Radius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ╔══════════════════════════════════════════════╗
        // ║  PRODUCTOS MÁS VENDIDOS                      ║
        // ╚══════════════════════════════════════════════╝
        if (r.topProductos.isNotEmpty) ...[
          pw.Container(
            color: fondo,
            padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfLabel('PRODUCTOS MÁS VENDIDOS', azul),
                pw.SizedBox(height: 14),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: azul,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(width: 28),
                      pw.Expanded(flex: 4, child: _pdfTh('PRODUCTO')),
                      pw.Expanded(flex: 2,
                          child: _pdfTh('UNIDADES', center: true)),
                      pw.Expanded(flex: 2,
                          child: _pdfTh('TOTAL', right: true)),
                    ],
                  ),
                ),
                ...r.topProductos.take(10).toList().asMap().entries.map((e) {
                  final p = e.value;
                  final pos = e.key + 1;
                  final par = e.key.isEven;
                  final badgeColor = pos == 1
                      ? PdfColor.fromHex('#F59E0B')
                      : pos == 2
                          ? PdfColor.fromHex('#9CA3AF')
                          : pos == 3
                              ? PdfColor.fromHex('#B45309')
                              : fondo;
                  return pw.Container(
                    color: par ? blanco : fondo,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 22,
                          height: 22,
                          decoration: pw.BoxDecoration(
                            color: pos <= 3 ? badgeColor : linea,
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Center(
                            child: pw.Text('#$pos',
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: pos <= 3 ? blanco : gris)),
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Expanded(flex: 4,
                            child: pw.Text(p.nombre,
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Expanded(flex: 2,
                            child: pw.Center(
                                child: pw.Text('${p.cantidad} uds',
                                    style: pw.TextStyle(
                                        fontSize: 10, color: gris)))),
                        pw.Expanded(flex: 2,
                            child: pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(cop.format(p.totalVentas),
                                    style: pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold,
                                        color: azul)))),
                      ],
                    ),
                  );
                }),
                pw.Container(
                  height: 2,
                  decoration: pw.BoxDecoration(
                    color: linea,
                    borderRadius: const pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(8),
                      bottomRight: pw.Radius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ╔══════════════════════════════════════════════╗
        // ║  DETALLE DE TURNOS                           ║
        // ╚══════════════════════════════════════════════╝
        if (r.turnos.isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfLabel('DETALLE DE TURNOS', azul),
                pw.SizedBox(height: 14),
                ...r.turnos.map((t) {
                  final dif    = t.diferencia ?? 0;
                  final difCol = dif > 0 ? rojo : dif < 0 ? verde : verde;
                  final difTxt = dif == 0
                      ? 'Cuadra exacto ✓'
                      : dif > 0
                          ? 'Faltante: ${cop.format(dif)}'
                          : 'Sobrante: ${cop.format(dif.abs())}';
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: linea, width: 1),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      children: [
                        // Cabecera tarjeta turno
                        pw.Container(
                          decoration: pw.BoxDecoration(
                            color: azulMed,
                            borderRadius: const pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(9),
                              topRight: pw.Radius.circular(9),
                            ),
                          ),
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(t.mesera,
                                  style: pw.TextStyle(
                                      color: blanco, fontSize: 12,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: pw.BoxDecoration(
                                  color: t.estaActivo
                                      ? verde
                                      : PdfColor(1, 1, 1, 0.2),
                                  borderRadius:
                                      pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                    t.estaActivo ? 'ACTIVO' : 'CERRADO',
                                    style: pw.TextStyle(
                                        color: blanco, fontSize: 8,
                                        fontWeight: pw.FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        // Cuerpo tarjeta turno
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(16),
                          child: pw.Column(
                            children: [
                              // Fila horario
                              pw.Row(
                                children: [
                                  _pdfDato('Inicio',
                                      hora.format(t.inicio), gris),
                                  if (t.fin != null)
                                    _pdfDato('Fin',
                                        hora.format(t.fin!), gris),
                                  _pdfDato('Clientes',
                                      '${t.clientesAtendidos}', gris),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Container(
                                  height: 1, color: linea),
                              pw.SizedBox(height: 10),
                              // Fila financiera
                              pw.Row(
                                children: [
                                  _pdfDato('Ventas',
                                      cop.format(t.totalVentas), azul,
                                      bold: true),
                                  _pdfDato('Base',
                                      cop.format(t.base), gris),
                                  if (t.totalEntregado != null)
                                    _pdfDato('Entregó',
                                        cop.format(t.totalEntregado!),
                                        gris),
                                  if (t.diferencia != null)
                                    _pdfDato('Diferencia', difTxt,
                                        difCol, bold: true),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // ╔══════════════════════════════════════════════╗
        // ║  FOOTER                                      ║
        // ╚══════════════════════════════════════════════╝
        pw.Container(
          color: azul,
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 36, vertical: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('GESTORIA',
                      style: pw.TextStyle(
                          color: blanco, fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5)),
                  pw.Text('Gestiona mejor. Crece más.',
                      style: pw.TextStyle(
                          color: PdfColor(0.7, 0.8, 0.9), fontSize: 8)),
                ],
              ),
              pw.Text('Generado el $fmtGen',
                  style: pw.TextStyle(
                      color: PdfColor(0.7, 0.8, 0.9), fontSize: 8)),
            ],
          ),
        ),
      ],
    ),
  );

  return pdf.save();
}

// ── Helpers de diseño ────────────────────────────────────

pw.Widget _pdfLabel(String text, PdfColor azul) => pw.Row(
      children: [
        pw.Container(
          width: 4, height: 14,
          decoration: pw.BoxDecoration(
            color: azul,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(text,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: azul,
                letterSpacing: 1.5)),
      ],
    );

pw.Widget _pdfKpiSmall(
    String label, String value, PdfColor textColor,
    PdfColor bg, PdfColor borde) =>
    pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: borde, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  color: PdfColor.fromHex('#6B7280'),
                  fontSize: 8, letterSpacing: 0.5)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  color: textColor, fontSize: 18,
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

pw.Widget _pdfTh(String text,
        {bool center = false, bool right = false}) =>
    pw.Align(
      alignment: right
          ? pw.Alignment.centerRight
          : center
              ? pw.Alignment.center
              : pw.Alignment.centerLeft,
      child: pw.Text(text,
          style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.8)),
    );

pw.Widget _pdfDato(String label, String value, PdfColor color,
        {bool bold = false}) =>
    pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 8, color: PdfColor.fromHex('#6B7280'))),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
