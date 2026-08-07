/// Hotel service — manages multi-hotel creation and lookup for a user
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:tulasihotels/core/services/cloud_function_helper.dart';
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
    final userId = _userId;
    if (userId == null) return Stream.value(const <HotelInfo>[]);

    return _hotelsRef.orderBy('createdAt').snapshots().asyncMap((
      snapshot,
    ) async {
      await _syncOwnerBusinessBundle(userId);
      final hotels = snapshot.docs
          .map((doc) => HotelInfo.fromFirestore(doc))
          .toList();
      return _hydrateHotelsWithLiveMembership(hotels, userId);
    });
  }

  /// Get all hotels (one-shot)
  static Future<List<HotelInfo>> getHotels() async {
    final userId = _userId;
    if (userId == null) return const <HotelInfo>[];

    await _syncOwnerBusinessBundle(userId);
    final snapshot = await _hotelsRef.orderBy('createdAt').get();
    final hotels = snapshot.docs
        .map((doc) => HotelInfo.fromFirestore(doc))
        .toList();
    return _hydrateHotelsWithLiveMembership(hotels, userId);
  }

  /// user_hotels is a lightweight mapping and can become stale when owner
  /// renames a restaurant or changes a member role. Read live docs so selector
  /// always shows current restaurant name and role label.
  static Future<List<HotelInfo>> _hydrateHotelsWithLiveMembership(
    List<HotelInfo> hotels,
    String userId,
  ) async {
    final ownerHotels = hotels.where((hotel) => hotel.isOwner).toList();
    final ownerHotelIds = ownerHotels.map((hotel) => hotel.id).toList();
    var normalizedBusinessHotelIds = <String>{};
    if (ownerHotelIds.isNotEmpty) {
      try {
        final entitlementDoc = await _firestore
            .collection('owner_entitlements')
            .doc(userId)
            .get();
        final entitlement = entitlementDoc.data();
        final isActiveBusiness =
            (entitlement?['plan'] as String?) == PlanConfig.business.key &&
            (entitlement?['status'] as String?) != 'expired';
        if (isActiveBusiness) {
          final seeded = (entitlement?['assignedRestaurantIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .where(ownerHotelIds.contains)
              .toList();
          final normalized = <String>[];
          for (final id in seeded) {
            if (!normalized.contains(id)) {
              normalized.add(id);
            }
            if (normalized.length >= 3) break;
          }
          for (final hotel in hotels.where((hotel) => hotel.isOwner)) {
            if (normalized.contains(hotel.id)) continue;
            normalized.add(hotel.id);
            if (normalized.length >= 3) break;
          }
          normalizedBusinessHotelIds = normalized.toSet();
        } else {
          normalizedBusinessHotelIds =
              await _inferBusinessHotelsFromOwnedStores(userId, ownerHotels);
        }
      } catch (_) {
        normalizedBusinessHotelIds =
            await _inferBusinessHotelsFromOwnedStores(userId, ownerHotels);
      }
    }

    return Future.wait(
      hotels.map((hotel) async {
        var name = hotel.name;
        var role = hotel.role;
        var customRoleName = hotel.customRoleName;
        var planKey = hotel.planKey;
        var status = hotel.status;

        // Keep displayed hotel name synced with users/{hotelId}.shopName.
        try {
          final storeDoc = await _firestore
              .collection('users')
              .doc(hotel.id)
              .get();
          final liveName = (storeDoc.data()?['shopName'] as String?)?.trim();
          if (liveName != null && liveName.isNotEmpty) {
            name = liveName;
          }

          final sub = storeDoc.data()?['subscription'] as Map<String, dynamic>?;
          final livePlanKey =
              (sub?['effectivePlan'] as String?)?.trim() ??
              (sub?['plan'] as String?)?.trim();
          if (livePlanKey != null && livePlanKey.isNotEmpty) {
            planKey = PlanConfig.fromKey(livePlanKey).key;
          }

          if (normalizedBusinessHotelIds.isNotEmpty && hotel.isOwner) {
            if (normalizedBusinessHotelIds.contains(hotel.id)) {
              planKey = PlanConfig.business.key;
              status = HotelStatus.active;
            } else {
              status = HotelStatus.suspended;
            }
          }
        } catch (_) {
          // Ignore read failures and fall back to cached mapping value.
        }

        // For non-owner entries, prefer live role from members/{uid}.
        if (!hotel.isOwner) {
          try {
            final memberDoc = await _firestore
                .collection('users/${hotel.id}/members')
                .doc(userId)
                .get();
            final data = memberDoc.data();
            final liveRole = (data?['role'] as String?)?.trim();
            if (liveRole != null && liveRole.isNotEmpty) {
              role = liveRole;
            }

            final liveCustomRole = (data?['customRoleName'] as String?)?.trim();
            customRoleName = (liveCustomRole == null || liveCustomRole.isEmpty)
                ? null
                : liveCustomRole;
          } catch (_) {
            // Ignore read failures and fall back to cached mapping value.
          }
        }

        if (name == hotel.name &&
            role == hotel.role &&
            customRoleName == hotel.customRoleName &&
            planKey == hotel.planKey &&
            status == hotel.status) {
          return hotel;
        }

        return HotelInfo(
          id: hotel.id,
          name: name,
          slug: hotel.slug,
          role: role,
          customRoleName: customRoleName,
          planKey: planKey,
          status: status,
          createdAt: hotel.createdAt,
        );
      }),
    );
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
    if (doc.exists) {
      // Sync name only if the currently active store IS the default (uid-based).
      // If the user is inside a different restaurant, don't overwrite the
      // default entry's name with potentially stale account-level shopName.
      final activeStore = ActiveStoreManager.storeId;
      if (activeStore == null || activeStore == userId) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final shopName = (userDoc.data()?['shopName'] as String?) ?? '';
        if (shopName.isNotEmpty && doc.data()?['name'] != shopName) {
          await _hotelsRef.doc(userId).update({
            'name': shopName,
            'slug': _generateSlug(shopName),
          });
        }
      }
      await _syncOwnerBusinessBundle(userId);
      return;
    }

    // Don't create a duplicate — if the user already has any hotels, skip
    final anyHotels = await _hotelsRef.limit(1).get();
    if (anyHotels.docs.isNotEmpty) return;

    // Read the user's existing store doc
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data() ?? {};
    final shopName = (userData['shopName'] as String?) ?? '';

    // Don't create a nameless ghost hotel — wait until the user has named
    // their restaurant (via shop setup or settings).
    if (shopName.isEmpty) return;

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
    await _syncOwnerBusinessBundle(userId);
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

  static Future<void> _syncOwnerBusinessBundle(String ownerUid) async {
    try {
      final entitlementRef = _firestore.collection('owner_entitlements').doc(ownerUid);
      final entitlementDoc = await entitlementRef.get();
      final entitlement = entitlementDoc.data();

      final defaultStore = await _firestore.collection('users').doc(ownerUid).get();
      final ownedStores = await _firestore
          .collection('users')
          .where('ownerUid', isEqualTo: ownerUid)
          .get();

      final storeDocs = <DocumentSnapshot<Map<String, dynamic>>>[
        if (defaultStore.exists) defaultStore,
        ...ownedStores.docs.where((doc) => doc.id != ownerUid),
      ];
      if (storeDocs.isEmpty) return;

      storeDocs.sort((a, b) {
        final aAt = (a.data()?['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bAt = (b.data()?['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return aAt.compareTo(bAt);
      });

      final entitlementPlan = (entitlement?['plan'] as String?)?.trim() ?? '';
      final entitlementStatus =
          (entitlement?['status'] as String?)?.trim() ?? 'inactive';
      final hasActiveBusinessEntitlement =
          entitlementPlan == PlanConfig.business.key &&
          entitlementStatus != 'expired';
        final defaultStoreSub = defaultStore.data()?['subscription'] as Map<String, dynamic>?;
        final defaultStorePlan =
          ((defaultStoreSub?['effectivePlan'] as String?) ??
              (defaultStoreSub?['plan'] as String?) ??
              'free')
            .trim();
        final defaultStoreStatus =
          ((defaultStoreSub?['effectiveStatus'] as String?) ??
              (defaultStoreSub?['status'] as String?) ??
              'active')
            .trim();
        final defaultStoreHasBusiness =
          defaultStore.exists &&
          defaultStoreStatus != 'expired' &&
          defaultStorePlan == PlanConfig.business.key;

      final businessDocs = storeDocs.where((doc) {
        final sub = doc.data()?['subscription'] as Map<String, dynamic>?;
        final status = ((sub?['effectiveStatus'] as String?) ??
                (sub?['status'] as String?) ??
                'active')
            .trim();
        final plan = ((sub?['effectivePlan'] as String?) ??
                (sub?['plan'] as String?) ??
                'free')
            .trim();
        return status != 'expired' && plan == PlanConfig.business.key;
      }).toList();

      if (!hasActiveBusinessEntitlement && !defaultStoreHasBusiness && businessDocs.isEmpty) {
        return;
      }

      final seededAssignedIds =
          (entitlement?['assignedRestaurantIds'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .where((id) => storeDocs.any((doc) => doc.id == id))
              .toList();

      final prioritized = <DocumentSnapshot<Map<String, dynamic>>>[
        if (defaultStoreHasBusiness)
          ...storeDocs.where((doc) => doc.id == ownerUid),
        ...seededAssignedIds
            .map(
              (id) => storeDocs.firstWhere(
                (doc) => doc.id == id,
              ),
            )
            ,
        ...businessDocs.where(
          (doc) =>
              !seededAssignedIds.contains(doc.id) &&
              (!defaultStoreHasBusiness || doc.id != ownerUid),
        ),
        ...storeDocs.where(
          (doc) =>
              (!defaultStoreHasBusiness || doc.id != ownerUid) &&
              !seededAssignedIds.contains(doc.id) &&
              !businessDocs.any((b) => b.id == doc.id),
        ),
      ];

      final assignedIds = prioritized.take(3).map((doc) => doc.id).toList();
      await entitlementRef.set({
        'plan': PlanConfig.business.key,
        'status': 'active',
        'maxRestaurants': 3,
        'assignedRestaurantIds': assignedIds,
        'primaryRestaurantId': assignedIds.first,
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      for (final doc in storeDocs) {
        final sub = doc.data()?['subscription'] as Map<String, dynamic>? ?? {};
        final directPlan = ((sub['directPlan'] as String?) ??
                (sub['effectivePlan'] as String?) ??
                (sub['plan'] as String?) ??
                PlanConfig.free.key)
            .trim();
        final directStatus = ((sub['directStatus'] as String?) ??
                (sub['effectiveStatus'] as String?) ??
                (sub['status'] as String?) ??
                'active')
            .trim();

        if (assignedIds.contains(doc.id)) {
          await _firestore.collection('users').doc(doc.id).set({
            'subscription.plan': PlanConfig.business.key,
            'subscription.status': 'active',
            'subscription.directPlan': directPlan == PlanConfig.business.key
                ? PlanConfig.free.key
                : directPlan,
            'subscription.directStatus': directStatus,
            'subscription.effectivePlan': PlanConfig.business.key,
            'subscription.effectiveStatus': 'active',
            'subscription.entitlementSource': 'owner_bundle',
            'subscription.entitlementOwnerUid': ownerUid,
            'subscription.entitlementId': ownerUid,
            'limits.billsLimit': PlanConfig.business.billsLimitFirestore,
            'limits.productsLimit': PlanConfig.business.productsLimitFirestore,
            'limits.customersLimit': PlanConfig.business.customersLimitFirestore,
            'limits.staffLimit': PlanConfig.business.staffLimitFirestore,
            'limits.tablesLimit': PlanConfig.business.tablesLimitFirestore,
          }, SetOptions(merge: true));
        } else {
          await _firestore.collection('users').doc(doc.id).set({
            'subscription.plan': directPlan == PlanConfig.business.key
                ? PlanConfig.free.key
                : directPlan,
            'subscription.status': directStatus,
            'subscription.directPlan': directPlan == PlanConfig.business.key
                ? PlanConfig.free.key
                : directPlan,
            'subscription.directStatus': directStatus,
            'subscription.effectivePlan': directPlan == PlanConfig.business.key
                ? PlanConfig.free.key
                : directPlan,
            'subscription.effectiveStatus': directStatus,
            'subscription.entitlementSource': 'direct',
            'subscription.entitlementOwnerUid': FieldValue.delete(),
            'subscription.entitlementId': FieldValue.delete(),
            'limits.billsLimit': PlanConfig.fromKey(
              directPlan == PlanConfig.business.key
                  ? PlanConfig.free.key
                  : directPlan,
            ).billsLimitFirestore,
            'limits.productsLimit': PlanConfig.fromKey(
              directPlan == PlanConfig.business.key
                  ? PlanConfig.free.key
                  : directPlan,
            ).productsLimitFirestore,
            'limits.customersLimit': PlanConfig.fromKey(
              directPlan == PlanConfig.business.key
                  ? PlanConfig.free.key
                  : directPlan,
            ).customersLimitFirestore,
            'limits.staffLimit': PlanConfig.fromKey(
              directPlan == PlanConfig.business.key
                  ? PlanConfig.free.key
                  : directPlan,
            ).staffLimitFirestore,
            'limits.tablesLimit': PlanConfig.fromKey(
              directPlan == PlanConfig.business.key
                  ? PlanConfig.free.key
                  : directPlan,
            ).tablesLimitFirestore,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('⚠️ _syncOwnerBusinessBundle error: $e');
    }
  }

  /// Set active/suspended status for an owned hotel — updates the user_hotels index (stream source).
  static Future<void> setHotelStatus(String hotelId, String status) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('user_hotels/$userId/hotels')
        .doc(hotelId)
        .update({'status': status});
  }

  /// Create a new hotel
  static Future<HotelInfo> createHotel({
    required String name,
    String? slug,
  }) async {
    final userId = _userId;
    if (userId == null) throw StateError('No authenticated user');
    final result = await CloudFunctionHelper.call('createRestaurant', {
      'name': name,
      if (slug != null && slug.isNotEmpty) 'slug': slug,
    });
    final hotelMap = result['hotel'] as Map<String, dynamic>?;
    if (hotelMap == null) {
      throw StateError('Failed to create restaurant');
    }

    final hotel = HotelInfo(
      id: (hotelMap['id'] as String?) ?? '',
      name: (hotelMap['name'] as String?) ?? name,
      slug: (hotelMap['slug'] as String?) ?? (slug ?? _generateSlug(name)),
      role: (hotelMap['role'] as String?) ?? 'owner',
      planKey: (hotelMap['planKey'] as String?) ?? PlanConfig.free.key,
      status: HotelStatus.fromString(
        (hotelMap['status'] as String?) ?? HotelStatus.active.name,
      ),
      createdAt: DateTime.now(),
    );
    debugPrint('Created new hotel via backend: ${hotel.name} (id=${hotel.id})');
    return hotel;
  }

  static Future<Set<String>> _inferBusinessHotelsFromOwnedStores(
    String ownerUid,
    List<HotelInfo> ownerHotels,
  ) async {
    final normalized = <String>[];

    for (final hotel in ownerHotels) {
      try {
        final storeDoc = await _firestore.collection('users').doc(hotel.id).get();
        final sub = storeDoc.data()?['subscription'] as Map<String, dynamic>?;
        final status = (sub?['effectiveStatus'] as String?)?.trim() ??
            (sub?['status'] as String?)?.trim() ??
            'active';
        final plan = (sub?['effectivePlan'] as String?)?.trim() ??
            (sub?['plan'] as String?)?.trim() ??
            'free';
        if (status != 'expired' && plan == PlanConfig.business.key) {
          normalized.add(hotel.id);
        }
      } catch (_) {}
      if (normalized.length >= 3) {
        return normalized.toSet();
      }
    }

    if (normalized.isEmpty) {
      return <String>{};
    }

    for (final hotel in ownerHotels) {
      if (normalized.contains(hotel.id)) continue;
      normalized.add(hotel.id);
      if (normalized.length >= 3) {
        break;
      }
    }
    return normalized.toSet();
  }

  /// Update hotel name
  static Future<void> updateHotelName(String hotelId, String name) async {
    await _hotelsRef.doc(hotelId).update({
      'name': name,
      'slug': _generateSlug(name),
    });
  }

  /// Ensure plan-driven limits on a store are not stale after opening it.
  static Future<void> syncPlanLimits(String hotelId) async {
    try {
      final doc = await _firestore.collection('users').doc(hotelId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final sub = data['subscription'] as Map<String, dynamic>? ?? {};
      final limits = data['limits'] as Map<String, dynamic>? ?? {};
        final plan =
          (sub['effectivePlan'] as String?) ?? (sub['plan'] as String?) ?? 'free';
      final tablesDefault = plan == 'business'
          ? 999999
          : plan == 'pro'
          ? 50
          : plan == 'starter'
          ? 15
          : 5;
      final staffDefault = plan == 'business'
          ? 999999
          : plan == 'pro'
          ? 10
          : plan == 'starter'
          ? 3
          : 0;
      final productsDefault = plan == 'business'
          ? 999999
          : plan == 'pro'
          ? 999999
          : plan == 'starter'
          ? 200
          : 50;
      final customersDefault = plan == 'business'
          ? 999999
          : plan == 'pro'
          ? 999999
          : plan == 'starter'
          ? 100
          : 10;

      final updates = <String, dynamic>{};
      if ((limits['tablesLimit'] as int? ?? 0) < tablesDefault) {
        updates['limits.tablesLimit'] = tablesDefault;
      }
      if ((limits['staffLimit'] as int? ?? 0) < staffDefault) {
        updates['limits.staffLimit'] = staffDefault;
      }
      if ((limits['productsLimit'] as int? ?? 0) < productsDefault) {
        updates['limits.productsLimit'] = productsDefault;
      }
      if ((limits['customersLimit'] as int? ?? 0) < customersDefault) {
        updates['limits.customersLimit'] = customersDefault;
      }

      if (updates.isEmpty) return;

      await _firestore.collection('users').doc(hotelId).update(updates);
      debugPrint('✅ Plan limits synced for $hotelId: $updates');
    } catch (e) {
      debugPrint('⚠️ HotelService.syncPlanLimits error: $e');
    }
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
