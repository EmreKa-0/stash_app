// lib/main.dart

import 'package:flutter/material.dart';
// Kendi dosya yolunuza göre düzeltin:
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Çalışan Uygulaması',
      debugShowCheckedModeBanner: false,

      // Uygulama Splash Screen ile başlıyor
      home: SplashScreen(),
    );
  }
}
