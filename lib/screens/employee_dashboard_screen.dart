import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // InputFormatter için eklendi
import '../utils/app_styles.dart';
import 'login_screen.dart';
import 'user_session.dart';
import 'shop_management_screen.dart';
import 'map_screen.dart';
import 'shop_reviews_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  final TextEditingController _codeController = TextEditingController();

  void _logout() {
    UserSession.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showShopMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.50,
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kOrangeButton, kOrangeButton.withOpacity(0.8)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white),
                ),
                title: Text(
                  UserSession.userName.isNotEmpty
                      ? UserSession.userName
                      : "Shop Owner",
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

              ListTile(
                leading: Icon(Icons.star_rate_rounded, color: kOrangeButton),
                title: Text(
                  "Shop Reviews",
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    color: kPrimaryBlue, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopReviewsScreen(
                          shopId: user.uid,
                          shopName: UserSession.userName.isNotEmpty 
                              ? UserSession.userName 
                              : "My Shop",
                          isShopOwner: true,
                        ),
                      ),
                    );
                  }
                },
              ),
              
              ListTile(
                leading: Icon(Icons.store_outlined, color: kOrangeButton),
                title: Text(
                  "Shop Management",
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
                      builder: (context) => const ShopManagementScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.map_outlined, color: kPrimaryBlue),
                title: Text(
                  "View Map",
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
                      builder: (context) => const MapScreen(),
                    ),
                  );
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
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

  // ✅ GÜVENLİK GÜNCELLEMESİ BURADA YAPILDI
  void _verifyAndCompleteStash(String docId, String realCode) {
    _codeController.clear(); // Her açılışta temizle
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified_user, color: kPrimaryBlue, size: 28),
            const SizedBox(width: 12),
            Text("Verify Pickup",
                style: TextStyle(
                    color: kPrimaryBlue, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Ask the customer for the pickup code:",
              style: TextStyle(color: kPrimaryBlue.withOpacity(0.8)),
            ),
            const SizedBox(height: 15),
            // GÜVENLİK EKLENEN TEXTFIELD
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              maxLength: 9, // En fazla 9 karakter
              textCapitalization: TextCapitalization.characters, // Otomatik büyük harf
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9-]")), // Sadece harf, rakam ve tire
              ],
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 2,
                color: kPrimaryBlue,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "ST-XXXXXX",
                counterText: "", // Sayacı gizle
                filled: true,
                fillColor: kLightBlue.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kOrangeButton, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: TextStyle(color: kPrimaryBlue.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kOrangeButton),
            onPressed: () async {
              // Kod kontrolü (Boşlukları temizleyerek)
              if (_codeController.text.trim().toUpperCase() == realCode.toUpperCase()) {
                // Veritabanını güncelle
                await FirebaseFirestore.instance
                    .collection('reservations')
                    .doc(docId)
                    .update({
                  'status': 'completed',
                  'completedAt': FieldValue.serverTimestamp()
                });

                if (ctx.mounted) Navigator.pop(ctx);
                _codeController.clear();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Success! Item delivered."),
                      backgroundColor: Colors.green));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Wrong code! Please check again."), 
                    backgroundColor: Colors.red));
              }
            },
            child: const Text("Confirm & Deliver",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Future.microtask(() => _logout());
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
              kLightOrange.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(user),

              // AKTİF SİPARİŞLER
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
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
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text("Incoming Stashes",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlue)),
                      ),
                      Expanded(
                        child: _buildReservationList(user.uid, 'active'),
                      ),
                    ],
                  ),
                ),
              ),

              // GEÇMİŞ SİPARİŞLER
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        kLightBlue.withOpacity(0.3),
                        kLightBlue.withOpacity(0.1)
                      ]),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text("Recent History",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryBlue)),
                        ),
                        Expanded(
                          child: _buildReservationList(user.uid, 'completed'),
                        ),
                      ],
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

  Widget _buildHeader(User user) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome Back,",
                  style: TextStyle(
                      fontSize: 16, color: kPrimaryBlue.withOpacity(0.7))),
              const SizedBox(height: 4),
              Text(
                  UserSession.userName.isNotEmpty
                      ? UserSession.userName
                      : "Shop Owner",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue)),
            ],
          ),
          IconButton(
              icon: const Icon(Icons.storefront), onPressed: _showShopMenu)
        ],
      ),
    );
  }

  Widget _buildReservationList(String shopId, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('shopId', isEqualTo: shopId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
                status == 'active' ? "No active stashes." : "No history yet.",
                style: TextStyle(color: kPrimaryBlue.withOpacity(0.5))),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                border: status == 'active'
                    ? Border.all(color: kOrangeButton)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag,
                      color: status == 'active' ? kOrangeButton : kPrimaryBlue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${data['bagCount']} Bags - ${data['size']}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlue)),
                        Text("TL ${data['totalPrice']}",
                            style: TextStyle(color: Colors.grey)),
                        if (status == 'active')
                          Text("Code: ${data['pickupCode']}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kOrangeButton)),
                      ],
                    ),
                  ),
                  if (status == 'active')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () =>
                          _verifyAndCompleteStash(docId, data['pickupCode']),
                      child: const Text("Deliver",
                          style: TextStyle(color: Colors.white)),
                    )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
