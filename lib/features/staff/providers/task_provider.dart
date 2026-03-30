/// Task management providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/services/task_service.dart';
import 'package:tulasihotels/models/task_model.dart';

/// Stream active tasks
final activeTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  return TaskService.activeTasksStream();
});

/// Stream tasks for a specific staff member
final staffTasksProvider =
    StreamProvider.autoDispose.family<List<TaskModel>, String>((ref, staffId) {
  return TaskService.staffTasksStream(staffId);
});
