/// Event / banquet management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/compliance/providers/compliance_provider.dart';
import 'package:tulasihotels/features/compliance/services/event_service.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/permissions/services/module_mutation_guard.dart';
import 'package:tulasihotels/features/permissions/widgets/permission_denied_view.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/router/app_router.dart';
import 'package:tulasihotels/models/event_model.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  bool _showAll = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventPermissions = ref.watch(routePermissionProvider(AppRoutes.events));
    final eventsAsync = _showAll
        ? ref.watch(allEventsProvider)
        : ref.watch(upcomingEventsProvider);

    if (!eventPermissions.isResolved) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!eventPermissions.canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Events & Banquets')),
        body: PermissionDeniedView(
          message: PermissionCenter.deniedViewMessage(AppRoutes.events),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Banquets'),
        actions: [
          FilterChip(
            label: Text(_showAll ? 'All' : 'Upcoming'),
            selected: _showAll,
            onSelected: (v) => setState(() => _showAll = v),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: eventPermissions.canCreate ? _showEventForm : null,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No events scheduled'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isPast = event.eventDate.isBefore(DateTime.now());

              return Card(
                child: ExpansionTile(
                  leading: Icon(
                    Icons.event,
                    color: isPast ? Colors.grey : Colors.blue,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (eventPermissions.canUpdate)
                        IconButton(
                          tooltip: 'Edit Event',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEventForm(existing: event),
                        ),
                      if (eventPermissions.canDelete)
                        IconButton(
                          tooltip: 'Delete Event',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteEvent(event),
                        ),
                      const Icon(Icons.expand_more),
                    ],
                  ),
                  title: Text(event.eventName),
                  subtitle: Text(
                    '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year} • ${event.guestCount} guests',
                  ),
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.person, size: 18),
                      title: Text(event.clientName),
                      subtitle: Text(event.clientPhone),
                    ),
                    if (event.menu.isNotEmpty) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Text(
                          'Menu Items (${event.menu.length})',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      ...event.menu.map(
                        (item) => ListTile(
                          dense: true,
                          title: Text(item.name),
                          trailing: Text('×${item.quantity}'),
                        ),
                      ),
                    ],
                    if (event.specialInstructions != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          event.specialInstructions!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: ₹${event.totalAmount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (event.balanceDue > 0)
                            Text(
                              'Due: ₹${event.balanceDue.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEventForm({EventModel? existing}) {
    final nameCtrl = TextEditingController(
      text: existing?.eventName ?? '',
    );
    final clientNameCtrl = TextEditingController(
      text: existing?.clientName ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: existing?.clientPhone ?? '',
    );
    final guestsCtrl = TextEditingController(
      text: existing?.guestCount.toString() ?? '',
    );
    final instructionsCtrl = TextEditingController(
      text: existing?.specialInstructions ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existing?.perPlatePrice.toStringAsFixed(0) ?? '',
    );
    final advanceCtrl = TextEditingController(
      text: existing?.advancePaid.toStringAsFixed(0) ?? '',
    );
    var selectedDate = existing?.eventDate ?? DateTime.now().add(const Duration(days: 7));

    final permissions = ref.read(routePermissionProvider(AppRoutes.events));
    final isEditing = existing != null;
    final requiredAction =
        isEditing ? PermissionAction.update : PermissionAction.create;
    final hasPermission =
        isEditing ? permissions.canUpdate : permissions.canCreate;

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            PermissionCenter.deniedActionMessage(
              AppRoutes.events,
              requiredAction,
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Edit Event' : 'New Event',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Event Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  child: Text(
                    'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clientNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Client Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: guestsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Guest Count',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Per Plate Price (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: advanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Advance Paid (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionsCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Special Instructions (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _submitEvent(
                      ctx,
                      existing: existing,
                      selectedDate: selectedDate,
                      nameCtrl: nameCtrl,
                      clientNameCtrl: clientNameCtrl,
                      phoneCtrl: phoneCtrl,
                      guestsCtrl: guestsCtrl,
                      instructionsCtrl: instructionsCtrl,
                      priceCtrl: priceCtrl,
                      advanceCtrl: advanceCtrl,
                    ),
                    child: Text(isEditing ? 'Update Event' : 'Create Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      clientNameCtrl.dispose();
      phoneCtrl.dispose();
      guestsCtrl.dispose();
      instructionsCtrl.dispose();
      priceCtrl.dispose();
      advanceCtrl.dispose();
    });
  }

  Future<void> _submitEvent(
    BuildContext ctx, {
    EventModel? existing,
    required DateTime selectedDate,
    required TextEditingController nameCtrl,
    required TextEditingController clientNameCtrl,
    required TextEditingController phoneCtrl,
    required TextEditingController guestsCtrl,
    required TextEditingController instructionsCtrl,
    required TextEditingController priceCtrl,
    required TextEditingController advanceCtrl,
  }) async {
    final permissions = ref.read(routePermissionProvider(AppRoutes.events));
    final isEditing = existing != null;
    final requiredAction =
        isEditing ? PermissionAction.update : PermissionAction.create;
    final hasPermission =
        isEditing ? permissions.canUpdate : permissions.canCreate;
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              PermissionCenter.deniedActionMessage(
                AppRoutes.events,
                requiredAction,
              ),
            ),
          ),
        );
      }
      return;
    }

    final name = nameCtrl.text.trim();
    final clientName = clientNameCtrl.text.trim();
    final clientPhone = phoneCtrl.text.trim();
    final guestCount = int.tryParse(guestsCtrl.text.trim()) ?? 0;

    if (name.isEmpty || clientName.isEmpty || guestCount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              name.isEmpty
                  ? 'Please enter an event name'
                  : clientName.isEmpty
                  ? 'Please enter a client name'
                  : 'Please enter a valid guest count',
            ),
          ),
        );
      }
      return;
    }

    final perPlate = double.tryParse(priceCtrl.text.trim()) ?? 0;
    final advance = double.tryParse(advanceCtrl.text.trim()) ?? 0;

    final event = EventModel(
      id: existing?.id ?? generateSafeId('event'),
      eventName: name,
      clientName: clientName,
      clientPhone: clientPhone,
      eventDate: selectedDate,
      guestCount: guestCount,
      perPlatePrice: perPlate,
      totalAmount: perPlate * guestCount,
      advancePaid: advance,
      specialInstructions: instructionsCtrl.text.trim().isEmpty
          ? null
          : instructionsCtrl.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    try {
      if (isEditing) {
        await EventService.updateEvent(event);
      } else {
        await EventService.createEvent(event);
      }
      if (ctx.mounted) {
        Navigator.of(ctx).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Event updated ✓' : 'Event created ✓'),
          ),
        );
      }
    } on ModulePermissionDenied catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        final denied =
            e.code == 'permission-denied' ||
            (e.message ?? '').toLowerCase().contains(
              'missing or insufficient permissions',
            );
        final message = denied
            ? PermissionCenter.deniedActionMessage(
                AppRoutes.events,
                requiredAction,
              )
            : 'Failed to save event: ${e.message ?? e.code}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save event: $e')));
      }
    }
  }

  Future<void> _deleteEvent(EventModel event) async {
    final permissions = ref.read(routePermissionProvider(AppRoutes.events));
    if (!permissions.canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            PermissionCenter.deniedActionMessage(
              AppRoutes.events,
              PermissionAction.delete,
            ),
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text(
          'Are you sure you want to delete "${event.eventName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await EventService.deleteEvent(event.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event deleted ✓')));
      }
    } on ModulePermissionDenied catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final denied =
          e.code == 'permission-denied' ||
          (e.message ?? '').toLowerCase().contains(
            'missing or insufficient permissions',
          );
      final message = denied
          ? PermissionCenter.deniedActionMessage(
              AppRoutes.events,
              PermissionAction.delete,
            )
          : 'Failed to delete event: ${e.message ?? e.code}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
    }
  }
}
