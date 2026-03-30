/// Event / banquet management service
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/models/event_model.dart';

class EventService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  static CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('$_basePath/events');

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
    await _eventsRef.doc(event.id).set(event.toFirestore());
  }

  /// Update an event
  static Future<void> updateEvent(EventModel event) async {
    await _eventsRef.doc(event.id).update(event.toFirestore());
  }

  /// Delete an event
  static Future<void> deleteEvent(String eventId) async {
    await _eventsRef.doc(eventId).delete();
  }
}
