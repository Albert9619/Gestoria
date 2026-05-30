import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/producto_model.dart';
import '../../../services/producto_service.dart';
import '../../../services/venta_service.dart';
import '../../../widgets/widgets.dart';

class VenderTab extends StatefulWidget {
  final String negocioId;
  final String turnoId;
  final String meseraId;

  const VenderTab({
    super.key,
    required this.negocioId,
    required this.turnoId,
    required this.meseraId,
  });

  @override
  State<VenderTab> createState() => _VenderTabState();
}

class _VenderTabState extends State<VenderTab> {
  String _busqueda = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _busqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _busqueda = '');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),

        // Lista de productos
        Expanded(
          child: StreamBuilder<List<ProductoModel>>(
            stream:
                ProductoService().getProductosActivos(widget.negocioId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var productos = snap.data ?? [];

              // Filtrar por búsqueda
              if (_busqueda.isNotEmpty) {
                productos = productos
                    .where((p) =>
                        p.nombre.toLowerCase().contains(_busqueda))
                    .toList();
              }

              if (productos.isEmpty) {
                return EmptyState(
                  icon: Icons.inventory_2_outlined,
                  message: _busqueda.isNotEmpty
                      ? 'Sin resultados para "$_busqueda"'
                      : 'Sin productos disponibles',
                  subMessage: _busqueda.isEmpty
                      ? 'El administrador debe registrar productos primero'
                      : null,
                );
              }

              // Separar por tipo
              final fisicos =
                  productos.where((p) => p.esFisico).toList();
              final servicios =
                  productos.where((p) => p.esServicio).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (fisicos.isNotEmpty) ...[
                    if (servicios.isNotEmpty)
                      const SectionHeader(title: 'BEBIDAS Y PRODUCTOS'),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: fisicos.length,
                      itemBuilder: (context, i) => _ProductoGridItem(
                        producto: fisicos[i],
                        onTap: () => _mostrarDialogoVenta(context, fisicos[i]),
                      ),
                    ),
                  ],
                  if (servicios.isNotEmpty) ...[
                    SectionHeader(
                      title: 'SERVICIOS',
                      trailing: fisicos.isNotEmpty
                          ? const SizedBox.shrink()
                          : null,
                    ),
                    ...servicios.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ServicioItem(
                            producto: p,
                            onTap: () =>
                                _mostrarDialogoVenta(context, p),
                          ),
                        )),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoVenta(BuildContext context, ProductoModel producto) {
    int cantidad = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(producto.nombre),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCOP(producto.precio),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              if (producto.esFisico) ...[
                const SizedBox(height: 4),
                Text(
                  'Stock disponible: ${producto.stockActual}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),

              // Selector de cantidad
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _qtyBtn(
                    icon: Icons.remove,
                    onTap: cantidad > 1
                        ? () => setDialogState(() => cantidad--)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '$cantidad',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _qtyBtn(
                    icon: Icons.add,
                    onTap: (!producto.esFisico ||
                            cantidad < producto.stockActual)
                        ? () => setDialogState(() => cantidad++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontWeight: FontWeight.w600)),
                    Text(
                      formatCOP(producto.precio * cantidad),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _registrarVenta(context, producto, cantidad);
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirmar venta'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registrarVenta(
      BuildContext context, ProductoModel producto, int cantidad) async {
    try {
      await VentaService().registrarVenta(
        negocioId: widget.negocioId,
        turnoId: widget.turnoId,
        meseraId: widget.meseraId,
        producto: producto,
        cantidad: cantidad,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ Venta registrada: $cantidad × ${producto.nombre}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _qtyBtn(
      {required IconData icon, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.divider,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color:
              onTap != null ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GRID ITEM (productos físicos)
// ─────────────────────────────────────────────
class _ProductoGridItem extends StatelessWidget {
  final ProductoModel producto;
  final VoidCallback onTap;

  const _ProductoGridItem({required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sinStock = producto.esFisico && producto.stockActual <= 0;

    return GestureDetector(
      onTap: sinStock ? null : onTap,
      child: AnimatedOpacity(
        opacity: sinStock ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sinStock)
                      const Icon(Icons.block,
                          size: 16, color: AppColors.error),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCOP(producto.precio),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      sinStock
                          ? 'Sin stock'
                          : '${producto.stockActual} disponibles',
                      style: TextStyle(
                        fontSize: 11,
                        color: sinStock
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SERVICIO ITEM (lista)
// ─────────────────────────────────────────────
class _ServicioItem extends StatelessWidget {
  final ProductoModel producto;
  final VoidCallback onTap;

  const _ServicioItem({required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFEF3C7),
          child: Icon(Icons.sports_outlined,
              color: Color(0xFFD97706), size: 20),
        ),
        title: Text(
          producto.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatCOP(producto.precio),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.add_circle_outline,
                color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
