/// Windows-specific Firestore stream safety wrapper.
///
/// The Firebase C++ Desktop SDK sends platform channel messages from
/// non-platform threads, which crashes the Flutter engine on Windows.
/// This utility replaces real-time `.snapshots()` listeners with periodic
/// polling via `.get()` on Windows to completely avoid the threading issue.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Whether the current platform needs Firestore polling instead of snapshots.
final bool _isWindows = !kIsWeb && Platform.isWindows;

/// Default polling interval for Windows Firestore queries.
const Duration _defaultPollInterval = Duration(seconds: 5);

/// Wraps a Firestore query as a stream.
///
/// On non-Windows platforms, uses real-time `.snapshots()`.
/// On Windows, uses periodic `.get()` polling to avoid native threading crashes.
Stream<QuerySnapshot<Map<String, dynamic>>> safeSnapshots(
  Query<Map<String, dynamic>> query, {
  Duration pollInterval = _defaultPollInterval,
}) {
  if (!_isWindows) return query.snapshots();
  return _pollQuery(query, pollInterval);
}

/// Wraps a Firestore document reference as a stream.
///
/// On non-Windows platforms, uses real-time `.snapshots()`.
/// On Windows, uses periodic `.get()` polling to avoid native threading crashes.
Stream<DocumentSnapshot<Map<String, dynamic>>> safeDocSnapshots(
  DocumentReference<Map<String, dynamic>> docRef, {
  Duration pollInterval = _defaultPollInterval,
}) {
  if (!_isWindows) return docRef.snapshots();
  return _pollDocument(docRef, pollInterval);
}

/// Polls a Firestore query periodically and emits results as a stream.
Stream<QuerySnapshot<Map<String, dynamic>>> _pollQuery(
  Query<Map<String, dynamic>> query,
  Duration interval,
) {
  late StreamController<QuerySnapshot<Map<String, dynamic>>> controller;
  Timer? timer;
  bool isClosed = false;

  Future<void> fetch() async {
    if (isClosed) return;
    try {
      final snapshot = await query.get(const GetOptions(source: Source.cache));
      if (!isClosed) controller.add(snapshot);
    } catch (e) {
      // Try server if cache fails
      try {
        final snapshot = await query.get();
        if (!isClosed) controller.add(snapshot);
      } catch (e2) {
        debugPrint('⚠️ Windows Firestore poll error: $e2');
      }
    }
  }

  controller = StreamController<QuerySnapshot<Map<String, dynamic>>>(
    onListen: () {
      // Fetch immediately, then periodically
      fetch();
      timer = Timer.periodic(interval, (_) => fetch());
    },
    onPause: () => timer?.cancel(),
    onResume: () {
      fetch();
      timer = Timer.periodic(interval, (_) => fetch());
    },
    onCancel: () {
      isClosed = true;
      timer?.cancel();
    },
  );

  return controller.stream;
}

/// Polls a Firestore document periodically and emits results as a stream.
Stream<DocumentSnapshot<Map<String, dynamic>>> _pollDocument(
  DocumentReference<Map<String, dynamic>> docRef,
  Duration interval,
) {
  late StreamController<DocumentSnapshot<Map<String, dynamic>>> controller;
  Timer? timer;
  bool isClosed = false;

  Future<void> fetch() async {
    if (isClosed) return;
    try {
      final snapshot = await docRef.get(const GetOptions(source: Source.cache));
      if (!isClosed) controller.add(snapshot);
    } catch (e) {
      try {
        final snapshot = await docRef.get();
        if (!isClosed) controller.add(snapshot);
      } catch (e2) {
        debugPrint('⚠️ Windows Firestore doc poll error: $e2');
      }
    }
  }

  controller = StreamController<DocumentSnapshot<Map<String, dynamic>>>(
    onListen: () {
      fetch();
      timer = Timer.periodic(interval, (_) => fetch());
    },
    onPause: () => timer?.cancel(),
    onResume: () {
      fetch();
      timer = Timer.periodic(interval, (_) => fetch());
    },
    onCancel: () {
      isClosed = true;
      timer?.cancel();
    },
  );

  return controller.stream;
}
