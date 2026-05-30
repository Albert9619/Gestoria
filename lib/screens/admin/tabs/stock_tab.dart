import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/entrada_stock_model.dart';
import '../../../models/producto_model.dart';
import '../../../services/producto_service.dart';
import '../../../services/stock_service.dart';
import '../../../widgets/widgets.dart';

class StockTab extends StatefulWidget {
  final String negocioId;
  final String adminNombre;

  const StockTab({
    super.key,
    required this.negocioId,
    required this.adminNombre,
  });

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab>
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
              Tab(text: 'Stock actual'),
              Tab(text: 'Historial entradas'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _StockActual(negocioId: widget.negocioId),
          _HistorialEntradas(negocioId: widget.negocioId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _registrarEntrada(context),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Registrar entrada'),
      ),
    );
  }

  void _registrarEntrada(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntradaStockSheet(
        negocioId: widget.negocioId,
        adminNombre: widget.adminNombre,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STOCK ACTUAL
// ─────────────────────────────────────────────
class _StockActual extends StatelessWidget {
  final String negocioId;
  const _StockActual({required this.negocioId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductoModel>>(
      stream: ProductoService().getProductos(negocioId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Solo físicos (los servicios no tienen stock)
        final fisicos = (snap.data ?? []).where((p) => p.esFisico).toList();

        if (fisicos.isEmpty) {
          return const EmptyState(
            icon: Icons.warehouse_outlined,
            message: 'No hay productos con stock',
            subMessage: 'Crea productos físicos en la pestaña Productos',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: fisicos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = fisicos[i];
            final stockBajo = p.stockActual <= 5;
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: stockBajo
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: stockBajo ? AppColors.error : AppColors.success,
                    size: 20,
                  ),
                ),
                title: Text(
                  p.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  formatCOP(p.precio),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.stockActual}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: stockBajo ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'unidades',
                      style: TextStyle(
                        fontSize: 11,
                        color: stockBajo
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// HISTORIAL DE ENTRADAS
// ─────────────────────────────────────────────
class _HistorialEntradas extends StatelessWidget {
  final String negocioId;
  const _HistorialEntradas({required this.negocioId});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return StreamBuilder<List<EntradaStockModel>>(
      stream: StockService().getEntradas(negocioId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entradas = snap.data ?? [];

        if (entradas.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            message: 'Sin entradas registradas',
            subMessage: 'Las entradas de mercancía aparecerán aquí',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entradas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final e = entradas[i];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.add_box_outlined,
                      color: Color(0xFF0369A1), size: 20),
                ),
                title: Text(
                  e.productoNombre,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${fmt.format(e.fecha)} · ${e.registradoPor}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${e.cantidad}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET: REGISTRAR ENTRADA
// ─────────────────────────────────────────────
class _EntradaStockSheet extends StatefulWidget {
  final String negocioId;
  final String adminNombre;

  const _EntradaStockSheet({
    required this.negocioId,
    required this.adminNombre,
  });

  @override
  State<_EntradaStockSheet> createState() => _EntradaStockSheetState();
}

class _EntradaStockSheetState extends State<_EntradaStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  ProductoModel? _productoSeleccionado;
  List<ProductoModel> _productos = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final snap = await ProductoService()
        .getProductos(widget.negocioId)
        .first;
    if (mounted) {
      setState(() {
        _productos = snap.where((p) => p.esFisico && p.activo).toList();
      });
    }
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_productoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un producto'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await StockService().registrarEntrada(
        negocioId: widget.negocioId,
        productoId: _productoSeleccionado!.id,
        productoNombre: _productoSeleccionado!.nombre,
        cantidad: int.parse(_cantidadCtrl.text),
        registradoPor: widget.adminNombre,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrada registrada'),
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
              'Registrar entrada de stock',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Selector de producto
            DropdownButtonFormField<ProductoModel>(
              initialValue: _productoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Producto',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              hint: const Text('Selecciona un producto'),
              items: _productos
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.nombre),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _productoSeleccionado = v),
            ),
            const SizedBox(height: 14),

            AppTextField(
              controller: _cantidadCtrl,
              label: 'Cantidad que ingresa',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.add_box_outlined),
              hint: 'Ej: 24',
              validator: (v) {
                if (v!.isEmpty) return 'Ingresa la cantidad';
                if (int.tryParse(v) == null) return 'Cantidad inválida';
                if (int.parse(v) <= 0) return 'Debe ser mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _registrar,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Registrar entrada'),
            ),
          ],
        ),
      ),
    );
  }
}
