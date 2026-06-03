import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/table_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('TableStatus enum', () {
    test('fromString parses all values', () {
      for (final s in TableStatus.values) {
        expect(TableStatus.fromString(s.name), s);
      }
    });

    test('fromString defaults to available', () {
      expect(TableStatus.fromString('xyz'), TableStatus.available);
    });
  });

  group('TableModel', () {
    test('constructor defaults', () {
      final m = makeTable();
      expect(m.status, TableStatus.available);
      expect(m.capacity, 4);
      expect(m.floor, 0);
      expect(m.currentOrderId, isNull);
    });

    test('displayName returns label when set', () {
      final m = makeTable(label: 'VIP 1');
      expect(m.displayName, 'VIP 1');
    });

    test('displayName returns Table N when no label', () {
      final m = makeTable(number: 5);
      expect(m.displayName, 'Table 5');
    });

    test('isFree true when available', () {
      expect(makeTable().isFree, isTrue);
    });

    test('isFree false when occupied', () {
      expect(makeTable(status: TableStatus.occupied).isFree, isFalse);
    });

    test('isFree false when reserved', () {
      expect(makeTable(status: TableStatus.reserved).isFree, isFalse);
    });

    test('hasActiveOrder true when orderId set', () {
      expect(makeTable(currentOrderId: 'order-1').hasActiveOrder, isTrue);
    });

    test('hasActiveOrder false when orderId null', () {
      expect(makeTable().hasActiveOrder, isFalse);
    });

    test('copyWith updates status and capacity', () {
      final m = makeTable();
      final updated = m.copyWith(status: TableStatus.occupied, capacity: 8);
      expect(updated.status, TableStatus.occupied);
      expect(updated.capacity, 8);
      expect(updated.id, m.id);
    });

    test('copyWith clearCurrentOrderId', () {
      final m = makeTable(currentOrderId: 'order-1');
      final updated = m.copyWith(clearCurrentOrderId: true);
      expect(updated.currentOrderId, isNull);
    });

    test('copyWith clearAssignedServer', () {
      final m = makeTable(assignedServerId: 's1', assignedServerName: 'Ravi');
      final updated = m.copyWith(clearAssignedServer: true);
      expect(updated.assignedServerId, isNull);
      expect(updated.assignedServerName, isNull);
    });

    test('copyWith updates floor plan fields', () {
      final m = makeTable();
      final updated = m.copyWith(posX: 10.5, posY: 20.3, shape: 'round');
      expect(updated.posX, 10.5);
      expect(updated.posY, 20.3);
      expect(updated.shape, 'round');
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeTable(label: 'Corner', assignedServerId: 's1');
      final updated = m.copyWith();
      expect(updated.label, 'Corner');
      expect(updated.assignedServerId, 's1');
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeTable(
          label: 'Patio 1',
          capacity: 6,
          floor: 1,
          status: TableStatus.occupied,
          currentOrderId: 'order-1',
          posX: 5.0,
          posY: 10.0,
          shape: 'square',
          assignedServerId: 's1',
          assignedServerName: 'Ravi',
        );
        final map = m.toFirestore();
        expect(map['number'], 1);
        expect(map['label'], 'Patio 1');
        expect(map['capacity'], 6);
        expect(map['floor'], 1);
        expect(map['status'], 'occupied');
        expect(map['currentOrderId'], 'order-1');
        expect(map['posX'], 5.0);
        expect(map['shape'], 'square');
        expect(map['assignedServerId'], 's1');
      });

      test('toFirestore omits null optional fields', () {
        final m = makeTable();
        final map = m.toFirestore();
        expect(map.containsKey('posX'), isFalse);
        expect(map.containsKey('shape'), isFalse);
        expect(map.containsKey('assignedServerId'), isFalse);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeTable(
          number: 5,
          label: 'Garden 1',
          capacity: 8,
          floor: 1,
          status: TableStatus.reserved,
          posX: 15.0,
          posY: 25.0,
          shape: 'rectangle',
          assignedServerId: 's2',
          assignedServerName: 'Kumar',
        );
        await firestore
            .collection('tables')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore.collection('tables').doc(original.id).get();
        final restored = TableModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.number, 5);
        expect(restored.label, 'Garden 1');
        expect(restored.displayName, 'Garden 1');
        expect(restored.capacity, 8);
        expect(restored.floor, 1);
        expect(restored.status, TableStatus.reserved);
        expect(restored.posX, 15.0);
        expect(restored.shape, 'rectangle');
        expect(restored.assignedServerId, 's2');
      });
    });
  });
}
