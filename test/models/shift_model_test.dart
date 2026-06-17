import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/shift_model.dart';
import 'package:tulasihotels/models/staff_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('ShiftType enum', () {
    test('fromString parses all values', () {
      for (final t in ShiftType.values) {
        expect(ShiftType.fromString(t.name), t);
      }
    });

    test('fromString defaults to custom', () {
      expect(ShiftType.fromString('xyz'), ShiftType.custom);
    });
  });

  group('ShiftModel', () {
    test('constructor defaults', () {
      final m = makeShift();
      expect(m.shiftType, ShiftType.morning);
      expect(m.role, StaffRole.waiter);
      expect(m.isSwapRequested, false);
      expect(m.swapWithStaffId, isNull);
    });

    test('duration calculates correctly', () {
      final m = makeShift(
        startTime: DateTime(2024, 1, 15, 6),
        endTime: DateTime(2024, 1, 15, 14),
      );
      expect(m.duration, const Duration(hours: 8));
    });

    test('duration for partial shift', () {
      final m = makeShift(
        startTime: DateTime(2024, 1, 15, 9),
        endTime: DateTime(2024, 1, 15, 13, 30),
      );
      expect(m.duration, const Duration(hours: 4, minutes: 30));
    });

    test('copyWith updates shiftType and notes', () {
      final m = makeShift();
      final updated = m.copyWith(
        shiftType: ShiftType.night,
        notes: 'Cover shift',
      );
      expect(updated.shiftType, ShiftType.night);
      expect(updated.notes, 'Cover shift');
      expect(updated.id, m.id);
    });

    test('copyWith updates swap fields', () {
      final m = makeShift();
      final updated = m.copyWith(
        isSwapRequested: true,
        swapWithStaffId: 'staff-2',
      );
      expect(updated.isSwapRequested, true);
      expect(updated.swapWithStaffId, 'staff-2');
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeShift(role: StaffRole.chef, notes: 'Kitchen duty');
      final updated = m.copyWith();
      expect(updated.role, StaffRole.chef);
      expect(updated.notes, 'Kitchen duty');
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeShift(
          role: StaffRole.chef,
          shiftType: ShiftType.evening,
          notes: 'Special event',
          isSwapRequested: true,
          swapWithStaffId: 'staff-2',
        );
        final map = m.toFirestore();
        expect(map['staffId'], 'staff-1');
        expect(map['role'], 'chef');
        expect(map['shiftType'], 'evening');
        expect(map['notes'], 'Special event');
        expect(map['isSwapRequested'], true);
        expect(map['swapWithStaffId'], 'staff-2');
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeShift(
          staffName: 'Ravi',
          role: StaffRole.chef,
          notes: 'Prep shift',
        );
        await firestore
            .collection('shifts')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore.collection('shifts').doc(original.id).get();
        final restored = ShiftModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.staffName, 'Ravi');
        expect(restored.role, StaffRole.chef);
        expect(restored.shiftType, ShiftType.morning);
        expect(restored.notes, 'Prep shift');
      });
    });
  });
}
