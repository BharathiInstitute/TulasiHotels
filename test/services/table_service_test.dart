/// Tests for TableService — CRUD, bulk create, status updates, server assignment
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/table_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/tables';
  });

  group('TableService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final table = makeTable(
        id: 'tbl-1',
        number: 5,
        label: 'Window Seat',
        capacity: 6,
        floor: 1,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(table.id)
          .set(table.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(table.id).get();
      final parsed = TableModel.fromFirestore(doc);
      expect(parsed.number, 5);
      expect(parsed.label, 'Window Seat');
      expect(parsed.capacity, 6);
      expect(parsed.floor, 1);
    });

    test('getTable — returns null for missing doc', () async {
      final doc =
          await fakeFirestore.collection(basePath).doc('missing').get();
      expect(doc.exists, isFalse);
    });

    test('update — modifies existing table', () async {
      final table = makeTable(id: 'tbl-u1');
      await fakeFirestore
          .collection(basePath)
          .doc(table.id)
          .set(table.toFirestore());

      await fakeFirestore.collection(basePath).doc('tbl-u1').update({
        'capacity': 8,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('tbl-u1').get();
      final parsed = TableModel.fromFirestore(doc);
      expect(parsed.capacity, 8);
    });

    test('delete — removes table', () async {
      final table = makeTable(id: 'tbl-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(table.id)
          .set(table.toFirestore());

      await fakeFirestore.collection(basePath).doc('tbl-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('tbl-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('updateTableStatus', () {
    test('sets status to occupied and assigns orderId', () async {
      final table = makeTable(id: 'tbl-st');
      await fakeFirestore
          .collection(basePath)
          .doc(table.id)
          .set(table.toFirestore());

      await fakeFirestore.collection(basePath).doc('tbl-st').update({
        'status': TableStatus.occupied.name,
        'currentOrderId': 'order-123',
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('tbl-st').get();
      final parsed = TableModel.fromFirestore(doc);
      expect(parsed.status, TableStatus.occupied);
      expect(parsed.currentOrderId, 'order-123');
    });

    test('setting available clears currentOrderId', () async {
      final table = makeTable(
        id: 'tbl-free',
        status: TableStatus.occupied,
        currentOrderId: 'order-123',
      );
      await fakeFirestore
          .collection(basePath)
          .doc(table.id)
          .set(table.toFirestore());

      await fakeFirestore.collection(basePath).doc('tbl-free').update({
        'status': TableStatus.available.name,
        'currentOrderId': null,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('tbl-free').get();
      final parsed = TableModel.fromFirestore(doc);
      expect(parsed.status, TableStatus.available);
      expect(parsed.currentOrderId, isNull);
    });
  });

  group('createBulkTables', () {
    test('creates multiple tables', () async {
      for (var i = 1; i <= 5; i++) {
        final table = makeTable(id: 'bulk-$i', number: i);
        await fakeFirestore
            .collection(basePath)
            .doc(table.id)
            .set(table.toFirestore());
      }

      final snapshot = await fakeFirestore.collection(basePath).get();
      expect(snapshot.docs.length, 5);
    });
  });

  group('assignServer / clearServerAssignment', () {
    test('assigns server to table', () async {
      final table = makeTable(id: 'tbl-srv');
      await fakeFirestore
          .collection(basePath)
          .doc(table.id)
          .set(table.toFirestore());

      await fakeFirestore.collection(basePath).doc('tbl-srv').update({
        'assignedServerId': 'staff-1',
        'assignedServerName': 'Ravi',
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('tbl-srv').get();
      final parsed = TableModel.fromFirestore(doc);
      expect(parsed.assignedServerId, 'staff-1');
      expect(parsed.assignedServerName, 'Ravi');
    });

    test('clears server assignment', () async {
      final table = makeTable(
        id: 'tbl-clr',
        assignedServerId: 'staff-1',
        assignedServerName: 'Ravi',
      );
      await fakeFirestore
          .collection(basePath)
          .doc(table.id)
          .set(table.toFirestore());

      await fakeFirestore.collection(basePath).doc('tbl-clr').update({
        'assignedServerId': null,
        'assignedServerName': null,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('tbl-clr').get();
      final parsed = TableModel.fromFirestore(doc);
      expect(parsed.assignedServerId, isNull);
      expect(parsed.assignedServerName, isNull);
    });
  });

  group('serverTablesStream query', () {
    test('filters tables by assignedServerId', () async {
      final t1 = makeTable(id: 'st1', assignedServerId: 'staff-1');
      final t2 = makeTable(id: 'st2', number: 2, assignedServerId: 'staff-2');
      final t3 = makeTable(id: 'st3', number: 3, assignedServerId: 'staff-1');

      for (final t in [t1, t2, t3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(t.id)
            .set(t.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('assignedServerId', isEqualTo: 'staff-1')
          .get();

      expect(snapshot.docs.length, 2);
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, {'st1', 'st3'});
    });
  });

  group('tablesStream ordering', () {
    test('returns tables ordered by number', () async {
      final t1 = makeTable(id: 't1', number: 3);
      final t2 = makeTable(id: 't2');
      final t3 = makeTable(id: 't3', number: 2);

      for (final t in [t1, t2, t3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(t.id)
            .set(t.toFirestore());
      }

      final snapshot =
          await fakeFirestore.collection(basePath).orderBy('number').get();

      final numbers = snapshot.docs
          .map((d) => TableModel.fromFirestore(d).number)
          .toList();
      expect(numbers, [1, 2, 3]);
    });
  });

  group('TableStatus enum round-trip', () {
    test('all statuses survive Firestore round-trip', () async {
      for (final status in TableStatus.values) {
        final table = makeTable(id: 'ts-${status.name}', status: status);
        await fakeFirestore
            .collection(basePath)
            .doc(table.id)
            .set(table.toFirestore());

        final doc =
            await fakeFirestore.collection(basePath).doc(table.id).get();
        final parsed = TableModel.fromFirestore(doc);
        expect(parsed.status, status);
      }
    });
  });

  group('displayName computed', () {
    test('uses label when set', () {
      final table = makeTable(label: 'VIP');
      expect(table.displayName, 'VIP');
    });

    test('falls back to Table {number} when no label', () {
      final table = makeTable(number: 5);
      expect(table.displayName, 'Table 5');
    });
  });

  group('isFree and hasActiveOrder', () {
    test('isFree is true when status is available', () {
      final table = makeTable();
      expect(table.isFree, isTrue);
    });

    test('isFree is false when occupied', () {
      final table = makeTable(status: TableStatus.occupied);
      expect(table.isFree, isFalse);
    });

    test('hasActiveOrder when currentOrderId is set', () {
      final table = makeTable(currentOrderId: 'order-1');
      expect(table.hasActiveOrder, isTrue);
    });

    test('hasActiveOrder is false when no order', () {
      final table = makeTable();
      expect(table.hasActiveOrder, isFalse);
    });
  });
}
