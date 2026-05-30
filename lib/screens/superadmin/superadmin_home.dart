import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/negocio_model.dart';
import '../../services/superadmin_service.dart';
import '../../widgets/widgets.dart';

class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestoria Admin',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            Text(
              'Panel de control',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<NegocioModel>>(
        stream: SuperAdminService().getNegociosStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final negocios = snap.data ?? [];

          if (negocios.isEmpty) {
            return const EmptyState(
              icon: Icons.store_outlined,
              message: 'Sin negocios registrados',
              subMessage: 'Los negocios aparecerán aquí al registrarse',
            );
          }

          // Resumen en la parte superior
          final activos =
              negocios.where((n) => n.suscripcionVigente).length;
          final vencidos = negocios.length - activos;

          return Column(
            children: [
              _ResumenBar(
                  total: negocios.length,
                  activos: activos,
                  vencidos: vencidos),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: negocios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _NegocioCard(
                    negocio: negocios[i],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BARRA DE RESUMEN
// ─────────────────────────────────────────────
class _ResumenBar extends StatelessWidget {
  final int total;
  final int activos;
  final int vencidos;

  const _ResumenBar(
      {required this.total,
      required this.activos,
      required this.vencidos});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _Chip(label: '$total negocios', color: AppColors.textSecondary),
          const SizedBox(width: 8),
          _Chip(label: '$activos activos', color: AppColors.success),
          if (vencidos > 0) ...[
            const SizedBox(width: 8),
            _Chip(label: '$vencidos vencidos', color: AppColors.error),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE NEGOCIO
// ─────────────────────────────────────────────
class _NegocioCard extends StatelessWidget {
  final NegocioModel negocio;
  const _NegocioCard({required this.negocio});

  @override
  Widget build(BuildContext context) {
    final dias = negocio.diasRestantes;
    final vigente = negocio.suscripcionVigente;

    Color diasColor;
    String diasLabel;
    if (!negocio.activo) {
      diasColor = AppColors.textSecondary;
      diasLabel = 'Bloqueado';
    } else if (!vigente) {
      diasColor = AppColors.error;
      diasLabel = 'Vencido';
    } else if (dias <= 7) {
      diasColor = const Color(0xFFD97706);
      diasLabel = '$dias días';
    } else {
      diasColor = AppColors.success;
      diasLabel = '$dias días';
    }

    return Card(
      child: ListTile(
        onTap: () => _mostrarDetalle(context),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: vigente
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.divider,
          child: Text(
            negocio.nombre.isNotEmpty
                ? negocio.nombre[0].toUpperCase()
                : 'N',
            style: TextStyle(
              color: vigente ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          negocio.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(negocio.email,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            Text('Código: ${negocio.codigo}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: diasColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                diasLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: diasColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              negocio.plan,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NegocioDetalleSheet(negocio: negocio),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET: DETALLE Y ACCIONES
// ─────────────────────────────────────────────
class _NegocioDetalleSheet extends StatefulWidget {
  final NegocioModel negocio;
  const _NegocioDetalleSheet({required this.negocio});

  @override
  State<_NegocioDetalleSheet> createState() => _NegocioDetalleSheetState();
}

class _NegocioDetalleSheetState extends State<_NegocioDetalleSheet> {
  bool _loading = false;
  final _service = SuperAdminService();

  Future<void> _extender(int dias) async {
    setState(() => _loading = true);
    try {
      await _service.extenderSuscripcion(
          widget.negocio.id, dias, widget.negocio.suscripcionHasta);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+$dias días aplicados a ${widget.negocio.nombre}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActivo() async {
    final nuevoEstado = !widget.negocio.activo;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(nuevoEstado ? 'Activar negocio' : 'Bloquear negocio'),
        content: Text(nuevoEstado
            ? '¿Activar acceso a ${widget.negocio.nombre}?'
            : '¿Bloquear el acceso a ${widget.negocio.nombre}? No podrán entrar a la app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  nuevoEstado ? AppColors.success : AppColors.error,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
            child: Text(nuevoEstado ? 'Activar' : 'Bloquear'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    setState(() => _loading = true);
    try {
      await _service.setActivo(widget.negocio.id, nuevoEstado);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy', 'es');
    final n = widget.negocio;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Nombre y estado
          Row(
            children: [
              Expanded(
                child: Text(
                  n.nombre,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: n.activo
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  n.activo ? 'Activo' : 'Bloqueado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: n.activo ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(n.email,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Info
          _InfoRow(label: 'Código', value: n.codigo),
          _InfoRow(label: 'Plan', value: n.plan),
          _InfoRow(
              label: 'Registrado',
              value: fmt.format(n.creadoEn)),
          _InfoRow(
            label: 'Suscripción hasta',
            value: n.suscripcionHasta != null
                ? '${fmt.format(n.suscripcionHasta!)} (${n.diasRestantes >= 0 ? '${n.diasRestantes} días restantes' : 'venció hace ${n.diasRestantes.abs()} días'})'
                : 'Sin fecha',
            valueColor: n.suscripcionVigente
                ? (n.diasRestantes <= 7
                    ? const Color(0xFFD97706)
                    : AppColors.success)
                : AppColors.error,
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Extender suscripción
          const Text(
            'Extender suscripción',
            style:
                TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ExtenderBtn(label: '+30 días', onTap: () => _extender(30)),
                _ExtenderBtn(label: '+90 días', onTap: () => _extender(90)),
                _ExtenderBtn(label: '+6 meses', onTap: () => _extender(180)),
                _ExtenderBtn(label: '+1 año', onTap: () => _extender(365)),
              ],
            ),

          const SizedBox(height: 20),

          // Bloquear / Activar
          OutlinedButton.icon(
            onPressed: _loading ? null : _toggleActivo,
            icon: Icon(
              n.activo ? Icons.block_outlined : Icons.check_circle_outline,
              size: 18,
            ),
            label: Text(n.activo ? 'Bloquear negocio' : 'Activar negocio'),
            style: OutlinedButton.styleFrom(
              foregroundColor: n.activo ? AppColors.error : AppColors.success,
              side: BorderSide(
                  color: n.activo ? AppColors.error : AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtenderBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ExtenderBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
        foregroundColor: AppColors.primary,
      ),
      child: Text(label,
          style:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
