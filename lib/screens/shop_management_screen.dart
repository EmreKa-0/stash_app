import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../utils/app_styles.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();

  bool _isOpen = false;
  bool _isLoading = true;
  bool _isSaving = false;

  Map<String, dynamic> _allCitiesData = {};
  List<String> _cities = [];
  List<String> _districts = [];
  String? _selectedCity;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Hem lokasyon verilerini hem de dükkan bilgilerini yükle
  Future<void> _loadInitialData() async {
    await _loadLocationJson();
    await _fetchShopData();
    if (mounted) setState(() => _isLoading = false);
  }

  // tr_locations.json verisini yükle
  Future<void> _loadLocationJson() async {
    try {
      final jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/locations/tr_locations.json');
      final List<dynamic> dataList = json.decode(jsonString);
      final Map<String, Map<String, dynamic>> cityMap = {};

      for (var provinceData in dataList) {
        if (provinceData is Map<String, dynamic> &&
            provinceData.containsKey('name')) {
          final String provinceName = provinceData['name'];
          final Map<String, dynamic> districtMap = {};
          if (provinceData.containsKey('towns') &&
              provinceData['towns'] is List) {
            for (var districtData in provinceData['towns']) {
              if (districtData is Map<String, dynamic> &&
                  districtData.containsKey('name')) {
                districtMap[districtData['name']] = {};
              }
            }
          }
          cityMap[provinceName] = districtMap;
        }
      }
      _allCitiesData = cityMap;
      _cities = cityMap.keys.toList().cast<String>();
    } catch (e) {
      debugPrint('Lokasyon yükleme hatası: $e');
    }
  }

  // Dükkan sahibinin verilerini çek (Null Safety kontrollü)
  Future<void> _fetchShopData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _priceController.text = (data['pricePerDay'] ?? 0).toString();
          _isOpen = data['isOpen'] ?? false;
          _selectedCity = data['city'];

          if (_selectedCity != null &&
              _allCitiesData.containsKey(_selectedCity)) {
            _districts = (_allCitiesData[_selectedCity] as Map)
                .keys
                .toList()
                .cast<String>();
            _selectedDistrict = data['district'];
          }
        });
      }
    } catch (e) {
      debugPrint('Dükkan verisi çekme hatası: $e');
    }
  }

  // Değişiklikleri Kaydet (Null Safety / uid hatası düzeltildi)
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Oturum hatası! Lütfen tekrar giriş yapın.")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'pricePerDay': double.parse(_priceController.text),
        'isOpen': _isOpen,
        'city': _selectedCity,
        'district': _selectedDistrict,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Bilgiler başarıyla güncellendi!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kLightBlue,
              kLightBlue.withOpacity(0.8),
              kLightOrange.withOpacity(0.2)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst Bölüm (Geri Butonu ve Başlık)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon:
                            Icon(Icons.arrow_back_ios_new, color: kPrimaryBlue),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Shop Management",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5))
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dükkan Durumu
                          _buildSectionTitle("Shop Visibility"),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: _isOpen
                                  ? Colors.green.withOpacity(0.05)
                                  : Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _isOpen
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.red.withOpacity(0.3)),
                            ),
                            child: SwitchListTile(
                              title: Text(
                                _isOpen ? "SHOP IS OPEN" : "SHOP IS CLOSED",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isOpen ? Colors.green : Colors.red),
                              ),
                              subtitle: const Text(
                                  "Control if your shop appears on the map."),
                              value: _isOpen,
                              activeColor: Colors.green,
                              onChanged: (val) => setState(() => _isOpen = val),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Ücretlendirme
                          _buildSectionTitle("Daily Storage Fee"),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _priceController,
                            icon: Icons.monetization_on_outlined,
                            hint: "Enter price (e.g. 50)",
                            label: "Price per Bag (TL)",
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 30),

                          // Konum Bilgileri
                          _buildSectionTitle("Address Information"),
                          const SizedBox(height: 12),
                          _buildLocationDropdown("City", _selectedCity, _cities,
                              (val) {
                            setState(() {
                              _selectedCity = val;
                              _selectedDistrict = null;
                              _districts = (_allCitiesData[val] as Map)
                                  .keys
                                  .toList()
                                  .cast<String>();
                            });
                          }),
                          const SizedBox(height: 16),
                          _buildLocationDropdown(
                              "District", _selectedDistrict, _districts, (val) {
                            setState(() => _selectedDistrict = val);
                          }),

                          const SizedBox(height: 40),

                          // Kaydet Butonu
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  kOrangeButton,
                                  kOrangeButton.withOpacity(0.8)
                                ]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: kOrangeButton.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5))
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _isSaving ? null : _saveChanges,
                                child: _isSaving
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text("UPDATE SHOP",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2)),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: kPrimaryBlue.withOpacity(0.8)),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required IconData icon,
      required String hint,
      required String label,
      TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kOrangeButton),
        hintText: hint,
        filled: true,
        fillColor: kLightBlue.withOpacity(0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: kOrangeButton, width: 2)),
      ),
      validator: (v) => v!.isEmpty ? "This field is required" : null,
    );
  }

  Widget _buildLocationDropdown(String label, String? currentValue,
      List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      hint: Text('Select $label'),
      style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kPrimaryBlue.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: kLightBlue)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: kOrangeButton, width: 2)),
      ),
      items: items
          .map((city) => DropdownMenuItem(value: city, child: Text(city)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
