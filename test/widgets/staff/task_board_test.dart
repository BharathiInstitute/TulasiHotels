import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/task_provider.dart';
import 'package:tulasihotels/features/staff/screens/task_board_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('TaskBoardScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(
        tester,
        const TaskBoardScreen(),
        overrides: [activeTasksProvider.overrideWith((_) => Stream.value([]))],
      );
      expect(find.text('Tasks'), findsOneWidget);
    });

    testWidgets('shows task titles in list', (tester) async {
      final tasks = [
        makeTask(title: 'Clean kitchen'),
        makeTask(id: 't2', title: 'Restock fridge'),
      ];
      await pumpWidget(
        tester,
        const TaskBoardScreen(),
        overrides: [
          activeTasksProvider.overrideWith((_) => Stream.value(tasks)),
        ],
      );
      expect(find.text('Clean kitchen'), findsOneWidget);
      expect(find.text('Restock fridge'), findsOneWidget);
    });

    testWidgets('shows task assignee name', (tester) async {
      final tasks = [makeTask(title: 'Deep clean', assignedToName: 'Ravi')];
      await pumpWidget(
        tester,
        const TaskBoardScreen(),
        overrides: [
          activeTasksProvider.overrideWith((_) => Stream.value(tasks)),
        ],
      );
      expect(find.textContaining('Ravi'), findsOneWidget);
    });

    testWidgets('shows FAB for creating task', (tester) async {
      await pumpWidget(
        tester,
        const TaskBoardScreen(),
        overrides: [activeTasksProvider.overrideWith((_) => Stream.value([]))],
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeTasksProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: TaskBoardScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
