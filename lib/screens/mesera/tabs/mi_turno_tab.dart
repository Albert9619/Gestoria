import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/cliente_model.dart';
import '../../../models/turno_model.dart';
import '../../../services/cliente_service.dart';
import '../../../services/turno_service.dart';
import '../../../widgets/widgets.dart';

class MiTurnoTab extends StatelessWidget {
  final String negocioId;
  final String turnoId;

  const MiTurnoTab({
    super.key,
    required this.negocioId,
    required this.turnoId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TurnoModel?>(
      stream: TurnoService().streamTurnoPorId(negocioId, turnoId),
      builder: (context, turnoSnap) {
        return StreamBuilder<List<ClienteModel>>(
          stream: ClienteService().getClientesTurno(negocioId, turnoId),
          builder: (context, clientesSnap) {
            final turno = turnoSnap.data;
            final clientes = clientesSnap.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Card turno activo
                Card(
                  color: AppColors.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.circle,
                                size: 10, color: Color(0xFF86EFAC)),
                            SizedBox(width: 6),
                            Text(
                              'Turno en curso',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          turno != null
                              ? DateFormat('HH:mm').format(turno.inicio)
                              : '--:--',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          turno != null
                              ? DateFormat('dd/MM/yyyy').format(turno.inicio)
                              : '',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SectionHeader(title: 'CLIENTES EN ESPERA'),

                // Contadores
                Row(
                  children: [
                    Expanded(
                      child: _ResumenCard(
                        icon: Icons.people_outline,
                        label: 'Con cuenta abierta',
                        valor: '${clientes.length}',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (clientes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      icon: Icons.people_outline,
                      message: 'Sin clientes activos',
                      subMessage:
                          'Los clientes que agregues aparecerán aquí',
                    ),
                  )
                else ...[
                  const SizedBox(height: 4),
                  ...clientes.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ClienteResumenItem(cliente: c),
                      )),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA RESUMEN
// ─────────────────────────────────────────────
class _ResumenCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color color;

  const _ResumenCard({
    required this.icon,
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ITEM CLIENTE
// ─────────────────────────────────────────────
class _ClienteResumenItem extends StatelessWidget {
  final ClienteModel cliente;
  const _ClienteResumenItem({required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            cliente.nombre.isNotEmpty
                ? cliente.nombre[0].toUpperCase()
                : 'C',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          cliente.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: Text(
          formatCOP(cliente.totalCuenta),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
