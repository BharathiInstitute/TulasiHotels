import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/menu/widgets/table_qr_generator.dart';

void main() {
  group('TableQrGenerator', () {
    testWidgets('renders with required params', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TableQrGenerator(
              hotelId: 'hotel-1',
              tableId: 't1',
              tableName: 'Table 1',
            ),
          ),
        ),
      );
      expect(find.byType(TableQrGenerator), findsOneWidget);
    });

    testWidgets('shows table name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TableQrGenerator(
              hotelId: 'hotel-1',
              tableId: 't2',
              tableName: 'VIP Table',
            ),
          ),
        ),
      );
      expect(find.textContaining('VIP Table'), findsWidgets);
    });

    test('is a StatelessWidget', () {
      const widget = TableQrGenerator(
        hotelId: 'h1',
        tableId: 't1',
        tableName: 'T1',
      );
      expect(widget, isA<StatelessWidget>());
    });
  });
}
