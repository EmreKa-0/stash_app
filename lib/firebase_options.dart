// lib/firebase_options.dart
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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'MacOS platform is not handled by this template.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows platform is not handled by this template.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux platform is not handled by this template.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- BURADAKİ BİLGİLERİ FIREBASE KONSOLUNDAN ALMALISIN ---

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzizC7JnHt5DVa7JD8W5D7qIOACdK3jU4', // Konsoldan kopyala
    appId: '1:772973568522:android:0f47b7308a2e271d70f5f3', // Konsoldan kopyala
    messagingSenderId: '772973568522', // Konsoldan kopyala
    projectId: 'stashapp-8ab49', // Konsoldan kopyala
    storageBucket: 'stashapp-8ab49.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBGYSgkD7X9lD_0vYG4PPPRdnwMEPVrKJs', // Konsoldan kopyala
    appId: '1:772973568522:ios:3da75503154508f570f5f3', // Konsoldan kopyala
    messagingSenderId: '772973568522',
    projectId: 'stashapp-8ab49',
    storageBucket: 'stashapp-8ab49.firebasestorage.app',
    iosClientId: '', // Konsoldan kopyala
    iosBundleId: 'com.example.emanet', // Senin Bundle ID'n
  );
  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyCuakECAaZTpWoIBynGF7RC1c2eLA6F9z0",
      authDomain: "stashapp-8ab49.firebaseapp.com",
      projectId: "stashapp-8ab49",
      storageBucket: "stashapp-8ab49.firebasestorage.app",
      messagingSenderId: "772973568522",
      appId: "1:772973568522:web:4b031e1e903c69fb70f5f3",
      measurementId: "G-MDGVECLX43");
}
