import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/attendance_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('AttendanceStatus enum', () {
    test('displayName returns correct text', () {
      expect(AttendanceStatus.clockedIn.displayName, 'Clocked In');
      expect(AttendanceStatus.clockedOut.displayName, 'Clocked Out');
      expect(AttendanceStatus.absent.displayName, 'Absent');
    });

    test('fromString parses valid values', () {
      expect(
        AttendanceStatus.fromString('clockedIn'),
        AttendanceStatus.clockedIn,
      );
      expect(
        AttendanceStatus.fromString('clockedOut'),
        AttendanceStatus.clockedOut,
      );
      expect(AttendanceStatus.fromString('absent'), AttendanceStatus.absent);
    });

    test('fromString defaults to absent for unknown', () {
      expect(AttendanceStatus.fromString('invalid'), AttendanceStatus.absent);
    });
  });

  group('AttendanceModel', () {
    test('constructor sets defaults', () {
      final m = makeAttendance();
      expect(m.id, 'att-1');
      expect(m.status, AttendanceStatus.clockedIn);
      expect(m.clockOut, isNull);
    });

    test('hoursWorked returns 0 when still clocked in', () {
      final m = makeAttendance();
      expect(m.hoursWorked, 0);
    });

    test('hoursWorked calculates correctly when clocked out', () {
      final m = makeAttendance(
        clockIn: DateTime(2024, 1, 15, 9),
        clockOut: DateTime(2024, 1, 15, 17, 30),
      );
      expect(m.hoursWorked, 8.5);
    });

    test('hoursWorked for partial hour', () {
      final m = makeAttendance(
        clockIn: DateTime(2024, 1, 15, 9),
        clockOut: DateTime(2024, 1, 15, 9, 45),
      );
      expect(m.hoursWorked, 0.75);
    });

    test('copyWith updates clockOut and status', () {
      final m = makeAttendance();
      final out = DateTime(2024, 1, 15, 18);
      final updated = m.copyWith(
        clockOut: out,
        status: AttendanceStatus.clockedOut,
      );
      expect(updated.clockOut, out);
      expect(updated.status, AttendanceStatus.clockedOut);
      expect(updated.id, m.id);
      expect(updated.staffId, m.staffId);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeAttendance(clockOut: DateTime(2024, 1, 15, 17));
      final updated = m.copyWith();
      expect(updated.clockOut, m.clockOut);
      expect(updated.status, m.status);
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeAttendance(
          clockOut: DateTime(2024, 1, 15, 17),
          status: AttendanceStatus.clockedOut,
        );
        final map = m.toFirestore();
        expect(map['staffId'], 'staff-1');
        expect(map['staffName'], 'Test Staff');
        expect(map['status'], 'clockedOut');
        expect(map['clockIn'], isA<Timestamp>());
        expect(map['clockOut'], isA<Timestamp>());
      });

      test('toFirestore sets clockOut null when absent', () {
        final m = makeAttendance();
        expect(m.toFirestore()['clockOut'], isNull);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeAttendance(
          clockOut: DateTime(2024, 1, 15, 17),
          status: AttendanceStatus.clockedOut,
        );
        await firestore
            .collection('attendance')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('attendance')
            .doc(original.id)
            .get();
        final restored = AttendanceModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.staffId, original.staffId);
        expect(restored.staffName, original.staffName);
        expect(restored.status, original.status);
        expect(restored.clockIn, original.clockIn);
        expect(restored.clockOut, original.clockOut);
      });
    });
  });
}
