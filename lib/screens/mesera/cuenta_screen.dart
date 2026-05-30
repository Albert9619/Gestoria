import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/cliente_model.dart';
import '../../models/consumo_model.dart';
import '../../models/producto_model.dart';
import '../../services/cliente_service.dart';
import '../../services/producto_service.dart';
import '../../widgets/widgets.dart';

class CuentaScreen extends StatelessWidget {
  final String negocioId;
  final String turnoId;
  final String meseraId;
  final String meseraNombre;
  final String clienteId;
  final String clienteNombre;

  const CuentaScreen({
    super.key,
    required this.negocioId,
    required this.turnoId,
    required this.meseraId,
    required this.meseraNombre,
    required this.clienteId,
    required this.clienteNombre,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClienteModel?>(
      stream: ClienteService().streamCliente(negocioId, clienteId),
      builder: (context, clienteSnap) {
        // Si el cliente fue eliminado (cobrado), regresar automáticamente
        if (clienteSnap.connectionState != ConnectionState.waiting &&
            clienteSnap.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
        }

        final cliente = clienteSnap.data;
        final nombre = cliente?.nombre ?? clienteNombre;
        final total = cliente?.totalCuenta ?? 0.0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                if ((cliente?.telefono ?? '').isNotEmpty)
                  Text(
                    cliente!.telefono,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: cliente != null
                    ? () => _confirmarCobrar(context, nombre, total)
                    : null,
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 20),
                label: const Text(
                  'Cobrar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          body: StreamBuilder<List<ConsumoModel>>(
            stream: ClienteService().getConsumos(negocioId, clienteId),
            builder: (context, consumosSnap) {
              if (consumosSnap.connectionState == ConnectionState.waiting &&
                  clienteSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final consumos = consumosSnap.data ?? [];

              return Column(
                children: [
                  Expanded(
                    child: consumos.isEmpty
                        ? const EmptyState(
                            icon: Icons.receipt_long_outlined,
                            message: 'Sin productos aún',
                            subMessage:
                                'Toca + para agregar lo que consumió',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: consumos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, i) => _ConsumoItem(
                              consumo: consumos[i],
                              negocioId: negocioId,
                              clienteId: clienteId,
                              turnoId: turnoId,
                            ),
                          ),
                  ),
                  _TotalBar(total: total),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _agregarProducto(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar'),
          ),

        );
      },
    );
  }

  void _agregarProducto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgregarProductoSheet(
        negocioId: negocioId,
        turnoId: turnoId,
        clienteId: clienteId,
        meseraId: meseraId,
        meseraNombre: meseraNombre,
      ),
    );
  }

  Future<void> _confirmarCobrar(
      BuildContext context, String nombre, double total) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cobrar cuenta?'),
        content: Text(
          'Total de $nombre:\n${formatCOP(total)}\n\n¿Ya recibiste el pago?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Sí, cobrada'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ClienteService().cobrarYEliminar(negocioId, clienteId, turnoId);
    }
  }
}

// ─────────────────────────────────────────────
// ITEM DE CONSUMO (deslizar para eliminar)
// ─────────────────────────────────────────────
class _ConsumoItem extends StatelessWidget {
  final ConsumoModel consumo;
  final String negocioId;
  final String clienteId;
  final String turnoId;

