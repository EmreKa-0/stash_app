import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/app_styles.dart';

// --- YENİ EKLENEN IMPORTLAR ---
import '../utils/database_helper.dart';
import '../models/user_models.dart';
import 'employee_dashboard_screen.dart'; // Çalışan paneli için
import 'baggage_detail_screen.dart'; // Ziyaretçi paneli için
// --- BİTİŞ ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // --- Animation Controllers ---
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // --- YENİ EKLENDİ ---
  bool _isLoading = false; // Yüklenme durumu için

  // --- LOGIN FONKSİYONU GÜNCELLENDİ ---
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // Yükleniyor...

      String email = _emailController.text;
      String password = _passwordController.text;

      // Önce Çalışan tablosunda ara
      Employee? employee =
          await DatabaseHelper.instance.getEmployeeLogin(email, password);

      if (employee != null) {
        // ÇALIŞAN BULUNDU
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const EmployeeDashboardScreen()),
          (Route<dynamic> route) => false,
        );
        return; // İşlemi bitir
      }

      // Çalışan değilse, Ziyaretçi tablosunda ara
      Visitor? visitor =
          await DatabaseHelper.instance.getVisitorLogin(email, password);

      if (visitor != null) {
        // ZİYARETÇİ BULUNDU
        if (!mounted) return;
        // Ziyaretçi için ana ekran Bagaj Detay ekranı
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BaggageDetailScreen()),
          (Route<dynamic> route) => false,
        );
        return; // İşlemi bitir
      }

      // KİMSE BULUNAMADI
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatalı e-posta veya şifre.')),
      );

      setState(() => _isLoading = false); // Yüklenme bitti
    }
  }
  // --- GÜNCELLEME BİTTİ ---

  @override
  void initState() {
    super.initState();
    // VisitorRegistrationScreen'deki Animasyon Ayarları
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Uzun süreli, sürekli ilerleme
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    // VisitorRegistrationScreen'deki gibi tekrarla (tersine çevirme yok)
    _animationController.repeat(reverse: false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Themed TextFormField helper
  Widget _buildThemedTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          obscureText: isPassword && !isVisible,
          decoration: InputDecoration(
            hintText: isPassword ? '******' : null,
            hintStyle: const TextStyle(color: Colors.black87),
            filled: true,
            fillColor: kInputFillColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black54,
                    ),
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    // BİREBİR AYNI ORAN: Mavi alan ekranın %12'si (VisitorScreen'den alındı)
    final double blueSectionHeight = screenHeight * 0.12;
    final double separatorPosition =
        blueSectionHeight; // Formun başlayacağı çizgi

    // Animasyon boyutu (VisitorScreen'den alındı)
    const double lottieHeight = 80;
    const double lottieWidth = 100;

    // Animasyonun dikey konumu: Formun başladığı çizginin 80px üzerine
    final double lottiePositionTop = separatorPosition - lottieHeight;

    // Yatay hareket miktarı (Ekran genişliğinden animasyon genişliğini çıkar)
    final double carMoveRange = screenWidth - lottieWidth;

    return Scaffold(
      backgroundColor: kLightBlue, // Mavi alanın rengi
      body: Stack(
        children: [
          // 1. Mavi Alan (Üst %12)
          Container(
              height: screenHeight, width: double.infinity, color: kLightBlue),

          // 2. Lottie Animasyonu (Hareketli - Visitor'daki gibi tek yönlü)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // VisitorRegistrationScreen'deki gibi hesaplama:
              // 1.0 -> 0.0 değeri (carMoveRange) ile çarpılır.
              final double carX = _animation.value * carMoveRange;

              return Positioned(
                // Animasyonun dikey konumu, formun başlangıç çizgisinin hemen üstü
                top: lottiePositionTop,
                left: carX,
                child: child!,
              );
            },
            child: Lottie.asset(
              'assets/lottie/tourists.json.json', // Dosya adını düzelttim.
              width: lottieWidth,
              height: lottieHeight,
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(height: 1);
              },
            ),
          ),

          // 3. Turuncu Alan (Form Alanı) - Yuvarlak geçişi koruduk
          Positioned.fill(
            top: separatorPosition, // Form, mavi alanın bittiği yerden başlar
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                // Yuvarlak bir geçiş istendiği için Container'a dekorasyon ekliyoruz
                decoration: BoxDecoration(
                    color: kLightOrange, // Turuncu renk burada başlar.
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(
                          30.0), // Yuvarlak köşe (Overlap simülasyonu)
                      topRight: Radius.circular(30.0), // Yuvarlak köşe
                    )),
                padding: const EdgeInsets.all(30),
                constraints:
                    BoxConstraints(minHeight: screenHeight - separatorPosition),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Başlıklar
                      const SizedBox(
                          height: 30), // Lottie animasyonuna yer açmak için
                      const Text('Welcome',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      const Text('Back',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 40),

                      // Email field
                      _buildThemedTextFormField(
                        controller: _emailController,
                        labelText: 'EMAIL',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty || !v.contains('@')
                            ? 'Valid email is required.'
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Password field
                      _buildThemedTextFormField(
                        controller: _passwordController,
                        labelText: 'PASSWORD',
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        onToggle: () => setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        }),
                        validator: (v) => v!.length < 6
                            ? 'Password must be at least 6 characters.'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Forgot Password button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Placeholder for Forgot Password logic
                          },
                          child: Text('Forgot Password?',
                              style: TextStyle(
                                  color: kPrimaryBlue,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- LOG IN BUTONU GÜNCELLENDİ ---
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOrangeButton,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('LOG IN',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      // --- GÜNCELLEME BİTTİ ---
                      const SizedBox(height: 40),

                      // Register Now Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: () {
                              // Selection screen'a geri dönüyoruz
                              Navigator.pop(context);
                            },
                            child: Text('Register Now',
                                style: TextStyle(
                                    color: kPrimaryBlue,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Geri Butonu
          Positioned(
            top: 40,
            left: 20,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: kPrimaryBlue),
              label: const Text('Back',
                  style: TextStyle(color: kPrimaryBlue, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
