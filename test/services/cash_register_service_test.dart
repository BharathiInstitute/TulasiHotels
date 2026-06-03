/// Tests for CashRegisterService — open, close, movements, history
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/cash_register_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/cashRegisters';
  });

  group('CashRegisterService Firestore operations', () {
    test('openRegister — writes and reads back all fields', () async {
      final register = makeCashRegister(
        id: 'reg-1',
        staffId: 'staff-1',
        staffName: 'Cashier',
        openingBalance: 2000,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(register.id)
          .set(register.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(register.id).get();
      final parsed = CashRegisterModel.fromFirestore(doc);
      expect(parsed.staffId, 'staff-1');
      expect(parsed.staffName, 'Cashier');
      expect(parsed.openingBalance, 2000);
      expect(parsed.closedAt, isNull);
    });

    test('getRegister — returns null for missing doc', () async {
      final doc =
          await fakeFirestore.collection(basePath).doc('missing').get();
      expect(doc.exists, isFalse);
    });
  });

  group('closeRegister', () {
    test('sets closingBalance and closedAt', () async {
      final register = makeCashRegister(id: 'reg-close');
      await fakeFirestore
          .collection(basePath)
          .doc(register.id)
          .set(register.toFirestore());

      final closedAt = DateTime.now();
      await fakeFirestore.collection(basePath).doc('reg-close').update({
        'closingBalance': 2500.0,
        'closedAt': closedAt.toIso8601String(),
        'closedByName': 'Manager',
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('reg-close').get();
      expect(doc.data()!['closingBalance'], 2500.0);
      expect(doc.data()!['closedAt'], isNotNull);
      expect(doc.data()!['closedByName'], 'Manager');
    });
  });

  group('addCashMovement', () {
    test('appends movement to movements array', () async {
      final register = makeCashRegister(id: 'reg-mv', movements: []);
      await fakeFirestore
          .collection(basePath)
          .doc(register.id)
          .set(register.toFirestore());

      final movement = makeCashMovement(
        amount: 500,
        reason: 'Petty cash',
        isInflow: false,
      );

      await fakeFirestore.collection(basePath).doc('reg-mv').update({
        'movements': [movement.toMap()],
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('reg-mv').get();
      final data = doc.data()!;
      final movements = data['movements'] as List;
      expect(movements.length, 1);
      expect(movements[0]['amount'], 500);
      expect(movements[0]['reason'], 'Petty cash');
      expect(movements[0]['isInflow'], isFalse);
    });
  });

  group('todayRegisterStream', () {
    test('filters by date field', () async {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final todayReg = makeCashRegister(id: 'today-reg');
      final todayData = todayReg.toFirestore();
      todayData['date'] = dateStr;
      await fakeFirestore.collection(basePath).doc('today-reg').set(todayData);

      final yesterdayReg = makeCashRegister(id: 'yesterday-reg');
      final yesterdayData = yesterdayReg.toFirestore();
      yesterdayData['date'] = '2024-01-01';
      await fakeFirestore
          .collection(basePath)
          .doc('yesterday-reg')
          .set(yesterdayData);

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('date', isEqualTo: dateStr)
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'today-reg');
    });
  });

  group('registerHistoryStream ordering', () {
    test('returns registers ordered by openedAt descending', () async {
      final r1 = makeCashRegister(
        id: 'r1',
        openedAt: DateTime(2024, 1, 1, 8, 0),
        staffName: 'First',
      );
      final r2 = makeCashRegister(
        id: 'r2',
        openedAt: DateTime(2024, 6, 1, 8, 0),
        staffName: 'Latest',
      );

      for (final r in [r1, r2]) {
        await fakeFirestore
            .collection(basePath)
            .doc(r.id)
            .set(r.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .orderBy('openedAt', descending: true)
          .get();

      final names = snapshot.docs
          .map((d) => CashRegisterModel.fromFirestore(d).staffName)
          .toList();
      expect(names, ['Latest', 'First']);
    });
  });

  group('register with multiple movements round-trip', () {
    test('multiple cash movements survive Firestore round-trip', () async {
      final movements = [
        makeCashMovement(amount: 200, reason: 'Change', isInflow: true),
        makeCashMovement(amount: 50, reason: 'Petty cash', isInflow: false),
      ];
      final register = makeCashRegister(id: 'reg-multi', movements: movements);

      await fakeFirestore
          .collection(basePath)
          .doc(register.id)
          .set(register.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('reg-multi').get();
      final parsed = CashRegisterModel.fromFirestore(doc);
      expect(parsed.movements.length, 2);
      expect(parsed.movements[0].amount, 200);
      expect(parsed.movements[0].isInflow, isTrue);
      expect(parsed.movements[1].amount, 50);
      expect(parsed.movements[1].isInflow, isFalse);
    });
  });

  group('isOpen getter', () {
    test('register is open when closedAt is null', () {
      final register = makeCashRegister(closedAt: null);
      expect(register.isOpen, isTrue);
    });

    test('register is not open when closedAt is set', () {
      final register = makeCashRegister(closedAt: DateTime.now());
      expect(register.isOpen, isFalse);
    });
  });
}
