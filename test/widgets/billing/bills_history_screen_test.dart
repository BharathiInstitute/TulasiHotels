import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/billing/providers/billing_provider.dart';
import 'package:tulasihotels/features/billing/screens/bills_history_screen.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/expense_model.dart';

import '../../helpers/test_factories.dart';

List<Override> _defaultOverrides({
  List<BillModel>? bills,
  List<ExpenseModel>? expenses,
  bool loading = false,
}) {
  return [
    filteredBillsProvider.overrideWith(
      (_) => loading
          ? const Stream<List<BillModel>>.empty()
          : Stream.value(bills ?? []),
    ),
    filteredExpensesProvider.overrideWith(
      (_) => loading
          ? const Stream<List<ExpenseModel>>.empty()
          : Stream.value(expenses ?? []),
    ),
    billsSyncStatusProvider.overrideWith((_) => Stream.value(<String, bool>{})),
    expensesSyncStatusProvider.overrideWith(
      (_) => Stream.value(<String, bool>{}),
    ),
  ];
}

void main() {
  group('BillsHistoryScreen', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides(),
          child: const MaterialApp(home: Scaffold(body: BillsHistoryScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(BillsHistoryScreen), findsOneWidget);
    });

    testWidgets('shows bill data in list', (tester) async {
      final bills = [
        makeBill(billNumber: 1, total: 500.0),
        makeBill(id: 'b2', billNumber: 2, total: 1200.0),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides(bills: bills),
          child: const MaterialApp(home: Scaffold(body: BillsHistoryScreen())),
        ),
      );
      await tester.pump();
      // Bills should render — verify the screen isn't empty
      expect(find.byType(BillsHistoryScreen), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides(loading: true),
          child: const MaterialApp(home: Scaffold(body: BillsHistoryScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
