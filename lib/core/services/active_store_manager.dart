/// Singleton that holds the active store (hotel) ID for static services.
///
/// Set when the user selects a hotel from the hotel selector.
/// All Firestore service classes use this to build their base path.
library;

import 'package:firebase_auth/firebase_auth.dart';

class ActiveStoreManager {
  ActiveStoreManager._();

  static String? _activeStoreId;

  /// The currently selected store/hotel ID.
  /// Falls back to the logged-in user's UID if no hotel is explicitly selected.
  static String? get storeId =>
      _activeStoreId ?? FirebaseAuth.instance.currentUser?.uid;

  /// Set the active store ID (called when user opens a hotel).
  static void setActiveStore(String id) {
    _activeStoreId = id;
  }

  /// Clear the active store (called on logout or hotel deselection).
  static void clear() {
    _activeStoreId = null;
  }

  /// Firestore base path for the active store: `users/{storeId}`
  static String get basePath {
    final id = storeId;
    if (id == null || id.isEmpty) return '';
    return 'users/$id';
  }
}
