/// Store member service — Firestore CRUD for multi-user store access
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/firebase_options.dart';

class MemberService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// The store ID — uses active hotel, falls back to current user UID
  static String? get _storeId => ActiveStoreManager.storeId;

  static CollectionReference<Map<String, dynamic>> get _membersRef {
    final storeId = _storeId;
    if (storeId == null) {
      throw StateError('No authenticated user');
    }
    return _firestore.collection('users/$storeId/members');
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Stream all members (real-time)
  static Stream<List<StoreMember>> membersStream() {
    return _membersRef
        .orderBy('displayName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoreMember.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream only active members
  static Stream<List<StoreMember>> activeMembersStream() {
    return _membersRef
        .where('status', isEqualTo: MemberStatus.active.name)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => StoreMember.fromFirestore(doc))
                  .toList()
                ..sort((a, b) => a.displayName.compareTo(b.displayName)),
        );
  }

  /// Get a single member
  static Future<StoreMember?> getMember(String uid) async {
    final doc = await _membersRef.doc(uid).get();
    if (!doc.exists) return null;
    return StoreMember.fromFirestore(doc);
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Invite a new member by email.
  /// If [password] is provided, creates a real Firebase Auth account using a
  /// secondary app instance (so the owner stays signed in).
  /// Also writes a user_hotels entry so the member sees this hotel on login.
  static Future<StoreMember> inviteMember({
    required String email,
    required String displayName,
    StoreRole role = StoreRole.custom,
    String? customRoleName,
    Map<String, List<String>>? permissions,
    String? password,
  }) async {
    final ownerId = _auth.currentUser?.uid ?? '';
    if (ownerId.isEmpty) throw StateError('No authenticated user');

    String memberUid;

    if (password != null && password.isNotEmpty) {
      // Create Firebase Auth account without signing out the owner.
      // We use a secondary Firebase App instance for this.
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = await Firebase.initializeApp(
          name: 'secondaryApp_${email.hashCode.abs()}',
          options: DefaultFirebaseOptions.currentPlatform,
        );
        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        try {
          final credential = await secondaryAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          memberUid = credential.user!.uid;
          await credential.user!.updateDisplayName(displayName);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // User already exists — add as invited member with placeholder UID.
            // Their real UID will be resolved when they log in.
            memberUid = 'existing_${email.hashCode.abs()}';
          } else {
            rethrow;
          }
        }
      } finally {
        await secondaryApp?.delete();
      }
    } else {
      // No password — use placeholder UID; member must self-register later
      memberUid = 'invite_${email.hashCode.abs()}';
    }

    // Write member doc under owner's store
    final isNewAccount =
        !memberUid.startsWith('invite_') && !memberUid.startsWith('existing_');
    final member = StoreMember(
      uid: memberUid,
      email: email,
      displayName: displayName,
      role: role,
      customRoleName: customRoleName,
      status: isNewAccount ? MemberStatus.active : MemberStatus.invited,
      permissions: permissions,
      joinedAt: DateTime.now(),
      invitedBy: ownerId,
    );
    await _membersRef.doc(memberUid).set(member.toFirestore());

    // The store this member is being added to (may differ from ownerId for
    // multi-hotel setups where admin manages more than one hotel)
    final storeId = _storeId ?? ownerId;

    // Write user_hotels entry so member can see this specific hotel in their selector
    if (isNewAccount) {
      final hotelDoc = _firestore
          .collection('user_hotels/$memberUid/hotels')
          .doc(storeId); // ← use storeId, not ownerId
      // Read the hotel name from the store doc (storeId may != ownerId)
      final storeDoc = await _firestore.collection('users').doc(storeId).get();
      final shopName = (storeDoc.data()?['shopName'] as String?) ?? 'Hotel';
      await hotelDoc.set({
        'id': storeId, // ← use storeId
        'name': shopName,
        'slug': shopName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
        'role': role.name,
        'customRoleName': ?customRoleName,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // For existing/invited users, write a pending invite so it can be
      // resolved when the user actually logs in
      final storeDoc = await _firestore.collection('users').doc(storeId).get();
      final shopName = (storeDoc.data()?['shopName'] as String?) ?? 'Hotel';
      await _firestore.collection('pending_member_invites').doc().set({
        'email': email,
        'ownerId': ownerId,
        'storeId':
            storeId, // ← add storeId so invite resolution uses correct hotel
        'shopName': shopName,
        'role': role.name,
        'customRoleName': ?customRoleName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('Created member: $displayName ($email) as ${role.displayName}');
    return member;
  }

  /// Register the owner as the first member of the store
  static Future<void> ensureOwnerMember() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _membersRef.doc(user.uid).get();
    if (doc.exists) return; // Already registered

    final owner = StoreMember(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Owner',
      role: StoreRole.owner,
      joinedAt: DateTime.now(),
    );
    await _membersRef.doc(user.uid).set(owner.toFirestore());
    debugPrint('Registered owner member: ${owner.displayName}');
  }

  /// Update a member's role (and optionally permissions)
  static Future<void> updateRole(
    String uid,
    StoreRole role, {
    Map<String, List<String>>? permissions,
  }) async {
    await _membersRef.doc(uid).update({
      'role': role.name,
      'permissions': ?permissions,
    });
  }

  /// Update only permissions for a member
  static Future<void> updatePermissions(
    String uid,
    Map<String, List<String>> permissions,
  ) async {
    await _membersRef.doc(uid).update({'permissions': permissions});
  }

  /// Update member profile fields
  static Future<void> updateMember(StoreMember member) async {
    await _membersRef.doc(member.uid).update(member.toFirestore());
  }

  /// Disable a member (revoke access without deleting)
  static Future<void> disableMember(String uid) async {
    await _membersRef.doc(uid).update({'status': MemberStatus.disabled.name});
  }

  /// Re-enable a disabled member
  static Future<void> enableMember(String uid) async {
    await _membersRef.doc(uid).update({'status': MemberStatus.active.name});
  }

  /// Remove a member entirely
  static Future<void> removeMember(String uid) async {
    await _membersRef.doc(uid).delete();
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Check if a member exists by email
  static Future<StoreMember?> findByEmail(String email) async {
    final snapshot = await _membersRef
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return StoreMember.fromFirestore(snapshot.docs.first);
  }

  /// Count members by role
  static Future<int> countByRole(StoreRole role) async {
    final snapshot = await _membersRef
        .where('role', isEqualTo: role.name)
        .get();
    return snapshot.docs.length;
  }
}
