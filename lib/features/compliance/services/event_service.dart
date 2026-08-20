/// Event / banquet management service
library;

import 'dart:async';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/features/permissions/services/module_mutation_guard.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/event_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class EventService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('$_basePath/events');

  /// Firestore writes should not block UX in offline/flaky networks.
  /// If the write doesn't resolve quickly, we assume it is queued locally.
  static Future<void> _commitWithOfflineFallback(Future<void> write) async {
    try {
      await write.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      debugPrint('⚠️ Event write timed out; treating as queued local write');
    }
  }

  /// Stream upcoming events
  static Stream<List<EventModel>> upcomingEventsStream() {
    return _eventsRef
        .where(
          'eventDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
        )
        .orderBy('eventDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream all events
  static Stream<List<EventModel>> allEventsStream() {
    return _eventsRef
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Create an event
  static Future<void> createEvent(EventModel event) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.events,
      PermissionAction.create,
    );
    await _commitWithOfflineFallback(
      _eventsRef.doc(event.id).set(event.toFirestore()),
    );
  }

  /// Update an event
  static Future<void> updateEvent(EventModel event) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.events,
      PermissionAction.update,
    );
    await _commitWithOfflineFallback(
      _eventsRef.doc(event.id).update(event.toFirestore()),
    );
  }

  /// Delete an event
  static Future<void> deleteEvent(String eventId) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.events,
      PermissionAction.delete,
    );
    await _eventsRef.doc(eventId).delete();
  }
}
