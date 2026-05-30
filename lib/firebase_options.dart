// Archivo generado manualmente con los valores de Firebase Console
// Proyecto: gestoria-569c8

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma.',
        );
    }
  }

  // ─── WEB ───────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDP5Zblq0FHlhgqoPlk1W9eCDYqgpig2Hg',
    appId: '1:1027544668996:web:79c84337f5660b3f5b5511',
    messagingSenderId: '1027544668996',
    projectId: 'gestoria-569c8',
    authDomain: 'gestoria-569c8.firebaseapp.com',
    storageBucket: 'gestoria-569c8.firebasestorage.app',
    measurementId: 'G-6PKCZM27GV',
  );

  // ─── ANDROID ───────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-IT62z2yDpOBGE9cEj9KvdrJ1C1HgNBM',
    appId: '1:1027544668996:android:ffec2f23744d1a0f5b5511',
    messagingSenderId: '1027544668996',
    projectId: 'gestoria-569c8',
    storageBucket: 'gestoria-569c8.firebasestorage.app',
  );

  // ─── iOS (pendiente de configurar) ─────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDP5Zblq0FHlhgqoPlk1W9eCDYqgpig2Hg',
    appId: '1:1027544668996:web:79c84337f5660b3f5b5511',
    messagingSenderId: '1027544668996',
    projectId: 'gestoria-569c8',
    storageBucket: 'gestoria-569c8.firebasestorage.app',
    iosBundleId: 'com.gestoria',
  );
}
