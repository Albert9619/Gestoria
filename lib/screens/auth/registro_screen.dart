import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _negocioCtrl = TextEditingController();
  final _adminNombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _showPass = false;

  @override
  void dispose() {
    _negocioCtrl.dispose();
    _adminNombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.registrarNegocio(
        negocioNombre: _negocioCtrl.text.trim(),
        adminNombre: _adminNombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // El AuthWrapper detecta el login y navega a AdminHome
    } on FirebaseAuthException catch (e) {
      String msg = 'Error al registrar';
      if (e.code == 'email-already-in-use') {
        msg = 'Este correo ya está registrado';
      } else if (e.code == 'weak-password') {
        msg = 'La contraseña debe tener al menos 6 caracteres';
      }
      _showError(msg);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar negocio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos del negocio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _negocioCtrl,
                label: 'Nombre del negocio',
                hint: 'Ej: Billar El Campeón',
                prefixIcon: const Icon(Icons.store_outlined),
                validator: (v) =>
                    v!.isEmpty ? 'Ingresa el nombre del negocio' : null,
              ),
              const SizedBox(height: 32),
              const Text(
                'Datos del administrador',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _adminNombreCtrl,
                label: 'Tu nombre',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (v) => v!.isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (v) {
                  if (v!.isEmpty) return 'Ingresa tu correo';
                  if (!v.contains('@')) return 'Correo inválido';
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
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirmPassCtrl,
                label: 'Confirmar contraseña',
                obscureText: !_showPass,
                prefixIcon: const Icon(Icons.lock_outline),
                validator: (v) {
                  if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Se generará un código único para que tus meseras puedan ingresar a la app.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _registrar,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Crear negocio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
