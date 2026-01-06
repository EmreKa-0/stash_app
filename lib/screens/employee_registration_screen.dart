import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/app_styles.dart';
import '../utils/validators.dart'; // Ô£à Global Validators Import
import 'shop_store.dart';
import 'location_picker_screen.dart';
import 'map_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class EmployeeRegistrationScreen extends StatefulWidget {
  const EmployeeRegistrationScreen({super.key});

  @override
  State<EmployeeRegistrationScreen> createState() =>
      _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState extends State<EmployeeRegistrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  LatLng? _finalShopCoordinates;
  bool _isLocationPicked = false;
  bool _isGeocodingLoading = false;

  final _formKey = GlobalKey<FormState>();
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

    if (password.isEmpty) { strength = 0.0; text = ''; }
    else if (password.length < 6) { strength = 0.25; text = 'Weak'; color = Colors.red; }
    else if (password.length < 8) { strength = 0.5; text = 'Fair'; color = Colors.orange; }
    else if (password.length < 10 && password.contains(RegExp(r'[A-Z]'))) { strength = 0.75; text = 'Good'; color = Colors.blue; }
    else if (password.length >= 10 && password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[0-9]'))) { strength = 1.0; text = 'Strong'; color = Colors.green; }
    else { strength = 0.6; text = 'Fair'; color = Colors.orange; }

    setState(() { _passwordStrength = strength; _passwordStrengthText = text; _passwordStrengthColor = color; });
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
    _addressController.dispose();
    super.dispose();
  }

  // --- REGEX & VALIDATION ---
  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'Address required';
    if (value.length < 15) return 'Address too short (min 15 chars)';
    int wordCount = value.trim().split(RegExp(r'\s+')).length;
    if (wordCount < 3) return 'Enter full address (City/District/Street)';
    return null;
  }

  // --- GOOGLE REGISTER ---
  void _registerWithGoogle() async {
    if (_validateAddress(_addressController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_validateAddress(_addressController.text)!), backgroundColor: Colors.red));
      return;
    }

    if (_nameController.text.isEmpty || _surnameController.text.isEmpty || _phoneController.text.isEmpty ||
        _shopNameController.text.isEmpty || _addressController.text.isEmpty || _taxIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all Shop details.'), backgroundColor: Colors.orange));
      return;
    }

    if (!_isLocationPicked || _finalShopCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pin your shop location on the map first.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check existing shop data first
      await ShopStore.verifyNewShopData(
        _addressController.text, 
        _taxIdController.text, 
        _finalShopCoordinates!.latitude, 
        _finalShopCoordinates!.longitude
      );

      final authService = AuthService();
      String? error = await authService.signInWithGoogle();

      if (error == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await ShopStore.saveShopToFirestore(
            uid: user.uid,
            email: user.email ?? '',
            name: '${_nameController.text.trim()} ${_surnameController.text.trim()}',
            shopName: _shopNameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            latitude: _finalShopCoordinates!.latitude,
            longitude: _finalShopCoordinates!.longitude,
            taxId: _taxIdController.text.trim(),
          );
        }

        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        // Only show error if it's not a cancellation
        if (!error.contains("cancelled")) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      String msg = "Error: $e";
      // Translate specific Firebase errors to English
      if (e is FirebaseAuthException) {
        if (e.code == 'address-already-exists') msg = "A shop with this address already exists!";
        if (e.code == 'tax-id-already-exists') msg = "This Tax ID is already in use!";
        if (e.code == 'location-already-used') msg = "There is already a shop at this location!";
      } else if (e.toString().contains('address-already-exists')) {
         msg = "A shop with this address already exists!";
      } else if (e.toString().contains('tax-id-already-exists')) {
         msg = "This Tax ID is already in use!";
      } else if (e.toString().contains('location-already-used')) {
         msg = "There is already a shop at this location!";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  // --- MANUAL REGISTER ---
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please correct the highlighted fields.'), backgroundColor: Colors.red));
      return;
    }
    if (!_isLocationPicked || _finalShopCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pin your shop location on the map.'), backgroundColor: Colors.orange));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ShopStore.registerShop(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        phone: _phoneController.text.trim(),
        shopName: _shopNameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _finalShopCoordinates!.latitude,
        longitude: _finalShopCoordinates!.longitude,
        taxId: _taxIdController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful! Please Login.'), backgroundColor: Colors.green));
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      String msg = e.message ?? "Registration failed";
      // Convert to English messages
      if (e.code == 'address-already-exists') msg = "A shop with this address already exists!";
      if (e.code == 'tax-id-already-exists') msg = "This Tax ID is already in use!";
      if (e.code == 'location-already-used') msg = "There is already a shop at this location!";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Catch-all for string errors
      String msg = "Error: $e";
      if (e.toString().contains('address-already-exists')) msg = "A shop with this address already exists!";
      else if (e.toString().contains('tax-id-already-exists')) msg = "This Tax ID is already in use!";
      else if (e.toString().contains('location-already-used')) msg = "There is already a shop at this location!";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  // --- LOCATION BUTTON ---
  Widget _buildLocationButton() {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLocationPicked
              ? [Colors.green.shade600, Colors.green.shade700]
              : [kOrangeButton, kOrangeButton.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isLocationPicked ? Colors.green : kOrangeButton).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isGeocodingLoading ? null : () async {
          setState(() => _isGeocodingLoading = true);
          
          LatLng initialPoint = const LatLng(37.2153, 28.3636); // Default Mugla

          if (_addressController.text.isNotEmpty) {
            try {
              List<Location> locations = await locationFromAddress(_addressController.text);
              if (locations.isNotEmpty) {
                initialPoint = LatLng(locations.first.latitude, locations.first.longitude);
              }
            } catch (e) {
              debugPrint("Geocoding failed: $e");
            }
          }

          if (!mounted) return;
          setState(() => _isGeocodingLoading = false);

          final LatLng? result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocationPickerScreen(initialLocation: initialPoint),
            ),
          );

          if (result != null) {
            setState(() {
              _finalShopCoordinates = result;
              _isLocationPicked = true;
            });
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location confirmed!'), backgroundColor: Colors.green));
          }
        },
        icon: _isGeocodingLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : Icon(_isLocationPicked ? Icons.check_circle : Icons.map, color: Colors.white),
        label: Text(
          _isGeocodingLoading ? 'Finding Address...' : (_isLocationPicked ? 'Location Verified' : 'Pin Location on Map'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
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
    bool isPassword = false,
    bool? isVisible,
    VoidCallback? onToggle,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        obscureText: isPassword && !(isVisible ?? false),
        maxLines: maxLines,
        style: TextStyle(color: kPrimaryBlue, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: kPrimaryBlue.withOpacity(0.7), fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kOrangeButton.withOpacity(0.8), kOrangeButton]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          suffixIcon: isPassword && onToggle != null
              ? IconButton(icon: Icon((isVisible ?? false) ? Icons.visibility_off : Icons.visibility, color: kOrangeButton, size: 20), onPressed: onToggle)
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kLightOrange.withOpacity(0.3), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kOrangeButton, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: kLightOrange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: kOrangeButton, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
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
            colors: [kLightBlue, kLightBlue.withOpacity(0.8), kLightOrange.withOpacity(0.3)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -50, right: -50,
                child: Opacity(
                  opacity: 0.15,
                  child: Lottie.asset('assets/lottie/tourists.json', width: 250, height: 250, repeat: true, errorBuilder: (c, e, s) => const SizedBox()),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                          child: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: kPrimaryBlue), onPressed: () => Navigator.pop(context)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Register Business', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                            Text('Employee Registration', style: TextStyle(fontSize: 12, color: kPrimaryBlue.withOpacity(0.6))),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                _buildSectionHeader(Icons.person, 'Personal Information'),
                                const SizedBox(height: 16),
                                _buildModernField(
                                  controller: _employeeIdController,
                                  label: 'EMPLOYEE ID',
                                  icon: Icons.badge_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                                Row(
                                  children: [
                                    Expanded(child: _buildModernField(
                                        controller: _nameController, 
                                        label: 'FIRST NAME', 
                                        icon: Icons.person_outline, 
                                        validator: Validators.validateName // Ô£à Global Validation
                                    )),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildModernField(
                                        controller: _surnameController, 
                                        label: 'LAST NAME', 
                                        icon: Icons.person_outline, 
                                        validator: Validators.validateName // Ô£à Global Validation
                                    )),
                                  ],
                                ),
                                _buildModernField(
                                  controller: _phoneController,
                                  label: 'PHONE NUMBER',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: Validators.validatePhone, // Ô£à Global Validation
                                ),

                                const SizedBox(height: 20),
                                _buildSectionHeader(Icons.store, 'Business Information'),
                                const SizedBox(height: 16),
                                _buildModernField(
                                  controller: _shopNameController,
                                  label: 'SHOP NAME',
                                  icon: Icons.storefront_outlined,
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                                
                                // ADRES
                                _buildModernField(
                                  controller: _addressController,
                                  label: 'FULL SHOP ADDRESS (City/District/Street)',
                                  icon: Icons.location_on_outlined,
                                  maxLines: 3,
                                  validator: _validateAddress,
                                ),
                                
                                _buildLocationButton(),
                                _buildModernField(
                                  controller: _taxIdController,
                                  label: 'TAX ID',
                                  icon: Icons.receipt_long_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),

                                const SizedBox(height: 20),
                                _buildSectionHeader(Icons.security, 'Account Security'),
                                const SizedBox(height: 16),
                                _buildModernField(
                                  controller: _emailController,
                                  label: 'EMAIL',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.validateEmail, // Ô£à Global Validation
                                ),
                                _buildModernField(
                                  controller: _passwordController,
                                  label: 'PASSWORD',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  isVisible: _isPasswordVisible,
                                  onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                                ),
                                if (_passwordController.text.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      children: [
                                        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: _passwordStrength, backgroundColor: Colors.grey.shade300, color: _passwordStrengthColor, minHeight: 6))),
                                        const SizedBox(width: 12),
                                        Text(_passwordStrengthText, style: TextStyle(color: _passwordStrengthColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                _buildModernField(
                                  controller: _confirmPasswordController,
                                  label: 'CONFIRM PASSWORD',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  isVisible: _isConfirmPasswordVisible,
                                  onToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                                  validator: (v) => v!.isEmpty ? 'Please confirm' : null,
                                ),

                                const SizedBox(height: 30),
                                Container(
                                  width: double.infinity, height: 60,
                                  decoration: BoxDecoration(gradient: LinearGradient(colors: [kOrangeButton, kOrangeButton.withOpacity(0.8)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: kOrangeButton.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Text('REGISTER BUSINESS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)), SizedBox(width: 8), Icon(Icons.arrow_forward, color: Colors.white)]),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(children: [Expanded(child: Divider(color: kPrimaryBlue.withOpacity(0.3))), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: kPrimaryBlue.withOpacity(0.5), fontWeight: FontWeight.bold))), Expanded(child: Divider(color: kPrimaryBlue.withOpacity(0.3)))]),
                                const SizedBox(height: 24),
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
