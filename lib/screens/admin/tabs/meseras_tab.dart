import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../models/usuario_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/mesera_service.dart';
import '../../../widgets/widgets.dart';

class MeserasTab extends StatelessWidget {
  final String negocioId;
  final String codigoNegocio;

  const MeserasTab({
    super.key,
    required this.negocioId,
    required this.codigoNegocio,
  });

  @override
  Widget build(BuildContext context) {
    final service = MeseraService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<UsuarioModel>>(
        stream: service.getMeseras(negocioId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar meseras:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            );
          }

          final meseras = snap.data ?? [];

          if (meseras.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              message: 'No hay meseras registradas',
              subMessage: 'Toca el botón + para agregar la primera',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: meseras.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _MeseraCard(mesera: meseras[i], negocioId: negocioId),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarCrearMesera(context),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nueva mesera'),
      ),
    );
  }

  void _mostrarCrearMesera(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CrearMeseraSheet(
        negocioId: negocioId,
        codigoNegocio: codigoNegocio,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE MESERA
// ─────────────────────────────────────────────
class _MeseraCard extends StatelessWidget {
  final UsuarioModel mesera;
  final String negocioId;

  const _MeseraCard({required this.mesera, required this.negocioId});

  @override
  Widget build(BuildContext context) {
    final inicial =
        mesera.nombre.isNotEmpty ? mesera.nombre[0].toUpperCase() : 'M';

    return AccentCard(
      accentColor: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(inicial,
                  style: AppTextStyles.titleSm
                      .copyWith(color: AppColors.primary)),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mesera.nombre, style: AppTextStyles.titleXs),
                  Text('@${mesera.username}',
                      style: AppTextStyles.labelSm),
                ],
              ),
            ),
            // Acciones
            IconButton(
              icon: const Icon(Icons.visibility_outlined,
                  color: AppColors.primary, size: 20),
              tooltip: 'Ver credenciales',
              onPressed: () => _verCredenciales(context),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.textSecondary, size: 20),
              tooltip: 'Editar',
              onPressed: () => _editarMesera(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              tooltip: 'Eliminar',
              onPressed: () => _confirmarEliminar(context),
            ),
          ],
        ),
      ),
    );
  }

  void _verCredenciales(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Credenciales de mesera'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _credRow('Nombre', mesera.nombre),
            const Divider(),
            _credRow('Usuario', mesera.username, copyable: true, context: context),
            const Divider(),
            _credRow('Contraseña', '••••••', note: 'La contraseña es la que asignaste al crearla'),
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

  Widget _credRow(String label, String value,
      {bool copyable = false, String? note, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              if (copyable && context != null)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18,
                      color: AppColors.textSecondary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Usuario copiado'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
            ],
          ),
          if (note != null)
            Text(note,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _editarMesera(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _EditarMeseraSheet(mesera: mesera, negocioId: negocioId),
    );
  }

  void _confirmarEliminar(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar mesera?'),
        content: Text(
            '${mesera.nombre} ya no podrá ingresar al sistema. Esta acción no se puede deshacer.'),
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await MeseraService().desactivarMesera(negocioId, mesera.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesera eliminada'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET: EDITAR MESERA
// ─────────────────────────────────────────────
class _EditarMeseraSheet extends StatefulWidget {
  final UsuarioModel mesera;
  final String negocioId;

  const _EditarMeseraSheet(
      {required this.mesera, required this.negocioId});

  @override
  State<_EditarMeseraSheet> createState() => _EditarMeseraSheetState();
}

class _EditarMeseraSheetState extends State<_EditarMeseraSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  final TextEditingController _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.mesera.nombre);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nuevoNombre = _nombreCtrl.text.trim();
    final nuevaPass = _passCtrl.text;

    // Nada cambió
    if (nuevoNombre == widget.mesera.nombre && nuevaPass.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _loading = true);
    try {
      if (nuevoNombre != widget.mesera.nombre) {
        await MeseraService().editarNombre(
          widget.negocioId,
          widget.mesera.id,
          nuevoNombre,
        );
      }
      if (nuevaPass.isNotEmpty) {
        await AuthService().cambiarPasswordMesera(
          meseraId: widget.mesera.id,
          nuevaPassword: nuevaPass,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesera actualizada'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

            const Text(
              'Editar mesera',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Usuario: ${widget.mesera.username}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            AppTextField(
              controller: _nombreCtrl,
              label: 'Nombre completo',
              prefixIcon: const Icon(Icons.person_outline),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 14),

            AppTextField(
              controller: _passCtrl,
              label: 'Nueva contraseña',
              hint: 'Dejar vacío para no cambiar',
              obscureText: !_showPass,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_showPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _showPass = !_showPass),
              ),
              validator: (v) {
                if (v!.isNotEmpty && v.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET: CREAR MESERA
// ─────────────────────────────────────────────
class _CrearMeseraSheet extends StatefulWidget {
  final String negocioId;
  final String codigoNegocio;

  const _CrearMeseraSheet({
    required this.negocioId,
    required this.codigoNegocio,
  });

  @override
  State<_CrearMeseraSheet> createState() => _CrearMeseraSheetState();
}

class _CrearMeseraSheetState extends State<_CrearMeseraSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().crearMesera(
        negocioId: widget.negocioId,
        codigoNegocio: widget.codigoNegocio,
        nombre: _nombreCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesera creada exitosamente'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

            const Text(
              'Nueva mesera',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            AppTextField(
              controller: _nombreCtrl,
              label: 'Nombre completo',
              prefixIcon: const Icon(Icons.person_outline),
              validator: (v) =>
                  v!.isEmpty ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _usernameCtrl,
              label: 'Nombre de usuario',
              hint: 'Ej: maria (sin espacios)',
              prefixIcon: const Icon(Icons.alternate_email),
              validator: (v) {
                if (v!.isEmpty) return 'Ingresa el usuario';
                if (v.contains(' ')) return 'Sin espacios';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _passCtrl,
              label: 'Contraseña',
              obscureText: !_showPass,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_showPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _showPass = !_showPass),
              ),
              validator: (v) {
                if (v!.isEmpty) return 'Ingresa una contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Código del negocio: ${widget.codigoNegocio} — la mesera lo necesita para iniciar sesión.',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
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
                  : const Text('Crear mesera'),
            ),
          ],
        ),
      ),
    );
  }
}
