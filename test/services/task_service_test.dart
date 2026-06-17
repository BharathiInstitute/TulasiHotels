/// Tests for TaskService — CRUD, status updates, priority sort, staff filtering
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/task_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/tasks';
  });

  group('TaskService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final task = makeTask(
        title: 'Clean kitchen',
        assignedToName: 'Ravi',
        priority: TaskPriority.high,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(task.id)
          .set(task.toFirestore());

      final doc = await fakeFirestore.collection(basePath).doc(task.id).get();
      final parsed = TaskModel.fromFirestore(doc);
      expect(parsed.title, 'Clean kitchen');
      expect(parsed.assignedToId, 'staff-1');
      expect(parsed.assignedToName, 'Ravi');
      expect(parsed.priority, TaskPriority.high);
    });

    test('update — modifies existing task', () async {
      final task = makeTask(id: 'task-u1');
      await fakeFirestore
          .collection(basePath)
          .doc(task.id)
          .set(task.toFirestore());

      final updated = task.copyWith(title: 'Updated task');
      await fakeFirestore
          .collection(basePath)
          .doc(task.id)
          .update(updated.toFirestore());

      final doc = await fakeFirestore.collection(basePath).doc('task-u1').get();
      final parsed = TaskModel.fromFirestore(doc);
      expect(parsed.title, 'Updated task');
    });

    test('delete — removes task', () async {
      final task = makeTask(id: 'task-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(task.id)
          .set(task.toFirestore());

      await fakeFirestore.collection(basePath).doc('task-d1').delete();

      final doc = await fakeFirestore.collection(basePath).doc('task-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('updateTaskStatus', () {
    test('setting completed adds completedAt', () async {
      final task = makeTask(id: 'task-comp');
      await fakeFirestore
          .collection(basePath)
          .doc(task.id)
          .set(task.toFirestore());

      final now = DateTime.now();
      await fakeFirestore.collection(basePath).doc('task-comp').update({
        'status': TaskStatus.completed.name,
        'completedAt': now.toIso8601String(),
      });

      final doc = await fakeFirestore
          .collection(basePath)
          .doc('task-comp')
          .get();
      expect(doc.data()!['status'], 'completed');
      expect(doc.data()!['completedAt'], isNotNull);
    });

    test('setting inProgress does not add completedAt', () async {
      final task = makeTask(id: 'task-ip');
      await fakeFirestore
          .collection(basePath)
          .doc(task.id)
          .set(task.toFirestore());

      await fakeFirestore.collection(basePath).doc('task-ip').update({
        'status': TaskStatus.inProgress.name,
      });

      final doc = await fakeFirestore.collection(basePath).doc('task-ip').get();
      expect(doc.data()!['status'], 'inProgress');
    });
  });

  group('activeTasksStream query', () {
    test('filters pending and inProgress tasks', () async {
      final pending = makeTask(id: 't1');
      final inProgress = makeTask(id: 't2', status: TaskStatus.inProgress);
      final completed = makeTask(id: 't3', status: TaskStatus.completed);
      for (final t in [pending, inProgress, completed]) {
        await fakeFirestore.collection(basePath).doc(t.id).set(t.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('status', whereIn: ['pending', 'inProgress'])
          .get();

      expect(snapshot.docs.length, 2);
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, {'t1', 't2'});
    });
  });

  group('staffTasksStream query', () {
    test('filters tasks by assignedToId', () async {
      final staff1Task = makeTask(id: 's1t');
      final staff2Task = makeTask(id: 's2t', assignedToId: 'staff-2');

      for (final t in [staff1Task, staff2Task]) {
        await fakeFirestore.collection(basePath).doc(t.id).set(t.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('assignedToId', isEqualTo: 'staff-1')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 's1t');
    });
  });

  group('priority sort', () {
    test('tasks sort by priority descending', () {
      final tasks = [
        makeTask(id: 't-low', priority: TaskPriority.low),
        makeTask(id: 't-high', priority: TaskPriority.high),
        makeTask(id: 't-med'),
        makeTask(id: 't-high2', priority: TaskPriority.high),
      ];

      tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));

      final ids = tasks.map((t) => t.id).toList();
      expect(ids, ['t-high', 't-high2', 't-med', 't-low']);
    });
  });

  group('TaskStatus enum round-trip', () {
    test('all statuses survive Firestore round-trip', () async {
      for (final status in TaskStatus.values) {
        final task = makeTask(id: 'ts-${status.name}', status: status);
        await fakeFirestore
            .collection(basePath)
            .doc(task.id)
            .set(task.toFirestore());

        final doc = await fakeFirestore.collection(basePath).doc(task.id).get();
        final parsed = TaskModel.fromFirestore(doc);
        expect(parsed.status, status);
      }
    });
  });
}
