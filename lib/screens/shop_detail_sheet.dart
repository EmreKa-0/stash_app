import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop_model.dart';
import '../utils/app_styles.dart';

import 'user_session.dart';
import 'login_screen.dart';
import 'baggage_detail_screen.dart';
import 'shop_reviews_screen.dart';
import 'navigation_screen.dart'; // ✅ YENİ EKRAN

class ShopDetailSheet extends StatelessWidget {
  final ShopModel shop;

  const ShopDetailSheet({Key? key, required this.shop}) : super(key: key);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // ✅ YENİ: In-app navigation'a yönlendirme
  void _openInAppNavigation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(
          destinationLat: shop.location.latitude,
          destinationLng: shop.location.longitude,
          shopName: shop.name,
          shopAddress: shop.address,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOpenNow = shop.isOpen;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER (Tutamaç ve Kapatma Butonu)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: kPrimaryBlue, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          // 2. İÇERİK (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dükkan Adı ve Açık/Kapalı Durumu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: kPrimaryBlue,
                              letterSpacing: -0.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isOpenNow
                                ? [Colors.green.shade400, Colors.green.shade600]
                                : [Colors.red.shade400, Colors.red.shade600],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOpenNow ? 'Open' : 'Closed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Rating
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(shop.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      double rating = 0.0;
                      int reviewCount = 0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        rating = (data['rating'] ?? 0.0).toDouble();
                        reviewCount = (data['reviewCount'] ?? 0);
                      }

                      return Row(
                        children: [
                          Icon(Icons.star, color: kOrangeButton, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            reviewCount == 0
                                ? "New"
                                : rating.toStringAsFixed(1),
                            style: TextStyle(
                                color: kPrimaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "($reviewCount reviews)",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Adres
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: kOrangeButton, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          shop.address,
                          style: TextStyle(
                              color: kPrimaryBlue.withOpacity(0.8),
                              fontSize: 15,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ✅ GÜNCELLEME: Directions butonu artık in-app navigation'ı açıyor
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        Icons.directions,
                        "Directions",
                        onTap: () => _openInAppNavigation(context),
                      ),
                      _buildActionButton(
                        Icons.call,
                        "Call",
                        onTap: () => _makePhoneCall(shop.phoneNumber),
                      ),
                      _buildActionButton(
                        Icons.chat_bubble_outline,
                        "Reviews",
                        onTap: () async {
                          final bool? reviewChanged =
                              await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              height: MediaQuery.of(context).size.height * 0.85,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20)),
                              ),
                              child: ShopReviewsScreen(
                                  shopId: shop.id, shopName: shop.name),
                            ),
                          );

                          if (reviewChanged == true && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Fiyat ve Rezervasyon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kLightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kOrangeButton.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Price per day",
                                style: TextStyle(
                                    color: kPrimaryBlue,
                                    fontWeight: FontWeight.w600)),
                            Text("TL ${shop.pricePerDay.toStringAsFixed(0)}",
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: kOrangeButton)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Builder(
                          builder: (context) {
                            // KONTROL 1: Dükkan Kapalı mı?
                            if (!isOpenNow) {
                              return Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_clock,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Shop is Closed",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // KONTROL 2: Kullanıcı Esnaf mı?
                            final bool isEmployee =
                                UserSession.userType == 'employee';
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final bool isOwnShop = currentUser != null &&
                                currentUser.uid == shop.id;

                            if (isEmployee || isOwnShop) {
                              return Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.3)),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.block, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Vendors Cannot Reserve",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // KONTROL 3: Her şey yolunda
                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (UserSession.isLoggedIn) {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                BaggageDetailScreen(
                                                    shop: shop)));
                                  } else {
                                    _showLoginDialog(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kOrangeButton,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("STASH NOW",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Login Required"),
              content: const Text("Please login to continue."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => const LoginScreen()));
                    },
                    child: const Text("Login")),
              ],
            ));
  }

  Widget _buildActionButton(IconData icon, String label,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: kOrangeButton.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: kOrangeButton),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
