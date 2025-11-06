import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_styles.dart';
import 'selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Varsayılan süre ekledik. Bu, Controller'ın süresiz kalmasını engeller.
  final Duration defaultDuration = const Duration(seconds: 7); // 1.5 saniye

  final String appName = 'STASH';

  @override
  void initState() {
    super.initState();

    // HATAYI ÇÖZMEK İÇİN: Controller'a bir varsayılan (placeholder) süre veriyoruz.
    _animationController = AnimationController(
      vsync: this,
      duration: defaultDuration, // BU SATIR HATAYI GİDERİR
    );

    // Animasyonu başlatma komutunu (forward()), Lottie'nin onLoaded callback'ine taşıdık.

    // Animasyon bitiş dinleyicisi
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToSelectionScreen();
      }
    });

    // Lottie yüklenmezse diye bir yedek (fallback) süre koyalım.
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _navigateToSelectionScreen();
      }
    });
  }

  void _navigateToSelectionScreen() {
    if (mounted) {
      // Yönlendirmeden önce Controller'ı durdur
      _animationController.stop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SelectionScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedText() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // ... Animasyonlu metin mantığı aynı kalır
        final int visibleChars =
            (appName.length * _animationController.value).ceil();
        final String visibleText = appName.substring(0, visibleChars);

        return Text(
          visibleText,
          style: GoogleFonts.montserrat(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: kPrimaryBlue,
            letterSpacing: 4,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBlue,
      body: Stack(
        children: [
          // Ana İçerik (Dikeyde Ortalandı)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie Animasyonu
                Lottie.asset(
                  'assets/lottie/travelling_girl.json.json',
                  width: 300,
                  height: 300,
                  repeat: true,
                  animate: true,
                  controller: _animationController,
                  onLoaded: (composition) {
                    // Lottie dosyası yüklendiğinde:
                    if (mounted) {
                      // 1. Controller'ın süresini Lottie'nin kendi gerçek süresi olarak ayarla.
                      _animationController.duration = composition.duration;

                      // 2. Animasyonu başlat (Artık süresi var).
                      _animationController.forward(from: 0.0);
                    }
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('LOTTIE YÜKLENEMEDİ! Yolu kontrol et.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Uygulama Adı (STASH)
                _buildAnimatedText(),
              ],
            ),
          ),
          // ... (Alt logo kısmı)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/codefather_logo.png',
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.code,
                          size: 20, color: kPrimaryBlue.withOpacity(0.7));
                    },
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'powered by Codefather',
                    style: TextStyle(
                      fontSize: 12,
                      color: kPrimaryBlue.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
