/// Table layout editor — drag-and-drop table positioning
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/tables/providers/table_provider.dart';
import 'package:tulasihotels/features/tables/services/table_service.dart';
import 'package:tulasihotels/models/table_model.dart';

class TableLayoutEditor extends ConsumerStatefulWidget {
  const TableLayoutEditor({super.key});

  @override
  ConsumerState<TableLayoutEditor> createState() => _TableLayoutEditorState();
}

class _TableLayoutEditorState extends ConsumerState<TableLayoutEditor> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Layout'),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.lock_open : Icons.lock),
            tooltip: _editMode ? 'Lock Layout' : 'Edit Layout',
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
        ],
      ),
      body: tablesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tables) => LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Grid background
                Container(
                  color: theme.colorScheme.surfaceContainerLow,
                ),
                // Table widgets
                for (final table in tables)
                  _TableWidget(
                    table: table,
                    editMode: _editMode,
                    maxWidth: constraints.maxWidth,
                    maxHeight: constraints.maxHeight,
                    onPositionChanged: (dx, dy) {
                      final normalizedX = dx / constraints.maxWidth;
                      final normalizedY = dy / constraints.maxHeight;
                      TableService.updateTable(table.copyWith(
                        posX: normalizedX.clamp(0.0, 1.0),
                        posY: normalizedY.clamp(0.0, 1.0),
                      ));
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TableWidget extends StatelessWidget {
  final TableModel table;
  final bool editMode;
  final double maxWidth;
  final double maxHeight;
  final void Function(double dx, double dy) onPositionChanged;

  const _TableWidget({
    required this.table,
    required this.editMode,
    required this.maxWidth,
    required this.maxHeight,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final x = (table.posX ?? 0.1) * maxWidth;
    final y = (table.posY ?? 0.1) * maxHeight;
    final isRound = table.shape == 'round';

    final tableWidget = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _statusColor(table.status, theme),
        shape: isRound ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isRound ? null : BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              table.displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              table.status.emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );

    if (!editMode) {
      return Positioned(left: x, top: y, child: tableWidget);
    }

    return Positioned(
      left: x,
      top: y,
      child: Draggable(
        feedback: Opacity(opacity: 0.7, child: Material(child: tableWidget)),
        childWhenDragging: Opacity(opacity: 0.3, child: tableWidget),
        onDragEnd: (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          onPositionChanged(details.offset.dx, details.offset.dy);
        },
        child: tableWidget,
      ),
    );
  }

  Color _statusColor(TableStatus status, ThemeData theme) {
    return switch (status) {
      TableStatus.available => theme.colorScheme.primaryContainer,
      TableStatus.occupied => theme.colorScheme.errorContainer,
      TableStatus.reserved => theme.colorScheme.tertiaryContainer,
      TableStatus.billing => theme.colorScheme.secondaryContainer,
    };
  }
}
