import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/app_styles.dart';

class ActiveReservationsScreen extends StatelessWidget {
  const ActiveReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kLightBlue, kLightOrange.withOpacity(0.3)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined,
                    size: 64, color: kPrimaryBlue.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  "Please login to see your reservations.",
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Reservations',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                        Text(
                          'Active stashes',
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

              // Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reservations')
                      .where('userId', isEqualTo: user.uid)
                      .where('status', isEqualTo: 'active')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: kOrangeButton),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              size: 80,
                              color: kPrimaryBlue.withOpacity(0.3),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "No active reservations",
                              style: TextStyle(
                                color: kPrimaryBlue.withOpacity(0.6),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Your active stashes will appear here",
                              style: TextStyle(
                                color: kPrimaryBlue.withOpacity(0.4),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final Timestamp? ts = data['createdAt'];
                        final dateStr = ts != null
                            ? DateFormat('dd MMM yyyy, HH:mm')
                                .format(ts.toDate())
                            : 'Just now';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kOrangeButton, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: kOrangeButton.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            kOrangeButton,
                                            kOrangeButton.withOpacity(0.8)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['shopName'] ?? 'Unknown Shop',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: kPrimaryBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  kPrimaryBlue.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                Divider(height: 30, color: kLightBlue),

                                // Details
                                _buildDetailRow(
                                  Icons.inventory_2,
                                  'Size',
                                  data['size'] ?? 'Medium',
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.shopping_bag_outlined,
                                  'Items',
                                  '${data['bagCount']} bags',
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  'Days',
                                  '${data['dayCount']} days',
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.payments,
                                  'Total',
                                  'TL ${data['totalPrice']}',
                                ),

                                Divider(height: 30, color: kLightBlue),

                                // Pickup Code
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        kLightOrange.withOpacity(0.3),
                                        kLightBlue.withOpacity(0.3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: kOrangeButton, width: 2),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.qr_code_2,
                                              color: kOrangeButton, size: 24),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Pickup Code',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: kPrimaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SelectableText(
                                        data['pickupCode'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 4,
                                          color: kPrimaryBlue,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Show this code at the shop',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: kPrimaryBlue.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: kOrangeButton, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: kPrimaryBlue.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: kPrimaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
