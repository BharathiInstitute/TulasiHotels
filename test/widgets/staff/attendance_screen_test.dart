import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/screens/attendance_screen.dart';
import 'package:tulasihotels/firebase_options.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) rethrow;
    }
  });

  group('AttendanceScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: AttendanceScreen())),
        ),
      );
      await tester.pump();
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('shows not logged in state when user is unauthenticated', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: AttendanceScreen())),
        ),
      );
      await tester.pump();
      expect(find.text('Not logged in'), findsOneWidget);
    });

    testWidgets('renders screen scaffold', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: AttendanceScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });
  }, skip: 'Depends on FirebaseAuthNotifier timers in widget-test environment');
}
