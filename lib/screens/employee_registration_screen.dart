import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../utils/app_styles.dart';
import 'employee_dashboard_screen.dart'; // Kayıttan sonra yönlendirilecek ekran

class EmployeeRegistrationScreen extends StatefulWidget {
  const EmployeeRegistrationScreen({super.key});

  @override
  State<EmployeeRegistrationScreen> createState() =>
      _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState extends State<EmployeeRegistrationScreen>
    with SingleTickerProviderStateMixin {
  // Animasyon için Ticker mixin

  // --- Animation Controllers ---
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Controller'lar
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // EK ALANLAR (Yeni eklenenler)
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Şifre görünürlük durumları
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Animasyon Ayarları
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _animationController.repeat(reverse: false);
  }

  @override
  void dispose() {
    _animationController.dispose(); // Animasyon controller dispose edildi
    _employeeIdController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _taxIdController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match.')));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee Registration Successful!')));
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const EmployeeDashboardScreen()),
      );
    }
  }

  // Ortak kullanılan tema uyumlu TextFormField (Şifre hariç)
  Widget _buildThemedTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
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
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintStyle: const TextStyle(color: Colors.black87),
            filled: true,
            fillColor: kInputFillColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  // Şifre alanları için özel widget (Göz butonu)
  Widget _buildPasswordTextFormField({
    required TextEditingController controller,
    required String labelText,
    required bool isVisible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
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
          obscureText: !isVisible,
          validator: validator,
          decoration: InputDecoration(
            hintText: '******',
            hintStyle: const TextStyle(color: Colors.black87),
            filled: true,
            fillColor: kInputFillColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black54),
              onPressed: onToggle, // Toggle işlemi
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    // ORANSAL AYARLAR (VisitorRegistrationScreen ve LoginScreen ile aynı)
    final double blueSectionHeight = screenHeight * 0.12;
    // HATA DÜZELTME: Formun başlangıç pozisyonunu topPosition olarak tanımlıyoruz
    final double topPosition = blueSectionHeight;

    // Animasyon boyutu
    const double lottieHeight = 80;
    const double lottieWidth = 100;

    // Animasyonun dikey konumu: Formun başladığı çizginin 80px üzerine
    final double lottiePositionTop =
        topPosition - lottieHeight; // DÜZELTME YAPILDI

    // Yatay hareket miktarı
    final double carMoveRange = screenWidth - lottieWidth;

    return Scaffold(
      backgroundColor: kLightBlue,
      body: Stack(
        children: [
          // 1. Mavi alanın dolgusu
          Container(
              height: screenHeight, width: double.infinity, color: kLightBlue),

          // 2. Lottie Animasyonu (Hareketli)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final double carX = _animation.value * carMoveRange;

              return Positioned(
                // Animasyonun dikey konumu, formun başlangıç çizgisinin hemen üstü
                top: lottiePositionTop,
                left: carX,
                child: child!,
              );
            },
            child: Lottie.asset(
              'assets/lottie/tourists.json.json',
              width: lottieWidth,
              height: lottieHeight,
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(height: 1);
              },
            ),
          ),

          // 3. Turuncu Alan (Form Alanı) - Yuvarlak geçişi uyguluyoruz
          Positioned.fill(
            top: topPosition, // Form, mavi alanın bittiği yerden başlar
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                // Yuvarlak bir geçiş için dekorasyon ekleniyor
                decoration: BoxDecoration(
                    color: kLightOrange,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30.0), // Yuvarlak köşe
                      topRight: Radius.circular(30.0), // Yuvarlak köşe
                    )),
                padding: const EdgeInsets.only(
                    top: 30, left: 30, right: 30, bottom: 30),
                constraints: BoxConstraints(
                  // Ekranın alt kısmına kadar uzamayı garanti eder
                  minHeight: screenHeight - topPosition,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Başlıklar
                      const Text('Create new',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      const Text('Employee Account',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 30),

                      // Personel ID
                      _buildThemedTextFormField(
                        controller: _employeeIdController,
                        labelText: 'EMPLOYEE ID',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) =>
                            value!.isEmpty ? 'Employee ID is required.' : null,
                      ),
                      const SizedBox(height: 15),

                      // İsim
                      _buildThemedTextFormField(
                          controller: _nameController,
                          labelText: 'FIRST NAME',
                          validator: (value) => value!.isEmpty
                              ? 'First name is required.'
                              : null),
                      const SizedBox(height: 15),

                      // Soyisim
                      _buildThemedTextFormField(
                          controller: _surnameController,
                          labelText: 'LAST NAME',
                          validator: (value) =>
                              value!.isEmpty ? 'Last name is required.' : null),
                      const SizedBox(height: 15),

                      // TELEFON
                      _buildThemedTextFormField(
                        controller: _phoneController,
                        labelText: 'PHONE NUMBER',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) =>
                            value!.isEmpty ? 'Phone number is required.' : null,
                      ),
                      const SizedBox(height: 15),

                      // DÜKKAN ADI
                      _buildThemedTextFormField(
                        controller: _shopNameController,
                        labelText: 'SHOP NAME',
                        validator: (value) =>
                            value!.isEmpty ? 'Shop Name is required.' : null,
                      ),
                      const SizedBox(height: 15),

                      // VERGİ NUMARASI
                      _buildThemedTextFormField(
                        controller: _taxIdController,
                        labelText: 'TAX ID',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) =>
                            value!.isEmpty ? 'Tax ID is required.' : null,
                      ),
                      const SizedBox(height: 15),

                      // E-posta
                      _buildThemedTextFormField(
                        controller: _emailController,
                        labelText: 'EMAIL',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value!.isEmpty || !value.contains('@')
                                ? 'Please enter a valid email address.'
                                : null,
                      ),
                      const SizedBox(height: 15),

                      // Şifre
                      _buildPasswordTextFormField(
                        controller: _passwordController,
                        labelText: 'PASSWORD',
                        isVisible: _isPasswordVisible,
                        onToggle: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        validator: (v) => v!.length < 6
                            ? 'Password must be at least 6 characters.'
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Şifre Tekrar
                      _buildPasswordTextFormField(
                        controller: _confirmPasswordController,
                        labelText: 'CONFIRM PASSWORD',
                        isVisible: _isConfirmPasswordVisible,
                        onToggle: () => setState(() =>
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                        validator: (value) => value!.isEmpty
                            ? 'Please confirm your password.'
                            : null,
                      ),
                      const SizedBox(height: 40),

                      // SIGN UP Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOrangeButton,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.5),
                          ),
                          child: const Text('SIGN UP',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Geri Butonu (Sabit)
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
