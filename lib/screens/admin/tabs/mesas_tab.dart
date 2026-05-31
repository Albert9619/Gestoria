import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/mesa_model.dart';
import '../../../services/mesa_service.dart';
import '../../../widgets/widgets.dart';

// Color de mesa ocupada (ámbar)


class MesasTab extends StatelessWidget {
  final String negocioId;
  const MesasTab({super.key, required this.negocioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<MesaModel>>(
        stream: MesaService().getMesas(negocioId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final mesas = snap.data ?? [];

          if (mesas.isEmpty) {
            return const EmptyState(
              icon: Icons.table_bar_outlined,
              message: 'No hay mesas registradas',
              subMessage: 'Toca el botón + para agregar la primera',
            );
          }

          final libres = mesas.where((m) => m.estaLibre).length;
          final ocupadas = mesas.where((m) => m.estaOcupada).length;

          return Column(
            children: [
              _ResumenMesas(libres: libres, ocupadas: ocupadas),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: mesas.length,
                  itemBuilder: (ctx, i) => _MesaCard(
                    mesa: mesas[i],
                    negocioId: negocioId,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarCrearMesa(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CrearMesaSheet(negocioId: negocioId),
    );
  }
}

// ─────────────────────────────────────────────
// RESUMEN SUPERIOR
// ─────────────────────────────────────────────
class _ResumenMesas extends StatelessWidget {
  final int libres;
  final int ocupadas;
  const _ResumenMesas({required this.libres, required this.ocupadas});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _chip(
            '$libres libre${libres != 1 ? 's' : ''}',
            AppColors.success,
            Icons.check_circle_outline,
          ),
          const SizedBox(width: 10),
          _chip(
            '$ocupadas ocupada${ocupadas != 1 ? 's' : ''}',
            AppColors.amber,
            Icons.people_outlined,
          ),
          const Spacer(),
          Text(
            '${libres + ocupadas} mesas',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE MESA
// ─────────────────────────────────────────────
class _MesaCard extends StatefulWidget {
  final MesaModel mesa;
  final String negocioId;
  const _MesaCard({required this.mesa, required this.negocioId});

  @override
  State<_MesaCard> createState() => _MesaCardState();
}

class _MesaCardState extends State<_MesaCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arrancarTimer();
  }

  @override
  void didUpdateWidget(_MesaCard old) {
    super.didUpdateWidget(old);
    if (widget.mesa.estaOcupada != old.mesa.estaOcupada) {
      _arrancarTimer();
    }
  }

  void _arrancarTimer() {
    _timer?.cancel();
    if (widget.mesa.estaOcupada && widget.mesa.inicioUso != null) {
      _timer =
          Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mesa = widget.mesa;
    final isLibre = mesa.estaLibre;
    final bgColor = isLibre ? AppColors.success : AppColors.amber;

    return GestureDetector(
      onTap: () => _verDetalle(context),
      onLongPress: () => _opciones(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: tipo + tiempo
            Row(
              children: [
                Icon(_tipoIcon(mesa.tipo),
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  _tipoLabel(mesa.tipo).toUpperCase(),
                  style: AppTextStyles.labelXs.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (!isLibre && mesa.inicioUso != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      mesa.tiempoEnUsoStr(),
                      style: AppTextStyles.labelXs.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Número protagonista
            Text(
              '${mesa.numero}',
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            const Spacer(),
            // Pie: estado o cliente
            if (isLibre)
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.6),
                          blurRadius: 4,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text('Disponible',
                      style: AppTextStyles.labelSm
                          .copyWith(color: Colors.white)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mesa.clienteNombre ?? '—',
                    style: AppTextStyles.titleXs.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((mesa.meseraNombre ?? '').isNotEmpty)
                    Text(
                      mesa.meseraNombre!,
                      style: AppTextStyles.labelXs.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _verDetalle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MesaDetalleSheet(
        mesa: widget.mesa,
        negocioId: widget.negocioId,
      ),
    );
  }

  void _opciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MesaOpcionesSheet(
        mesa: widget.mesa,
        negocioId: widget.negocioId,
      ),
    );
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'ping-pong':
        return Icons.sports_tennis_outlined;
      case 'futbolín':
        return Icons.sports_soccer_outlined;
      default:
        return Icons.table_bar_outlined;
    }
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'ping-pong':
        return 'Ping-pong';
      case 'futbolín':
        return 'Futbolín';
      case 'otro':
        return 'Mesa';
      default:
        return 'Billar';
    }
  }
}

// ─────────────────────────────────────────────
// DETALLE DE MESA (tap)
// ─────────────────────────────────────────────
class _MesaDetalleSheet extends StatefulWidget {
  final MesaModel mesa;
  final String negocioId;
  const _MesaDetalleSheet({required this.mesa, required this.negocioId});

  @override
  State<_MesaDetalleSheet> createState() => _MesaDetalleSheetState();
}

class _MesaDetalleSheetState extends State<_MesaDetalleSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final mesa = widget.mesa;
    final isLibre = mesa.estaLibre;
    final color = isLibre ? AppColors.success : AppColors.amber;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Header
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${mesa.numero}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mesa ${mesa.numero}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _tipoLabel(mesa.tipo),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLibre ? 'Libre' : 'Ocupada',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          if (isLibre) ...[
            const Text(
              'Mesa disponible',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _ocuparManual(context),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Ocupar manualmente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ] else ...[
            InfoRow(
              label: 'Cliente',
              value: mesa.clienteNombre ?? '—',
            ),
            if (mesa.meseraNombre != null)
              InfoRow(
                label: 'Atendida por',
                value: mesa.meseraNombre!,
              ),
            if (mesa.inicioUso != null)
              InfoRow(
                label: 'Tiempo en uso',
                value: mesa.tiempoEnUsoStr(),
                valueColor: AppColors.amber,
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : () => _liberar(context),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_open_outlined, size: 18),
              label: const Text('Liberar mesa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _liberar(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Liberar mesa?'),
        content: Text(
            'La Mesa ${widget.mesa.numero} quedará disponible para otro cliente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Liberar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    await MesaService().liberarMesa(widget.negocioId, widget.mesa.id);
    if (mounted) Navigator.pop(context);
  }

  void _ocuparManual(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OcuparMesaSheet(
        mesa: widget.mesa,
        negocioId: widget.negocioId,
      ),
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'ping-pong':
        return 'Ping-pong';
      case 'futbolín':
        return 'Futbolín';
      case 'otro':
        return 'Mesa';
      default:
        return 'Billar';
    }
  }
}

// ─────────────────────────────────────────────
// OCUPAR MESA MANUAL (admin)
// ─────────────────────────────────────────────
class _OcuparMesaSheet extends StatefulWidget {
  final MesaModel mesa;
  final String negocioId;
  const _OcuparMesaSheet({required this.mesa, required this.negocioId});

  @override
  State<_OcuparMesaSheet> createState() => _OcuparMesaSheetState();
}

class _OcuparMesaSheetState extends State<_OcuparMesaSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
          Text(
            'Ocupar Mesa ${widget.mesa.numero}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _ctrl,
            label: 'Nombre del cliente',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _ocupar,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Ocupar'),
          ),
        ],
      ),
    );
  }

  Future<void> _ocupar() async {
    final nombre = _ctrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _loading = true);
    await MesaService().ocuparMesa(
      negocioId: widget.negocioId,
      mesaId: widget.mesa.id,
      clienteNombre: nombre,
    );
    if (mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────
// OPCIONES DE MESA (long press)
// ─────────────────────────────────────────────
class _MesaOpcionesSheet extends StatelessWidget {
  final MesaModel mesa;
  final String negocioId;
  const _MesaOpcionesSheet({required this.mesa, required this.negocioId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              children: [
                Text(
                  'Mesa ${mesa.numero}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar mesa'),
            onTap: () {
              Navigator.pop(context);
              _editarMesa(context);
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Eliminar mesa',
                style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(context);
              _confirmarEliminar(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _editarMesa(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarMesaSheet(mesa: mesa, negocioId: negocioId),
    );
  }

  void _confirmarEliminar(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar mesa?'),
        content: Text(
            'Mesa ${mesa.numero} se eliminará permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await MesaService().eliminarMesa(negocioId, mesa.id);
    }
  }
}

// ─────────────────────────────────────────────
// EDITAR MESA
// ─────────────────────────────────────────────
class _EditarMesaSheet extends StatefulWidget {
  final MesaModel mesa;
  final String negocioId;
  const _EditarMesaSheet({required this.mesa, required this.negocioId});

  @override
  State<_EditarMesaSheet> createState() => _EditarMesaSheetState();
}

class _EditarMesaSheetState extends State<_EditarMesaSheet> {
  late final TextEditingController _numCtrl;
  late String _tipo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _numCtrl =
        TextEditingController(text: '${widget.mesa.numero}');
    _tipo = widget.mesa.tipo;
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    super.dispose();
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
          const Text('Editar mesa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          AppTextField(
            controller: _numCtrl,
            label: 'Número de mesa',
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.tag),
          ),
          const SizedBox(height: 14),
          const Text('Tipo',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _tipoSelector(),
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
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }

  Widget _tipoSelector() {
    const tipos = [
      ('billar', 'Billar', Icons.table_bar_outlined),
      ('ping-pong', 'Ping-pong', Icons.sports_tennis_outlined),
      ('futbolín', 'Futbolín', Icons.sports_soccer_outlined),
      ('otro', 'Otro', Icons.dashboard_outlined),
    ];
    return Wrap(
      spacing: 8,
      children: tipos.map((t) {
        final (val, label, icon) = t;
        final selected = _tipo == val;
        return ChoiceChip(
          avatar: Icon(icon, size: 16),
          label: Text(label),
          selected: selected,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          onSelected: (_) => setState(() => _tipo = val),
        );
      }).toList(),
    );
  }

  Future<void> _guardar() async {
    final num = int.tryParse(_numCtrl.text.trim());
    if (num == null || num <= 0) return;
    setState(() => _loading = true);
    await MesaService().editarMesa(
      negocioId: widget.negocioId,
      mesaId: widget.mesa.id,
      numero: num,
      tipo: _tipo,
    );
    if (mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────
// CREAR MESA
// ─────────────────────────────────────────────
class CrearMesaSheet extends StatefulWidget {
  final String negocioId;
  const CrearMesaSheet({required this.negocioId});

  @override
  State<CrearMesaSheet> createState() => CrearMesaSheetState();
}

class CrearMesaSheetState extends State<CrearMesaSheet> {
  final _numCtrl = TextEditingController();
  String _tipo = 'billar';
  bool _loading = false;

  @override
  void dispose() {
    _numCtrl.dispose();
    super.dispose();
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
          const Text('Nueva mesa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          AppTextField(
            controller: _numCtrl,
            label: 'Número de mesa',
            hint: 'Ej: 1',
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.tag),
          ),
          const SizedBox(height: 14),
          const Text('Tipo',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _tipoSelector(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _crear,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Crear mesa'),
          ),
        ],
      ),
    );
  }

  Widget _tipoSelector() {
    const tipos = [
      ('billar', 'Billar', Icons.table_bar_outlined),
      ('ping-pong', 'Ping-pong', Icons.sports_tennis_outlined),
      ('futbolín', 'Futbolín', Icons.sports_soccer_outlined),
      ('otro', 'Otro', Icons.dashboard_outlined),
    ];
    return Wrap(
      spacing: 8,
      children: tipos.map((t) {
        final (val, label, icon) = t;
        final selected = _tipo == val;
        return ChoiceChip(
          avatar: Icon(icon, size: 16),
          label: Text(label),
          selected: selected,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          onSelected: (_) => setState(() => _tipo = val),
        );
      }).toList(),
    );
  }

  Future<void> _crear() async {
    final num = int.tryParse(_numCtrl.text.trim());
    if (num == null || num <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un número válido'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await MesaService().crearMesa(
        negocioId: widget.negocioId,
        numero: num,
        tipo: _tipo,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesa creada'),
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
}
