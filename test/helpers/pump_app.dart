/// Widget test helper — pumps a widget inside ProviderScope + MaterialApp
/// with localization delegates and optional GoRouter support.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/l10n/app_localizations.dart';

import 'fake_router.dart';

/// Pump a widget wrapped in ProviderScope + MaterialApp.router + l10n.
///
/// Use [overrides] to inject test providers.
/// The widget is placed at '/' by default via [fakeRouter].
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  GoRouter? router,
  ThemeData? theme,
}) async {
  final effectiveRouter = router ?? fakeRouter(child);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: effectiveRouter,
        theme: theme ?? ThemeData.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pump a widget in simple MaterialApp (no router, no l10n) — minimal wrapper.
/// Use for pure widgets that don't need navigation or localization.
Future<void> pumpWidget(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
