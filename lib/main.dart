// lib/main.dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'utils/time_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await TimeService.syncWithServer();
  } catch (_) {}
  runApp(const MyApp());
  await FirebaseAppCheck.instance.activate(
    // Android için Play Integrity (Eskiden SafetyNet vardı, artık bu öneriliyor)
    androidProvider: AndroidProvider.debug,

    // iOS için DeviceCheck veya App Attest
    appleProvider: AppleProvider.deviceCheck,

    // Web kullanıyorsan reCaptcha anahtarı gerekir (mobil için gerekmez)
    // webRecaptchaSiteKey: 'recaptcha-v3-site-key',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Stash',
      debugShowCheckedModeBanner: false,

      // Uygulama Splash Screen ile başlıyor
      home: SplashScreen(),
    );
  }
}
