import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/task_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('TaskStatus enum', () {
    test('fromString parses all values', () {
      for (final s in TaskStatus.values) {
        expect(TaskStatus.fromString(s.name), s);
      }
    });

    test('fromString defaults to pending', () {
      expect(TaskStatus.fromString('xyz'), TaskStatus.pending);
    });
  });

  group('TaskPriority enum', () {
    test('fromString parses all values', () {
      for (final p in TaskPriority.values) {
        expect(TaskPriority.fromString(p.name), p);
      }
    });

    test('fromString defaults to medium', () {
      expect(TaskPriority.fromString('xyz'), TaskPriority.medium);
    });
  });

  group('TaskModel', () {
    test('constructor defaults', () {
      final m = makeTask();
      expect(m.status, TaskStatus.pending);
      expect(m.priority, TaskPriority.medium);
      expect(m.dueDate, isNull);
      expect(m.completedAt, isNull);
    });

    test('isOverdue true when past due and not completed', () {
      final m = makeTask(
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(m.isOverdue, isTrue);
    });

    test('isOverdue false when past due but completed', () {
      final m = makeTask(
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: TaskStatus.completed,
      );
      expect(m.isOverdue, isFalse);
    });

    test('isOverdue false when future due', () {
      final m = makeTask(dueDate: DateTime.now().add(const Duration(days: 7)));
      expect(m.isOverdue, isFalse);
    });

    test('isOverdue false when no dueDate', () {
      expect(makeTask().isOverdue, isFalse);
    });

    test('copyWith updates status and priority', () {
      final m = makeTask();
      final updated = m.copyWith(
        status: TaskStatus.completed,
        priority: TaskPriority.high,
        completedAt: DateTime(2024, 1, 16),
      );
      expect(updated.status, TaskStatus.completed);
      expect(updated.priority, TaskPriority.high);
      expect(updated.completedAt, DateTime(2024, 1, 16));
      expect(updated.id, m.id);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeTask(title: 'Clean kitchen', description: 'Deep clean');
      final updated = m.copyWith();
      expect(updated.title, 'Clean kitchen');
      expect(updated.description, 'Deep clean');
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeTask(
          description: 'Mop floors',
          priority: TaskPriority.high,
          dueDate: DateTime(2024, 1, 20),
          completedAt: DateTime(2024, 1, 19),
        );
        final map = m.toFirestore();
        expect(map['title'], 'Test Task');
        expect(map['description'], 'Mop floors');
        expect(map['status'], 'pending');
        expect(map['priority'], 'high');
        expect(map['assignedToId'], 'staff-1');
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeTask(
          title: 'Inventory check',
          description: 'Count all items',
          assignedToName: 'Ravi',
          priority: TaskPriority.high,
          dueDate: DateTime(2024, 2),
        );
        await firestore
            .collection('tasks')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore.collection('tasks').doc(original.id).get();
        final restored = TaskModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.title, 'Inventory check');
        expect(restored.description, 'Count all items');
        expect(restored.assignedToName, 'Ravi');
        expect(restored.priority, TaskPriority.high);
      });
    });
  });
}
