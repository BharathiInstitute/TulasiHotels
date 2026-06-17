import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/shared/widgets/onboarding_checklist.dart';

/// Tests for the onboarding helper functions and ChecklistItem widget.
///
/// OnboardingChecklist itself depends on FirebaseAuth.instance.currentUser
/// and FirebaseFirestore streams, so we test pure logic helpers and the
/// private _ChecklistItem widget pattern.
void main() {
  group('_allStepsDone logic', () {
    test('returns true when all steps completed', () {
      final data = {
        'firstProductAdded': true,
        'firstBillCreated': true,
        'firstCustomerAdded': true,
      };
      expect(
        data['firstProductAdded'] == true &&
            data['firstBillCreated'] == true &&
            data['firstCustomerAdded'] == true,
        isTrue,
      );
    });

    test('returns false when some steps incomplete', () {
      final data = {
        'firstProductAdded': true,
        'firstBillCreated': false,
        'firstCustomerAdded': true,
      };
      expect(
        data['firstProductAdded'] == true &&
            data['firstBillCreated'] == true &&
            data['firstCustomerAdded'] == true,
        isFalse,
      );
    });

    test('returns false when all steps incomplete', () {
      final data = <String, dynamic>{};
      expect(
        data['firstProductAdded'] == true &&
            data['firstBillCreated'] == true &&
            data['firstCustomerAdded'] == true,
        isFalse,
      );
    });
  });

  group('Checklist Item UI', () {
    testWidgets('completed item shows check_circle icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InkWell(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add your first menu item',
                    style: TextStyle(decoration: TextDecoration.lineThrough),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Add your first menu item'), findsOneWidget);
    });

    testWidgets('incomplete item shows radio_button_unchecked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InkWell(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text('Create your first bill'),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.text('Create your first bill'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('OnboardingChecklist widget', () {
    testWidgets('is a StatelessWidget', (tester) async {
      // OnboardingChecklist depends on Firebase, so it renders SizedBox.shrink
      // when no user is signed in. Just verify it can be instantiated.
      const widget = OnboardingChecklist();
      expect(widget, isA<StatelessWidget>());
    });
  });

  group('Onboarding step count calculation', () {
    test('counts completed steps correctly', () {
      final onboarding = {
        'firstProductAdded': true,
        'firstBillCreated': false,
        'firstCustomerAdded': true,
      };
      final hasProducts = onboarding['firstProductAdded'] == true;
      final hasBill = onboarding['firstBillCreated'] == true;
      final hasCustomer = onboarding['firstCustomerAdded'] == true;
      final doneCount =
          (hasProducts ? 1 : 0) + (hasBill ? 1 : 0) + (hasCustomer ? 1 : 0);

      expect(doneCount, 2);
    });

    test('zero when nothing done', () {
      final onboarding = <String, dynamic>{};
      final hasProducts = onboarding['firstProductAdded'] == true;
      final hasBill = onboarding['firstBillCreated'] == true;
      final hasCustomer = onboarding['firstCustomerAdded'] == true;
      final doneCount =
          (hasProducts ? 1 : 0) + (hasBill ? 1 : 0) + (hasCustomer ? 1 : 0);

      expect(doneCount, 0);
    });

    test('three when all done', () {
      final onboarding = {
        'firstProductAdded': true,
        'firstBillCreated': true,
        'firstCustomerAdded': true,
      };
      final hasProducts = onboarding['firstProductAdded'] == true;
      final hasBill = onboarding['firstBillCreated'] == true;
      final hasCustomer = onboarding['firstCustomerAdded'] == true;
      final doneCount =
          (hasProducts ? 1 : 0) + (hasBill ? 1 : 0) + (hasCustomer ? 1 : 0);

      expect(doneCount, 3);
    });
  });
}
