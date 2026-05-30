import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'models/negocio_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/mesera/mesera_home.dart';
import 'screens/superadmin/superadmin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es', null);
  runApp(const GestoriaApp());
}

class GestoriaApp extends StatelessWidget {
  const GestoriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestoria',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      home: const _AuthWrapper(),
    );
  }
}

// ─────────────────────────────────────────────
// DATOS DE SESIÓN
// ─────────────────────────────────────────────
class _SesionData {
  final String rol;
  final String negocioId;
  final String nombre;
  final NegocioModel? negocio; // null para superadmin

  _SesionData({
    required this.rol,
    required this.negocioId,
    required this.nombre,
    this.negocio,
  });
}

// ─────────────────────────────────────────────
// AUTH WRAPPER — decide a qué pantalla ir
// ─────────────────────────────────────────────
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  Future<_SesionData?> _cargarSesion(String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    if (!userDoc.exists) return null;

    final data = userDoc.data() as Map<String, dynamic>;
    final rol = data['rol'] as String? ?? '';
    final negocioId = data['negocioId'] as String? ?? '';
    final nombre = data['nombre'] as String? ?? 'Usuario';

    // El superadmin no tiene negocioId
    if (rol == 'superadmin') {
      return _SesionData(
          rol: rol, negocioId: '', nombre: nombre, negocio: null);
    }

    // Admin y mesera: cargar negocio para verificar suscripción
    if (negocioId.isEmpty) return null;
    final negocioDoc = await FirebaseFirestore.instance
        .collection('negocios')
        .doc(negocioId)
        .get();

    if (!negocioDoc.exists) return null;
    final negocio = NegocioModel.fromMap(
        negocioDoc.id, negocioDoc.data() as Map<String, dynamic>);

    return _SesionData(
        rol: rol, negocioId: negocioId, nombre: nombre, negocio: negocio);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        if (authSnap.data == null) {
          return const LoginScreen();
        }

        return FutureBuilder<_SesionData?>(
          future: _cargarSesion(authSnap.data!.uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }

            if (!snap.hasData || snap.data == null) {
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            }

            final sesion = snap.data!;

            // Superadmin: acceso directo, sin verificar suscripción
            if (sesion.rol == 'superadmin') {
              return const SuperAdminHome();
            }

            // Verificar suscripción del negocio
            if (sesion.negocio != null &&
                !sesion.negocio!.suscripcionVigente) {
              return _SuscripcionVencidaScreen(negocio: sesion.negocio!);
            }

            switch (sesion.rol) {
              case 'admin':
                return AdminHome(negocioId: sesion.negocioId);
              case 'mesera':
                return MeseraHome(
                  negocioId: sesion.negocioId,
                  meseraId: authSnap.data!.uid,
                  meseraNombre: sesion.nombre,
                );
              default:
                FirebaseAuth.instance.signOut();
                return const LoginScreen();
            }
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// PANTALLA: SUSCRIPCIÓN VENCIDA
// ─────────────────────────────────────────────
class _SuscripcionVencidaScreen extends StatelessWidget {
  final NegocioModel negocio;
  const _SuscripcionVencidaScreen({required this.negocio});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy', 'es');
    final vencio = negocio.suscripcionHasta;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_outlined,
                    size: 44,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Suscripción vencida',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (vencio != null)
                  Text(
                    'Tu acceso a ${negocio.nombre} venció el ${fmt.format(vencio)}.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Comunícate con Gestoria para renovar tu plan y seguir operando.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Caja con datos de contacto
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Contacto Gestoria',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'gestoria.soporte@gmail.com',
                        style: TextStyle(
                            color: AppColors.primary, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
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
// SPLASH SCREEN
// ─────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
