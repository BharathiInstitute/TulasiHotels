/// Firestore service for reading and writing attendance geo-fence settings.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/features/settings/models/attendance_settings_model.dart';

class AttendanceSettingsService {
  AttendanceSettingsService._();

  static DocumentReference<Map<String, dynamic>> _doc(String hotelId) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(hotelId)
          .collection('settings')
          .doc('attendance');

  /// Stream of attendance settings for real-time updates.
  static Stream<AttendanceSettingsModel> stream(String hotelId) {
    return _doc(hotelId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return AttendanceSettingsModel.empty;
      }
      return AttendanceSettingsModel.fromFirestore(snap.data()!);
    });
  }

  /// One-time fetch — used by attendance_service during clock-in/out.
  static Future<AttendanceSettingsModel> fetch(String hotelId) async {
    try {
      final snap = await _doc(hotelId).get();
      if (!snap.exists || snap.data() == null) {
        return AttendanceSettingsModel.empty;
      }
      return AttendanceSettingsModel.fromFirestore(snap.data()!);
    } catch (e) {
      debugPrint('⚠️ AttendanceSettingsService.fetch error: $e');
      return AttendanceSettingsModel.empty;
    }
  }

  /// Save settings (owner only).
  static Future<void> save(
    String hotelId,
    AttendanceSettingsModel settings,
  ) async {
    await _doc(hotelId).set(settings.toFirestore(), SetOptions(merge: true));
    debugPrint('✅ Attendance settings saved for $hotelId');
  }
}
