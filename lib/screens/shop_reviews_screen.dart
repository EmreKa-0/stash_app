import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../utils/app_styles.dart';

class ShopReviewsScreen extends StatefulWidget {
  final String shopId;
  final String shopName;
  final bool isShopOwner; // ✅ YENİ: Esnaf mı kontrolü

  const ShopReviewsScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    this.isShopOwner = false, // Varsayılan olarak müşteri (false)
  });

  @override
  State<ShopReviewsScreen> createState() => _ShopReviewsScreenState();
}

class _ShopReviewsScreenState extends State<ShopReviewsScreen> {
  bool _canReview = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    // ✅ Eğer giren kişi esnafsa izin kontrolüne gerek yok, direkt false yapıyoruz
    if (widget.isShopOwner) {
      _canReview = false;
      _checkingPermission = false;
    } else {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _canReview = false;
          _checkingPermission = false;
        });
      }
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: user.uid)
          .where('shopId', isEqualTo: widget.shopId)
          .where('status', whereIn: ['picked_up', 'completed'])
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _canReview = query.docs.isNotEmpty;
          _checkingPermission = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _checkingPermission = false);
    }
  }

  Future<void> _recalculateShopRating(String shopId) async {
    try {
      // 1. Bu shop için tüm yorumları çek
      var reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('shopId', isEqualTo: shopId)
          .get();

      double totalRating = 0;
      int count = reviewsSnapshot.docs.length;

      // 2. Ortalamayı hesapla
      if (count > 0) {
        for (var doc in reviewsSnapshot.docs) {
          totalRating += (doc.data()['rating'] as num).toDouble();
        }
      }

      double newAverage = count > 0 ? totalRating / count : 0.0;

      // 3. USERS collection'ında SHOP'un dökümanını güncelle
      await FirebaseFirestore.instance.collection('users').doc(shopId).update({
        'rating': newAverage,
        'reviewCount': count,
      });

      debugPrint(
          '✅ Rating updated: $newAverage ($count reviews) for shop: $shopId');
    } catch (e) {
      debugPrint("❌ Rating Error: $e");
    }
  }

  void _showReviewModal(BuildContext context,
      {String? docId, double? currentRating, String? currentComment}) {
    final TextEditingController commentController =
        TextEditingController(text: currentComment ?? "");
    double userRating = currentRating ?? 5.0;
    bool isEditing = docId != null;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
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
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      child: const Icon(Icons.rate_review,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? "Edit Review" : "Rate ${widget.shopName}",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: RatingBar.builder(
                    initialRating: userRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 40,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 6.0),
                    itemBuilder: (context, _) =>
                        Icon(Icons.star_rounded, color: kOrangeButton),
                    onRatingUpdate: (rating) {
                      userRating = rating;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: commentController,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: "How was your experience?",
                    hintStyle: TextStyle(color: kPrimaryBlue.withOpacity(0.4)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: kLightOrange, width: 2)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: kLightOrange, width: 2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: kOrangeButton, width: 2)),
                    filled: true,
                    fillColor: kLightBlue.withOpacity(0.1),
                    counterStyle:
                        TextStyle(color: kPrimaryBlue.withOpacity(0.5)),
                  ),
                  maxLines: 4,
                  style: TextStyle(color: kPrimaryBlue),
                ),
                const SizedBox(height: 20),
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
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: const [
                                Icon(Icons.error_outline, color: Colors.white),
                                SizedBox(width: 12),
                                Text("Please write a comment."),
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

                      Navigator.pop(ctx);

                      try {
                        if (isEditing) {
                          await FirebaseFirestore.instance
                              .collection('reviews')
                              .doc(docId)
                              .update({
                            'rating': userRating,
                            'comment': commentController.text.trim(),
                          });
                        } else {
                          await FirebaseFirestore.instance
                              .collection('reviews')
                              .add({
                            'shopId': widget.shopId,
                            'rating': userRating,
                            'comment': commentController.text.trim(),
                            'createdAt': FieldValue.serverTimestamp(),
                            'userId': currentUser.uid,
                          });
                        }

                        await _recalculateShopRating(widget.shopId);

                        if (!mounted) return;

                        Navigator.pop(context, true);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white),
                                const SizedBox(width: 12),
                                Text(isEditing
                                    ? "Review updated!"
                                    : "Thanks for your review!"),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  "Action failed. Check connection."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      isEditing ? "Update Review" : "Submit Review",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteReview(String docId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text("Delete Review"),
          ],
        ),
        content: const Text("Are you sure you want to delete your review?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("Cancel",
                  style: TextStyle(color: kPrimaryBlue.withOpacity(0.6)))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('reviews')
            .doc(docId)
            .delete();

        await _recalculateShopRating(widget.shopId);

        if (!mounted) return;

        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Review deleted."),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error deleting review.")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String currentUid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kLightBlue.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
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
                          'Reviews',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                        Text(
                          widget.shopName,
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

              // HEADER: CANLI PUAN GÖSTERİMİ
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.shopId)
                    .snapshots(),
                builder: (context, snapshot) {
                  double rating = 0.0;
                  int count = 0;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    rating = (data['rating'] ?? 0.0).toDouble();
                    count = (data['reviewCount'] ?? 0);
                  }
                  bool isNew = count == 0;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kLightOrange.withOpacity(0.4),
                          kLightBlue.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isNew ? Colors.green : kOrangeButton,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isNew ? Colors.green : kOrangeButton)
                              .withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: isNew
                        ? Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.new_releases,
                                          color: Colors.white, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'NEW',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No reviews yet",
                                  style: TextStyle(
                                      color: kPrimaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Be the first to review!",
                                  style: TextStyle(
                                      color: kPrimaryBlue.withOpacity(0.6),
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: kOrangeButton,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RatingBarIndicator(
                                    rating: rating,
                                    itemBuilder: (context, index) => Icon(
                                        Icons.star_rounded,
                                        color: kOrangeButton),
                                    itemCount: 5,
                                    itemSize: 28.0,
                                    direction: Axis.horizontal,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "$count reviews",
                                    style: TextStyle(
                                        color: kPrimaryBlue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // LİSTE
              Expanded(
                child: Column(
                  children: [
                    // ✅ Esnaf ise bu uyarıyı göstermeye gerek yok
                    if (!_checkingPermission &&
                        !_canReview &&
                        !widget.isShopOwner)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kLightBlue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kPrimaryBlue.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: kPrimaryBlue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Only customers who completed a stash can write a review.",
                                style: TextStyle(
                                    color: kPrimaryBlue.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('shopId', isEqualTo: widget.shopId)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError)
                            return const Center(
                                child: Text("Loading error..."));
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return Center(
                                child: CircularProgressIndicator(
                                    color: kOrangeButton));

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rate_review_outlined,
                                      size: 80,
                                      color: kPrimaryBlue.withOpacity(0.3)),
                                  const SizedBox(height: 16),
                                  Text("No reviews yet.",
                                      style: TextStyle(
                                          color: kPrimaryBlue.withOpacity(0.6),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: snapshot.data!.docs.length,
                            separatorBuilder: (ctx, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              final double rating =
                                  (data['rating'] ?? 0).toDouble();
                              final String comment = data['comment'] ?? '';
                              final Timestamp? ts = data['createdAt'];
                              final String reviewOwnerId = data['userId'] ?? '';

                              final String dateStr = ts != null
                                  ? DateFormat('dd MMM yyyy')
                                      .format(ts.toDate())
                                  : 'Recent';

                              bool isMyReview = (currentUid.isNotEmpty &&
                                  reviewOwnerId.isNotEmpty &&
                                  currentUid == reviewOwnerId);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: isMyReview
                                          ? kOrangeButton.withOpacity(0.3)
                                          : kLightOrange,
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                        color: (isMyReview
                                                ? kOrangeButton
                                                : kPrimaryBlue)
                                            .withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: kOrangeButton,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: List.generate(
                                                    5,
                                                    (starIndex) => Icon(
                                                        starIndex < rating
                                                            ? Icons.star_rounded
                                                            : Icons
                                                                .star_border_rounded,
                                                        size: 14,
                                                        color: Colors.white)),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(dateStr,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: kPrimaryBlue
                                                        .withOpacity(0.5),
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            if (isMyReview)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: kOrangeButton
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text("You",
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: kOrangeButton,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                              ),
                                          ],
                                        ),
                                        // Esnaf başkasının yorumunu düzenleyemez
                                        if (isMyReview)
                                          PopupMenuButton<String>(
                                            icon: Icon(Icons.more_horiz,
                                                color: kPrimaryBlue),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showReviewModal(context,
                                                    docId: doc.id,
                                                    currentRating: rating,
                                                    currentComment: comment);
                                              } else if (value == 'delete') {
                                                _deleteReview(doc.id);
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) => [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Row(children: [
                                                  Icon(Icons.edit,
                                                      size: 18,
                                                      color: kPrimaryBlue),
                                                  const SizedBox(width: 8),
                                                  const Text("Edit")
                                                ]),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(children: [
                                                  Icon(Icons.delete,
                                                      size: 18,
                                                      color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text("Delete",
                                                      style: TextStyle(
                                                          color: Colors.red))
                                                ]),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(comment,
                                        style: TextStyle(
                                            color:
                                                kPrimaryBlue.withOpacity(0.9),
                                            fontSize: 14,
                                            height: 1.4)),
                                  ],
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
            ],
          ),
        ),
      ),
      // ✅ YENİ: Esnafsa veya yorum yetkisi yoksa buton null olur
      floatingActionButton: (widget.isShopOwner || !_canReview)
          ? null
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kOrangeButton, kOrangeButton.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kOrangeButton.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showReviewModal(context),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text("Write Review",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
            ),
    );
  }
}
