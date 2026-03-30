/// Task assignment model for staff management
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Task lifecycle status
enum TaskStatus {
  pending('Pending', '📋'),
  inProgress('In Progress', '🔄'),
  completed('Completed', '✅'),
  overdue('Overdue', '⚠️');

  final String displayName;
  final String emoji;

  const TaskStatus(this.displayName, this.emoji);

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.pending,
    );
  }
}

/// Task priority levels
enum TaskPriority {
  low('Low', '🟢'),
  medium('Medium', '🟡'),
  high('High', '🔴');

  final String displayName;
  final String emoji;

  const TaskPriority(this.displayName, this.emoji);

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String assignedToId;
  final String assignedToName;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.assignedToId,
    required this.assignedToName,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
  });

  /// Whether the task is overdue
  bool get isOverdue =>
      dueDate != null &&
      DateTime.now().isAfter(dueDate!) &&
      status != TaskStatus.completed;

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      description: data['description'] as String?,
      assignedToId: (data['assignedToId'] as String?) ?? '',
      assignedToName: (data['assignedToName'] as String?) ?? '',
      status: TaskStatus.fromString(
        (data['status'] as String?) ?? 'pending',
      ),
      priority: TaskPriority.fromString(
        (data['priority'] as String?) ?? 'medium',
      ),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'status': status.name,
      'priority': priority.name,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    String? assignedToId,
    String? assignedToName,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
