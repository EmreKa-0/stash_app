import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShopStore {
  static String _normalizeAddress(String address) {
    final trimmed = address.trim().toLowerCase();
    final normalized = trimmed.replaceAll(
      RegExp(r"[^\p{L}\p{N}]+", unicode: true),
      " ",
    );
    return normalized.replaceAll(RegExp(r"\s+"), " ").trim();
  }

  /// Esnaf Kaydı (Email/Şifre ile)
  static Future<void> registerShop({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String phone,
    required String shopName,
    required String address,
    required double latitude,
    required double longitude,
    required String taxId,
  }) async {
    // 1. KONTROL: Bu bilgilerle (adres, vergi no, konum) başka dükkan var mı?
    await verifyNewShopData(address, taxId, latitude, longitude);

    // 2. Auth Kullanıcısı Oluştur
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // 3. Firestore'a yaz
    await saveShopToFirestore(
      uid: userCredential.user!.uid,
      email: email,
      name: '$name $surname',
      shopName: shopName,
      phone: phone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      taxId: taxId,
    );
  }

  /// KAYIT OLMADAN ÖNCE KONTROL EDEN FONKSİYON
  /// (Hem Manuel hem Google kayıtlarında bunu çağıracağız)
  static Future<void> verifyNewShopData(
      String address, String taxId, double lat, double lng) async {
    final firestore = FirebaseFirestore.instance;
    final normalizedAddress = _normalizeAddress(address);

    final normalizedAddressQuery = await firestore
        .collection('users')
        .where('userType', isEqualTo: 'employee')
        .where('addressNormalized', isEqualTo: normalizedAddress)
        .get();

    if (normalizedAddressQuery.docs.isNotEmpty) {
      throw FirebaseAuthException(
          code: 'address-already-exists',
          message: 'Bu adres ile kayitli bir dukkan zaten var. Lutfen adresi kontrol edin.');
    }

    // A) ADRES METNİ KONTROLÜ (Veritabanında bu adres yazısı var mı?)
    // Not: .trim() ile baştaki sondaki boşlukları temizleyip bakar.
    final addressQuery = await firestore
        .collection('users')
        .where('userType', isEqualTo: 'employee')
        .where('address', isEqualTo: address.trim()) 
        .get();

    if (addressQuery.docs.isNotEmpty) {
      throw FirebaseAuthException(
          code: 'address-already-exists',
          message: 'Bu açık adres ile kayıtlı bir dükkan zaten var! Lütfen adresi kontrol edin.');
    }

    // B) VERGİ NUMARASI KONTROLÜ
    final taxQuery = await firestore
        .collection('users')
        .where('userType', isEqualTo: 'employee')
        .where('taxId', isEqualTo: taxId)
        .get();

    if (taxQuery.docs.isNotEmpty) {
      throw FirebaseAuthException(
          code: 'tax-id-already-exists',
          message: 'Bu Vergi Numarası (Tax ID) zaten kullanımda.');
    }

    // C) KOORDİNAT KONTROLÜ (Tam üstüne kayıt engelleme)
    final locationQuery = await firestore
        .collection('users')
        .where('userType', isEqualTo: 'employee')
        .where('latitude', isEqualTo: lat)
        .where('longitude', isEqualTo: lng)
        .get();

    if (locationQuery.docs.isNotEmpty) {
      throw FirebaseAuthException(
          code: 'location-already-used',
          message: 'Haritada bu noktada zaten bir dükkan var.');
    }
  }

  /// Ortak Firestore Kayıt Fonksiyonu
  static Future<void> saveShopToFirestore({
    required String uid,
    required String email,
    required String name,
    required String shopName,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required String taxId,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'userType': 'employee',
      'name': name,
      'shopName': shopName,
      'email': email,
      'phone': phone,
      'address': address.trim(), // Adresi kaydederken de temizliyoruz
      'addressNormalized': _normalizeAddress(address),
      'latitude': latitude,
      'longitude': longitude,
      'taxId': taxId,
      'isOpen': true,
      'rating': 0.0,
      'reviewCount': 0,
      'pricePerDay': 80.0,
      'imageUrl': 'https://images.unsplash.com/photo-1556740758-90de374c12ad',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}