  const _ConsumoItem({
    required this.consumo,
    required this.negocioId,
    required this.clienteId,
    required this.turnoId,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(consumo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 2),
            Text('Quitar',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmarEliminar(context),
      onDismissed: (_) async {
        try {
          await ClienteService().eliminarConsumo(
            negocioId: negocioId,
            clienteId: clienteId,
            turnoId: turnoId,
            consumo: consumo,
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al quitar: $e'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: consumo.esFisico
                ? AppColors.primary.withValues(alpha: 0.08)
                : const Color(0xFFFEF3C7),
            child: Icon(
              consumo.esFisico
                  ? Icons.local_bar_outlined
                  : Icons.sports_outlined,
              color: consumo.esFisico
                  ? AppColors.primary
                  : const Color(0xFFD97706),
              size: 18,
            ),
          ),
          title: Text(
            consumo.productoNombre,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '${consumo.cantidad} × ${formatCOP(consumo.precioUnitario)}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: Text(
            formatCOP(consumo.subtotal),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmarEliminar(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Quitar producto?'),
        content: Text(
            '${consumo.cantidad} × ${consumo.productoNombre} (${formatCOP(consumo.subtotal)}) se eliminará de la cuenta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BARRA DE TOTAL
// ─────────────────────────────────────────────
class _TotalBar extends StatelessWidget {
  final double total;
  const _TotalBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total a cobrar',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          Text(
            formatCOP(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET: AGREGAR PRODUCTOS (multi)
// ─────────────────────────────────────────────
class _AgregarProductoSheet extends StatefulWidget {
  final String negocioId;
  final String turnoId;
  final String clienteId;
  final String meseraId;
  final String meseraNombre;

  const _AgregarProductoSheet({
    required this.negocioId,
    required this.turnoId,
    required this.clienteId,
    required this.meseraId,
    required this.meseraNombre,
  });

  @override
  State<_AgregarProductoSheet> createState() => _AgregarProductoSheetState();
}

class _AgregarProductoSheetState extends State<_AgregarProductoSheet> {
  List<ProductoModel> _productos = [];
  final Map<String, int> _carrito = {}; // productoId → cantidad
  bool _loading = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final snap =
        await ProductoService().getProductosActivos(widget.negocioId).first;
    if (mounted) setState(() { _productos = snap; _cargando = false; });
  }

  double get _total => _productos.fold(0.0,
      (sum, p) => sum + p.precio * (_carrito[p.id] ?? 0));

  int get _totalItems => _carrito.values.fold(0, (a, b) => a + b);

  List<ProductoModel> get _seleccionados =>
      _productos.where((p) => (_carrito[p.id] ?? 0) > 0).toList();

  void _agregar(ProductoModel p) {
    if (p.esFisico && (_carrito[p.id] ?? 0) >= p.stockActual) return;
    setState(() => _carrito[p.id] = (_carrito[p.id] ?? 0) + 1);
  }

  void _quitar(ProductoModel p) {
    final actual = _carrito[p.id] ?? 0;
    if (actual <= 0) return;
    setState(() {
      if (actual == 1) {
        _carrito.remove(p.id);
      } else {
        _carrito[p.id] = actual - 1;
      }
    });
  }

  Future<void> _confirmar() async {
    if (_seleccionados.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ClienteService().agregarConsumos(
        negocioId: widget.negocioId,
        clienteId: widget.clienteId,
        turnoId: widget.turnoId,
        mesera: widget.meseraNombre,
        meseraId: widget.meseraId,
        productos: _seleccionados,
        cantidades: _carrito,
      );
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final fisicos = _productos.where((p) => p.esFisico).toList();
    final servicios = _productos.where((p) => p.esServicio).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Título
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Agregar a la cuenta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const Divider(height: 1),

          // Lista de productos
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _productos.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        message: 'Sin productos disponibles',
                        subMessage:
                            'El administrador debe registrar productos primero',
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 8),
                        children: [
                          if (fisicos.isNotEmpty) ...[
                            if (servicios.isNotEmpty)
                              _SectionLabel('BEBIDAS Y PRODUCTOS'),
                            ...fisicos.map((p) => _ProductoRow(
                                  producto: p,
                                  cantidad: _carrito[p.id] ?? 0,
                                  onAdd: () => _agregar(p),
                                  onRemove: () => _quitar(p),
                                )),
                          ],
                          if (servicios.isNotEmpty) ...[
                            _SectionLabel('SERVICIOS'),
                            ...servicios.map((p) => _ProductoRow(
                                  producto: p,
                                  cantidad: _carrito[p.id] ?? 0,
                                  onAdd: () => _agregar(p),
                                  onRemove: () => _quitar(p),
                                )),
                          ],
                        ],
                      ),
          ),

          // Barra inferior con total y confirmar
          const Divider(height: 1),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _totalItems == 0
                            ? 'Ningún producto seleccionado'
                            : '$_totalItems producto${_totalItems == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_totalItems > 0)
                        Text(
                          formatCOP(_total),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed:
                      (_loading || _totalItems == 0) ? null : _confirmar,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 48),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirmar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ETIQUETA DE SECCIÓN
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILA DE PRODUCTO CON CONTADOR
// ─────────────────────────────────────────────
class _ProductoRow extends StatelessWidget {
  final ProductoModel producto;
  final int cantidad;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductoRow({
    required this.producto,
    required this.cantidad,
    required this.onAdd,
    required this.onRemove,
  });

  bool get _sinStock => producto.esFisico && producto.stockActual <= 0;
  bool get _maxReached =>
      producto.esFisico && cantidad >= producto.stockActual;

  @override
  Widget build(BuildContext context) {
    final seleccionado = cantidad > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: seleccionado
          ? AppColors.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: producto.esFisico
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFFEF3C7),
          child: Icon(
            producto.esFisico
                ? Icons.local_bar_outlined
                : Icons.sports_outlined,
            color: producto.esFisico
                ? AppColors.primary
                : const Color(0xFFD97706),
            size: 18,
          ),
        ),
        title: Text(
          producto.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _sinStock
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _sinStock
              ? 'Sin stock'
              : producto.esFisico
                  ? '${formatCOP(producto.precio)} · Stock: ${producto.stockActual}'
                  : formatCOP(producto.precio),
          style: TextStyle(
            fontSize: 12,
            color: _sinStock ? AppColors.error : AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cantidad > 0) ...[
              _QtyBtn(
                  icon: Icons.remove, enabled: true, onTap: onRemove),
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    '$cantidad',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
            _QtyBtn(
              icon: Icons.add,
              enabled: !_sinStock && !_maxReached,
              onTap: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTÓN DE CANTIDAD
// ─────────────────────────────────────────────
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _QtyBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.divider,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
