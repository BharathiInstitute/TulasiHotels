/// Customer feedback management service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/feedback_model.dart';

class FeedbackService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _feedbackRef =>
      _firestore.collection('$_basePath/feedback');

  /// Stream recent feedback
  static Stream<List<FeedbackModel>> recentFeedbackStream() {
    return _feedbackRef
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedbackModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Submit feedback (from customer-facing web or tablet)
  static Future<void> submitFeedback(FeedbackModel feedback) async {
    await _feedbackRef.doc(feedback.id).set(feedback.toFirestore());
  }

  /// Submit feedback for a specific hotel (public â€” no auth needed)
  static Future<void> submitPublicFeedback(
      String hotelUid, FeedbackModel feedback) async {
    await _firestore
        .collection('users/$hotelUid/feedback')
        .doc(feedback.id)
        .set(feedback.toFirestore());
  }

  /// Get average ratings
  static Future<Map<String, double>> getAverageRatings() async {
    final snapshot = await _feedbackRef.get();
    if (snapshot.docs.isEmpty) {
      return {'food': 0, 'service': 0, 'ambiance': 0, 'overall': 0};
    }

    double totalFood = 0, totalService = 0, totalAmbiance = 0, totalOverall = 0;
    for (final doc in snapshot.docs) {
      final fb = FeedbackModel.fromFirestore(doc);
      totalFood += fb.foodRating;
      totalService += fb.serviceRating;
      totalAmbiance += fb.ambianceRating;
      totalOverall += fb.averageRating;
    }
    final count = snapshot.docs.length;
    return {
      'food': totalFood / count,
      'service': totalService / count,
      'ambiance': totalAmbiance / count,
      'overall': totalOverall / count,
    };
  }

  /// Delete feedback
  static Future<void> deleteFeedback(String feedbackId) async {
    await _feedbackRef.doc(feedbackId).delete();
  }
}
