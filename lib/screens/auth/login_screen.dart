import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _passwordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();

  bool _esMesera = false;
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_esMesera) {
        await _authService.loginMesera(
          username: _usernameCtrl.text.trim(),
          codigoNegocio: _codigoCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await _authService.loginAdmin(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(_mensajeError(e.code));
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

  String _mensajeError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Usuario o contraseña incorrectos';
      case 'invalid-codigo':
        return 'Código de negocio inválido';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      default:
        return 'Error al iniciar sesión. Intenta de nuevo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A3577),
              Color(0xFF0F2150),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header con logo ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xxl,
                    AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 68,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Gestiona mejor. Crece más.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Formulario ───────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xxl + 4)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Iniciar sesión',
                              style: AppTextStyles.titleLg),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _esMesera
                                ? 'Ingresa con tu usuario y código del negocio'
                                : 'Ingresa con tu correo y contraseña',
                            style: AppTextStyles.bodyXs
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Toggle Admin / Mesera
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                _toggleBtn('Administrador', !_esMesera,
                                    () => setState(() => _esMesera = false)),
                                _toggleBtn('Mesera', _esMesera,
                                    () => setState(() => _esMesera = true)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          if (!_esMesera) ...[
                            AppTextField(
                              controller: _emailCtrl,
                              label: 'Correo electrónico',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon:
                                  const Icon(Icons.email_outlined),
                              validator: (v) =>
                                  v!.isEmpty ? 'Ingresa tu correo' : null,
                            ),
                          ] else ...[
                            AppTextField(
                              controller: _usernameCtrl,
                              label: 'Usuario',
                              prefixIcon:
                                  const Icon(Icons.person_outline),
                              validator: (v) =>
                                  v!.isEmpty ? 'Ingresa tu usuario' : null,
                            ),
                            const SizedBox(height: AppSpacing.formGap),
                            AppTextField(
                              controller: _codigoCtrl,
                              label: 'Código del negocio',
                              hint: 'Ejemplo: ABC123',
                              prefixIcon:
                                  const Icon(Icons.store_outlined),
                              validator: (v) => v!.isEmpty
                                  ? 'Ingresa el código del negocio'
                                  : null,
                            ),
                          ],

                          const SizedBox(height: AppSpacing.formGap),

                          AppTextField(
                            controller: _passwordCtrl,
                            label: 'Contraseña',
                            obscureText: !_showPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(
                                  () => _showPassword = !_showPassword),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Ingresa tu contraseña' : null,
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          ElevatedButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Iniciar sesión'),
                          ),

                          if (!_esMesera) ...[
                            const SizedBox(height: AppSpacing.md),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegistroScreen(),
                                  ),
                                ),
                                child: const Text(
                                    '¿Nuevo negocio? Regístrate aquí'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleBtn(
      String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(
              color:
                  selected ? Colors.white : AppColors.textSecondary,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
