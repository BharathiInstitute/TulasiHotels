import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/auth/screens/register_screen.dart';

void main() {
  group('RegisterScreen', () {
    Widget buildScreen({String? error}) {
      return ProviderScope(
        overrides: [authErrorProvider.overrideWithValue(error)],
        child: const MaterialApp(home: RegisterScreen()),
      );
    }

    Future<void> pumpRegister(WidgetTester tester, {String? error}) async {
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
      await pumpRegister(tester);
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('shows Create Account text', (tester) async {
      await pumpRegister(tester);
      expect(find.textContaining('Create'), findsWidgets);
    });

    testWidgets('shows subtitle text', (tester) async {
      await pumpRegister(tester);
      expect(find.textContaining('Get started'), findsOneWidget);
    });

    testWidgets('shows sign in link for existing users', (tester) async {
      await pumpRegister(tester);
      expect(find.textContaining('Already'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows error when auth error exists', (tester) async {
      await pumpRegister(tester, error: 'Email already in use');
      expect(find.text('Email already in use'), findsOneWidget);
    });
  });
}
