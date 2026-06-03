import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/auth/screens/forgot_password_screen.dart';

void main() {
  group('ForgotPasswordScreen', () {
    Widget buildScreen({String? error}) {
      return ProviderScope(
        overrides: [authErrorProvider.overrideWithValue(error)],
        child: const MaterialApp(home: ForgotPasswordScreen()),
      );
    }

    Future<void> pumpForgotPassword(
      WidgetTester tester, {
      String? error,
    }) async {
      final origHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        origHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = origHandler);

      await tester.pumpWidget(buildScreen(error: error));
      await tester.pump();
    }

    testWidgets('renders without crash', (tester) async {
      await pumpForgotPassword(tester);
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('shows Reset Password title', (tester) async {
      await pumpForgotPassword(tester);
      expect(find.text('Reset Password'), findsOneWidget);
    });

    testWidgets('shows email related text', (tester) async {
      await pumpForgotPassword(tester);
      expect(find.textContaining('email'), findsWidgets);
    });

    testWidgets('shows app name', (tester) async {
      await pumpForgotPassword(tester);
      expect(find.textContaining('Tulasi'), findsWidgets);
    });

    testWidgets('shows error when auth error exists', (tester) async {
      await pumpForgotPassword(tester, error: 'User not found');
      expect(find.text('User not found'), findsOneWidget);
    });
  });
}
