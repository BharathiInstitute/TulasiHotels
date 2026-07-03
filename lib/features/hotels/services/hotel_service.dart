/// Hotel service — manages multi-hotel creation and lookup for a user
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/features/hotels/models/hotel_info.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';

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
    return _hotelsRef
        .orderBy('createdAt')
        .snapshots()
        .map(
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

    // Also recover any additional hotels this user owns (where ownerUid==userId)
    // This fixes hotels that were incorrectly pruned by a previous bug.
    await recoverOwnedHotels();
  }

  /// Scans Firestore for stores owned by this user (ownerUid == userId) and
  /// re-registers any that are missing from user_hotels. Called once during
  /// ensureDefaultHotel to recover hotels lost by the pruning bug.
  static Future<void> recoverOwnedHotels() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      // Find all stores where this user is the creator
      final ownedStores = await _firestore
          .collection('users')
          .where('ownerUid', isEqualTo: userId)
          .get();

      for (final storeDoc in ownedStores.docs) {
        final storeId = storeDoc.id;
        if (storeId == userId) continue; // Default hotel already handled

        // Check if already in user_hotels
        final existing = await _hotelsRef.doc(storeId).get();
        if (existing.exists) continue;

        // Re-register the missing hotel entry
        final data = storeDoc.data();
        final name = (data['shopName'] as String?) ?? 'Hotel';
        await _hotelsRef.doc(storeId).set({
          'name': name,
          'slug': _generateSlug(name),
          'role': 'owner',
          'status': HotelStatus.active.name,
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        });
        debugPrint('Recovered missing hotel entry: $name (id=$storeId)');
      }
    } catch (e) {
      debugPrint(
        '⚠️ recoverOwnedHotels error (check Firestore rules/index): $e',
      );
    }
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
      'isShopSetupComplete': true,
      'limits': {
        'productsCount': 0,
        'productsLimit': PlanConfig.free.productsLimitFirestore,
        'billsThisMonth': 0,
        'billsLimit': PlanConfig.free.billsLimitFirestore,
        'customersCount': 0,
        'customersLimit': PlanConfig.free.customersLimitFirestore,
        'staffCount': 0,
        'staffLimit': PlanConfig.free.staffLimitFirestore,
        'tablesCount': 0,
        'tablesLimit': PlanConfig.free.tablesLimitFirestore,
      },
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

    // Initialize billing counter for the new store
    await _firestore.doc('users/$storeId/counters/billing').set({'current': 0});

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

  /// Remove user_hotels entries where the user has no valid member doc.
  /// Also removes ghost "owner" entries created by an old bug (staff members
  /// whose users/{uid} doc was auto-created before the staff-detection fix).
  /// Runs on login to clean up stale entries.
  static Future<void> pruneInvalidHotels() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final hotels = await _hotelsRef.get();
      for (final hotelDoc in hotels.docs) {
        final hotelId = hotelDoc.id;
        final role = (hotelDoc.data()['role'] as String?) ?? '';

        if (role == 'owner') {
          // Verify this user is actually the owner of this store.
          // Real owners have users/{hotelId}.ownerUid == userId.
          // Ghost entries (created by the old auto-create bug) won't match.
          try {
            final storeDoc = await _firestore
                .collection('users')
                .doc(hotelId)
                .get();
            if (storeDoc.exists) {
              final ownerUid = storeDoc.data()?['ownerUid'] as String?;
              if (ownerUid == userId) continue; // real owner — keep
            }
            // No store doc, or ownerUid doesn't match → ghost entry → prune
            await _hotelsRef.doc(hotelId).delete();
            debugPrint('Pruned ghost owner hotel entry: $hotelId');
          } catch (_) {
            continue; // Can't verify → keep (fail safe)
          }
        } else {
          // For non-owner entries (invited members), verify the member doc exists.
          final memberDoc = await _firestore
              .collection('users/$hotelId/members')
              .doc(userId)
              .get();
          if (!memberDoc.exists) {
            await _hotelsRef.doc(hotelId).delete();
            debugPrint('Pruned invalid hotel entry: $hotelId');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ pruneInvalidHotels error: $e');
    }
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
        // storeId is the specific hotel the member was invited to.
        // Falls back to ownerId for old invites created before this field existed.
        final storeId = (data['storeId'] as String?)?.isNotEmpty == true
            ? data['storeId'] as String
            : ownerId;
        final shopName = data['shopName'] as String? ?? 'Hotel';
        final role = data['role'] as String? ?? 'staff';

        // Write user_hotels entry pointing to the correct store (hotel)
        await _firestore
            .collection('user_hotels/${user.uid}/hotels')
            .doc(storeId) // ← use storeId
            .set({
              'id': storeId, // ← use storeId
              'name': shopName,
              'slug': shopName.toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]'),
                '-',
              ),
              'role': role,
              if (data['customRoleName'] != null)
                'customRoleName': data['customRoleName'],
              'status': 'active',
              'createdAt': FieldValue.serverTimestamp(),
            });

        // Directly write the real-UID member doc from invite data.
        // We do NOT try to read the placeholder doc (staff lack permission to
        // read members they are not yet part of). Writing the real UID doc
        // directly is allowed by the Firestore rule:
        //   memberId == request.auth.uid && resource.data.email == request.auth.token.email
        final membersRef = _firestore.collection('users/$storeId/members');
        final customRoleName = data['customRoleName'] as String?;
        await membersRef.doc(user.uid).set(
          {
            'uid': user.uid,
            'email': user.email ?? '',
            'displayName': user.displayName ?? '',
            'role': role,
            if (customRoleName != null && customRoleName.isNotEmpty)
              'customRoleName': customRoleName,
            'status': 'active',
            'invitedBy': data['ownerId'] ?? '',
            'joinedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ); // merge:true avoids overwriting existing docs

        // Best-effort: try to clean up the placeholder doc if it exists.
        // This may fail if the staff can't read it — that's OK, real doc is already written.
        try {
          final placeholders = await membersRef
              .where('email', isEqualTo: user.email)
              .get();
          for (final memberDoc in placeholders.docs) {
            if (memberDoc.id.startsWith('existing_') ||
                memberDoc.id.startsWith('invite_')) {
              await memberDoc.reference.delete();
            }
          }
        } catch (_) {
          // Permission denied reading placeholder — harmless, real doc is written
        }

        await doc.reference.delete();
      }
      if (invites.docs.isNotEmpty) {
        debugPrint('Resolved ${invites.docs.length} pending invite(s)');
      }
    } catch (e) {
      debugPrint('⚠️ resolvePendingInvites step 1 error: $e');
    }

    // ── 2. Collection-group scan: fix placeholder UID docs only ──
    // Only processes docs with placeholder IDs (invite_/existing_) that were
    // created before the user had a real UID. Does NOT auto-link hotels for
    // docs that already have the real UID — those should have a user_hotels
    // entry written at invite time already.
    try {
      final memberDocs = await _firestore
          .collectionGroup('members')
          .where('email', isEqualTo: user.email)
          .get();

      for (final snap in memberDocs.docs) {
        final pathParts = snap.reference.path.split('/');
        if (pathParts.length < 4) continue;
        final storeId = pathParts[1]; // users/{storeId}/members/{docId}

        // Skip the user's own store
        if (storeId == user.uid) continue;

        // Only process placeholder docs — real UID docs are already resolved
        final isPlaceholder =
            snap.id.startsWith('existing_') || snap.id.startsWith('invite_');
        if (!isPlaceholder) continue;

        // Migrate placeholder to real UID
        final memberData = Map<String, dynamic>.from(snap.data());
        memberData['uid'] = user.uid;
        memberData['status'] = 'active';
        await _firestore
            .collection('users/$storeId/members')
            .doc(user.uid)
            .set(memberData);
        await snap.reference.delete();

        // Write user_hotels entry if not already present
        final existing = await _firestore
            .collection('user_hotels/${user.uid}/hotels')
            .doc(storeId)
            .get();
        if (!existing.exists) {
          final storeDoc = await _firestore
              .collection('users')
              .doc(storeId)
              .get();
          final shopName = (storeDoc.data()?['shopName'] as String?) ?? 'Hotel';
          final role = memberData['role'] as String? ?? 'staff';
          await _firestore
              .collection('user_hotels/${user.uid}/hotels')
              .doc(storeId)
              .set({
                'id': storeId,
                'name': shopName,
                'slug': shopName.toLowerCase().replaceAll(
                  RegExp(r'[^a-z0-9]'),
                  '-',
                ),
                'role': role,
                'status': 'active',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        debugPrint('Resolved placeholder member → $storeId');
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
