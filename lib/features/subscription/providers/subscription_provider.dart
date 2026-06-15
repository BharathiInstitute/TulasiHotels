/// Riverpod provider that streams the current user's subscription plan
/// from Firestore in real-time.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Real-time subscription plan stream: "free", "pro", or "business"
final subscriptionPlanProvider = StreamProvider<String>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value('free');

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
        final sub = doc.data()?['subscription'] as Map<String, dynamic>?;
        return (sub?['plan'] as String?) ?? 'free';
      });
});
