import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import 'confirmation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop_model.dart';

class BaggageDetailScreen extends StatefulWidget {
  final ShopModel shop;

  const BaggageDetailScreen({super.key, required this.shop});

  @override
  State<BaggageDetailScreen> createState() => _BaggageDetailScreenState();
}

class _BaggageDetailScreenState extends State<BaggageDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _shopName = '';
  String _shopAddress = '';
  double _dailyPrice = 0.0;

  int _bagCount = 1;
  int _dayCount = 1;

  final List<String> _sizeOptions = ['Small', 'Medium', 'Big', 'Bag', 'Other'];
  String _selectedSize = 'Medium';

  final Map<String, double> _sizeMultipliers = {
    'Small': 0.8,
    'Medium': 1.0,
    'Big': 1.3,
    'Bag': 0.7,
    'Other': 1.1,
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _shopName = widget.shop.name;
    _shopAddress = widget.shop.address;
    _dailyPrice = widget.shop.pricePerDay;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _generatePickupCode() {
    final random = Random();
    final number = 100000 + random.nextInt(900000);
    return 'ST-$number';
  }

  double get _totalPrice {
    // ✅ Güvenlik: Asla negatif fiyat çıkmasın
    final multiplier = _sizeMultipliers[_selectedSize] ?? 1.0;
    double total = _dailyPrice * _dayCount * _bagCount.toDouble() * multiplier;
    return total < 0 ? 0 : total;
  }

  void _completeReservation() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please login to make a reservation'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // ✅ MANTIKSAL VALIDASYON (Logic Security)
    if (_bagCount < 1 || _bagCount > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid bag count (1-100)'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_dayCount < 1 || _dayCount > 365) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid duration (1-365 days)'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pickupCode = _generatePickupCode();

      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Customer',
        'shopId': widget.shop.id,
        'shopName': widget.shop.name,
        'pickupCode': pickupCode,
        'size': _selectedSize,
        'bagCount': _bagCount,
        'dayCount': _dayCount,
        'totalPrice': _totalPrice,
        'status': 'active',
        'isRated': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            pickupCode: pickupCode,
            shopName: widget.shop.name,
            dateRange: '$_dayCount Days',
            totalPrice: _totalPrice,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
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
              kLightOrange.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildCustomAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildShopCard(),
                        const SizedBox(height: 16),
                        _buildBaggageFormCard(),
                        const SizedBox(height: 16),
                        _buildBottomSummaryAndButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: kPrimaryBlue),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stash Details',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue)),
                Text('Configure your storage',
                    style: TextStyle(
                        fontSize: 12, color: kPrimaryBlue.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLightOrange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: kOrangeButton, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_shopName,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue)),
                    Text(_shopAddress,
                        style: TextStyle(
                            fontSize: 12,
                            color: kPrimaryBlue.withOpacity(0.6))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.payments, color: kOrangeButton, size: 20),
              const SizedBox(width: 8),
              Text('TL ${_dailyPrice.toStringAsFixed(0)} / day',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBaggageFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLightOrange, width: 2),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            children: _sizeOptions.map((size) {
              final isSelected = _selectedSize == size;
              return ChoiceChip(
                label: Text(size),
                selected: isSelected,
                selectedColor: kOrangeButton,
                labelStyle:
                    TextStyle(color: isSelected ? Colors.white : kPrimaryBlue),
                onSelected: (selected) => setState(() => _selectedSize = size),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildCounterRow(
              'Number of Items',
              _bagCount,
              () => setState(() {
                    if (_bagCount > 1) _bagCount--;
                  }),
              // ✅ MAX Sınır Kontrolü (100)
              () => setState(() {
                    if (_bagCount < 100) _bagCount++;
                  })),
          const SizedBox(height: 10),
          _buildCounterRow(
              'Number of Days',
              _dayCount,
              () => setState(() {
                    if (_dayCount > 1) _dayCount--;
                  }),
              // ✅ MAX Sınır Kontrolü (365)
              () => setState(() {
                    if (_dayCount < 365) _dayCount++;
                  })),
        ],
      ),
    );
  }

  Widget _buildCounterRow(
      String label, int value, VoidCallback onDec, VoidCallback onInc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold)),
        Row(
          children: [
            IconButton(
                onPressed: onDec,
                icon: Icon(Icons.remove_circle, color: kOrangeButton)),
            Text('$value',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue)),
            IconButton(
                onPressed: onInc,
                icon: Icon(Icons.add_circle, color: kOrangeButton)),
          ],
        )
      ],
    );
  }

  Widget _buildBottomSummaryAndButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: kOrangeButton.withOpacity(0.3), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Price',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue)),
              Text('TL ${_totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kOrangeButton)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrangeButton,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _completeReservation,
              child: const Text('CONFIRM STASH',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
