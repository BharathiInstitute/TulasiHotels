/// Task board screen — Kanban-style task management
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/staff/providers/task_provider.dart';
import 'package:tulasihotels/features/staff/services/task_service.dart';
import 'package:tulasihotels/models/task_model.dart';

class TaskBoardScreen extends ConsumerWidget {
  const TaskBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(activeTasksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('No active tasks'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _priorityColor(task.priority, theme),
                    child: Text(task.priority.emoji),
                  ),
                  title: Text(task.title),
                  subtitle: Text(
                    '${task.assignedToName.isEmpty ? "Unassigned" : task.assignedToName} • ${task.status.displayName}',
                  ),
                  trailing: PopupMenuButton<TaskStatus>(
                    onSelected: (status) =>
                        TaskService.updateTaskStatus(task.id, status),
                    itemBuilder: (ctx) => TaskStatus.values.map((s) {
                      return PopupMenuItem(
                        value: s,
                        child: Text('${s.emoji} ${s.displayName}'),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _priorityColor(TaskPriority priority, ThemeData theme) {
    return switch (priority) {
      TaskPriority.low => theme.colorScheme.surfaceContainerHighest,
      TaskPriority.medium => theme.colorScheme.tertiaryContainer,
      TaskPriority.high => theme.colorScheme.errorContainer,
    };
  }

  void _showTaskForm(BuildContext context) {
    final titleCtrl = TextEditingController();
    var priority = TaskPriority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('New Task',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: TaskPriority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.emoji} ${p.displayName}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => priority = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (titleCtrl.text.isEmpty) return;
                      final task = TaskModel(
                        id: generateSafeId('task'),
                        title: titleCtrl.text.trim(),
                        assignedToId: '',
                        assignedToName: '',
                        priority: priority,
                        createdAt: DateTime.now(),
                      );
                      TaskService.createTask(task);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Create Task'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
