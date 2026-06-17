import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/complaint_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('ComplaintStatus enum', () {
    test('displayName and emoji', () {
      expect(ComplaintStatus.open.displayName, 'Open');
      expect(ComplaintStatus.open.emoji, '🔴');
      expect(ComplaintStatus.resolved.displayName, 'Resolved');
    });

    test('fromString parses valid values', () {
      for (final s in ComplaintStatus.values) {
        expect(ComplaintStatus.fromString(s.name), s);
      }
    });

    test('fromString defaults to open for unknown', () {
      expect(ComplaintStatus.fromString('xyz'), ComplaintStatus.open);
    });
  });

  group('ComplaintCategory enum', () {
    test('displayName and emoji', () {
      expect(ComplaintCategory.food.displayName, 'Food');
      expect(ComplaintCategory.billing.emoji, '💰');
    });

    test('fromString parses valid values', () {
      for (final c in ComplaintCategory.values) {
        expect(ComplaintCategory.fromString(c.name), c);
      }
    });

    test('fromString defaults to other for unknown', () {
      expect(ComplaintCategory.fromString('xyz'), ComplaintCategory.other);
    });
  });

  group('ComplaintModel', () {
    test('constructor defaults', () {
      final m = makeComplaint();
      expect(m.status, ComplaintStatus.open);
      expect(m.category, ComplaintCategory.other);
      expect(m.resolvedAt, isNull);
    });

    test('resolutionTime returns null when unresolved', () {
      expect(makeComplaint().resolutionTime, isNull);
    });

    test('resolutionTime calculates correctly when resolved', () {
      final m = makeComplaint(
        createdAt: DateTime(2024, 1, 15, 10),
        resolvedAt: DateTime(2024, 1, 15, 12, 30),
      );
      expect(m.resolutionTime, const Duration(hours: 2, minutes: 30));
    });

    test('copyWith updates status and resolution', () {
      final m = makeComplaint();
      final updated = m.copyWith(
        status: ComplaintStatus.resolved,
        resolution: 'Fixed',
        resolvedAt: DateTime(2024, 1, 15, 14),
      );
      expect(updated.status, ComplaintStatus.resolved);
      expect(updated.resolution, 'Fixed');
      expect(updated.resolvedAt, isNotNull);
      expect(updated.id, m.id);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeComplaint(
        category: ComplaintCategory.food,
        assignedTo: 'staff-1',
      );
      final updated = m.copyWith();
      expect(updated.category, ComplaintCategory.food);
      expect(updated.assignedTo, 'staff-1');
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeComplaint(
          orderId: 'order-1',
          customerName: 'Ravi',
          category: ComplaintCategory.service,
          resolvedAt: DateTime(2024, 1, 16),
        );
        final map = m.toFirestore();
        expect(map['orderId'], 'order-1');
        expect(map['customerName'], 'Ravi');
        expect(map['category'], 'service');
        expect(map['status'], 'open');
        expect(map['resolvedAt'], isA<Timestamp>());
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeComplaint(
          orderId: 'order-1',
          customerName: 'Ravi',
          category: ComplaintCategory.hygiene,
          status: ComplaintStatus.investigating,
          assignedTo: 'staff-2',
        );
        await firestore
            .collection('complaints')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('complaints')
            .doc(original.id)
            .get();
        final restored = ComplaintModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.orderId, 'order-1');
        expect(restored.customerName, 'Ravi');
        expect(restored.category, ComplaintCategory.hygiene);
        expect(restored.status, ComplaintStatus.investigating);
        expect(restored.assignedTo, 'staff-2');
        expect(restored.resolvedAt, isNull);
      });
    });
  });
}
