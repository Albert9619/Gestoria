import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/cliente_model.dart';
import '../../../models/mesa_model.dart';
import '../../../services/cliente_service.dart';
import '../../../services/mesa_service.dart';
import '../../../widgets/widgets.dart';
import '../cuenta_screen.dart';

class ClientesTab extends StatelessWidget {
  final String negocioId;
  final String turnoId;
  final String meseraId;
  final String meseraNombre;

  const ClientesTab({
    super.key,
    required this.negocioId,
    required this.turnoId,
    required this.meseraId,
    required this.meseraNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<ClienteModel>>(
        stream: ClienteService().getClientesTurno(negocioId, turnoId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: AppColors.error)),
            );
          }

          final clientes = snap.data ?? [];

          if (clientes.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              message: 'No hay clientes en este turno',
              subMessage: 'Toca el botón + para registrar el primero',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: clientes.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) => _ClienteCard(
              cliente: clientes[i],
              negocioId: negocioId,
              turnoId: turnoId,
              meseraId: meseraId,
              meseraNombre: meseraNombre,
            ),
          );
        },
      ),
      floatingActionButton: GradientFAB(
        onPressed: () => _mostrarCrearCliente(context),
        icon: Icons.person_add_outlined,
        label: 'Nuevo cliente',
      ),
    );
  }

  void _mostrarCrearCliente(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CrearClienteSheet(
        negocioId: negocioId,
        turnoId: turnoId,
        meseraId: meseraId,
        meseraNombre: meseraNombre,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE CLIENTE
// ─────────────────────────────────────────────
class _ClienteCard extends StatelessWidget {
  final ClienteModel cliente;
  final String negocioId;
  final String turnoId;
  final String meseraId;
  final String meseraNombre;

  const _ClienteCard({
    required this.cliente,
    required this.negocioId,
    required this.turnoId,
    required this.meseraId,
    required this.meseraNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CuentaScreen(
              negocioId: negocioId,
              turnoId: turnoId,
              meseraId: meseraId,
              meseraNombre: meseraNombre,
              clienteId: cliente.id,
              clienteNombre: cliente.nombre,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              // Avatar inicial
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  cliente.nombre.isNotEmpty
                      ? cliente.nombre[0].toUpperCase()
                      : 'C',
                  style: AppTextStyles.titleSm
                      .copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Nombre y teléfono
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cliente.nombre, style: AppTextStyles.titleXs),
                    if (cliente.telefono.isNotEmpty)
                      Text(cliente.telefono,
                          style: AppTextStyles.labelSm),
                  ],
                ),
              ),
              // Total + flecha
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCOP(cliente.totalCuenta),
                    style: AppTextStyles.kpiSm
                        .copyWith(color: AppColors.primary),
                  ),
                  Text('cuenta', style: AppTextStyles.labelXs),
                ],
              ),
              const SizedBox(width: AppSpacing.xxs),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET: CREAR CLIENTE
// ─────────────────────────────────────────────
class _CrearClienteSheet extends StatefulWidget {
  final String negocioId;
  final String turnoId;
  final String meseraId;
  final String meseraNombre;

  const _CrearClienteSheet({
    required this.negocioId,
    required this.turnoId,
    required this.meseraId,
    required this.meseraNombre,
  });

  @override
  State<_CrearClienteSheet> createState() => _CrearClienteSheetState();
}

class _CrearClienteSheetState extends State<_CrearClienteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _loading = false;
  List<MesaModel> _mesasLibres = [];
  MesaModel? _mesaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarMesas();
  }

  Future<void> _cargarMesas() async {
    final mesas =
        await MesaService().getMesasLibres(widget.negocioId).first;
    if (mounted) setState(() => _mesasLibres = mesas);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final clienteId = await ClienteService().crearCliente(
        negocioId: widget.negocioId,
        turnoId: widget.turnoId,
        nombre: _nombreCtrl.text,
        telefono: _telefonoCtrl.text,
        creadoPor: widget.meseraNombre,
        creadoPorId: widget.meseraId,
      );
      // Asignar mesa si se seleccionó una
      if (_mesaSeleccionada != null) {
        await MesaService().ocuparMesa(
          negocioId: widget.negocioId,
          mesaId: _mesaSeleccionada!.id,
          clienteId: clienteId,
          clienteNombre: _nombreCtrl.text.trim(),
          turnoId: widget.turnoId,
          meseraId: widget.meseraId,
          meseraNombre: widget.meseraNombre,
        );
      }
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text(
              'Nuevo cliente',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _nombreCtrl,
              label: 'Nombre',
              prefixIcon: const Icon(Icons.person_outline),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _telefonoCtrl,
              label: 'Teléfono (opcional)',
              hint: 'Ej: 3001234567',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            // Selector de mesa (solo si hay mesas libres)
            if (_mesasLibres.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Mesa (opcional)',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Sin mesa'),
                    selected: _mesaSeleccionada == null,
                    onSelected: (_) =>
                        setState(() => _mesaSeleccionada = null),
                  ),
                  ..._mesasLibres.map((m) => ChoiceChip(
                        avatar: Icon(
                          m.tipo == 'ping-pong'
                              ? Icons.sports_tennis_outlined
                              : m.tipo == 'futbolín'
                                  ? Icons.sports_soccer_outlined
                                  : Icons.table_bar_outlined,
                          size: 14,
                        ),
                        label: Text('${_tipoLabel(m.tipo)} ${m.numero}'),
                        selected: _mesaSeleccionada?.id == m.id,
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        onSelected: (_) =>
                            setState(() => _mesaSeleccionada = m),
                      )),
                ],
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _guardar,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Registrar cliente'),
            ),
          ],
        ),
      ),
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'ping-pong':
        return 'Ping-pong';
      case 'futbolín':
        return 'Futbolín';
      default:
        return 'Billar';
    }
  }
}
