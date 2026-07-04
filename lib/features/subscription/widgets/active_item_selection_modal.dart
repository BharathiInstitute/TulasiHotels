/// Modal that asks the user to pick which items to keep active after a downgrade.
library;

import 'package:flutter/material.dart';

/// Generic item selection modal for downgrade flows.
/// Shows all items and lets user pick up to [maxSelection] to keep active.
class ActiveItemSelectionModal<T> extends StatefulWidget {
  final String title;
  final String subtitle;
  final int maxSelection;
  final List<T> items;
  final String Function(T) getName;
  final String Function(T) getId;
  final String? Function(T)? getSubtitle;

  const ActiveItemSelectionModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.maxSelection,
    required this.items,
    required this.getName,
    required this.getId,
    this.getSubtitle,
  });

  @override
  State<ActiveItemSelectionModal<T>> createState() =>
      _ActiveItemSelectionModalState<T>();
}

class _ActiveItemSelectionModalState<T>
    extends State<ActiveItemSelectionModal<T>> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = widget.maxSelection - _selectedIds.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: cs.primaryContainer.withValues(alpha: 0.3),
            child: Column(
              children: [
                Text(
                  widget.subtitle,
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  remaining > 0
                      ? 'Select $remaining more (${_selectedIds.length}/${widget.maxSelection})'
                      : 'Selection complete (${_selectedIds.length}/${widget.maxSelection})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: remaining > 0 ? cs.primary : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _selectedIds.length / widget.maxSelection,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    _selectedIds.length >= widget.maxSelection
                        ? Colors.green
                        : cs.primary,
                  ),
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final id = widget.getId(item);
                final isSelected = _selectedIds.contains(id);
                final canSelect =
                    isSelected || _selectedIds.length < widget.maxSelection;

                return ListTile(
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: canSelect
                        ? (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIds.add(id);
                              } else {
                                _selectedIds.remove(id);
                              }
                            });
                          }
                        : null,
                  ),
                  title: Text(
                    widget.getName(item),
                    style: TextStyle(
                      color: canSelect || isSelected
                          ? null
                          : cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  subtitle: widget.getSubtitle != null
                      ? Text(widget.getSubtitle!(item) ?? '')
                      : null,
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Colors.green.shade600)
                      : !canSelect
                          ? Icon(Icons.lock_outline,
                              color: cs.onSurface.withValues(alpha: 0.3))
                          : null,
                  onTap: canSelect
                      ? () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(id);
                            } else {
                              _selectedIds.add(id);
                            }
                          });
                        }
                      : null,
                );
              },
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _selectedIds.length == widget.maxSelection
                    ? () => Navigator.pop(context, _selectedIds.toList())
                    : null,
                child: Text(
                  _selectedIds.length == widget.maxSelection
                      ? 'Confirm Selection'
                      : 'Select ${remaining} more items',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
