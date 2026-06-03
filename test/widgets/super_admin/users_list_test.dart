import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/super_admin/screens/users_list_screen.dart';

void main() {
  group('UsersListScreen', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = UsersListScreen();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = UsersListScreen(key: Key('users'));
      expect(widget.key, const Key('users'));
    });

    test('createState returns non-null', () {
      const widget = UsersListScreen();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
