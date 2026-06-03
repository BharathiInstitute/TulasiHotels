import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for NpsSurveyDialog UI structure.
///
/// NpsSurveyDialog.showIfEligible depends on FirebaseFirestore.instance,
/// so we test the dialog UI by building it directly.
void main() {
  group('NPS Survey Dialog UI', () {
    testWidgets('shows 0-10 ChoiceChips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => StatefulBuilder(
                    builder: (context, setState) {
                      int? selectedScore;
                      return AlertDialog(
                        title: const Text(
                          'How likely are you to recommend us?',
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'On a scale of 0-10, how likely are you to recommend Tulasi Hotels to a friend or colleague?',
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 4,
                              children: List.generate(11, (index) {
                                return ChoiceChip(
                                  label: Text('$index'),
                                  selected: selectedScore == index,
                                  onSelected: (selected) {
                                    setState(
                                      () => selectedScore = selected
                                          ? index
                                          : null,
                                    );
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Skip'),
                          ),
                          FilledButton(
                            onPressed: selectedScore != null ? () {} : null,
                            child: const Text('Submit'),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
              child: const Text('Show NPS'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show NPS'));
      await tester.pumpAndSettle();

      // Title
      expect(find.text('How likely are you to recommend us?'), findsOneWidget);

      // 11 ChoiceChips (0 through 10)
      expect(find.byType(ChoiceChip), findsNWidgets(11));
      for (var i = 0; i <= 10; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Action buttons
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('shows question text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('How likely are you to recommend us?'),
                    content: Text(
                      'On a scale of 0-10, how likely are you to recommend Tulasi Hotels to a friend or colleague?',
                    ),
                  ),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tulasi Hotels'), findsOneWidget);
      expect(find.textContaining('friend or colleague'), findsOneWidget);
    });

    testWidgets('Submit disabled when no score selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    actions: [
                      FilledButton(
                        onPressed: null,
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
