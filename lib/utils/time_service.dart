import 'package:cloud_firestore/cloud_firestore.dart';

class TimeService {
  static DateTime? _serverUtcAtSync;
  static Stopwatch? _stopwatch;
  static bool _isSyncing = false;

  static bool get isSynced => _serverUtcAtSync != null;

  static Future<void> syncWithServer() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final docRef =
          FirebaseFirestore.instance.collection('meta').doc('serverTime');
      await docRef.set(
        {'timestamp': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      final snapshot = await docRef.get();
      final data = snapshot.data();
      final ts = data?['timestamp'];
      if (ts is Timestamp) {
        _serverUtcAtSync = ts.toDate().toUtc();
        _stopwatch = Stopwatch()..start();
      }
    } finally {
      _isSyncing = false;
    }
  }

  static DateTime nowTurkey() {
    if (_serverUtcAtSync != null && _stopwatch != null) {
      return _serverUtcAtSync!
          .add(_stopwatch!.elapsed)
          .add(const Duration(hours: 3));
    }
    return DateTime.now().toUtc().add(const Duration(hours: 3));
  }
}
