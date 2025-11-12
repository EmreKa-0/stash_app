import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../utils/app_styles.dart';
import 'employee_dashboard_screen.dart';
import '../utils/database_helper.dart';
import '../models/user_models.dart';

class EmployeeRegistrationScreen extends StatefulWidget {
  const EmployeeRegistrationScreen({super.key});

  @override
  State<EmployeeRegistrationScreen> createState() =>
      _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState extends State<EmployeeRegistrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  // YENİ: Adres Controller
  final TextEditingController _addressController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    _employeeIdController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _taxIdController.dispose();
    _shopNameController.dispose();
    _addressController.dispose(); // YENİ
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match.')));
        return;
      }

      try {
        // Çalışan nesnesini oluştur (Adres dahil)
        Employee newEmployee = Employee(
          employeeId: _employeeIdController.text,
          firstName: _nameController.text,
          lastName: _surnameController.text,
          phone: _phoneController.text,
          shopName: _shopNameController.text,
          taxId: _taxIdController.text,
          address: _addressController.text, // YENİ: Adres eklendi
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Veritabanına kaydet
        await DatabaseHelper.instance.insertEmployee(newEmployee);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee Registration Successful!')));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const EmployeeDashboardScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Registration Failed: $e')));
      }
    }
  }

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
    final double topPosition = screenHeight * 0.12;
    const double lottieHeight = 80;
    const double lottieWidth = 100;
    final double lottiePositionTop = topPosition - lottieHeight;
    final double carMoveRange = screenWidth - lottieWidth;

    return Scaffold(
      backgroundColor: kLightBlue,
      body: Stack(
        children: [
          Container(
              height: screenHeight, width: double.infinity, color: kLightBlue),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final double carX = _animation.value * carMoveRange;
              return Positioned(
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
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox(height: 1),
            ),
          ),
          Positioned.fill(
            top: topPosition,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                decoration: BoxDecoration(
                    color: kLightOrange,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                    )),
                padding: const EdgeInsets.all(30),
                constraints: BoxConstraints(
                  minHeight: screenHeight - topPosition,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Create new',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      const Text('Employee Account',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),

                      _buildThemedTextFormField(
                        controller: _employeeIdController,
                        labelText: 'EMPLOYEE ID',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) =>
                            value!.isEmpty ? 'Required.' : null,
                      ),
                      const SizedBox(height: 15),
                      _buildThemedTextFormField(
                          controller: _nameController,
                          labelText: 'FIRST NAME',
                          validator: (value) =>
                              value!.isEmpty ? 'Required.' : null),
                      const SizedBox(height: 15),
                      _buildThemedTextFormField(
                          controller: _surnameController,
                          labelText: 'LAST NAME',
                          validator: (value) =>
                              value!.isEmpty ? 'Required.' : null),
                      const SizedBox(height: 15),
                      _buildThemedTextFormField(
                        controller: _phoneController,
                        labelText: 'PHONE NUMBER',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) =>
                            value!.isEmpty ? 'Required.' : null,
                      ),
                      const SizedBox(height: 15),
                      _buildThemedTextFormField(
                        controller: _shopNameController,
                        labelText: 'SHOP NAME',
                        validator: (value) =>
                            value!.isEmpty ? 'Required.' : null,
                      ),
                      const SizedBox(height: 15),
                      _buildThemedTextFormField(
                        controller: _taxIdController,
                        labelText: 'TAX ID',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) =>
                            value!.isEmpty ? 'Required.' : null,
                      ),
                      const SizedBox(height: 15),

                      // --- YENİ: ADRES ALANI ---
                      _buildThemedTextFormField(
                        controller: _addressController,
                        labelText: 'SHOP ADDRESS',
                        validator: (value) =>
                            value!.isEmpty ? 'Address is required.' : null,
                      ),
                      const SizedBox(height: 15),
                      // -------------------------

                      _buildThemedTextFormField(
                        controller: _emailController,
                        labelText: 'EMAIL',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value!.isEmpty || !value.contains('@')
                                ? 'Valid email required.'
                                : null,
                      ),
                      const SizedBox(height: 15),
                      _buildPasswordTextFormField(
                        controller: _passwordController,
                        labelText: 'PASSWORD',
                        isVisible: _isPasswordVisible,
                        onToggle: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        validator: (v) => v!.length < 6 ? 'Min 6 chars.' : null,
                      ),
                      const SizedBox(height: 15),
                      _buildPasswordTextFormField(
                        controller: _confirmPasswordController,
                        labelText: 'CONFIRM PASSWORD',
                        isVisible: _isConfirmPasswordVisible,
                        onToggle: () => setState(() =>
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                        validator: (value) =>
                            value!.isEmpty ? 'Required.' : null,
                      ),
                      const SizedBox(height: 40),
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
