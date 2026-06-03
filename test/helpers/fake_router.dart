/// Minimal GoRouter for widget tests — renders a single widget at '/'
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates a GoRouter that renders [child] at [initialRoute].
/// Optionally add additional [routes] for navigation testing.
GoRouter fakeRouter(
  Widget child, {
  String initialRoute = '/',
  List<RouteBase> extraRoutes = const [],
}) {
  return GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => child,
      ),
      ...extraRoutes,
    ],
  );
}
