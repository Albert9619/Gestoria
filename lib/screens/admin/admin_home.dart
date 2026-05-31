import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/mesas_tab.dart';
import 'tabs/meseras_tab.dart';
import 'tabs/productos_tab.dart';
import 'tabs/stock_tab.dart';
import 'tabs/caja_tab.dart';
import 'tabs/reportes_tab.dart';
// Sheets públicos
export 'tabs/mesas_tab.dart' show CrearMesaSheet;
export 'tabs/productos_tab.dart' show CrearProductoSheet;

class AdminHome extends StatefulWidget {
  final String negocioId;
  const AdminHome({super.key, required this.negocioId});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _tabIndex = 0;
  String _negocioNombre = '';
  String _codigoNegocio = '';
  String _adminNombre = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final negocioDoc = await FirebaseFirestore.instance
        .collection('negocios')
        .doc(widget.negocioId)
        .get();
    final adminDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    if (mounted) {
      setState(() {
        _negocioNombre = negocioDoc.data()?['nombre'] ?? 'Mi Negocio';
        _codigoNegocio = negocioDoc.data()?['codigo'] ?? '';
        _adminNombre = adminDoc.data()?['nombre'] ?? 'Admin';
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content:
            const Text('¿Estás seguro de que quieres cerrar sesión?'),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm == true) await AuthService().logout();
  }

  void _mostrarCodigo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Código del negocio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Comparte este código con tus meseras:',
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                _codigoNegocio,
                style: AppTextStyles.kpiLg.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 6,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ── FAB según la pestaña activa ───────────
  Widget? _fabPorTab(BuildContext context) {
    switch (_tabIndex) {
      case 1: // Ventas → Mesas
        return GradientFAB(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => CrearMesaSheet(negocioId: widget.negocioId),
          ),
          icon: Icons.add_rounded,
          label: 'Nueva mesa',
        );
      case 2: // Inventario → Productos
        return GradientFAB(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => CrearProductoSheet(negocioId: widget.negocioId),
          ),
          icon: Icons.add_rounded,
          label: 'Nuevo producto',
        );
      default:
        return null;
    }
  }

  // ── Menú "Más" ────────────────────────────
  void _mostrarMas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MasSheet(
        negocioId: widget.negocioId,
        codigoNegocio: _codigoNegocio,
        negocioNombre: _negocioNombre,
        adminNombre: _adminNombre,
        onMostrarCodigo: _mostrarCodigo,
        onLogout: _logout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 4 tabs reales: Inicio, Ventas, Inventario, Caja
    final tabs = [
      DashboardTab(
        negocioId: widget.negocioId,
        adminNombre: _adminNombre,
        onNavigateTo: (i) => setState(() => _tabIndex = i),
      ),
      MesasTab(negocioId: widget.negocioId),
      ProductosTab(negocioId: widget.negocioId),
      CajaTab(negocioId: widget.negocioId),
    ];

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1A3577), Color(0xFF0F2150)],
            ),
          ),
        ),
        title: Row(
          children: [
            // Logo en contenedor blanco
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _negocioNombre.isEmpty ? 'Mi Negocio' : _negocioNombre,
                  style: AppTextStyles.titleSm
                      .copyWith(color: Colors.white),
                ),
                Text(
                  'Administrador',
                  style: AppTextStyles.labelXs.copyWith(
                      color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'Código del negocio',
            onPressed: _mostrarCodigo,
          ),
        ],
      ),
      extendBody: true,
      floatingActionButton: _fabPorTab(context),
      body: tabs[_tabIndex],
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _tabIndex,
        onTap: (i) {
          if (i == 4) {
            _mostrarMas(context);
          } else {
            setState(() => _tabIndex = i);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_bar_outlined),
            activeIcon: Icon(Icons.table_bar),
            label: 'Ventas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: 'Caja',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded),
            activeIcon: Icon(Icons.more_horiz_rounded),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MENÚ "MÁS" — bottom sheet
// ─────────────────────────────────────────────
class _MasSheet extends StatelessWidget {
  final String negocioId;
  final String codigoNegocio;
  final String negocioNombre;
  final String adminNombre;
  final VoidCallback onMostrarCodigo;
  final VoidCallback onLogout;

  const _MasSheet({
    required this.negocioId,
    required this.codigoNegocio,
    required this.negocioNombre,
    required this.adminNombre,
    required this.onMostrarCodigo,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              children: [
                _MasOption(
                  icon: Icons.warehouse_rounded,
                  label: 'Stock',
                  subtitle: 'Registrar entradas de inventario',
                  color: AppColors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Stock'),
                            flexibleSpace: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1A3577),
                                    Color(0xFF0F2150)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          body: StockTab(
                            negocioId: negocioId,
                            adminNombre: adminNombre,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: AppSpacing.md),
                _MasOption(
                  icon: Icons.people_rounded,
                  label: 'Meseras',
                  subtitle: 'Gestionar personal',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Meseras')),
                          body: MeserasTab(
                            negocioId: negocioId,
                            codigoNegocio: codigoNegocio,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: AppSpacing.md),
                _MasOption(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reportes',
                  subtitle: 'Ver estadísticas y PDF',
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Reportes')),
                          body: ReportesTab(
                            negocioId: negocioId,
                            negocioNombre: negocioNombre,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: AppSpacing.md),
                _MasOption(
                  icon: Icons.qr_code_rounded,
                  label: 'Código del negocio',
                  subtitle: 'Compartir con meseras',
                  color: AppColors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    onMostrarCodigo();
                  },
                ),
                const Divider(height: AppSpacing.md),
                _MasOption(
                  icon: Icons.logout_rounded,
                  label: 'Cerrar sesión',
                  subtitle: adminNombre,
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MasOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.titleXs),
                  Text(subtitle, style: AppTextStyles.labelSm),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
