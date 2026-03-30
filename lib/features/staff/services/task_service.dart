/// Task management service for staff
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/models/task_model.dart';

class TaskService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  static CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('$_basePath/tasks');

  /// Stream active tasks (not completed/cancelled)
  static Stream<List<TaskModel>> activeTasksStream() {
    return _tasksRef
        .where('status', whereIn: ['pending', 'inProgress'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) => b.priority.index.compareTo(a.priority.index)),
        );
  }

  /// Stream tasks assigned to a specific staff member
  static Stream<List<TaskModel>> staffTasksStream(String staffId) {
    return _tasksRef
        .where('assignedToId', isEqualTo: staffId)
        .where('status', whereIn: ['pending', 'inProgress'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Create a task
  static Future<void> createTask(TaskModel task) async {
    await _tasksRef.doc(task.id).set(task.toFirestore());
  }

  /// Update task status
  static Future<void> updateTaskStatus(
      String taskId, TaskStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == TaskStatus.completed) {
      updates['completedAt'] = FieldValue.serverTimestamp();
    }
    await _tasksRef.doc(taskId).update(updates);
  }

  /// Update a task
  static Future<void> updateTask(TaskModel task) async {
    await _tasksRef.doc(task.id).update(task.toFirestore());
  }

  /// Delete a task
  static Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }
}
