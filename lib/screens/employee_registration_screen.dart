import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Lottie animasyonu bu ekranda varsayılan olarak çıkarıldı, istenirse eklenebilir.
// import 'package:lottie/lottie.dart';

import '../utils/app_styles.dart';
import 'employee_dashboard_screen.dart'; // Kayıttan sonra yönlendirilecek ekran

class EmployeeRegistrationScreen extends StatefulWidget {
  const EmployeeRegistrationScreen({super.key});

  @override
  State<EmployeeRegistrationScreen> createState() =>
      _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState
    extends State<EmployeeRegistrationScreen> {
  // Controller'lar
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Şifre görünürlük durumları
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      // Düzeltme: Hata mesajı İngilizce'ye çevrildi
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match.')));
        return;
      }

      // Düzeltme: Başarı mesajı İngilizce'ye çevrildi
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
        // Label Text Düzeltme: Her zaman İngilizce ve büyük harf
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
        // Label Text Düzeltme: Her zaman İngilizce ve büyük harf
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
            hintText: '******', // Şifre alanına hint eklendi
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
    // Mavi kısım yüksekliği: %12 olarak Ziyaretçi ekranı ile eşitlendi
    final double blueSectionHeight = screenHeight * 0.12;

    // Top pozisyonu: Mavi alanın hemen altı
    final double topPosition = blueSectionHeight;

    return Scaffold(
      backgroundColor: kLightBlue,
      body: Stack(
        children: [
          // 1. Turuncu Alan (Düz çizgi başlangıcı)
          Positioned.fill(
            top: topPosition,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                color: kLightOrange,
                padding: const EdgeInsets.only(
                    top: 30, left: 30, right: 30, bottom: 30),
                constraints: BoxConstraints(
                  minHeight: screenHeight - topPosition + 30,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Başlıklar İngilizce'ye çevrildi
                      const Text('Create new',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      const Text('Employee Account',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 30),

                      // Personel ID alanı ve validasyon mesajı İngilizce'ye çevrildi
                      _buildThemedTextFormField(
                        controller: _employeeIdController,
                        labelText: 'EMPLOYEE ID', // GÜNCELLENDİ
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) => value!.isEmpty
                            ? 'Employee ID is required.' // GÜNCELLENDİ
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // İsim ve Soyisim alanları ve validasyon mesajları İngilizce'ye çevrildi
                      _buildThemedTextFormField(
                          controller: _nameController,
                          labelText: 'FIRST NAME', // GÜNCELLENDİ
                          validator: (value) => value!.isEmpty
                              ? 'First name is required.'
                              : null),
                      const SizedBox(height: 15),
                      _buildThemedTextFormField(
                          controller: _surnameController,
                          labelText: 'LAST NAME', // GÜNCELLENDİ
                          validator: (value) =>
                              value!.isEmpty ? 'Last name is required.' : null),
                      const SizedBox(height: 15),

                      // Telefon Numarası alanı ve validasyon mesajı İngilizce'ye çevrildi
                      _buildThemedTextFormField(
                        controller: _phoneController,
                        labelText: 'PHONE NUMBER', // GÜNCELLENDİ
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) => value!.isEmpty
                            ? 'Phone number is required.' // GÜNCELLENDİ
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // E-posta alanı ve validasyon mesajı İngilizce'ye çevrildi
                      _buildThemedTextFormField(
                        controller: _emailController,
                        labelText: 'EMAIL', // GÜNCELLENDİ
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.isEmpty ||
                                !value.contains('@')
                            ? 'Please enter a valid email address.' // GÜNCELLENDİ
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Şifre Alanı ve validasyon mesajı İngilizce'ye çevrildi
                      _buildPasswordTextFormField(
                        controller: _passwordController,
                        labelText: 'PASSWORD', // GÜNCELLENDİ
                        isVisible: _isPasswordVisible,
                        onToggle: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        validator: (v) => v!.length < 6
                            ? 'Password must be at least 6 characters.' // GÜNCELLENDİ
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Şifre Tekrar Alanı ve validasyon mesajı İngilizce'ye çevrildi
                      _buildPasswordTextFormField(
                        controller: _confirmPasswordController,
                        labelText: 'CONFIRM PASSWORD', // GÜNCELLENDİ
                        isVisible: _isConfirmPasswordVisible,
                        onToggle: () => setState(() =>
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                        validator: (value) => value!.isEmpty
                            ? 'Please confirm your password.' // GÜNCELLENDİ
                            : null,
                      ),
                      const SizedBox(height: 40),

                      // SIGN UP Butonu (Renk ve metin doğru)
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

          // 2. Geri Butonu (Sabit)
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
