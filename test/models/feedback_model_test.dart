import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/feedback_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('FeedbackModel', () {
    test('constructor defaults', () {
      final m = makeFeedback();
      expect(m.foodRating, 4);
      expect(m.serviceRating, 4);
      expect(m.ambianceRating, 4);
      expect(m.orderId, isNull);
    });

    test('averageRating calculates correctly', () {
      final m = makeFeedback(
        foodRating: 5,
        serviceRating: 4,
        ambianceRating: 3,
      );
      expect(m.averageRating, 4.0);
    });

    test('averageRating with equal ratings', () {
      final m = makeFeedback(
        foodRating: 3,
        serviceRating: 3,
        ambianceRating: 3,
      );
      expect(m.averageRating, 3.0);
    });

    test('averageRating with all zeros', () {
      final m = makeFeedback(
        foodRating: 0,
        serviceRating: 0,
        ambianceRating: 0,
      );
      expect(m.averageRating, 0.0);
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeFeedback(
          orderId: 'order-1',
          customerName: 'Ravi',
          comments: 'Great food!',
        );
        final map = m.toFirestore();
        expect(map['orderId'], 'order-1');
        expect(map['customerName'], 'Ravi');
        expect(map['foodRating'], 4);
        expect(map['comments'], 'Great food!');
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeFeedback(
          orderId: 'order-1',
          billId: 'bill-1',
          customerName: 'Ravi',
          customerPhone: '9876543210',
          foodRating: 5,
          serviceRating: 3,
          ambianceRating: 4,
          comments: 'Nice ambiance',
        );
        await firestore
            .collection('feedback')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('feedback')
            .doc(original.id)
            .get();
        final restored = FeedbackModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.orderId, 'order-1');
        expect(restored.billId, 'bill-1');
        expect(restored.customerName, 'Ravi');
        expect(restored.foodRating, 5);
        expect(restored.serviceRating, 3);
        expect(restored.ambianceRating, 4);
        expect(restored.comments, 'Nice ambiance');
      });
    });
  });
}
