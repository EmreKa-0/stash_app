import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../utils/app_styles.dart';

class UserHistoryScreen extends StatelessWidget {
  const UserHistoryScreen({super.key});

  void _showRatingDialog(
    BuildContext context,
    String reservationId,
    String shopId,
    String shopName,
  ) {
    double selectedRating = 0;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.star_outline, color: kOrangeButton, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Rate $shopName",
                style:
                    TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "How was your experience?",
              style: TextStyle(
                color: kPrimaryBlue.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star_rounded,
                color: kOrangeButton,
              ),
              onRatingUpdate: (rating) {
                selectedRating = rating;
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "Optional comment...",
                hintStyle: TextStyle(color: kPrimaryBlue.withOpacity(0.4)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kLightOrange, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kLightOrange, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kOrangeButton, width: 2),
                ),
                filled: true,
                fillColor: kLightBlue.withOpacity(0.1),
              ),
              maxLines: 3,
              style: TextStyle(color: kPrimaryBlue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(color: kPrimaryBlue.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrangeButton,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              if (selectedRating == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Text("Please give at least 1 star."),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }

              try {
                // 1. Add review
                await FirebaseFirestore.instance.collection('reviews').add({
                  'shopId': shopId,
                  'userId': FirebaseAuth.instance.currentUser!.uid,
                  'rating': selectedRating,
                  'comment': commentController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                // 2. Mark reservation as rated
                await FirebaseFirestore.instance
                    .collection('reservations')
                    .doc(reservationId)
                    .update({'isRated': true});

                final reviewsQuery = await FirebaseFirestore.instance
                    .collection('reviews')
                    .where('shopId', isEqualTo: shopId)
                    .get();

                double totalRating = 0;
                int reviewCount = reviewsQuery.docs.length;

                for (var doc in reviewsQuery.docs) {
                  totalRating += (doc.data()['rating'] as num).toDouble();
                }

                double averageRating =
                    reviewCount > 0 ? totalRating / reviewCount : 0.0;

                // 4. Dükkan dökümanını (users koleksiyonu) güncelle
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(shopId)
                    .update({
                  'rating': averageRating,
                  'reviewCount': reviewCount,
                });

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Thank you for your feedback!"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Submit",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                  "Please login to see history.",
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
                          'My Stash History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                        Text(
                          'Completed reservations',
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
                      .where('status', isEqualTo: 'completed')
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
                              Icons.history_outlined,
                              size: 80,
                              color: kPrimaryBlue.withOpacity(0.3),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "No history found.",
                              style: TextStyle(
                                color: kPrimaryBlue.withOpacity(0.6),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Your completed stashes will appear here",
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
                        bool isRated = data['isRated'] ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isRated
                                  ? Colors.amber.withOpacity(0.3)
                                  : kLightOrange,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isRated ? Colors.amber : kOrangeButton)
                                    .withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isRated
                                      ? [
                                          Colors.amber.shade400,
                                          Colors.amber.shade600
                                        ]
                                      : [
                                          kLightBlue,
                                          kLightBlue.withOpacity(0.5)
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isRated ? Icons.star : Icons.check_circle,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              data['shopName'] ?? 'Unknown Shop',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlue,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.payments,
                                          size: 16, color: kOrangeButton),
                                      const SizedBox(width: 6),
                                      Text(
                                        "TL ${data['totalPrice']}",
                                        style: TextStyle(
                                          color: kPrimaryBlue.withOpacity(0.8),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.inventory_2,
                                          size: 16, color: kPrimaryBlue),
                                      const SizedBox(width: 6),
                                      Text(
                                        "${data['size']}",
                                        style: TextStyle(
                                          color: kPrimaryBlue.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: isRated
                                ? Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 24,
                                    ),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kOrangeButton,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _showRatingDialog(
                                      context,
                                      doc.id,
                                      data['shopId'],
                                      data['shopName'],
                                    ),
                                    child: const Text(
                                      "Rate",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
}
