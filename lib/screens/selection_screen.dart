import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import 'employee_registration_screen.dart';
import 'visitor_registration_screen.dart';
import 'login_screen.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  // Seçim Butonu Widget'ı (Yan yana ikon ve yazı düzeni)
  Widget _buildSelectionButton(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    // Görseldeki turuncu kart yapısını simüle etmek için Container kullandık
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: kLightOrange, // Turuncu arka plan
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Row(
          children: [
            // İkon
            Icon(icon, size: 55, color: kPrimaryBlue),
            const SizedBox(width: 25),
            // Başlık
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: kPrimaryBlue, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBlue, // Temel arka plan rengi
      body: Stack(
        children: <Widget>[
          // --- 1. SİLÜET (TÜM EKRANI KAPLAYAN BÜYÜK VALİZ) ---
          // Center ile ikon tam ortaya hizalandı (Düzeltme 1)
          Center(
            child: Opacity(
              opacity: 0.2,
              child: Icon(
                Icons.luggage_outlined, // Valiz/bagaj ikonu
                size: MediaQuery.of(context).size.width * 1.2,
                color: kPrimaryBlue.withOpacity(0.4),
              ),
            ),
          ),

          // --- 2. İÇERİK (Başlıklar ve Butonlar) ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Geri Butonu (En üstte)
                  Align(
                    alignment: Alignment.topLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: kPrimaryBlue),
                      label: const Text('Back',
                          style: TextStyle(color: kPrimaryBlue, fontSize: 18)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ana Başlık
                  Text(
                    'ENJOY THE LAST\nDAY OF YOUR\nTRIP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: kPrimaryBlue,
                        fontSize: 36,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        height: 1.2),
                  ),
                  const SizedBox(height: 50),

                  // Alt Başlık
                  const Text(
                    'WHO ARE YOU?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 1. Ziyaretçi Butonu (Visitor)
                  _buildSelectionButton(
                    context,
                    title: 'VISITOR (CHECK-IN)',
                    icon: Icons.cases_outlined,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const VisitorRegistrationScreen()));
                    },
                  ),

                  // 2. Çalışan Butonu (Employee)
                  _buildSelectionButton(
                    context,
                    title: 'EMPLOYEE (CHECK-OUT)',
                    icon: Icons.storefront_outlined,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const EmployeeRegistrationScreen()));
                    },
                  ),

                  const SizedBox(height: 80),

                  // Log In Linki
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()));
                    },
                    child: Column(
                      children: [
                        const Text(
                          'DO YOU ALREADY HAVE AN ACCOUNT?',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'LOG IN',
                          style: TextStyle(
                              fontSize: 18,
                              color: kPrimaryBlue,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
