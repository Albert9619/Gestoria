import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/turno_model.dart';
import '../../services/auth_service.dart';
import '../../services/turno_service.dart';
import '../../widgets/widgets.dart';
import 'tabs/clientes_tab.dart';
import 'tabs/mi_turno_tab.dart';

class MeseraHome extends StatefulWidget {
  final String negocioId;
  final String meseraId;
  final String meseraNombre;

  const MeseraHome({
    super.key,
    required this.negocioId,
    required this.meseraId,
    required this.meseraNombre,
  });

  @override
  State<MeseraHome> createState() => _MeseraHomeState();
}

class _MeseraHomeState extends State<MeseraHome> {
  int _tabIndex = 0;
  TurnoModel? _turnoActual;
  bool _cargandoTurno = true;

  @override
  void initState() {
    super.initState();
    _iniciarTurno();
  }

  Future<void> _iniciarTurno() async {
    final turnoService = TurnoService();
    TurnoModel? turno = await turnoService.getTurnoActivo(
      widget.negocioId,
      widget.meseraId,
    );
    if (turno == null) {
      final turnoId = await turnoService.crearTurno(
        negocioId: widget.negocioId,
        meseraId: widget.meseraId,
        mesera: widget.meseraNombre,
      );
      turno = TurnoModel(
        id: turnoId,
        meseraId: widget.meseraId,
        mesera: widget.meseraNombre,
        inicio: DateTime.now(),
        estado: 'activo',
        base: 0,
        totalVentas: 0,
      );
    }
    if (mounted) {
      setState(() {
        _turnoActual = turno;
        _cargandoTurno = false;
      });
    }
  }

  void _mostrarCrearCliente(BuildContext context) {
    if (_turnoActual == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CrearClienteSheet(
        negocioId: widget.negocioId,
        turnoId: _turnoActual!.id,
        meseraId: widget.meseraId,
        meseraNombre: widget.meseraNombre,
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salir del turno'),
        content: const Text(
          'Tu turno seguirá activo. El administrador lo cerrará cuando reciba el dinero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirm == true) await AuthService().logout();
  }

  @override
  Widget build(BuildContext context) {
    // Loading con marca
    if (_cargandoTurno) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store_rounded,
                    size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Iniciando turno...',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    // Inicial del nombre para el avatar
    final inicial = widget.meseraNombre.isNotEmpty
        ? widget.meseraNombre[0].toUpperCase()
        : 'M';

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
            // Logo
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
                Text(widget.meseraNombre,
                    style: AppTextStyles.titleSm
                        .copyWith(color: Colors.white)),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text('Turno activo',
                        style: AppTextStyles.labelXs.copyWith(
                            color:
                                Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Salir',
            onPressed: _logout,
          ),
        ],
      ),
      extendBody: true,
      floatingActionButton: (_tabIndex == 0 && _turnoActual != null)
          ? GradientFAB(
              onPressed: () => _mostrarCrearCliente(context),
              icon: Icons.person_add_outlined,
              label: 'Nuevo cliente',
            )
          : null,
      body: _turnoActual == null
          ? const Center(child: Text('Error al cargar el turno'))
          : IndexedStack(
              index: _tabIndex,
              children: [
                ClientesTab(
                  negocioId: widget.negocioId,
                  turnoId: _turnoActual!.id,
                  meseraId: widget.meseraId,
                  meseraNombre: widget.meseraNombre,
                ),
                MiTurnoTab(
                  negocioId: widget.negocioId,
                  turnoId: _turnoActual!.id,
                ),
              ],
            ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Mi turno',
          ),
        ],
      ),
    );
  }
}
