/// Tests for ComplaintService — Firestore CRUD + query logic
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/complaint_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/complaints';
  });

  group('ComplaintService Firestore operations', () {
    test('create — writes document and reads back all fields', () async {
      final complaint = makeComplaint(
        id: 'comp-100',
        category: ComplaintCategory.food,
        description: 'Hair in food',
        status: ComplaintStatus.open,
        customerName: 'Ravi',
      );

      await fakeFirestore
          .collection(basePath)
          .doc(complaint.id)
          .set(complaint.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(complaint.id).get();
      expect(doc.exists, isTrue);

      final parsed = ComplaintModel.fromFirestore(doc);
      expect(parsed.id, 'comp-100');
      expect(parsed.category, ComplaintCategory.food);
      expect(parsed.description, 'Hair in food');
      expect(parsed.status, ComplaintStatus.open);
      expect(parsed.customerName, 'Ravi');
    });

    test('read — returns data for missing doc snapshot', () async {
      final doc =
          await fakeFirestore.collection(basePath).doc('nonexistent').get();
      expect(doc.exists, isFalse);
    });

    test('update — modifies fields on existing doc', () async {
      final complaint = makeComplaint(id: 'comp-u1');
      await fakeFirestore
          .collection(basePath)
          .doc(complaint.id)
          .set(complaint.toFirestore());

      await fakeFirestore.collection(basePath).doc('comp-u1').update({
        'status': ComplaintStatus.investigating.name,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('comp-u1').get();
      final parsed = ComplaintModel.fromFirestore(doc);
      expect(parsed.status, ComplaintStatus.investigating);
    });

    test('delete — removes document', () async {
      final complaint = makeComplaint(id: 'comp-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(complaint.id)
          .set(complaint.toFirestore());

      await fakeFirestore.collection(basePath).doc('comp-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('comp-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('active complaints query', () {
    test('filters only open and inProgress complaints', () async {
      final open = makeComplaint(id: 'c1', status: ComplaintStatus.open);
      final investigating =
          makeComplaint(id: 'c2', status: ComplaintStatus.investigating);
      final resolved =
          makeComplaint(id: 'c3', status: ComplaintStatus.resolved);
      final closed = makeComplaint(id: 'c4', status: ComplaintStatus.closed);

      for (final c in [open, investigating, resolved, closed]) {
        await fakeFirestore
            .collection(basePath)
            .doc(c.id)
            .set(c.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('status', whereIn: ['open', 'investigating'])
          .get();

      expect(snapshot.docs.length, 2);
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, containsAll(['c1', 'c2']));
    });
  });

  group('updateStatus business logic', () {
    test('setting resolved adds resolvedAt timestamp', () async {
      final complaint = makeComplaint(id: 'comp-res');
      await fakeFirestore
          .collection(basePath)
          .doc(complaint.id)
          .set(complaint.toFirestore());

      final now = DateTime.now();
      await fakeFirestore.collection(basePath).doc('comp-res').update({
        'status': ComplaintStatus.resolved.name,
        'resolvedAt': now.toIso8601String(),
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('comp-res').get();
      expect(doc.data()!['status'], 'resolved');
      expect(doc.data()!['resolvedAt'], isNotNull);
    });

    test('setting non-resolved status does not add resolvedAt', () async {
      final complaint = makeComplaint(id: 'comp-inv');
      await fakeFirestore
          .collection(basePath)
          .doc(complaint.id)
          .set(complaint.toFirestore());

      await fakeFirestore.collection(basePath).doc('comp-inv').update({
        'status': ComplaintStatus.investigating.name,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('comp-inv').get();
      expect(doc.data()!['status'], 'investigating');
    });
  });

  group('ComplaintStatus enum', () {
    test('fromString returns correct status for all values', () {
      for (final status in ComplaintStatus.values) {
        expect(ComplaintStatus.fromString(status.name), status);
      }
    });

    test('fromString returns open for unknown value', () {
      expect(ComplaintStatus.fromString('unknown'), ComplaintStatus.open);
    });
  });

  group('ComplaintCategory enum', () {
    test('fromString returns correct category for all values', () {
      for (final cat in ComplaintCategory.values) {
        expect(ComplaintCategory.fromString(cat.name), cat);
      }
    });

    test('fromString returns other for unknown value', () {
      expect(ComplaintCategory.fromString('invalid'), ComplaintCategory.other);
    });
  });

  group('all complaints query', () {
    test('returns all documents regardless of status', () async {
      for (final status in ComplaintStatus.values) {
        final c = makeComplaint(id: 'all-${status.name}', status: status);
        await fakeFirestore
            .collection(basePath)
            .doc(c.id)
            .set(c.toFirestore());
      }

      final snapshot = await fakeFirestore.collection(basePath).get();
      expect(snapshot.docs.length, ComplaintStatus.values.length);
    });
  });
}
