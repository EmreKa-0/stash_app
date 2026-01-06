import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart'; // Eğer uuid paketi yoksa: Random kullanılabilir.

class ReservationStore {
  /// Yeni bir rezervasyon oluşturur ve Firestore'a yazar.
  /// Bu fonksiyon çağrıldığı anda Esnafın ekranına bildirim düşer.
  static Future<String> createReservation({
    required String shopId,
    required String shopName,
    required String size, // 'Small', 'Medium', 'Large' vb.
    required int bagCount,
    required int dayCount,
    required double totalPrice,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User must be logged in");

    // Benzersiz bir Pickup Code üret (Örn: ST-A1B2)
    String pickupCode =
        "ST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

    await FirebaseFirestore.instance.collection('reservations').add({
      'userId': user.uid,
      'userName': user.displayName ?? 'Customer', // Varsa kullanıcı adı
      'shopId': shopId, // Bildirimin kime gideceği burada belirlenir
      'shopName': shopName,
      'status': 'active', // active, completed, cancelled
      'pickupCode': pickupCode,
      'size': size,
      'bagCount': bagCount,
      'dayCount': dayCount,
      'totalPrice': totalPrice,
      'isRated': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return pickupCode;
  }

  /// Rezervasyonu tamamlandı (Teslim edildi) olarak işaretle
  static Future<void> completeReservation(String docId) async {
    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(docId)
        .update({
      'status': 'completed',
      'deliveredAt': FieldValue.serverTimestamp(),
    });
  }
}
