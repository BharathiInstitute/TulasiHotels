/// Hotel service — manages multi-hotel creation and lookup for a user
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/features/hotels/models/hotel_info.dart';

class HotelService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  /// Collection: user_hotels/{userId}/hotels/{hotelId}
  static CollectionReference<Map<String, dynamic>> get _hotelsRef {
    final userId = _userId;
    if (userId == null) throw StateError('No authenticated user');
    return _firestore.collection('user_hotels/$userId/hotels');
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Stream all hotels the current user has access to
  static Stream<List<HotelInfo>> hotelsStream() {
    return _hotelsRef.orderBy('createdAt').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => HotelInfo.fromFirestore(doc)).toList(),
    );
  }

  /// Get all hotels (one-shot)
  static Future<List<HotelInfo>> getHotels() async {
    final snapshot = await _hotelsRef.orderBy('createdAt').get();
    return snapshot.docs.map((doc) => HotelInfo.fromFirestore(doc)).toList();
  }

  /// Check if user has any hotels registered
  static Future<bool> hasHotels() async {
    final snapshot = await _hotelsRef.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Ensure the user's existing store is registered as a hotel
  /// (backward compatibility for single-store users)
  static Future<void> ensureDefaultHotel() async {
    final userId = _userId;
    if (userId == null) return;

    final doc = await _hotelsRef.doc(userId).get();
    if (doc.exists) return; // Already registered

    // Read the user's existing store doc
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data() ?? {};
    final shopName = (userData['shopName'] as String?) ?? 'My Hotel';

    // Register existing store as the default hotel
    final hotel = HotelInfo(
      id: userId,
      name: shopName,
      slug: _generateSlug(shopName),
      role: 'owner',
      createdAt: DateTime.now(),
    );
    await _hotelsRef.doc(userId).set(hotel.toFirestore());
    debugPrint('Registered default hotel: $shopName');
  }

  /// Create a new hotel
  static Future<HotelInfo> createHotel({
    required String name,
    String? slug,
  }) async {
    final userId = _userId;
    if (userId == null) throw StateError('No authenticated user');

    // Create a new store document in users/ collection
    final storeRef = _firestore.collection('users').doc();
    final storeId = storeRef.id;
    final user = _auth.currentUser!;

    // Create the store document with minimal data
    await storeRef.set({
      'shopName': name,
      'ownerName': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': '',
      'ownerUid': userId,
      'currency': 'INR',
      'timezone': 'Asia/Kolkata',
      'settings': {'darkMode': false},
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Register the owner as a member of the new store
    await _firestore.collection('users/$storeId/members').doc(userId).set({
      'email': user.email ?? '',
      'displayName': user.displayName ?? 'Owner',
      'role': 'owner',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // Add to user's hotel list
    final hotelSlug = slug ?? _generateSlug(name);
    final hotel = HotelInfo(
      id: storeId,
      name: name,
      slug: hotelSlug,
      role: 'owner',
      createdAt: DateTime.now(),
    );
    await _hotelsRef.doc(storeId).set(hotel.toFirestore());

    debugPrint('Created new hotel: $name (id=$storeId)');
    return hotel;
  }

  /// Update hotel name
  static Future<void> updateHotelName(String hotelId, String name) async {
    await _hotelsRef.doc(hotelId).update({
      'name': name,
      'slug': _generateSlug(name),
    });
  }

  /// Archive a hotel (soft delete)
  static Future<void> archiveHotel(String hotelId) async {
    await _hotelsRef.doc(hotelId).update({'status': HotelStatus.archived.name});
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Resolve any pending member invites and also auto-link the user to any
  /// hotels where they appear as a member (collection group query).
  /// Called on login — handles both new invites and pre-existing members.
  static Future<void> resolvePendingInvites() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    // ── 1. Resolve pending_member_invites (placeholder UIDs) ──
    try {
      final invites = await _firestore
          .collection('pending_member_invites')
          .where('email', isEqualTo: user.email)
          .get();

      for (final doc in invites.docs) {
        final data = doc.data();
        final ownerId = data['ownerId'] as String;
        final shopName = data['shopName'] as String? ?? 'Hotel';
        final role = data['role'] as String? ?? 'staff';

        await _firestore
            .collection('user_hotels/${user.uid}/hotels')
            .doc(ownerId)
            .set({
          'id': ownerId,
          'name': shopName,
          'slug': shopName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
          'role': role,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Replace placeholder member doc with real UID
        final membersRef = _firestore.collection('users/$ownerId/members');
        final placeholders = await membersRef
            .where('email', isEqualTo: user.email)
            .get();
        for (final memberDoc in placeholders.docs) {
          if (memberDoc.id.startsWith('existing_') ||
              memberDoc.id.startsWith('invite_')) {
            final memberData = Map<String, dynamic>.from(memberDoc.data());
            memberData['uid'] = user.uid;
            memberData['status'] = 'active';
            await membersRef.doc(user.uid).set(memberData);
            await memberDoc.reference.delete();
          }
        }
        await doc.reference.delete();
      }
      if (invites.docs.isNotEmpty) {
        debugPrint('Resolved ${invites.docs.length} pending invite(s)');
      }
    } catch (e) {
      debugPrint('⚠️ resolvePendingInvites step 1 error: $e');
    }

    // ── 2. Collection-group scan: find member docs for this user by email ──
    // This catches members added before the pending_invites system, or cases
    // where user_hotels entry was never written.
    try {
      final memberDocs = await _firestore
          .collectionGroup('members')
          .where('email', isEqualTo: user.email)
          .get();

      for (final snap in memberDocs.docs) {
        // The owner ID is the parent of the 'members' subcollection:
        // path = users/{ownerId}/members/{uid}
        final pathParts = snap.reference.path.split('/');
        if (pathParts.length < 4) continue;
        final ownerId = pathParts[1]; // users/{ownerId}/members/{docId}

        // Skip if this is the user's own store
        if (ownerId == user.uid) continue;

        // Check if user_hotels entry already exists
        final existing = await _firestore
            .collection('user_hotels/${user.uid}/hotels')
            .doc(ownerId)
            .get();
        if (existing.exists) continue;

        // Fetch store name
        final ownerDoc =
            await _firestore.collection('users').doc(ownerId).get();
        final shopName =
            (ownerDoc.data()?['shopName'] as String?) ?? 'Hotel';
        final role = snap.data()['role'] as String? ?? 'staff';

        await _firestore
            .collection('user_hotels/${user.uid}/hotels')
            .doc(ownerId)
            .set({
          'id': ownerId,
          'name': shopName,
          'slug': shopName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
          'role': role,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Fix placeholder UID if needed
        if (snap.id != user.uid) {
          final memberData = Map<String, dynamic>.from(snap.data());
          memberData['uid'] = user.uid;
          memberData['status'] = 'active';
          await _firestore
              .collection('users/$ownerId/members')
              .doc(user.uid)
              .set(memberData);
          if (snap.id.startsWith('existing_') ||
              snap.id.startsWith('invite_')) {
            await snap.reference.delete();
          }
        }

        debugPrint('Auto-linked hotel: $shopName (ownerId=$ownerId)');
      }
    } catch (e) {
      debugPrint('⚠️ resolvePendingInvites step 2 error: $e');
    }
  }

  static String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
