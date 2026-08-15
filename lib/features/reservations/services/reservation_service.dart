/// Reservation management service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/router/app_router.dart';
import 'package:tulasihotels/models/reservation_model.dart';

class ReservationService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _reservationsRef =>
      _firestore.collection('$_basePath/reservations');

  /// Stream today's reservations
  static Stream<List<ReservationModel>> todayReservationsStream() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _reservationsRef
        .where(
          'dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ReservationModel.fromFirestore(doc))
                  .toList()
                ..sort((a, b) => a.dateTime.compareTo(b.dateTime)),
        );
  }

  /// Stream upcoming reservations. Window matches the 90-day booking horizon
  /// offered by the new-reservation date picker.
  static Stream<List<ReservationModel>> upcomingReservationsStream({
    int daysAhead = 90,
  }) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final horizon = startOfToday.add(Duration(days: daysAhead + 1));

    return _reservationsRef
        .where(
          'dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
        )
        .where('dateTime', isLessThan: Timestamp.fromDate(horizon))
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ReservationModel.fromFirestore(doc))
                  .toList()
                ..sort((a, b) => a.dateTime.compareTo(b.dateTime)),
        );
  }

  /// Create a new reservation
  static Future<ReservationModel> createReservation(
    ReservationModel reservation,
    RoutePermissionState permissions,
  ) async {
    if (!permissions.canCreate) {
      throw StateError(
        PermissionCenter.deniedActionMessage(
          AppRoutes.reservations,
          PermissionAction.create,
        ),
      );
    }
    await _reservationsRef.doc(reservation.id).set(reservation.toFirestore());
    debugPrint(
      'Created reservation for ${reservation.guestName} at ${reservation.dateTime}',
    );
    return reservation;
  }

  /// Confirm a reservation
  static Future<void> confirmReservation(
    String id,
    RoutePermissionState permissions,
  ) async {
    if (!permissions.canUpdate) {
      throw StateError(
        PermissionCenter.deniedActionMessage(
          AppRoutes.reservations,
          PermissionAction.update,
        ),
      );
    }
    await _reservationsRef.doc(id).update({
      'status': ReservationStatus.confirmed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Seat a reservation (assign table)
  static Future<void> seatReservation(
    String id,
    String tableId,
    RoutePermissionState permissions,
  ) async {
    if (!permissions.canUpdate) {
      throw StateError(
        PermissionCenter.deniedActionMessage(
          AppRoutes.reservations,
          PermissionAction.update,
        ),
      );
    }
    await _reservationsRef.doc(id).update({
      'status': ReservationStatus.seated.name,
      'tableId': tableId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel a reservation
  static Future<void> cancelReservation(
    String id,
    RoutePermissionState permissions,
  ) async {
    if (!permissions.canUpdate) {
      throw StateError(
        PermissionCenter.deniedActionMessage(
          AppRoutes.reservations,
          PermissionAction.update,
        ),
      );
    }
    await _reservationsRef.doc(id).update({
      'status': ReservationStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark as no-show
  static Future<void> markNoShow(
    String id,
    RoutePermissionState permissions,
  ) async {
    if (!permissions.canUpdate) {
      throw StateError(
        PermissionCenter.deniedActionMessage(
          AppRoutes.reservations,
          PermissionAction.update,
        ),
      );
    }
    await _reservationsRef.doc(id).update({
      'status': ReservationStatus.noShow.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if a table is available at a given time
  static Future<bool> isTableAvailable(
    String tableId,
    DateTime dateTime,
  ) async {
    final start = dateTime.subtract(const Duration(minutes: 90));
    final end = dateTime.add(const Duration(minutes: 90));

    final snapshot = await _reservationsRef
        .where('tableId', isEqualTo: tableId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.isEmpty;
  }

  /// Delete a reservation
  static Future<void> deleteReservation(
    String id,
    RoutePermissionState permissions,
  ) async {
    if (!permissions.canDelete) {
      throw StateError(
        PermissionCenter.deniedActionMessage(
          AppRoutes.reservations,
          PermissionAction.delete,
        ),
      );
    }
    await _reservationsRef.doc(id).delete();
  }
}
