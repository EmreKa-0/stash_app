// lib/screens/visitor_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../utils/app_styles.dart';
import 'baggage_detail_screen.dart';

// --- YENİ EKLENEN IMPORTLAR ---
import '../utils/database_helper.dart';
import '../models/user_models.dart';
// --- BİTİŞ ---

class VisitorRegistrationScreen extends StatefulWidget {
  const VisitorRegistrationScreen({super.key});

  @override
  State<VisitorRegistrationScreen> createState() =>
      _VisitorRegistrationScreenState();
}

class _VisitorRegistrationScreenState extends State<VisitorRegistrationScreen>
    with SingleTickerProviderStateMixin {
  // Gerekli Controllerlar
  final TextEditingController _tcknController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _selectedGender;
  bool _isTcknSelected = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // --- YENİ EKLENDİ ---
  bool _isLoading = false; // Buton için yüklenme durumu

  // Animasyon Controller'ları
  late AnimationController _animationController;
  late Animation<double> _carAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _carAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _animationController.repeat(reverse: false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tcknController.dispose();
    _passportController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- FONKSİYON GÜNCELLENDİ (async eklendi ve DB kodu) ---
  void _navigateToBaggageDetail() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }

      // Yükleniyor...
      setState(() => _isLoading = true);

      try {
        // 1. Visitor nesnesini oluştur
        Visitor newVisitor = Visitor(
          idOrPassport:
              _isTcknSelected ? _tcknController.text : _passportController.text,
          firstName: _nameController.text,
          lastName: _surnameController.text,
          gender: _selectedGender ?? 'Other',
          age: int.tryParse(_ageController.text) ?? 0,
          phone: _phoneController.text,
          email: _emailController.text,
          password:
              _passwordController.text, // Gerçek uygulamada HASH yapılmalı!
        );

        // 2. Veritabanına ekle
        await DatabaseHelper.instance.insertVisitor(newVisitor);

        // 3. Başarılıysa yönlendir
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BaggageDetailScreen()),
        );
      } catch (e) {
        // 4. Hata olursa (örn: e-posta zaten kayıtlı)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt hatası: $e')),
        );
      } finally {
        // 5. Yüklenmeyi durdur
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  // --- GÜNCELLEME BİTTİ ---

  Widget _buildThemedTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
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
          maxLength: maxLength,
          decoration: InputDecoration(
            counterText: '',
            hintStyle: const TextStyle(color: Colors.black87),
            filled: true,
            fillColor: kInputFillColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

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
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black54),
              onPressed: onToggle,
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

    final double blueSectionHeight = screenHeight * 0.12;
    final double separatorPosition = blueSectionHeight;

    return Scaffold(
      backgroundColor: kLightBlue,
      body: Stack(
        children: [
          // 1. Mavi Arka Plan (Tüm ekranı kaplıyor)
          Container(
              height: screenHeight, width: double.infinity, color: kLightBlue),

          // 2. Lottie Animasyonu (Hareketli ve konumu düzeltilmiş)
          AnimatedBuilder(
            animation: _carAnimation,
            builder: (context, child) {
              final double carX = _carAnimation.value * (screenWidth - 100);

              return Positioned(
                top: separatorPosition - 80,
                left: carX,
                child: child!,
              );
            },
            child: Lottie.asset(
              'assets/lottie/tourists.json.json',
              width: 100,
              height: 80,
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(height: 1);
              },
            ),
          ),

          // 3. Turuncu Alan (Düz çizgi başlangıcı)
          Positioned.fill(
            top: separatorPosition,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                color: kLightOrange,
                padding: const EdgeInsets.all(30),
                constraints: BoxConstraints(
                    minHeight: screenHeight - separatorPosition + 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Create new',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      const Text('Visitor Account',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),

                      // --- ID / PASSPORT SELECTION ---
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              activeColor: kPrimaryBlue,
                              title: const Text('ID Number'),
                              value: true,
                              groupValue: _isTcknSelected,
                              onChanged: (bool? value) =>
                                  setState(() => _isTcknSelected = value!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              activeColor: kPrimaryBlue,
                              title: const Text('Passport'),
                              value: false,
                              groupValue: _isTcknSelected,
                              onChanged: (bool? value) =>
                                  setState(() => _isTcknSelected = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // TCKN / Pasaport Numarası Alanı
                      _isTcknSelected
                          ? _buildThemedTextFormField(
                              controller: _tcknController,
                              labelText: 'ID NUMBER',
                              keyboardType: TextInputType.number,
                              maxLength: 11,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) => value!.length != 11
                                  ? 'ID Number must be 11 digits.'
                                  : null,
                            )
                          : _buildThemedTextFormField(
                              controller: _passportController,
                              labelText: 'PASSPORT NUMBER',
                              validator: (value) => value!.isEmpty
                                  ? 'Passport number is required.'
                                  : null,
                            ),
                      const SizedBox(height: 15),

                      // İsim Soyisim
                      _buildThemedTextFormField(
                          controller: _nameController,
                          labelText: 'FIRST NAME',
                          validator: (value) => value!.isEmpty
                              ? 'First name is required.'
                              : null),
                      const SizedBox(height: 15),
                      _buildThemedTextFormField(
                          controller: _surnameController,
                          labelText: 'LAST NAME',
                          validator: (value) =>
                              value!.isEmpty ? 'Last name is required.' : null),
                      const SizedBox(height: 15),

                      // Cinsiyet ve Yaş
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('GENDER',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: kInputFillColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 10),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                  ),
                                  items: ['Female', 'Male', 'Other']
                                      .map((v) => DropdownMenuItem(
                                          value: v, child: Text(v)))
                                      .toList(),
                                  onChanged: (String? newValue) => setState(
                                      () => _selectedGender = newValue),
                                  validator: (v) => v == null
                                      ? 'Gender selection is required.'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildThemedTextFormField(
                              controller: _ageController,
                              labelText: 'AGE',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) =>
                                  value!.isEmpty ? 'Age is required.' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Telefon ve E-posta
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

                      // Şifre Alanları
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

                      _buildPasswordTextFormField(
                        controller: _confirmPasswordController,
                        labelText: 'CONFIRM PASSWORD',
                        isVisible: _isConfirmPasswordVisible,
                        onToggle: () => setState(() =>
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                        validator: (v) =>
                            v!.isEmpty ? 'Please confirm your password.' : null,
                      ),
                      const SizedBox(height: 40),

                      // --- BUTON GÜNCELLENDİ (Loading eklendi) ---
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _navigateToBaggageDetail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOrangeButton,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'SIGN UP AND CONTINUE',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      // --- GÜNCELLEME BİTTİ ---
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Mavi Geri Butonu
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
