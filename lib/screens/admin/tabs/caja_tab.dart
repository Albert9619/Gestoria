import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/turno_model.dart';
import '../../../services/turno_service.dart';
import '../../../widgets/widgets.dart';

class CajaTab extends StatefulWidget {
  final String negocioId;
  const CajaTab({super.key, required this.negocioId});

  @override
  State<CajaTab> createState() => _CajaTabState();
}

class _CajaTabState extends State<CajaTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Material(
          color: AppColors.surface,
          elevation: 1,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Turnos activos'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _ResumenDia(negocioId: widget.negocioId),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _TurnosActivos(negocioId: widget.negocioId),
                _HistorialTurnos(negocioId: widget.negocioId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RESUMEN DEL DÍA
// ─────────────────────────────────────────────
class _ResumenDia extends StatelessWidget {
  final String negocioId;
  const _ResumenDia({required this.negocioId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TurnoModel>>(
      stream: TurnoService().getTurnosHoy(negocioId),
      builder: (context, snap) {
        final turnos = snap.data ?? [];

        final totalVendido =
            turnos.fold<double>(0, (s, t) => s + t.totalVentas);
        final cerrados = turnos.where((t) => t.estaCerrado).toList();
        final activos = turnos.where((t) => t.estaActivo).toList();
        final totalRecaudado =
            cerrados.fold<double>(0, (s, t) => s + (t.totalEntregado ?? 0));

        final hoy =
            DateFormat("d 'de' MMMM", 'es').format(DateTime.now());

        return Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fecha
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'Hoy, $hoy',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  // chips de conteo
                  if (activos.isNotEmpty)
                    _chip(
                      '${activos.length} activo${activos.length != 1 ? 's' : ''}',
                      AppColors.success,
                      Icons.radio_button_checked,
                    ),
                  if (activos.isNotEmpty && cerrados.isNotEmpty)
                    const SizedBox(width: 6),
                  if (cerrados.isNotEmpty)
                    _chip(
                      '${cerrados.length} cerrado${cerrados.length != 1 ? 's' : ''}',
                      AppColors.textSecondary,
                      Icons.check_circle_outline,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // KPIs
              Row(
                children: [
                  _kpi(
                    label: 'Vendido hoy',
                    value: formatCOP(totalVendido),
                    icon: Icons.trending_up_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  _kpi(
                    label: 'Recaudado',
                    value: formatCOP(totalRecaudado),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.success,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kpi({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TURNOS ACTIVOS
// ─────────────────────────────────────────────
class _TurnosActivos extends StatelessWidget {
  final String negocioId;
  const _TurnosActivos({required this.negocioId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TurnoModel>>(
      stream: TurnoService().getTurnosActivos(negocioId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final turnos = snap.data ?? [];

        if (turnos.isEmpty) {
          return const EmptyState(
            icon: Icons.point_of_sale_outlined,
            message: 'No hay turnos activos',
            subMessage: 'Cuando una mesera inicie sesión, aparecerá aquí',
          );
        }

        // Resumen total
        final totalVentas =
            turnos.fold<double>(0, (sum, t) => sum + t.totalVentas);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card resumen
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total en turno',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCOP(totalVentas),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${turnos.length} mesera${turnos.length != 1 ? 's' : ''} activa${turnos.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            ...turnos.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TurnoActivoCard(turno: t, negocioId: negocioId),
                )),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE TURNO ACTIVO
// ─────────────────────────────────────────────
class _TurnoActivoCard extends StatelessWidget {
  final TurnoModel turno;
  final String negocioId;

  const _TurnoActivoCard({required this.turno, required this.negocioId});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                  child: Text(
                    turno.mesera.isNotEmpty
                        ? turno.mesera[0].toUpperCase()
                        : 'M',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        turno.mesera,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Desde las ${fmt.format(turno.inicio)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                EstadoChip(label: 'Activo', color: AppColors.success),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            InfoRow(
              label: 'Base asignada',
              value: formatCOP(turno.base),
            ),
            InfoRow(
              label: 'Total vendido',
              value: formatCOP(turno.totalVentas),
              valueColor: AppColors.primary,
            ),
            InfoRow(
              label: 'Debe entregar',
              value: formatCOP(turno.debeEntregar),
              valueColor: AppColors.textPrimary,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _asignarBase(context),
                    icon: const Icon(Icons.account_balance_wallet_outlined,
                        size: 18),
                    label: const Text('Asignar base'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _cobrarYCerrar(context),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Cobrar y cerrar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _asignarBase(BuildContext context) {
    final ctrl = TextEditingController(
        text: turno.base > 0 ? turno.base.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Base para ${turno.mesera}'),
        content: TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Dinero base entregado',
            prefixText: '\$ ',
            helperText: 'El dinero que le das para dar cambio',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              final val = double.tryParse(ctrl.text) ?? 0;
              await TurnoService().asignarBase(negocioId, turno.id, val);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _cobrarYCerrar(BuildContext context) {
    final ctrl = TextEditingController();
    final notaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final entregado = double.tryParse(ctrl.text) ?? 0;
          final diferencia = turno.debeEntregar - entregado;

          return AlertDialog(
            title: Text('Cobro de ${turno.mesera}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Resumen
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      InfoRow(
                          label: 'Ventas del turno',
                          value: formatCOP(turno.totalVentas)),
                      InfoRow(
                          label: 'Base asignada',
                          value: formatCOP(turno.base)),
                      const Divider(),
                      InfoRow(
                        label: 'Debe entregar',
                        value: formatCOP(turno.debeEntregar),
                        valueColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Total que entregó',
                    prefixText: '\$ ',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (ctrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: diferencia > 0
                          ? AppColors.error.withValues(alpha: 0.08)
                          : diferencia < 0
                              ? AppColors.success.withValues(alpha: 0.08)
                              : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          diferencia > 0
                              ? 'Faltante'
                              : diferencia < 0
                                  ? 'Sobrante'
                                  : 'Cuadre exacto',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: diferencia > 0
                                ? AppColors.error
                                : diferencia < 0
                                    ? AppColors.success
                                    : AppColors.primary,
                          ),
                        ),
                        Text(
                          formatCOP(diferencia.abs()),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: diferencia > 0
                                ? AppColors.error
                                : diferencia < 0
                                    ? AppColors.success
                                    : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: notaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    hintText: 'Ej: Faltaron \$5000 por cambio',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                onPressed: ctrl.text.isEmpty
                    ? null
                    : () async {
                        final totalEntregado =
                            double.tryParse(ctrl.text) ?? 0;
                        await TurnoService().cerrarTurno(
                          negocioId: negocioId,
                          turnoId: turno.id,
                          totalEntregado: totalEntregado,
                          debeEntregar: turno.debeEntregar,
                          nota: notaCtrl.text.trim().isEmpty
                              ? null
                              : notaCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                child: const Text('Cerrar turno'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HISTORIAL DE TURNOS
// ─────────────────────────────────────────────
class _HistorialTurnos extends StatelessWidget {
  final String negocioId;
  const _HistorialTurnos({required this.negocioId});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return StreamBuilder<List<TurnoModel>>(
      stream: TurnoService().getHistorial(negocioId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final turnos = snap.data ?? [];

        if (turnos.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            message: 'Sin turnos cerrados',
            subMessage: 'Los turnos cobrados aparecerán aquí',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: turnos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final t = turnos[i];
            final dif = t.diferencia ?? 0;

            return Card(
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.background,
                  child: Text(
                    t.mesera.isNotEmpty ? t.mesera[0].toUpperCase() : 'M',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(
                  t.mesera,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  fmt.format(t.inicio),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCOP(t.totalVentas),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      dif > 0
                          ? '-${formatCOP(dif)}'
                          : dif < 0
                              ? '+${formatCOP(dif.abs())}'
                              : 'Cuadre exacto',
                      style: TextStyle(
                        fontSize: 11,
                        color: dif > 0
                            ? AppColors.error
                            : dif < 0
                                ? AppColors.success
                                : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(),
                        InfoRow(
                            label: 'Base asignada',
                            value: formatCOP(t.base)),
                        InfoRow(
                            label: 'Ventas',
                            value: formatCOP(t.totalVentas)),
                        InfoRow(
                            label: 'Debía entregar',
                            value: formatCOP(t.debeEntregar)),
                        InfoRow(
                          label: 'Entregó',
                          value: formatCOP(t.totalEntregado ?? 0),
                          valueColor: AppColors.primary,
                        ),
                        if (dif != 0)
                          InfoRow(
                            label: dif > 0 ? 'Faltante' : 'Sobrante',
                            value: formatCOP(dif.abs()),
                            valueColor: dif > 0
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        if (t.nota != null && t.nota!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Nota: ${t.nota}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
