import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/feedback/providers/feedback_provider.dart';
import 'package:tulasihotels/features/feedback/screens/feedback_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('FeedbackScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(
        tester,
        const FeedbackScreen(),
        overrides: [
          recentFeedbackProvider.overrideWith((_) => Stream.value([])),
          averageRatingsProvider.overrideWith((_) async => <String, double>{}),
        ],
      );
      expect(find.text('Customer Feedback'), findsOneWidget);
    });

    testWidgets('shows rating badges for categories', (tester) async {
      await pumpWidget(
        tester,
        const FeedbackScreen(),
        overrides: [
          recentFeedbackProvider.overrideWith((_) => Stream.value([])),
          averageRatingsProvider.overrideWith(
            (_) async => {
              'food': 4.2,
              'service': 3.8,
              'ambiance': 4.5,
              'overall': 4.1,
            },
          ),
        ],
      );
      expect(find.textContaining('Food'), findsOneWidget);
      expect(find.textContaining('Service'), findsOneWidget);
      expect(find.textContaining('Ambiance'), findsOneWidget);
    });

    testWidgets('shows feedback comments in list', (tester) async {
      final feedback = [
        makeFeedback(comments: 'Great biryani!', customerName: 'Ravi'),
        makeFeedback(
          id: 'fb-2',
          comments: 'Slow service',
          customerName: 'Priya',
        ),
      ];
      await pumpWidget(
        tester,
        const FeedbackScreen(),
        overrides: [
          recentFeedbackProvider.overrideWith((_) => Stream.value(feedback)),
          averageRatingsProvider.overrideWith((_) async => <String, double>{}),
        ],
      );
      expect(find.text('Great biryani!'), findsOneWidget);
      expect(find.text('Slow service'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentFeedbackProvider.overrideWith((_) => const Stream.empty()),
            averageRatingsProvider.overrideWith((_) async {
              return <String, double>{};
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: FeedbackScreen())),
        ),
      );
      // Only pump once — stream never emits so loading is shown
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows customer name in feedback list', (tester) async {
      final feedback = [makeFeedback(customerName: 'Anand Kumar')];
      await pumpWidget(
        tester,
        const FeedbackScreen(),
        overrides: [
          recentFeedbackProvider.overrideWith((_) => Stream.value(feedback)),
          averageRatingsProvider.overrideWith((_) async => <String, double>{}),
        ],
      );
      expect(find.textContaining('Anand Kumar'), findsOneWidget);
    });
  });
}
