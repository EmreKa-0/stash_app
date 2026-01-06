import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart'; // Tarih formatı için eklendi

import '../utils/app_styles.dart';
import '../models/shop_model.dart';
import 'shop_detail_sheet.dart';
import 'login_screen.dart';
import 'user_session.dart';
import 'selection_screen.dart';
import 'visitor_profile_screen.dart';
import 'active_reservations_screen.dart';
import 'user_history_screen.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Timer? _refreshTimer;
  static const String _cloudFunctionUrl =
      'https://us-central1-stashapp-8ab49.cloudfunctions.net/api';

  bool _showSelectionPanel = false;

  static const latlong.LatLng _initialPosition =
      latlong.LatLng(37.1684, 28.3629);
  double _initialZoom = 15.0;

  // --- FİLTRELEME DEĞİŞKENLERİ ---
  bool _showOnlyOpenNow = false; // "Sadece Şu An Açıklar"
  DateTime? _selectedFilterDate; // Kullanıcının seçtiği gelecek tarih/saat
  
  String _sortBy = 'distance'; // 'distance', 'rating', 'price'
  double? _minRating;
  static const double _priceFilterMin = 0;
  static const double _priceFilterMax = 500;
  RangeValues _priceRange =
      const RangeValues(_priceFilterMin, _priceFilterMax);

  Map<String, dynamic> _allCitiesData = {};
  List<String> _cities = [];
  List<String> _districts = [];

  String? _selectedCity;
  String? _selectedDistrict;

  latlong.LatLng? _userLocation;
  bool _isLoadingLocation = false;
  bool _isLoadingData = true;
  bool _initialCityApplied = false;
  bool _userChangedCity = false;

  // --- TARİH SEÇME FONKSİYONU ---
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    // 1. Tarih Seç
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: kOrangeButton,
            colorScheme: ColorScheme.light(primary: kOrangeButton),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // 2. Saat Seç
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedFilterDate ?? now),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: kOrangeButton,
              colorScheme: ColorScheme.light(primary: kOrangeButton),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          // Tarih ve Saati birleştir
          _selectedFilterDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          // Eğer tarih seçildiyse "Open Now" (Şu an açık) toggle'ını kapat, çakışmasın
          _showOnlyOpenNow = false;
        });
      }
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedFilterDate = null;
    });
  }

  // Calculate distance in kilometers
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  String _normalizeCityName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll('\u011f', 'g')
        .replaceAll('\u0131', 'i')
        .replaceAll('\u015f', 's')
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u00f6', 'o')
        .replaceAll('\u00fc', 'u')
        .replaceAll(RegExp(r'\s+'), '');
  }

  String _formatPrice(double value) {
    return value.toStringAsFixed(0);
  }

  String _formatRatingLabel(double rating) {
    if (rating % 1 == 0) {
      return rating.toStringAsFixed(0);
    }
    return rating.toStringAsFixed(1);
  }

  String _priceRangeLabel() {
    final isDefault = _priceRange.start == _priceFilterMin &&
        _priceRange.end == _priceFilterMax;
    if (isDefault) return 'All Prices';
    return 'TL ${_formatPrice(_priceRange.start)} - ${_formatPrice(_priceRange.end)}';
  }

  void _showRatingFilterSheet() {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  kLightBlue.withOpacity(0.15),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: kLightBlue.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    'Minimum Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Radio<double?>(
                      value: null,
                      groupValue: _minRating,
                      onChanged: (value) {
                        setState(() => _minRating = value);
                        Navigator.pop(context);
                      },
                      activeColor: kOrangeButton,
                    ),
                    title: Text(
                      'All Ratings',
                      style: TextStyle(
                        color: kPrimaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      setState(() => _minRating = null);
                      Navigator.pop(context);
                    },
                  ),
                  ...[3.0, 4.0, 4.5].map((rating) {
                    return ListTile(
                      leading: Radio<double?>(
                        value: rating,
                        groupValue: _minRating,
                        onChanged: (value) {
                          setState(() => _minRating = value);
                          Navigator.pop(context);
                        },
                        activeColor: kOrangeButton,
                      ),
                      title: Text(
                        '${_formatRatingLabel(rating)}+',
                        style: TextStyle(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        setState(() => _minRating = rating);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPriceFilterSheet() {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        RangeValues tempRange = _priceRange;
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      kLightBlue.withOpacity(0.15),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: kLightBlue.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TL ${_formatPrice(tempRange.start)}',
                            style: TextStyle(
                              color: kPrimaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'TL ${_formatPrice(tempRange.end)}',
                            style: TextStyle(
                              color: kPrimaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: tempRange,
                        min: _priceFilterMin,
                        max: _priceFilterMax,
                        divisions: 50,
                        activeColor: kOrangeButton,
                        inactiveColor: kLightBlue.withOpacity(0.5),
                        labels: RangeLabels(
                          'TL ${_formatPrice(tempRange.start)}',
                          'TL ${_formatPrice(tempRange.end)}',
                        ),
                        onChanged: (values) {
                          setModalState(() => tempRange = values);
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempRange = const RangeValues(
                                    _priceFilterMin,
                                    _priceFilterMax,
                                  );
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: kOrangeButton),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Reset',
                                style: TextStyle(
                                  color: kPrimaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _priceRange = tempRange);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kOrangeButton,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _trySetInitialCityFromLocation() async {
    if (_initialCityApplied || _userChangedCity) return;
    if (_userLocation == null || _cities.isEmpty) return;

    try {
      final placemarks = await placemarkFromCoordinates(
        _userLocation!.latitude,
        _userLocation!.longitude,
      );
      if (placemarks.isEmpty) return;

      final adminArea = placemarks.first.administrativeArea ?? '';
      if (adminArea.isEmpty) return;

      final normalizedAdmin = _normalizeCityName(adminArea);
      final matchedCity = _cities.firstWhere(
        (city) => _normalizeCityName(city) == normalizedAdmin,
        orElse: () => '',
      );
      if (matchedCity.isEmpty) return;

      if (!mounted) return;
      setState(() {
        _selectedCity = matchedCity;
        _selectedDistrict = null;
        _initialCityApplied = true;
      });
      if (mounted) {
        _trySetInitialCityFromLocation();
      }
    } catch (e) {
      debugPrint('Initial city lookup failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLocationData();
    _getUserLocation();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocationData() async {
    if (!mounted) return;

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
                final String districtName = districtData['name'];
                districtMap[districtName] = {
                  'lat': 0.0,
                  'lon': 0.0,
                  'neighborhoods': <String>[],
                };
              }
            }
          }
          cityMap[provinceName] = districtMap;
        }
      }

      setState(() {
        _allCitiesData = cityMap;
        _cities = cityMap.keys.toList().cast<String>();
        _isLoadingData = false;

        if (_cities.isNotEmpty && _selectedCity == null) {
          _selectedCity = _cities.first;
        }
      });
    } catch (e) {
      debugPrint('❌ FATAL ERROR LOADING ASSET: $e');
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = latlong.LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_userLocation!, 15.0);
      await _trySetInitialCityFromLocation();
    } catch (e) {
      debugPrint("Location Error: $e");
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _performGeocodingAndMoveMap(BuildContext context) async {
    if (_selectedDistrict == null || _selectedCity == null) return;

    String fullAddress;
    if (_selectedDistrict?.toLowerCase().contains('merkez') ?? false) {
      fullAddress = '$_selectedCity Merkez, $_selectedCity İli, Türkiye';
    } else {
      fullAddress = '$_selectedDistrict, $_selectedCity İli, Türkiye';
    }

    String platform = "web";
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        platform = "android";
      } else if (Platform.isIOS) {
        platform = "ios";
      }
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Text('Konum aranıyor...'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }

      final dio = Dio();

      final response = await dio.post(
        _cloudFunctionUrl,
        data: {
          "address": fullAddress,
          "platform": platform,
        },
        options: Options(
          headers: {"Content-Type": "application/json"},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data['success'] == true) {
        final latitude = response.data['lat'];
        final longitude = response.data['lng'];
        final formattedAddress = response.data['formatted_address'] ?? '';

        _mapController.move(latlong.LatLng(latitude, longitude), 12.5);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$_selectedDistrict, $_selectedCity',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (formattedAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      formattedAddress,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Konum bulunamadı: ${response.data['error']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Hata: ${e.message}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildLocationDropdown(
    String label,
    String? currentValue,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        hint: Text('Select $label'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: kPrimaryBlue.withOpacity(0.8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: kOrangeButton.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: kOrangeButton, width: 2),
          ),
          fillColor: Colors.white,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _handleProfileIconTap() {
    if (UserSession.isLoggedIn) {
      _showProfileMenu();
    } else {
      _showAuthBottomSheet();
    }
  }

  void _showAuthBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kLightBlue,
                kLightBlue.withOpacity(0.8),
                kLightOrange.withOpacity(0.3)
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Icon(Icons.waving_hand, size: 48, color: kOrangeButton),
                const SizedBox(height: 16),
                Text(
                  'Welcome to STASH!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please login or create an account to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: kPrimaryBlue.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kOrangeButton, kOrangeButton.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kOrangeButton.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      ).then((_) => setState(() {}));
                    },
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SelectionScreen()),
                      );
                    },
                    icon: Icon(Icons.person_add, color: kPrimaryBlue),
                    label: Text(
                      'SIGN UP',
                      style: TextStyle(
                        fontSize: 18,
                        color: kPrimaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      side: BorderSide(color: kOrangeButton, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileMenu() {
    final isEmployee = UserSession.userType == 'employee';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                kLightBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Header
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kOrangeButton, kOrangeButton.withOpacity(0.8)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEmployee ? Icons.store : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  UserSession.userName,
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  UserSession.userEmail,
                  style: TextStyle(color: kPrimaryBlue.withOpacity(0.6)),
                ),
              ),
              Divider(color: kLightBlue),

              // Menu Items - Different for Employee vs Visitor
              if (isEmployee) ...[
                ListTile(
                  leading: Icon(Icons.storefront, color: kOrangeButton),
                  title: Text(
                    "Back to Dashboard",
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: kPrimaryBlue, size: 16),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.pop(context); 
                  },
                ),
              ] else ...[
                // VISITOR MENU
                ListTile(
                  leading: Icon(Icons.person, color: kOrangeButton),
                  title: Text(
                    "My Profile",
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: kPrimaryBlue, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VisitorProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.inventory_2, color: kOrangeButton),
                  title: Text(
                    "My Reservations",
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: kPrimaryBlue, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActiveReservationsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history, color: kPrimaryBlue),
                  title: Text(
                    "Reservation History",
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: kPrimaryBlue, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],

              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      UserSession.logout();
                      setState(() {});
                      _showAuthBottomSheet();
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: _initialZoom,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.stash.app',
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('userType', isEqualTo: 'employee')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const MarkerLayer(markers: []);
                    }

                    final markers = <Marker>[];
                    final List<ShopModel> allShops = [];

                    // User location marker
                    if (_userLocation != null) {
                      markers.add(
                        Marker(
                          point: _userLocation!,
                          width: 60,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimaryBlue.withOpacity(0.3),
                              border: Border.all(color: kPrimaryBlue, width: 3),
                            ),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kPrimaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    // Parse all shops
                    final docs = snapshot.data!.docs;
                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;

                      if (!data.containsKey('latitude') ||
                          !data.containsKey('longitude') ||
                          data['latitude'] == null ||
                          data['longitude'] == null) {
                        continue;
                      }

                      final shop = ShopModel.fromFirestore(doc);

                      // --- FİLTRELEME MANTIĞI (PLANLI ZİYARET) ---
                      bool isShopAvailable = true;

                      // 1. Eğer kullanıcı belirli bir tarih seçtiyse:
                      if (_selectedFilterDate != null) {
                        // ShopModel'deki isOpenAt fonksiyonunu kullanarak 
                        // o tarihte açık mı kontrol ediyoruz.
                        isShopAvailable = shop.isOpenAt(_selectedFilterDate!);
                      } 
                      // 2. Eğer tarih seçilmedi ama "Şu an açıklar" filtresi seçildiyse:
                      else if (_showOnlyOpenNow) {
                        isShopAvailable = shop.isOpen; // Şu an açık mı?
                      }

                      // Eğer dükkan uygun değilse listeye ekleme
                      if (!isShopAvailable) continue;

                      // Diğer filtreler (Rating, Fiyat)
                      if (_minRating != null && shop.rating < _minRating!) {
                        continue;
                      }
                      if (shop.pricePerDay < _priceRange.start ||
                          shop.pricePerDay > _priceRange.end) {
                        continue;
                      }

                      allShops.add(shop);
                    }

                    // Sort shops based on selected criteria
                    if (_userLocation != null && _sortBy == 'distance') {
                      allShops.sort((a, b) {
                        final distA = _calculateDistance(
                          _userLocation!.latitude,
                          _userLocation!.longitude,
                          a.location.latitude,
                          a.location.longitude,
                        );
                        final distB = _calculateDistance(
                          _userLocation!.latitude,
                          _userLocation!.longitude,
                          b.location.latitude,
                          b.location.longitude,
                        );
                        return distA.compareTo(distB);
                      });
                    } else if (_sortBy == 'rating') {
                      allShops.sort((a, b) => b.rating.compareTo(a.rating));
                    } else if (_sortBy == 'price') {
                      allShops.sort(
                          (a, b) => a.pricePerDay.compareTo(b.pricePerDay));
                    }

                    // Create markers
                    for (var shop in allShops) {
                      
                      // --- MARKER RENGİ BELİRLEME ---
                      // Eğer kullanıcı bir tarih seçtiyse, o tarihteki duruma bak
                      // Seçmediyse şu anki duruma bak
                      final bool isOpen = _selectedFilterDate != null 
                          ? shop.isOpenAt(_selectedFilterDate!) 
                          : shop.isOpen;

                      Color markerColor =
                          isOpen ? Colors.green : Colors.red;
                      IconData markerIcon =
                          isOpen ? Icons.location_on : Icons.location_off;

                      // Calculate distance if user location available
                      String distanceText = '';
                      if (_userLocation != null) {
                        final distance = _calculateDistance(
                          _userLocation!.latitude,
                          _userLocation!.longitude,
                          shop.location.latitude,
                          shop.location.longitude,
                        );
                        distanceText = distance < 1
                            ? '${(distance * 1000).toStringAsFixed(0)}m'
                            : '${distance.toStringAsFixed(1)}km';
                      }

                      markers.add(
                        Marker(
                          point: shop.location,
                          width: 160,
                          height: 125,
                          child: GestureDetector(
                            onTap: () async {
                              final bool? needsRefresh =
                                  await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    ShopDetailSheet(shop: shop),
                              );
                              if (needsRefresh == true && mounted) {
                                setState(() {});
                              }
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(markerIcon, size: 45, color: markerColor),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: markerColor, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        shop.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryBlue,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isOpen ? 'Open' : 'Closed',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: markerColor,
                                            ),
                                          ),
                                          if (distanceText.isNotEmpty) ...[
                                            Text(
                                              ' | ',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: kPrimaryBlue
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            Text(
                                              distanceText,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: kOrangeButton,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star,
                                              size: 12, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(
                                            shop.rating.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: kPrimaryBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${shop.reviewCount})',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: kPrimaryBlue
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return MarkerLayer(markers: markers);
                  },
                ),
              ],
            ),
          ),
          
          // Top Panel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kLightBlue,
                    kLightBlue.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showSelectionPanel = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(15),
                              border:
                                  Border.all(color: kOrangeButton, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: kOrangeButton.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: kOrangeButton, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedCity != null
                                        ? (_selectedCity! +
                                            (_selectedDistrict != null
                                                ? ' / $_selectedDistrict'
                                                : ''))
                                        : 'Select City / Select District',
                                    style: TextStyle(
                                      color: kPrimaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down,
                                    color: kPrimaryBlue),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kOrangeButton, width: 2),
                        ),
                        child: IconButton(
                          onPressed: _getUserLocation,
                          icon: _isLoadingLocation
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: kOrangeButton,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.my_location, color: kOrangeButton),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kOrangeButton,
                              kOrangeButton.withOpacity(0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kOrangeButton.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: IconButton(
                          onPressed: _handleProfileIconTap,
                          icon: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter Chips (GÜNCELLENDİ)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 1. OPEN NOW (ŞU AN AÇIKLAR) FİLTRESİ
                  _buildFilterChip(
                    label: 'Open Now',
                    icon: _showOnlyOpenNow ? Icons.check_circle : Icons.access_time,
                    isSelected: _showOnlyOpenNow,
                    color: Colors.green,
                    onTap: () {
                      setState(() {
                        // Eğer tarih filtresi varsa onu temizle
                        _selectedFilterDate = null;
                        _showOnlyOpenNow = !_showOnlyOpenNow;
                      });
                    },
                  ),
                  const SizedBox(width: 8),

                  // 2. YENİ EKLENEN: TARİH/SAAT SEÇİMİ (Drop-off Time)
                  Stack(
                    children: [
                      _buildFilterChip(
                        label: _selectedFilterDate == null
                            ? 'Plan Visit'
                            : DateFormat('dd MMM, HH:mm').format(_selectedFilterDate!),
                        icon: Icons.calendar_month,
                        isSelected: _selectedFilterDate != null,
                        color: kOrangeButton,
                        onTap: _pickDateTime,
                      ),
                      // Temizleme (X) butonu sadece tarih seçiliyse görünür
                      if (_selectedFilterDate != null)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: GestureDetector(
                            onTap: _clearDateFilter,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 10, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  // 3. Distance Filter
                  _buildFilterChip(
                    label: 'Distance',
                    icon: Icons.near_me,
                    isSelected: _sortBy == 'distance',
                    color: kPrimaryBlue,
                    onTap: () => setState(() => _sortBy = 'distance'),
                  ),
                  const SizedBox(width: 8),
                  
                  // 4. Rating Filter
                  _buildFilterChip(
                    label: _minRating == null
                        ? 'All Ratings'
                        : '${_formatRatingLabel(_minRating!)}+',
                    icon: Icons.star,
                    isSelected: _minRating != null,
                    color: kOrangeButton,
                    onTap: _showRatingFilterSheet,
                  ),
                  const SizedBox(width: 8),
                  
                  // 5. Price Filter
                  _buildFilterChip(
                    label: _priceRangeLabel(),
                    icon: Icons.payments,
                    isSelected: !(_priceRange.start == _priceFilterMin &&
                        _priceRange.end == _priceFilterMax),
                    color: kPrimaryBlue,
                    onTap: _showPriceFilterSheet,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          
          // Selection Panel (Overlay)
          if (_showSelectionPanel)
            Positioned.fill(
              child: Container(
                color: Colors.black54, // Haritanın üzerine hafif karartma
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // İL SEÇİMİ
                        _buildLocationDropdown(
                          'City',
                          _selectedCity,
                          _cities,
                          (String? newCity) {
                            setState(() {
                              _selectedCity = newCity;
                              _selectedDistrict =
                                  null; // İl değişince ilçe sıfırlanır
                              _userChangedCity = true;
                            });
                          },
                        ),
                        const SizedBox(height: 15),

                        // İLÇE SEÇİMİ
                        if (_selectedCity != null &&
                            _allCitiesData.containsKey(_selectedCity))
                          _buildLocationDropdown(
                            'District',
                            _selectedDistrict,
                            // İlçe listesini hazırlar
                            (_allCitiesData[_selectedCity]
                                    as Map<String, dynamic>)
                                .keys
                                .toList()
                                .cast<String>(),
                            (String? newDistrict) {
                              setState(() {
                                _selectedDistrict = newDistrict;
                              });
                            },
                          ),

                        // KAYDET/UYGULA BUTONU
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedDistrict != null
                                ? () {
                                    // 1. Ekranı Kapat
                                    setState(() {
                                      _showSelectionPanel = false;
                                    });

                                    // 2. Haritayı Güncelle
                                    _performGeocodingAndMoveMap(context);
                                  }
                                : null, // İlçe seçilmeden buton pasif
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kOrangeButton,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text('APPLY LOCATION',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),

                        // İPTAL BUTONU
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showSelectionPanel = false;
                            });
                          },
                          child: Text('Cancel',
                              style: TextStyle(color: kPrimaryBlue)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : kLightOrange,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? color : kOrangeButton).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : kPrimaryBlue.withOpacity(0.6),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? color : kPrimaryBlue,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}