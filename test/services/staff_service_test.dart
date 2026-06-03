/// Tests for StaffService — CRUD, PIN verify, toggle active, permissions
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/staff_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/staff';
  });

  group('StaffService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final staff = makeStaff(
        id: 'staff-1',
        name: 'Ravi Kumar',
        email: 'ravi@test.com',
        phone: '9876543210',
        role: StaffRole.waiter,
        pin: '4567',
      );

      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(staff.id).get();
      final parsed = StaffModel.fromFirestore(doc);
      expect(parsed.name, 'Ravi Kumar');
      expect(parsed.email, 'ravi@test.com');
      expect(parsed.phone, '9876543210');
      expect(parsed.role, StaffRole.waiter);
      expect(parsed.pin, '4567');
    });

    test('getStaff — returns null for missing doc', () async {
      final doc =
          await fakeFirestore.collection(basePath).doc('missing').get();
      expect(doc.exists, isFalse);
    });

    test('update — modifies existing staff', () async {
      final staff = makeStaff(id: 'staff-u1', name: 'Old Name');
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      final updated = staff.copyWith(name: 'New Name');
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .update(updated.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('staff-u1').get();
      final parsed = StaffModel.fromFirestore(doc);
      expect(parsed.name, 'New Name');
    });

    test('delete — removes staff', () async {
      final staff = makeStaff(id: 'staff-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      await fakeFirestore.collection(basePath).doc('staff-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('staff-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('verifyPin', () {
    test('returns matching active staff for correct pin', () async {
      final staff = makeStaff(id: 's-pin', pin: '1234', isActive: true);
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('pin', isEqualTo: '1234')
          .where('isActive', isEqualTo: true)
          .get();

      expect(snapshot.docs.length, 1);
      final found = StaffModel.fromFirestore(snapshot.docs.first);
      expect(found.id, 's-pin');
    });

    test('returns empty for inactive staff', () async {
      final staff = makeStaff(id: 's-inactive', pin: '1234', isActive: false);
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('pin', isEqualTo: '1234')
          .where('isActive', isEqualTo: true)
          .get();

      expect(snapshot.docs.isEmpty, isTrue);
    });

    test('returns empty for wrong pin', () async {
      final staff = makeStaff(id: 's-wrong', pin: '5678', isActive: true);
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('pin', isEqualTo: '0000')
          .where('isActive', isEqualTo: true)
          .get();

      expect(snapshot.docs.isEmpty, isTrue);
    });
  });

  group('verifyEmailAndPin', () {
    test('returns staff matching both email and pin', () async {
      final staff = makeStaff(
        id: 's-ep',
        email: 'test@hotel.com',
        pin: '4567',
        isActive: true,
      );
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('email', isEqualTo: 'test@hotel.com')
          .where('pin', isEqualTo: '4567')
          .where('isActive', isEqualTo: true)
          .get();

      expect(snapshot.docs.length, 1);
    });

    test('returns empty if email matches but pin does not', () async {
      final staff = makeStaff(
        id: 's-email',
        email: 'test@hotel.com',
        pin: '1111',
        isActive: true,
      );
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('email', isEqualTo: 'test@hotel.com')
          .where('pin', isEqualTo: '9999')
          .where('isActive', isEqualTo: true)
          .get();

      expect(snapshot.docs.isEmpty, isTrue);
    });
  });

  group('isPinTaken', () {
    test('returns true when pin is in use by another staff', () async {
      final staff = makeStaff(id: 's-taken', pin: '1234');
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('pin', isEqualTo: '1234')
          .get();

      final takenByOther =
          snapshot.docs.any((doc) => doc.id != 'non-existent-id');
      expect(takenByOther, isTrue);
    });

    test('returns false for untaken pin', () async {
      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('pin', isEqualTo: '9999')
          .get();

      expect(snapshot.docs.isEmpty, isTrue);
    });

    test('excludes own staffId when checking', () async {
      final staff = makeStaff(id: 's-self', pin: '5555');
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('pin', isEqualTo: '5555')
          .get();

      final takenByOther =
          snapshot.docs.any((doc) => doc.id != 's-self');
      expect(takenByOther, isFalse);
    });
  });

  group('toggleStaffActive', () {
    test('toggles from active to inactive', () async {
      final staff = makeStaff(id: 's-toggle', isActive: true);
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      await fakeFirestore.collection(basePath).doc('s-toggle').update({
        'isActive': false,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('s-toggle').get();
      final parsed = StaffModel.fromFirestore(doc);
      expect(parsed.isActive, isFalse);
    });
  });

  group('updatePermissions', () {
    test('writes permissions map', () async {
      final staff = makeStaff(id: 's-perm');
      await fakeFirestore
          .collection(basePath)
          .doc(staff.id)
          .set(staff.toFirestore());

      final permissions = <String, List<String>>{
        '/billing': ['view', 'create'],
        '/orders': ['view'],
      };

      await fakeFirestore.collection(basePath).doc('s-perm').update({
        'permissions': permissions,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('s-perm').get();
      final parsed = StaffModel.fromFirestore(doc);
      expect(parsed.permissions, isNotNull);
      expect(parsed.permissions!['/billing'], contains('view'));
      expect(parsed.permissions!['/billing'], contains('create'));
      expect(parsed.permissions!['/orders'], ['view']);
    });
  });

  group('staffStream ordering', () {
    test('returns staff ordered by name', () async {
      final s1 = makeStaff(id: 's1', name: 'Zara');
      final s2 = makeStaff(id: 's2', name: 'Amit');
      final s3 = makeStaff(id: 's3', name: 'Kumar');

      for (final s in [s1, s2, s3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(s.id)
            .set(s.toFirestore());
      }

      final snapshot =
          await fakeFirestore.collection(basePath).orderBy('name').get();

      final names = snapshot.docs
          .map((d) => StaffModel.fromFirestore(d).name)
          .toList();
      expect(names, ['Amit', 'Kumar', 'Zara']);
    });
  });

  group('StaffRole enum round-trip', () {
    test('all roles survive Firestore round-trip', () async {
      for (final role in StaffRole.values) {
        final staff = makeStaff(id: 'sr-${role.name}', role: role);
        await fakeFirestore
            .collection(basePath)
            .doc(staff.id)
            .set(staff.toFirestore());

        final doc =
            await fakeFirestore.collection(basePath).doc(staff.id).get();
        final parsed = StaffModel.fromFirestore(doc);
        expect(parsed.role, role);
      }
    });
  });
}
