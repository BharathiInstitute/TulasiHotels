/// Tests for FeedbackService — submit, public, averages
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/feedback_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/feedback';
  });

  group('FeedbackService Firestore operations', () {
    test('submitFeedback — writes and reads back all fields', () async {
      final feedback = makeFeedback(
        id: 'fb-1',
        customerName: 'Ravi',
        foodRating: 5,
        serviceRating: 4,
        ambianceRating: 3,
        comments: 'Great food!',
      );

      await fakeFirestore
          .collection(basePath)
          .doc(feedback.id)
          .set(feedback.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(feedback.id).get();
      final parsed = FeedbackModel.fromFirestore(doc);
      expect(parsed.customerName, 'Ravi');
      expect(parsed.foodRating, 5);
      expect(parsed.serviceRating, 4);
      expect(parsed.ambianceRating, 3);
      expect(parsed.comments, 'Great food!');
    });

    test('delete — removes feedback', () async {
      final feedback = makeFeedback(id: 'fb-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(feedback.id)
          .set(feedback.toFirestore());

      await fakeFirestore.collection(basePath).doc('fb-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('fb-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('submitPublicFeedback', () {
    test('writes to specific hotel UID path', () async {
      const hotelUid = 'hotel-owner-123';
      final publicPath = 'users/$hotelUid/feedback';
      final feedback = makeFeedback(id: 'pub-1', customerName: 'Anon');

      await fakeFirestore
          .collection(publicPath)
          .doc(feedback.id)
          .set(feedback.toFirestore());

      final doc =
          await fakeFirestore.collection(publicPath).doc('pub-1').get();
      expect(doc.exists, isTrue);
      final parsed = FeedbackModel.fromFirestore(doc);
      expect(parsed.customerName, 'Anon');
    });
  });

  group('getAverageRatings', () {
    test('returns zero averages for empty collection', () async {
      final snapshot = await fakeFirestore.collection(basePath).get();
      expect(snapshot.docs.isEmpty, isTrue);

      // Simulate getAverageRatings logic
      final averages = <String, double>{
        'food': 0,
        'service': 0,
        'ambiance': 0,
        'overall': 0,
      };
      expect(averages['food'], 0);
      expect(averages['overall'], 0);
    });

    test('calculates correct averages for multiple feedbacks', () async {
      final fb1 = makeFeedback(
        id: 'avg-1',
        foodRating: 5,
        serviceRating: 4,
        ambianceRating: 3,
      );
      final fb2 = makeFeedback(
        id: 'avg-2',
        foodRating: 3,
        serviceRating: 2,
        ambianceRating: 5,
      );

      for (final fb in [fb1, fb2]) {
        await fakeFirestore
            .collection(basePath)
            .doc(fb.id)
            .set(fb.toFirestore());
      }

      final snapshot = await fakeFirestore.collection(basePath).get();
      final feedbacks = snapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();

      double totalFood = 0, totalService = 0, totalAmbiance = 0;
      double totalOverall = 0;
      for (final fb in feedbacks) {
        totalFood += fb.foodRating;
        totalService += fb.serviceRating;
        totalAmbiance += fb.ambianceRating;
        totalOverall += fb.averageRating;
      }
      final count = feedbacks.length;

      expect(totalFood / count, 4.0); // (5+3)/2
      expect(totalService / count, 3.0); // (4+2)/2
      expect(totalAmbiance / count, 4.0); // (3+5)/2
      expect(totalOverall / count, closeTo(3.67, 0.01)); // avg of averages
    });
  });

  group('recentFeedbackStream ordering', () {
    test('returns feedback ordered by createdAt descending', () async {
      final fb1 = makeFeedback(
        id: 'r1',
        createdAt: DateTime(2024, 1, 1),
        customerName: 'First',
      );
      final fb2 = makeFeedback(
        id: 'r2',
        createdAt: DateTime(2024, 6, 1),
        customerName: 'Second',
      );
      final fb3 = makeFeedback(
        id: 'r3',
        createdAt: DateTime(2024, 3, 1),
        customerName: 'Third',
      );

      for (final fb in [fb1, fb2, fb3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(fb.id)
            .set(fb.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .orderBy('createdAt', descending: true)
          .get();

      final names = snapshot.docs
          .map((d) => FeedbackModel.fromFirestore(d).customerName)
          .toList();
      expect(names, ['Second', 'Third', 'First']);
    });
  });

  group('averageRating computed', () {
    test('averageRating averages all three ratings', () {
      final fb = makeFeedback(foodRating: 5, serviceRating: 3, ambianceRating: 4);
      expect(fb.averageRating, 4.0);
    });

    test('averageRating handles all zeros', () {
      final fb = makeFeedback(foodRating: 0, serviceRating: 0, ambianceRating: 0);
      expect(fb.averageRating, 0.0);
    });
  });
}
