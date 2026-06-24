/// Complaint management service
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/models/complaint_model.dart';

class ComplaintService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  static CollectionReference<Map<String, dynamic>> get _complaintsRef =>
      _firestore.collection('$_basePath/complaints');

  /// Stream active complaints
  static Stream<List<ComplaintModel>> activeComplaintsStream() {
    return _complaintsRef
        .where('status', whereIn: ['open', 'investigating'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ComplaintModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream all complaints
  static Stream<List<ComplaintModel>> allComplaintsStream() {
    return _complaintsRef
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ComplaintModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Create a complaint
  static Future<void> createComplaint(ComplaintModel complaint) async {
    await _complaintsRef
        .doc(complaint.id)
        .set(complaint.toFirestore());
  }

  /// Update complaint status
  static Future<void> updateStatus(
      String complaintId, ComplaintStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == ComplaintStatus.resolved) {
      updates['resolvedAt'] = FieldValue.serverTimestamp();
    }
    await _complaintsRef.doc(complaintId).update(updates);
  }

  /// Update a complaint
  static Future<void> updateComplaint(ComplaintModel complaint) async {
    await _complaintsRef
        .doc(complaint.id)
        .update(complaint.toFirestore());
  }

  /// Delete a complaint
  static Future<void> deleteComplaint(String complaintId) async {
    await _complaintsRef.doc(complaintId).delete();
  }
}
