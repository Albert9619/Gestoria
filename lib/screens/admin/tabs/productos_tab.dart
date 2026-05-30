import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/producto_model.dart';
import '../../../services/producto_service.dart';
import '../../../widgets/widgets.dart';

class ProductosTab extends StatelessWidget {
  final String negocioId;
  const ProductosTab({super.key, required this.negocioId});

  @override
  Widget build(BuildContext context) {
    final service = ProductoService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<ProductoModel>>(
        stream: service.getProductos(negocioId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final productos = snap.data ?? [];

          if (productos.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No hay productos registrados',
              subMessage: 'Toca el botón + para agregar el primero',
            );
          }

          // Agrupar por tipo
          final fisicos =
              productos.where((p) => p.esFisico).toList();
          final servicios =
              productos.where((p) => p.esServicio).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (fisicos.isNotEmpty) ...[
                const SectionHeader(title: 'PRODUCTOS FÍSICOS'),
                ...fisicos.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProductoCard(
                          producto: p, negocioId: negocioId),
                    )),
              ],
              if (servicios.isNotEmpty) ...[
                const SectionHeader(title: 'SERVICIOS'),
                ...servicios.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProductoCard(
                          producto: p, negocioId: negocioId),
                    )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarCrearProducto(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
    );
  }

  void _mostrarCrearProducto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CrearProductoSheet(negocioId: negocioId),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE PRODUCTO
// ─────────────────────────────────────────────
class _ProductoCard extends StatelessWidget {
  final ProductoModel producto;
  final String negocioId;

  const _ProductoCard({required this.producto, required this.negocioId});

  @override
  Widget build(BuildContext context) {
    final sinStock = producto.esFisico && producto.stockActual == 0;
    final stockBajo = producto.esFisico &&
        producto.stockActual > 0 &&
        producto.stockActual <= 5;
    final accentColor =
        producto.esFisico ? AppColors.primary : AppColors.accent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Ícono de tipo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                producto.esFisico
                    ? Icons.inventory_2_outlined
                    : Icons.sports_outlined,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Nombre + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: AppTextStyles.titleXs.copyWith(
                      color: producto.activo
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      decoration: producto.activo
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        producto.esFisico
                            ? 'Stock: ${producto.stockActual}'
                            : 'Servicio',
                        style: AppTextStyles.labelSm,
                      ),
                      if (sinStock || stockBajo) ...[
                        const SizedBox(width: AppSpacing.xxs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: (sinStock ? AppColors.error : AppColors.amber)
                                .withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            sinStock ? 'Sin stock' : 'Stock bajo',
                            style: AppTextStyles.labelXs.copyWith(
                              color: sinStock
                                  ? AppColors.error
                                  : AppColors.amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Precio + menú
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCOP(producto.precio),
                  style: AppTextStyles.kpiSm
                      .copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 2),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppColors.textSecondary),
              onSelected: (val) => _accion(context, val),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'nombre',
                  child: Row(children: [
                    Icon(Icons.label_outline, size: 18),
                    SizedBox(width: 10),
                    Text('Editar nombre'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'precio',
                  child: Row(children: [
                    Icon(Icons.attach_money, size: 18),
                    SizedBox(width: 10),
                    Text('Editar precio'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(
                      producto.activo
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(producto.activo ? 'Desactivar' : 'Activar'),
                  ]),
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

  void _accion(BuildContext context, String accion) {
    if (accion == 'nombre') {
      _editarNombre(context);
    } else if (accion == 'precio') {
      _editarPrecio(context);
    } else if (accion == 'toggle') {
      ProductoService()
          .toggleActivo(negocioId, producto.id, !producto.activo);
    }
  }

  void _editarNombre(BuildContext context) {
    final ctrl = TextEditingController(text: producto.nombre);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar nombre'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre del producto',
              prefixIcon: Icon(Icons.label_outline),
            ),
            validator: (v) => v!.trim().isEmpty ? 'Ingresa el nombre' : null,
          ),
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
              if (!formKey.currentState!.validate()) return;
              await ProductoService().editarNombre(
                negocioId,
                producto.id,
                ctrl.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _editarPrecio(BuildContext context) {
    final ctrl =
        TextEditingController(text: producto.precio.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Precio de ${producto.nombre}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nuevo precio',
              prefixText: '\$ ',
            ),
            validator: (v) {
              if (v!.isEmpty) return 'Ingresa el precio';
              if (double.tryParse(v) == null) return 'Precio inválido';
              if (double.parse(v) <= 0) return 'El precio debe ser mayor a 0';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ProductoService().editarPrecio(
                negocioId,
                producto.id,
                double.parse(ctrl.text),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET: CREAR PRODUCTO
// ─────────────────────────────────────────────
class _CrearProductoSheet extends StatefulWidget {
  final String negocioId;
  const _CrearProductoSheet({required this.negocioId});

  @override
  State<_CrearProductoSheet> createState() => _CrearProductoSheetState();
}

class _CrearProductoSheetState extends State<_CrearProductoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  String _tipo = 'fisico';
  bool _loading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ProductoService().crearProducto(
        negocioId: widget.negocioId,
        nombre: _nombreCtrl.text.trim(),
        tipo: _tipo,
        precio: double.parse(_precioCtrl.text),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto creado'),
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
              'Nuevo producto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // Tipo selector
            const Text('Tipo de producto',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                _tipoBtn('Físico\n(tiene stock)', 'fisico',
                    Icons.inventory_2_outlined),
                const SizedBox(width: 10),
                _tipoBtn('Servicio\n(sin stock)', 'servicio',
                    Icons.sports_outlined),
              ],
            ),
            const SizedBox(height: 16),

            AppTextField(
              controller: _nombreCtrl,
              label: 'Nombre del producto',
              hint: _tipo == 'fisico' ? 'Ej: Cerveza' : 'Ej: Mesa de billar',
              prefixIcon: const Icon(Icons.label_outline),
              validator: (v) =>
                  v!.isEmpty ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _precioCtrl,
              label: 'Precio de venta',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.attach_money),
              hint: 'Ej: 3000',
              validator: (v) {
                if (v!.isEmpty) return 'Ingresa el precio';
                if (double.tryParse(v) == null) return 'Precio inválido';
                if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                return null;
              },
            ),
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
                  : const Text('Crear producto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoBtn(String label, String value, IconData icon) {
    final selected = _tipo == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipo = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
