import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../utils/time_service.dart';

class ShopModel {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final LatLng location;
  final double pricePerDay;
  final bool isManuallyOpen;
  final List<int> openDays;
  final String? openTime;
  final String? closeTime;
  final DateTime? openStartDate;
  final DateTime? openEndDate;

  ShopModel({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.location,
    required this.pricePerDay,
    required this.isManuallyOpen,
    this.openDays = const [],
    this.openTime,
    this.closeTime,
    this.openStartDate,
    this.openEndDate,
  });

  bool get isOpen => isOpenAt(TimeService.nowTurkey());

  bool isOpenAt(DateTime now) {
    if (!isManuallyOpen) return false;
    final hasSchedule = openDays.isNotEmpty ||
        openTime != null ||
        closeTime != null ||
        openStartDate != null ||
        openEndDate != null;
    if (!hasSchedule) return true;
    if (openDays.isEmpty ||
        openTime == null ||
        closeTime == null ||
        openStartDate == null ||
        openEndDate == null) {
      return false;
    }
    if (!_isWithinDateRange(now)) return false;
    if (!openDays.contains(now.weekday)) return false;

    final openMinutes = _parseTimeToMinutes(openTime!);
    final closeMinutes = _parseTimeToMinutes(closeTime!);
    if (openMinutes == null || closeMinutes == null) return false;
    if (closeMinutes <= openMinutes) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
  }

  bool _isWithinDateRange(DateTime now) {
    if (openStartDate == null && openEndDate == null) return true;
    final today = DateTime(now.year, now.month, now.day);
    if (openStartDate != null) {
      final start = DateTime(
        openStartDate!.year,
        openStartDate!.month,
        openStartDate!.day,
      );
      if (today.isBefore(start)) return false;
    }
    if (openEndDate != null) {
      final end = DateTime(
        openEndDate!.year,
        openEndDate!.month,
        openEndDate!.day,
      );
      if (today.isAfter(end)) return false;
    }
    return true;
  }

  static int? _parseTimeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour * 60) + minute;
  }

  static List<int> _parseOpenDays(dynamic raw) {
    if (raw is! List) return [];
    final days = <int>[];
    for (final entry in raw) {
      int? value;
      if (entry is int) {
        value = entry;
      } else if (entry is num) {
        value = entry.toInt();
      } else if (entry is String) {
        value = int.tryParse(entry);
      }
      if (value != null && value >= 1 && value <= 7) {
        days.add(value);
      }
    }
    days.sort();
    return days;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  // Firestore mapper.
  factory ShopModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Koordinatları güvenli çekme (Hata riskini sıfırlar)
    double lat = 0;
    double lng = 0;

    // Eğer GeoPoint olarak kayıtlıysa (Standart Firebase):
    // Not: Kayıt ekranında manuel double olarak atmıştık ama garanti olsun.
    if (data['latitude'] != null && data['longitude'] != null) {
      lat = (data['latitude'] as num).toDouble();
      lng = (data['longitude'] as num).toDouble();
    } else if (data['location'] is GeoPoint) {
      lat = (data['location'] as GeoPoint).latitude;
      lng = (data['location'] as GeoPoint).longitude;
    }

    return ShopModel(
      id: doc.id,
      name: data['shopName'] ?? 'Unknown Shop',
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'] ??
          'assets/images/ceyda_abla.jpg', // Resim yoksa varsayılan
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      phoneNumber: data['phone'] ?? '',
      location: LatLng(lat, lng),
      pricePerDay: (data['price'] as num?)?.toDouble() ?? 80.0,
      isManuallyOpen: data['isOpen'] ?? true,
      openDays: _parseOpenDays(data['openDays']),
      openTime: data['openTime'] as String?,
      closeTime: data['closeTime'] as String?,
      openStartDate: _parseDate(data['openStartDate']),
      openEndDate: _parseDate(data['openEndDate']),
    );
  }
}
