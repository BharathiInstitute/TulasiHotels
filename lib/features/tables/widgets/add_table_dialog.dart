/// Add/Edit table dialog
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/tables/services/table_service.dart';
import 'package:tulasihotels/models/table_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class AddTableDialog extends ConsumerStatefulWidget {
  final TableModel? editTable;

  const AddTableDialog({super.key, this.editTable});

  @override
  ConsumerState<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends ConsumerState<AddTableDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _labelController;
  late final TextEditingController _capacityController;
  late final TextEditingController _floorController;

  bool _isBulk = false;
  late final TextEditingController _bulkFromController;
  late final TextEditingController _bulkToController;

  bool _isLoading = false;

  bool get _isEditing => widget.editTable != null;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: widget.editTable?.number.toString() ?? '',
    );
    _labelController = TextEditingController(
      text: widget.editTable?.label ?? '',
    );
    _capacityController = TextEditingController(
      text: (widget.editTable?.capacity ?? 4).toString(),
    );
    _floorController = TextEditingController(
      text: (widget.editTable?.floor ?? 0).toString(),
    );
    _bulkFromController = TextEditingController();
    _bulkToController = TextEditingController();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _labelController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
    _bulkFromController.dispose();
    _bulkToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(routePermissionProvider(AppRoutes.tables));
    final canSave = _isEditing
        ? permissions.canUpdate
        : permissions.canCreate;

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Table' : 'Add Table'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isEditing)
                SwitchListTile(
                  title: const Text('Bulk add'),
                  subtitle: const Text('Add multiple tables at once'),
                  value: _isBulk,
                  onChanged: (v) => setState(() => _isBulk = v),
                  contentPadding: EdgeInsets.zero,
                ),

              if (_isBulk) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bulkFromController,
                        decoration: const InputDecoration(labelText: 'From #'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bulkToController,
                        decoration: const InputDecoration(labelText: 'To #'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(labelText: 'Table Number'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Enter a number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label (optional)',
                    hintText: 'e.g., Window Seat, VIP',
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      decoration: const InputDecoration(labelText: 'Floor'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || !canSave ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final permissions = ref.read(routePermissionProvider(AppRoutes.tables));
    final canSave = _isEditing
        ? permissions.canUpdate
        : permissions.canCreate;
    if (!canSave) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'You do not have permission to update tables.'
                  : 'You do not have permission to create tables.',
            ),
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final capacity = int.tryParse(_capacityController.text) ?? 4;
      final floor = int.tryParse(_floorController.text) ?? 0;

      if (_isEditing) {
        final updated = widget.editTable!.copyWith(
          number: int.parse(_numberController.text),
          label: _labelController.text.isEmpty ? null : _labelController.text,
          capacity: capacity,
          floor: floor,
        );
        await TableService.updateTable(updated);
      } else if (_isBulk) {
        final from = int.parse(_bulkFromController.text);
        final to = int.parse(_bulkToController.text);
        await TableService.createBulkTables(
          from: from,
          to: to,
          capacity: capacity,
          floor: floor,
        );
      } else {
        await TableService.createTable(
          number: int.parse(_numberController.text),
          label:
              _labelController.text.isEmpty ? null : _labelController.text,
          capacity: capacity,
          floor: floor,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
