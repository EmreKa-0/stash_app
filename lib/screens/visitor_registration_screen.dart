import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../utils/app_styles.dart';
import '../utils/validators.dart'; // Ô£à Validators import edildi
import 'login_screen.dart';
import 'map_screen.dart' show MapScreen;
import '../services/auth_service.dart';

class VisitorRegistrationScreen extends StatefulWidget {
  const VisitorRegistrationScreen({super.key});

  @override
  State<VisitorRegistrationScreen> createState() =>
      _VisitorRegistrationScreenState();
}

class _VisitorRegistrationScreenState extends State<VisitorRegistrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  bool _isLoading = false;

  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    double strength = 0.0;
    String text = '';
    Color color = Colors.grey;

    if (password.isEmpty) {
      strength = 0.0;
      text = '';
    } else if (password.length < 6) {
      strength = 0.25;
      text = 'Weak';
      color = Colors.red;
    } else if (password.length < 8) {
      strength = 0.5;
      text = 'Fair';
      color = Colors.orange;
    } else if (password.length < 10 && password.contains(RegExp(r'[A-Z]'))) {
      strength = 0.75;
      text = 'Good';
      color = Colors.blue;
    } else if (password.length >= 10 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'))) {
      strength = 1.0;
      text = 'Strong';
      color = Colors.green;
    } else {
      strength = 0.6;
      text = 'Fair';
      color = Colors.orange;
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = text;
      _passwordStrengthColor = color;
    });
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

  void _registerVisitor() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please correct the highlighted fields.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    final authService = AuthService();

    String idOrPassportValue = _isTcknSelected
        ? _tcknController.text.trim()
        : _passportController.text.trim();

    String? error = await authService.registerVisitor(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      firstName: _nameController.text.trim(),
      lastName: _surnameController.text.trim(),
      phone: _phoneController.text.trim(),
      idOrPassport: idOrPassportValue,
      gender: _selectedGender ?? 'Other',
      age: int.tryParse(_ageController.text) ?? 18,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      _showSuccessSnackBar('Registration Successful! Please Login.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } else {
      _showErrorSnackBar(error);
    }
  }

  void _registerWithGoogle() async {
    setState(() => _isLoading = true);
    final authService = AuthService();
    String? error = await authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      _showSuccessSnackBar('Google Sign-In Successful!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MapScreen()),
        (route) => false,
      );
    } else {
      if (!error.contains("cancelled")) {
        _showErrorSnackBar(error);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool isPassword = false,
    bool? isVisible,
    VoidCallback? onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        obscureText: isPassword && !(isVisible ?? false),
        style: TextStyle(
            color: kPrimaryBlue, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: kPrimaryBlue.withOpacity(0.7), fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kOrangeButton.withOpacity(0.8), kOrangeButton],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          suffixIcon: isPassword && onToggle != null
              ? IconButton(
                  icon: Icon(
                    (isVisible ?? false)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: kOrangeButton,
                    size: 20,
                  ),
                  onPressed: onToggle,
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: kLightOrange.withOpacity(0.3), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: kOrangeButton, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kLightBlue,
              kLightBlue.withOpacity(0.8),
              kLightOrange.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated Background
              Positioned(
                top: -50,
                right: -50,
                child: Opacity(
                  opacity: 0.15,
                  child: Lottie.asset(
                    'assets/lottie/travelling_girl.json',
                    width: 250,
                    height: 250,
                    repeat: true,
                  ),
                ),
              ),

              ...List.generate(3, (index) {
                return Positioned(
                  top: 100.0 * index + 200,
                  left: index.isEven ? -30 : null,
                  right: index.isOdd ? -30 : null,
                  child: Opacity(
                    opacity: 0.08,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index.isEven ? kOrangeButton : kPrimaryBlue,
                      ),
                    ),
                  ),
                );
              }),

              // Main Content
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios_new,
                                color: kPrimaryBlue),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlue,
                              ),
                            ),
                            Text(
                              'Visitor Registration',
                              style: TextStyle(
                                fontSize: 12,
                                color: kPrimaryBlue.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 10),

                                // ID Type Selection
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: kLightOrange.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _isTcknSelected = true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            decoration: BoxDecoration(
                                              gradient: _isTcknSelected
                                                  ? LinearGradient(
                                                      colors: [
                                                        kOrangeButton,
                                                        kOrangeButton
                                                            .withOpacity(0.8)
                                                      ],
                                                    )
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'ID Number',
                                                style: TextStyle(
                                                  color: _isTcknSelected
                                                      ? Colors.white
                                                      : kPrimaryBlue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _isTcknSelected = false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            decoration: BoxDecoration(
                                              gradient: !_isTcknSelected
                                                  ? LinearGradient(
                                                      colors: [
                                                        kOrangeButton,
                                                        kOrangeButton
                                                            .withOpacity(0.8)
                                                      ],
                                                    )
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Passport',
                                                style: TextStyle(
                                                  color: !_isTcknSelected
                                                      ? Colors.white
                                                      : kPrimaryBlue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ID/Passport Field
                                _isTcknSelected
                                    ? _buildModernField(
                                        controller: _tcknController,
                                        label: 'ID NUMBER',
                                        icon: Icons.badge_outlined,
                                        keyboardType: TextInputType.number,
                                        maxLength: 11,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        validator: (value) =>
                                            value!.length != 11
                                                ? 'ID must be 11 digits'
                                                : null,
                                      )
                                    : _buildModernField(
                                        controller: _passportController,
                                        label: 'PASSPORT NUMBER',
                                        icon: Icons.document_scanner_outlined,
                                        validator: (value) => value!.isEmpty
                                            ? 'Passport is required'
                                            : null,
                                      ),

                                // Name & Surname (GLOBAL UNICODE UPDATE)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildModernField(
                                        controller: _nameController,
                                        label: 'FIRST NAME',
                                        icon: Icons.person_outline,
                                        // Ô£à Validators.validateName kullan─▒m─▒
                                        validator: Validators.validateName,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildModernField(
                                        controller: _surnameController,
                                        label: 'LAST NAME',
                                        icon: Icons.person_outline,
                                        // Ô£à Validators.validateName kullan─▒m─▒
                                        validator: Validators.validateName,
                                      ),
                                    ),
                                  ],
                                ),

                                // Gender & Age
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedGender,
                                          dropdownColor:
                                              kLightBlue.withOpacity(0.9),
                                          icon: Icon(Icons.arrow_drop_down,
                                              color: kPrimaryBlue
                                                  .withOpacity(0.7)),
                                          style: TextStyle(
                                              color: kLightOrange,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600),
                                          elevation: 8,
                                          isExpanded: true,
                                          menuMaxHeight: 200,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          decoration: InputDecoration(
                                            labelText: 'GENDER',
                                            labelStyle: TextStyle(
                                              color:
                                                  kPrimaryBlue.withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(12),
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    kOrangeButton
                                                        .withOpacity(0.8),
                                                    kOrangeButton
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.wc,
                                                  color: Colors.white,
                                                  size: 18),
                                            ),
                                            filled: true,
                                            fillColor:
                                                Colors.white.withOpacity(0.9),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: kLightOrange
                                                    .withOpacity(0.3),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          items: ['Female', 'Male', 'Other']
                                              .map((v) => DropdownMenuItem(
                                                  value: v, child: Text(v)))
                                              .toList(),
                                          onChanged: (v) => setState(
                                              () => _selectedGender = v),
                                          validator: (v) =>
                                              v == null ? 'Required' : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildModernField(
                                        controller: _ageController,
                                        label: 'AGE',
                                        icon: Icons.cake_outlined,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(3),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Required';
                                          int? age = int.tryParse(value);
                                          if (age == null || age > 120)
                                            return 'Max 120';
                                          if (age < 18)
                                            return 'Min 18';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                // Phone
                                _buildModernField(
                                  controller: _phoneController,
                                  label: 'PHONE NUMBER',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  // Ô£à Global Phone Regex Kullan─▒m─▒
                                  validator: Validators.validatePhone,
                                ),

                                // Email
                                _buildModernField(
                                  controller: _emailController,
                                  label: 'EMAIL',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.validateEmail,
                                ),

                                // Password
                                _buildModernField(
                                  controller: _passwordController,
                                  label: 'PASSWORD',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  isVisible: _isPasswordVisible,
                                  onToggle: () => setState(() =>
                                      _isPasswordVisible = !_isPasswordVisible),
                                  validator: (v) =>
                                      v!.length < 6 ? 'Min 6 characters' : null,
                                ),

                                if (_passwordController.text.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: LinearProgressIndicator(
                                                  value: _passwordStrength,
                                                  backgroundColor:
                                                      Colors.grey.shade300,
                                                  color: _passwordStrengthColor,
                                                  minHeight: 6,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _passwordStrengthText,
                                              style: TextStyle(
                                                color: _passwordStrengthColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                // Confirm Password
                                _buildModernField(
                                  controller: _confirmPasswordController,
                                  label: 'CONFIRM PASSWORD',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  isVisible: _isConfirmPasswordVisible,
                                  onToggle: () => setState(() =>
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible),
                                  validator: (value) => value!.isEmpty
                                      ? 'Please confirm password'
                                      : null,
                                ),

                                const SizedBox(height: 30),

                                // Sign Up Button
                                Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        kOrangeButton,
                                        kOrangeButton.withOpacity(0.8)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kOrangeButton.withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _registerVisitor,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                'SIGN UP',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward,
                                                  color: Colors.white),
                                            ],
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color:
                                                kPrimaryBlue.withOpacity(0.3))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: kPrimaryBlue.withOpacity(0.5),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color:
                                                kPrimaryBlue.withOpacity(0.3))),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Google Button
                                GoogleAuthButton(
                                  text: 'Sign up with Google',
                                  isLoading: _isLoading,
                                  onPressed: _registerWithGoogle,
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
