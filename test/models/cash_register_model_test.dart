import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/cash_register_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('CashMovement', () {
    test('toMap serialises all fields', () {
      final m = makeCashMovement();
      final map = m.toMap();
      expect(map['amount'], 100.0);
      expect(map['reason'], 'Test movement');
      expect(map['isInflow'], true);
      expect(map['timestamp'], isA<Timestamp>());
    });

    test('fromMap deserialises correctly', () {
      final map = {
        'amount': 200.0,
        'reason': 'Payout',
        'isInflow': false,
        'timestamp': Timestamp.fromDate(DateTime(2024, 3, 1)),
      };
      final m = CashMovement.fromMap(map);
      expect(m.amount, 200.0);
      expect(m.reason, 'Payout');
      expect(m.isInflow, false);
    });

    test('fromMap handles missing fields with defaults', () {
      final m = CashMovement.fromMap({});
      expect(m.amount, 0);
      expect(m.reason, '');
      expect(m.isInflow, true);
    });
  });

  group('CashRegisterModel', () {
    test('constructor defaults', () {
      final m = makeCashRegister();
      expect(m.closingBalance, 0);
      expect(m.expectedBalance, 0);
      expect(m.variance, 0);
      expect(m.movements, isEmpty);
    });

    test('isOpen returns true when closedAt is null', () {
      final m = makeCashRegister();
      expect(m.isOpen, isTrue);
    });

    test('isOpen returns false when closedAt is set', () {
      final m = makeCashRegister(closedAt: DateTime(2024, 1, 15, 22, 0));
      expect(m.isOpen, isFalse);
    });

    test('copyWith updates closingBalance and movements', () {
      final m = makeCashRegister();
      final movement = makeCashMovement(amount: 50);
      final updated = m.copyWith(closingBalance: 1200, movements: [movement]);
      expect(updated.closingBalance, 1200);
      expect(updated.movements.length, 1);
      expect(updated.openingBalance, m.openingBalance);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeCashRegister(closingBalance: 900, variance: 50);
      final updated = m.copyWith();
      expect(updated.closingBalance, 900);
      expect(updated.variance, 50);
    });

    group('Firestore round-trip', () {
      test('toFirestore serialises movements', () {
        final m = makeCashRegister(
          movements: [makeCashMovement()],
          closedAt: DateTime(2024, 1, 15, 22, 0),
        );
        final map = m.toFirestore();
        expect(map['staffId'], 'staff-1');
        expect(map['openingBalance'], 1000.0);
        expect(map['movements'], isList);
        expect((map['movements'] as List).length, 1);
        expect(map['closedAt'], isA<Timestamp>());
      });

      test('toFirestore sets closedAt null when open', () {
        final m = makeCashRegister();
        expect(m.toFirestore()['closedAt'], isNull);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeCashRegister(
          movements: [makeCashMovement(amount: 300, reason: 'Sale')],
          closedAt: DateTime(2024, 1, 15, 22, 0),
          closingBalance: 1300,
          expectedBalance: 1300,
          variance: 0,
        );
        await firestore
            .collection('registers')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('registers')
            .doc(original.id)
            .get();
        final restored = CashRegisterModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.staffId, original.staffId);
        expect(restored.openingBalance, original.openingBalance);
        expect(restored.closingBalance, original.closingBalance);
        expect(restored.movements.length, 1);
        expect(restored.movements.first.amount, 300);
        expect(restored.isOpen, isFalse);
      });
    });
  });
}
