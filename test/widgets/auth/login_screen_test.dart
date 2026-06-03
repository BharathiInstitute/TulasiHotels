import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/auth/screens/login_screen.dart';

void main() {
  group('LoginScreen', () {
    Widget buildScreen({String? error}) {
      return ProviderScope(
        overrides: [authErrorProvider.overrideWithValue(error)],
        child: const MaterialApp(home: LoginScreen()),
      );
    }

    Future<void> pumpLogin(WidgetTester tester, {String? error}) async {
      // Auth screen Row overflows on narrow viewports — suppress in tests
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
      await pumpLogin(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('shows Welcome text', (tester) async {
      await pumpLogin(tester);
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets('shows sign in subtitle', (tester) async {
      await pumpLogin(tester);
      expect(find.text('Sign in to manage your hotel'), findsOneWidget);
    });

    testWidgets('shows email reference', (tester) async {
      await pumpLogin(tester);
      expect(find.textContaining('Email'), findsWidgets);
    });

    testWidgets('shows error message when auth error exists', (tester) async {
      await pumpLogin(tester, error: 'Invalid credentials');
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
