import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/staff_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('StaffRole enum', () {
    test('fromString parses all values', () {
      for (final r in StaffRole.values) {
        expect(StaffRole.fromString(r.name), r);
      }
    });

    test('fromString defaults to waiter', () {
      expect(StaffRole.fromString('xyz'), StaffRole.waiter);
    });
  });

  group('StaffModel', () {
    test('constructor defaults', () {
      final m = makeStaff();
      expect(m.role, StaffRole.waiter);
      expect(m.isActive, true);
      expect(m.permissions, isNull);
    });

    test('copyWith updates name, role and pin', () {
      final m = makeStaff();
      final updated = m.copyWith(
        name: 'Ravi',
        role: StaffRole.chef,
        pin: '5678',
      );
      expect(updated.name, 'Ravi');
      expect(updated.role, StaffRole.chef);
      expect(updated.pin, '5678');
      expect(updated.id, m.id);
    });

    test('copyWith updates permissions', () {
      final m = makeStaff();
      final perms = {
        '/billing': ['view', 'create'],
      };
      final updated = m.copyWith(permissions: perms);
      expect(updated.permissions, perms);
    });

    test('copyWith sets updatedAt to now', () {
      final m = makeStaff();
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final updated = m.copyWith(isActive: false);
      expect(updated.isActive, false);
      expect(updated.updatedAt, isNotNull);
      expect(updated.updatedAt!.isAfter(before), isTrue);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeStaff(email: 'ravi@test.com', phone: '9999999999');
      final updated = m.copyWith();
      expect(updated.email, 'ravi@test.com');
      expect(updated.phone, '9999999999');
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeStaff(
          email: 'staff@test.com',
          phone: '9876543210',
          role: StaffRole.manager,
          permissions: {
            '/billing': ['view', 'create', 'delete'],
          },
        );
        final map = m.toFirestore();
        expect(map['name'], 'Test Staff');
        expect(map['role'], 'manager');
        expect(map['pin'], '1234');
        expect(map['isActive'], true);
        expect(map['permissions'], isA<Map<String, dynamic>>());
      });

      test('toFirestore omits permissions when null', () {
        final m = makeStaff();
        final map = m.toFirestore();
        expect(map.containsKey('permissions'), isFalse);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeStaff(
          name: 'Ravi',
          email: 'ravi@hotel.com',
          phone: '9999999999',
          role: StaffRole.chef,
          pin: '5678',
          permissions: {
            '/orders': ['view'],
            '/billing': ['view', 'create'],
          },
        );
        await firestore
            .collection('staff')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore.collection('staff').doc(original.id).get();
        final restored = StaffModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.name, 'Ravi');
        expect(restored.email, 'ravi@hotel.com');
        expect(restored.role, StaffRole.chef);
        expect(restored.pin, '5678');
        expect(restored.permissions, isNotNull);
        expect(restored.permissions!['/orders'], ['view']);
        expect(restored.permissions!['/billing'], ['view', 'create']);
      });

      test('fromFirestore handles missing permissions', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeStaff();
        await firestore
            .collection('staff')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore.collection('staff').doc(original.id).get();
        final restored = StaffModel.fromFirestore(doc);
        expect(restored.permissions, isNull);
      });
    });
  });
}
