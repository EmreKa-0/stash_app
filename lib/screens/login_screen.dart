import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_styles.dart';
import 'employee_dashboard_screen.dart';
import 'map_screen.dart';
import 'selection_screen.dart';
import '../services/auth_service.dart';
import 'user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- ┼Ş─░FRE SIFIRLAMA D─░ALOGU ---
  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Reset Password",
            style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter your email address to receive a password reset link.",
                style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 20),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.email, color: kOrangeButton),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kOrangeButton,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Please enter a valid email.")));
                return;
              }

              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Reset link sent! Check your email."),
                    backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Error: $e"), backgroundColor: Colors.red));
              }
            },
            child:
                const Text("Send Link", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- G├£VENL─░ LOGIN FONKS─░YONU ---
  void _login() async {
    // 1. Form ge├ğerli mi kontrol et
    if (!_formKey.currentState!.validate()) return;

    // 2. Klavyeyi kapat
    FocusScope.of(context).unfocus();

    // 3. Y├╝kleniyor ba┼şlat
    if (mounted) setState(() => _isLoading = true);

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      final authService = AuthService();

      // Giri┼ş yapmay─▒ dene
      String? error =
          await authService.loginUser(email: email, password: password);

      if (error != null) {
        // E─şer AuthService bir hata d├Ând├╝rd├╝yse hata f─▒rlat
        throw Exception(error);
      }

      // Giri┼ş ba┼şar─▒l─▒, kullan─▒c─▒ verisini ├ğek
      Map<String, dynamic>? userData = await authService.getUserData();

      if (userData == null) {
        throw Exception("Kullan─▒c─▒ verisi veritaban─▒nda bulunamad─▒.");
      }

      String userType = userData['userType'] ?? 'visitor';
      String firstName = userData['name'] ?? 'User';

      // Oturumu kaydet
      UserSession.login(
        name: firstName,
        email: email,
        type: userType,
      );

      if (!mounted) return;

      // Y├Ânlendirme yap (Burada isLoading'i false yapmaya gerek yok, sayfa de─şi┼şiyor)
      if (userType == 'employee') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const EmployeeDashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // B─░R HATA OLURSA BURAYA D├£┼ŞER
      debugPrint("Login Hatas─▒: $e"); // Konsola hatay─▒ yaz

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                // Hata mesaj─▒n─▒ ekrana bas (Exception: kelimesini temizle)
                Expanded(
                    child: Text(e.toString().replaceAll('Exception: ', ''))),
              ],
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // NE OLURSA OLSUN Y├£KLEMEY─░ DURDUR
      // (E─şer sayfa de─şi┼şmediyse ├ğark─▒ durdurur)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _signInWithGoogle() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      String? error = await authService.signInWithGoogle();

      if (error == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          String userType = 'visitor';
          String userName = user.displayName ?? 'User';

          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            userType = data['userType'] ?? 'visitor';
            if (data.containsKey('name')) userName = data['name'];
          }

          UserSession.login(
            name: userName,
            email: user.email ?? '',
            type: userType,
          );

          if (!mounted) return;

          if (userType == 'employee') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const EmployeeDashboardScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
              (route) => false,
            );
          }
        }
      } else {
        if (!mounted) return;
        if (!error.contains("cancelled")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In Error: $e"),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
            color: kPrimaryBlue, fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: kPrimaryBlue.withOpacity(0.7)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kOrangeButton.withOpacity(0.8), kOrangeButton],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: kOrangeButton,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: kLightOrange.withOpacity(0.3), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: kOrangeButton, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
              ...List.generate(3, (index) {
                return Positioned(
                  top: 100.0 * index,
                  left: index.isEven ? -50 : null,
                  right: index.isOdd ? -50 : null,
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(seconds: 3 + index),
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * value),
                        child: Opacity(
                          opacity: 0.1,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  index.isEven ? kOrangeButton : kPrimaryBlue,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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

                            const SizedBox(height: 40),

                            Center(
                              child: Hero(
                                tag: 'app_logo',
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [kOrangeButton, kLightOrange],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kOrangeButton.withOpacity(0.4),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: Lottie.asset(
                                    'assets/lottie/travelling_girl.json',
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.white),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            Text(
                              'Welcome\nBack!',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: kPrimaryBlue,
                                height: 1.2,
                                letterSpacing: -1,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Login to continue your journey',
                              style: TextStyle(
                                fontSize: 16,
                                color: kPrimaryBlue.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 40),

                            _buildGlassField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v!.isEmpty || !v.contains('@')
                                  ? 'Please enter a valid email'
                                  : null,
                            ),

                            _buildGlassField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              validator: (v) => v!.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),

                            // Forgot Password (G├╝ncellendi)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    _showForgotPasswordDialog, // Yeni metoda ba─şland─▒
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: kOrangeButton,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

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
                                onPressed: _isLoading ? null : _login,
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
                                            'LOGIN',
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
                                      color: kPrimaryBlue.withOpacity(0.3)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: kPrimaryBlue.withOpacity(0.5),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                      color: kPrimaryBlue.withOpacity(0.3)),
                                ),
                              ],
                            ),

                            // ... ├╝stteki kodlar (Divider vs.) ayn─▒ kal─▒yor

                            const SizedBox(height: 24),

                            GoogleAuthButton(
                              text: 'Sign in with Google',
                              isLoading: _isLoading,
                              onPressed: _signInWithGoogle,
                            ),

                            const SizedBox(
                                height: 30), // Art─▒k burada hata almayacaks─▒n

// ... alttaki Don't have an account k─▒sm─▒ ayn─▒ kal─▒yor

                            const SizedBox(height: 30),

                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: kLightOrange.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SelectionScreen(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: TextStyle(
                                          color: kPrimaryBlue.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: kOrangeButton,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.arrow_forward,
                                          color: kOrangeButton, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
