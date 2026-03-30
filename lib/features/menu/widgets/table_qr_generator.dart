/// Table QR code generator widget
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TableQrGenerator extends StatelessWidget {
  final String hotelId;
  final String tableId;
  final String tableName;

  const TableQrGenerator({
    super.key,
    required this.hotelId,
    required this.tableId,
    required this.tableName,
  });

  String get menuUrl => 'https://tulasihotels.web.app/menu/$hotelId?table=$tableId';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tableName,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            QrImageView(
              data: menuUrl,
              size: 200,
              errorStateBuilder: (context, error) => const Center(
                child: Icon(Icons.error_outline, size: 64, color: Colors.red),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              menuUrl,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
