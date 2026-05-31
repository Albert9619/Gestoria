import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/mesa_model.dart';
import '../../../models/turno_model.dart';
import '../../../services/mesa_service.dart';
import '../../../services/turno_service.dart';
import '../../../widgets/widgets.dart';
import 'stock_tab.dart';

class DashboardTab extends StatelessWidget {
  final String negocioId;
  final String adminNombre;
  final ValueChanged<int>? onNavigateTo;

  const DashboardTab({
    super.key,
    required this.negocioId,
    required this.adminNombre,
    this.onNavigateTo,
  });

  String get _saludo {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {},
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _GreetingBanner(
                  saludo: _saludo, nombre: adminNombre),
            ),
            SliverToBoxAdapter(
              child: _VentasSection(negocioId: negocioId),
            ),
            SliverToBoxAdapter(
              child: _MesasSection(negocioId: negocioId),
            ),
            SliverToBoxAdapter(
              child: _TurnosSection(negocioId: negocioId),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BANNER DE BIENVENIDA
// ─────────────────────────────────────────────
class _GreetingBanner extends StatelessWidget {
  final String saludo;
  final String nombre;
  const _GreetingBanner({required this.saludo, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final fecha =
        DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());
    final hora = DateFormat('HH:mm').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3577), Color(0xFF0D2050)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$saludo 👋',
                  style: AppTextStyles.labelMd
                      .copyWith(color: Colors.white.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  nombre.isEmpty ? 'Administrador' : nombre,
                  style: AppTextStyles.titleLg
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  fecha,
                  style: AppTextStyles.labelSm
                      .copyWith(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(hora,
                style: AppTextStyles.kpiSm
                    .copyWith(color: Colors.white, fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECCIÓN VENTAS DEL DÍA
// ─────────────────────────────────────────────
class _VentasSection extends StatelessWidget {
  final String negocioId;
  const _VentasSection({required this.negocioId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TurnoModel>>(
      stream: TurnoService().getTurnosHoy(negocioId),
      builder: (context, snap) {
        final turnos = snap.data ?? [];
        final vendido =
            turnos.fold<double>(0, (s, t) => s + t.totalVentas);
        final recaudado =
            turnos.fold<double>(0, (s, t) => s + (t.totalEntregado ?? 0));
        final activos = turnos.where((t) => t.estaActivo).length;
        final cerrados = turnos.where((t) => t.estaCerrado).length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0,
              AppSpacing.md, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Ventas del día'),
              const SizedBox(height: AppSpacing.xs),
              // Tarjeta grande de ventas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.trending_up_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text('Total vendido',
                            style: AppTextStyles.labelMd),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      formatCOP(vendido),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: 'Recaudado',
                            value: formatCOP(recaudado),
                            color: AppColors.success,
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 32,
                            color: AppColors.divider),
                        Expanded(
                          child: _MiniStat(
                            label: 'Pendiente',
                            value: formatCOP(vendido - recaudado),
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Fila turnos
              Row(
                children: [
                  Expanded(
                    child: _SmallCard(
                      icon: Icons.radio_button_checked,
                      label: 'Turnos activos',
                      value: '$activos',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _SmallCard(
                      icon: Icons.check_circle_outline,
                      label: 'Cerrados hoy',
                      value: '$cerrados',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// SECCIÓN ESTADO DE MESAS
// ─────────────────────────────────────────────
class _MesasSection extends StatelessWidget {
  final String negocioId;
  const _MesasSection({required this.negocioId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MesaModel>>(
      stream: MesaService().getMesas(negocioId),
      builder: (context, snap) {
        final mesas = snap.data ?? [];
        if (mesas.isEmpty) return const SizedBox.shrink();

        final libres = mesas.where((m) => m.estaLibre).length;
        final ocupadas = mesas.where((m) => m.estaOcupada).length;
        final total = mesas.length;
        final pct = total > 0 ? ocupadas / total : 0.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0,
              AppSpacing.md, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Estado de mesas'),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MesaStatusTile(
                            count: libres,
                            label: 'Disponibles',
                            color: AppColors.success,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _MesaStatusTile(
                            count: ocupadas,
                            label: 'Ocupadas',
                            color: AppColors.amber,
                            icon: Icons.people_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Barra de ocupación
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor:
                            AppColors.success.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(
                            pct > 0.7
                                ? AppColors.error
                                : pct > 0.4
                                    ? AppColors.amber
                                    : AppColors.success),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}% ocupación · $total mesas',
                        style: AppTextStyles.labelXs,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// SECCIÓN TURNOS ACTIVOS
// ─────────────────────────────────────────────
class _TurnosSection extends StatelessWidget {
  final String negocioId;
  const _TurnosSection({required this.negocioId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TurnoModel>>(
      stream: TurnoService().getTurnosHoy(negocioId),
      builder: (context, snap) {
        final activos = (snap.data ?? [])
            .where((t) => t.estaActivo)
            .toList();
        if (activos.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0,
              AppSpacing.md, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Turnos activos ahora'),
              const SizedBox(height: AppSpacing.xs),
              ...activos.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _TurnoActivoCard(turno: t),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _TurnoActivoCard extends StatelessWidget {
  final TurnoModel turno;
  const _TurnoActivoCard({required this.turno});

  @override
  Widget build(BuildContext context) {
    final inicial = turno.mesera.isNotEmpty
        ? turno.mesera[0].toUpperCase()
        : 'M';
    final duracion = DateTime.now().difference(turno.inicio);
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes.remainder(60);
    final durStr =
        horas > 0 ? '${horas}h ${minutos}min' : '${minutos}min';

    return AccentCard(
      accentColor: AppColors.success,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.success.withValues(alpha: 0.15),
              child: Text(inicial,
                  style: AppTextStyles.titleSm
                      .copyWith(color: AppColors.success)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(turno.mesera, style: AppTextStyles.titleXs),
                  Text('$durStr · ${turno.clientesAtendidos ?? 0} clientes',
                      style: AppTextStyles.labelSm),
                ],
              ),
            ),
            Text(
              formatCOP(turno.totalVentas),
              style: AppTextStyles.kpiSm
                  .copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACCIONES RÁPIDAS
// ─────────────────────────────────────────────
class _AccionesRapidas extends StatelessWidget {
  final String negocioId;
  final ValueChanged<int>? onNavigateTo;

  const _AccionesRapidas({
    required this.negocioId,
    this.onNavigateTo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Acciones rápidas'),
          const SizedBox(height: AppSpacing.xs),
          // Fila 1
          Row(
            children: [
              Expanded(
                child: _AccionBtn(
                  icon: Icons.table_bar_rounded,
                  label: 'Nueva\nmesa',
                  color: AppColors.primary,
                  onTap: () => onNavigateTo?.call(1),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _AccionBtn(
                  icon: Icons.inventory_2_rounded,
                  label: 'Nuevo\nproducto',
                  color: AppColors.accent,
                  onTap: () => onNavigateTo?.call(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Fila 2
          SizedBox(
            width: double.infinity,
            child: _AccionBtn(
              icon: Icons.add_box_rounded,
              label: 'Registrar entrada de stock',
              color: AppColors.amber,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        _StockQuickScreen(negocioId: negocioId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AccionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md, horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pantalla rápida de stock (acceso desde el Dashboard)
class _StockQuickScreen extends StatelessWidget {
  final String negocioId;
  const _StockQuickScreen({required this.negocioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario / Stock'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A3577), Color(0xFF0F2150)],
            ),
          ),
        ),
      ),
      body: StockTab(negocioId: negocioId, adminNombre: ''),
    );
  }
}


// ─────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: AppTextStyles.titleSm),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          Text(value,
              style:
                  AppTextStyles.kpiSm.copyWith(color: color, fontSize: 15)),
          Text(label, style: AppTextStyles.labelXs),
        ],
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SmallCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTextStyles.kpiSm.copyWith(color: color)),
              Text(label, style: AppTextStyles.labelXs),
            ],
          ),
        ],
      ),
    );
  }
}

class _MesaStatusTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  const _MesaStatusTile(
      {required this.count,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count',
                style: AppTextStyles.kpiSm.copyWith(color: color)),
            Text(label, style: AppTextStyles.labelXs),
          ],
        ),
      ],
    );
  }
}
