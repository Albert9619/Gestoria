import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import 'tabs/mesas_tab.dart';
import 'tabs/meseras_tab.dart';
import 'tabs/productos_tab.dart';
import 'tabs/stock_tab.dart';
import 'tabs/caja_tab.dart';
import 'tabs/reportes_tab.dart';

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

    // Cargar datos del negocio
    final negocioDoc = await FirebaseFirestore.instance
        .collection('negocios')
        .doc(widget.negocioId)
        .get();

    // Cargar nombre del admin
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
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            const Text(
              'Comparte este código con tus meseras para que puedan ingresar:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                _codigoNegocio,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
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

  @override
  Widget build(BuildContext context) {
    final tabs = [
      MesasTab(negocioId: widget.negocioId),
      MeserasTab(
          negocioId: widget.negocioId, codigoNegocio: _codigoNegocio),
      ProductosTab(negocioId: widget.negocioId),
      StockTab(negocioId: widget.negocioId, adminNombre: _adminNombre),
      CajaTab(negocioId: widget.negocioId),
      ReportesTab(
          negocioId: widget.negocioId, negocioNombre: _negocioNombre),
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.store_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _negocioNombre.isEmpty ? 'Gestoria' : _negocioNombre,
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
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      extendBody: true,
      body: tabs[_tabIndex],
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_bar_outlined),
            activeIcon: Icon(Icons.table_bar),
            label: 'Mesas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Meseras',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse_outlined),
            activeIcon: Icon(Icons.warehouse),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: 'Caja',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}
