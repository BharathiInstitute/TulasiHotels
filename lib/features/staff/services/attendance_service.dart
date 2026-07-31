/// Attendance service � Firestore CRUD for staff attendance tracking
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/settings/services/attendance_settings_service.dart';
import 'package:tulasihotels/features/staff/services/location_service.dart';
import 'package:tulasihotels/models/attendance_model.dart';

class AttendanceService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _attendanceRef =>
      _firestore.collection('$_basePath/attendance');

  /// Stream today's attendance records (real-time)
  static Stream<List<AttendanceModel>> todayAttendanceStream() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _attendanceRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => AttendanceModel.fromFirestore(doc))
                  .toList()
                ..sort((a, b) => b.clockIn.compareTo(a.clockIn)),
        );
  }

  /// Stream attendance for a specific date range
  static Stream<List<AttendanceModel>> attendanceStream({
    required DateTime from,
    required DateTime to,
  }) {
    return _attendanceRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream attendance for a specific staff member within a date range
  static Stream<List<AttendanceModel>> staffAttendanceStream({
    required String staffId,
    required DateTime from,
    required DateTime to,
  }) {
    return _attendanceRef
        .where('staffId', isEqualTo: staffId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Clock in a staff member (with optional geo-tag)
  static Future<AttendanceModel> clockIn({
    required String staffId,
    required String staffName,
    ClockSource source = ClockSource.staff,
    bool captureLocation = true,
  }) async {
    final now = DateTime.now();
    final id = generateSafeId('att');
    final hotelId = ActiveStoreManager.storeId;

    // -- Geo-fence enforcement -----------------------------------
    LocationResult? location;
    if (captureLocation || hotelId != null) {
      // Fetch settings to check if geo-fence is required
      final geoSettings = hotelId != null
          ? await AttendanceSettingsService.fetch(hotelId)
          : null;

      if (geoSettings != null &&
          geoSettings.requireGeoFence &&
          geoSettings.hasLocation) {
        // Must capture location and check radius
        location = await LocationService.captureLocation();
        if (location == null) {
          throw Exception(
            'GPS location is required for clock-in. '
            'Please enable location services and try again.',
          );
        }
        final distance = LocationService.distanceBetween(
          location.latitude,
          location.longitude,
          geoSettings.storeLatitude!,
          geoSettings.storeLongitude!,
        );
        if (distance > geoSettings.geoFenceRadius) {
        throw Exception(
            'You are ${distance.toStringAsFixed(0)}m away from the store. '
            'Must be within ${geoSettings.geoFenceRadius}m to clock in.',
          );
        }
      } else if (captureLocation) {
        // Geo-fence not required � capture location silently if allowed
        location = await LocationService.captureLocation();
      }
    }

    final attendance = AttendanceModel(
      id: id,
      staffId: staffId,
      staffName: staffName,
      date: DateTime(now.year, now.month, now.day),
      clockIn: now,
      clockInLat: location?.latitude,
      clockInLng: location?.longitude,
      clockInAddress: location?.address,
      clockInInside: location?.isInsideGeofence,
      clockInSource: source,
    );

    await _attendanceRef.doc(id).set(attendance.toFirestore());
    debugPrint(
      'Clock in: $staffName at $now (${location?.address ?? "no location"})',
    );
    return attendance;
  }

  /// Clock out a staff member (with optional geo-tag)
  ///
  /// If [recordId] is provided, updates that record directly (preferred).
  /// Otherwise falls back to querying for the open record.
  static Future<void> clockOut(
    String staffId, {
    String? recordId,
    ClockSource source = ClockSource.staff,
    bool captureLocation = true,
  }) async {
    final hotelId = ActiveStoreManager.storeId;

    // -- Geo-fence enforcement -------------------------------------
    LocationResult? location;
    if (captureLocation || hotelId != null) {
      final geoSettings = hotelId != null
          ? await AttendanceSettingsService.fetch(hotelId)
          : null;

      if (geoSettings != null &&
          geoSettings.requireGeoFence &&
          geoSettings.hasLocation) {
        location = await LocationService.captureLocation();
        if (location == null) {
          throw Exception(
            'GPS location is required for clock-out. '
            'Please enable location services and try again.',
          );
        }
        final distance = LocationService.distanceBetween(
          location.latitude,
          location.longitude,
          geoSettings.storeLatitude!,
          geoSettings.storeLongitude!,
        );
        if (distance > geoSettings.geoFenceRadius) {
          throw Exception(
            'You are ${distance.toStringAsFixed(0)}m away from the store. '
            'Must be within ${geoSettings.geoFenceRadius}m to clock out.',
          );
        }
      } else if (captureLocation) {
        location = await LocationService.captureLocation();
      }
    }

    final updates = <String, dynamic>{
      'clockOut': Timestamp.fromDate(DateTime.now()),
      'status': AttendanceStatus.clockedOut.name,
      'clockOutSource': source.name,
      if (location != null) 'clockOutLat': location.latitude,
      if (location != null) 'clockOutLng': location.longitude,
      if (location?.address != null) 'clockOutAddress': location!.address,
      if (location != null) 'clockOutInside': location.isInsideGeofence,
    };

    if (recordId != null) {
      await _attendanceRef.doc(recordId).update(updates);
      debugPrint('Clock out: $staffId (direct)');
      return;
    }

    // Fallback: query for today's open record
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _attendanceRef
        .where('staffId', isEqualTo: staffId)
        .where('status', isEqualTo: AttendanceStatus.clockedIn.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final docId = snapshot.docs.first.id;
    await _attendanceRef.doc(docId).update(updates);
    debugPrint('Clock out: $staffId');
  }

  /// Check if a staff member is currently clocked in today
  static Future<bool> isClockedIn(String staffId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _attendanceRef
        .where('staffId', isEqualTo: staffId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('status', isEqualTo: AttendanceStatus.clockedIn.name)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ── Owner manual corrections ──────────────────────────────────

  /// Add a manual attendance record (owner use)
  static Future<void> addManualRecord({
    required String staffId,
    required String staffName,
    required DateTime date,
    required DateTime clockIn,
    required DateTime clockOut,
    String? editedBy,
    String? editNote,
  }) async {
    final id = generateSafeId('att');
    final attendance = AttendanceModel(
      id: id,
      staffId: staffId,
      staffName: staffName,
      date: DateTime(date.year, date.month, date.day),
      clockIn: clockIn,
      clockOut: clockOut,
      status: AttendanceStatus.clockedOut,
      clockInSource: ClockSource.manual,
      clockOutSource: ClockSource.manual,
      editedBy: editedBy,
      editedAt: DateTime.now(),
      editNote: editNote,
    );
    await _attendanceRef.doc(id).set(attendance.toFirestore());
    debugPrint('Manual record added for $staffName on $date');
  }

  /// Update an existing attendance record (owner correction)
  static Future<void> updateRecord(
    String recordId, {
    DateTime? clockIn,
    DateTime? clockOut,
    AttendanceStatus? status,
    String? editedBy,
    String? editNote,
  }) async {
    final updates = <String, dynamic>{};
    if (clockIn != null) updates['clockIn'] = Timestamp.fromDate(clockIn);
    if (clockOut != null) updates['clockOut'] = Timestamp.fromDate(clockOut);
    if (status != null) updates['status'] = status.name;
    if (editedBy != null) {
      updates['editedBy'] = editedBy;
      updates['editedAt'] = Timestamp.fromDate(DateTime.now());
    }
    if (editNote != null) updates['editNote'] = editNote;
    if (updates.isEmpty) return;
    await _attendanceRef.doc(recordId).update(updates);
    debugPrint('Record $recordId updated by $editedBy');
  }

  /// Delete an attendance record (owner correction)
  static Future<void> deleteRecord(String recordId) async {
    await _attendanceRef.doc(recordId).delete();
    debugPrint('Record $recordId deleted');
  }
}
