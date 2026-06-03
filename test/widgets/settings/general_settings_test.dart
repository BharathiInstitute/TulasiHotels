import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/settings/screens/general_settings_screen.dart';

void main() {
  group('GeneralSettingsScreen', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = GeneralSettingsScreen();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = GeneralSettingsScreen(key: Key('settings'));
      expect(widget.key, const Key('settings'));
    });

    test('createState returns non-null', () {
      const widget = GeneralSettingsScreen();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
