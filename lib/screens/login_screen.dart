import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Import Lottie
import '../utils/app_styles.dart'; // Assumed dependency for colors
import 'selection_screen.dart'; // Assumed screen for navigation

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    // Blue section height: 25% of screen height
    final double blueSectionHeight = screenHeight * 0.25;

    // Position where the colored sections meet (straight transition)
    final double transitionPosition = blueSectionHeight;

    return Scaffold(
      backgroundColor: kLightBlue,
      body: Stack(
        children: [
          // 1. Blue Background (Needed for background color)
          Container(
              height: screenHeight, width: double.infinity, color: kLightBlue),

          // 2. Walking Man Lottie Animation
          Positioned(
            // Positioned just above the orange section start
            top: transitionPosition - 70,
            left: 0,
            right: 0,
            child: Center(
              child: Lottie.asset(
                // Corrected the likely double extension (.json.json -> .json)
                'assets/lottie/tourists.json.json',
                width: 100,
                height: 80,
                fit: BoxFit.fitWidth,
                repeat: true, // Loop continuously
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(height: 1); // Return empty box on error
                },
              ),
            ),
          ),

          // 3. Orange Area (Scrollable content)
          Positioned(
            top: transitionPosition, // Straight transition start
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                color: kLightOrange,
                padding: const EdgeInsets.only(
                    top: 30, left: 30, right: 30, bottom: 30),
                constraints: BoxConstraints(
                  minHeight: screenHeight - transitionPosition,
                ),
                child: const LoginFormContent(),
              ),
            ),
          ),

          // 4. Back Button (Stays on top)
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

// LoginFormContent Widget (Handles form state and logic)
class LoginFormContent extends StatefulWidget {
  const LoginFormContent({super.key});

  @override
  State<LoginFormContent> createState() => _LoginFormContentState();
}

class _LoginFormContentState extends State<LoginFormContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Password visibility state
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // Translation: 'Giriş Başarılı (Simülasyon)' -> 'Login Successful (Simulation)'
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful (Simulation)')),
      );
      // Navigate to SelectionScreen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SelectionScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Themed TextFormField helper (General use)
  Widget _buildThemedTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.bold)), // Added bold for consistency
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
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

  // Password TextFormField helper (Includes visibility toggle)
  Widget _buildPasswordTextFormField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.bold)), // Added bold for consistency
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: !_isPasswordVisible,
          // Translation: 'Şifre en az 6 karakter olmalıdır.' -> 'Password must be at least 6 characters.'
          validator: (v) =>
              v!.length < 6 ? 'Password must be at least 6 characters.' : null,
          decoration: InputDecoration(
            hintText: '******', // Added hint text for password fields
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
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.black54,
              ),
              onPressed: () {
                // Toggles password visibility
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Welcome',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const Text('Back',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),

          const SizedBox(height: 40),

          // Email field
          _buildThemedTextFormField(
            controller: _emailController,
            // Translation: 'E-POSTA' -> 'EMAIL'
            labelText: 'EMAIL',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.isEmpty || !v.contains('@')
                // Translation: 'Geçerli e-posta gerekli.' -> 'Valid email is required.'
                ? 'Valid email is required.'
                : null,
          ),
          const SizedBox(height: 15),

          // Password field
          _buildPasswordTextFormField(
            controller: _passwordController,
            // Translation: 'ŞİFRE' -> 'PASSWORD'
            labelText: 'PASSWORD',
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
                      color: kPrimaryBlue, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),

          // LOG IN Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrangeButton,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.5),
              ),
              child: const Text('LOG IN',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
