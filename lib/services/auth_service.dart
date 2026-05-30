import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../firebase_options.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // REGISTRO DE NUEVO NEGOCIO (admin)
  // ─────────────────────────────────────────────
  Future<void> registrarNegocio({
    required String negocioNombre,
    required String adminNombre,
    required String email,
    required String password,
  }) async {
    // 1. Crear usuario en Firebase Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // 2. Generar ID de negocio y código corto (6 chars)
    final negocioRef = _db.collection('negocios').doc();
    final negocioId = negocioRef.id;
    final codigo = _generarCodigo();

    final batch = _db.batch();

    // 3. Documento del negocio (con 15 días de prueba automáticos)
    final prueba = DateTime.now().add(const Duration(days: 15));
    batch.set(negocioRef, {
      'nombre': negocioNombre,
      'email': email,
      'codigo': codigo,
      'activo': true,
      'plan': 'basico',
      'creadoEn': FieldValue.serverTimestamp(),
      'suscripcionHasta': Timestamp.fromDate(prueba),
    });

    // 4. Usuario global (para routing al iniciar sesión)
    batch.set(_db.collection('usuarios').doc(uid), {
      'negocioId': negocioId,
      'rol': 'admin',
      'nombre': adminNombre,
      'email': email,
    });

    // 5. Usuario dentro del negocio
    batch.set(
      _db
          .collection('negocios')
          .doc(negocioId)
          .collection('usuarios')
          .doc(uid),
      {
        'nombre': adminNombre,
        'username': '',
        'email': email,
        'rol': 'admin',
        'activo': true,
        'creadoEn': FieldValue.serverTimestamp(),
      },
    );

    // 6. Lookup de código → negocioId
    batch.set(_db.collection('codigos').doc(codigo), {
      'negocioId': negocioId,
    });

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // CREAR MESERA (REST API — no afecta la sesión del admin)
  // ─────────────────────────────────────────────
  Future<void> crearMesera({
    required String negocioId,
    required String codigoNegocio,
    required String nombre,
    required String username,
    required String password,
  }) async {
    final email = _emailMesera(username, codigoNegocio);
    final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;

    // 1. Crear usuario via REST API sin afectar la sesión actual
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': false,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final msg =
          (body['error'] as Map?)?['message'] ?? 'Error al crear usuario';
      // Traducir errores comunes de Firebase
      if (msg == 'EMAIL_EXISTS') {
        throw Exception('El usuario "$username" ya existe en este negocio');
      }
      throw Exception(msg);
    }

    final uid =
        (jsonDecode(response.body) as Map<String, dynamic>)['localId'] as String;

    // 2. Guardar documentos en Firestore
    final batch = _db.batch();

    batch.set(
      _db
          .collection('negocios')
          .doc(negocioId)
          .collection('usuarios')
          .doc(uid),
      {
        'nombre': nombre,
        'username': username,
        'email': email,
        'rol': 'mesera',
        'activo': true,
        'creadoEn': FieldValue.serverTimestamp(),
      },
    );

    batch.set(_db.collection('usuarios').doc(uid), {
      'negocioId': negocioId,
      'rol': 'mesera',
      'nombre': nombre,
      'username': username,
    });

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // CAMBIAR CONTRASEÑA DE MESERA (REST API — no afecta la sesión del admin)
  // ─────────────────────────────────────────────
  Future<void> cambiarPasswordMesera({
    required String meseraId,
    required String nuevaPassword,
  }) async {
    final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'localId': meseraId,
        'password': nuevaPassword,
        'returnSecureToken': false,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = (body['error'] as Map?)?['message'] ??
          'Error al cambiar contraseña';
      throw Exception(msg);
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN ADMIN (email + contraseña)
  // ─────────────────────────────────────────────
  Future<void> loginAdmin(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ─────────────────────────────────────────────
  // LOGIN MESERA (username + código + contraseña)
  // ─────────────────────────────────────────────
  Future<void> loginMesera({
    required String username,
    required String codigoNegocio,
    required String password,
  }) async {
    final codigo = codigoNegocio.trim().toUpperCase();

    // Verificar que el código existe
    final codeDoc = await _db.collection('codigos').doc(codigo).get();
    if (!codeDoc.exists) {
      throw FirebaseAuthException(
        code: 'invalid-codigo',
        message: 'Código de negocio inválido',
      );
    }

    final email = _emailMesera(username, codigo);
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────
  Future<void> logout() async => _auth.signOut();

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  /// Construye el email interno de una mesera
  String _emailMesera(String username, String codigo) {
    final clean = username.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return '$clean.$codigo@gestoria.app'.toLowerCase();
  }

  /// Genera un código alfanumérico de 6 caracteres para el negocio
  String _generarCodigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final uuid = const Uuid().v4().replaceAll('-', '');
    final result = StringBuffer();
    for (int i = 0; i < 6; i++) {
      result.write(chars[int.parse(uuid[i], radix: 16) % chars.length]);
    }
    return result.toString();
  }
}
