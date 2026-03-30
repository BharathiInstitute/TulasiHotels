/// Event / banquet management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/compliance/providers/compliance_provider.dart';
import 'package:tulasihotels/features/compliance/services/event_service.dart';
import 'package:tulasihotels/models/event_model.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _nameCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _guestsCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  bool _showAll = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientNameCtrl.dispose();
    _phoneCtrl.dispose();
    _guestsCtrl.dispose();
    _instructionsCtrl.dispose();
    _priceCtrl.dispose();
    _advanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = _showAll
        ? ref.watch(allEventsProvider)
        : ref.watch(upcomingEventsProvider);

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
        onPressed: _showEventForm,
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

  void _showEventForm() {
    _nameCtrl.clear();
    _clientNameCtrl.clear();
    _phoneCtrl.clear();
    _guestsCtrl.clear();
    _instructionsCtrl.clear();
    _priceCtrl.clear();
    _advanceCtrl.clear();
    _date = DateTime.now().add(const Duration(days: 7));

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
                Text('New Event', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
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
                      initialDate: _date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setSheetState(() => _date = picked);
                  },
                  child: Text(
                    'Date: ${_date.day}/${_date.month}/${_date.year}',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clientNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Client Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _guestsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Guest Count',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Per Plate Price (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _advanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Advance Paid (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _instructionsCtrl,
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
                    onPressed: () => _submitEvent(ctx),
                    child: const Text('Create Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitEvent(BuildContext ctx) async {
    final name = _nameCtrl.text.trim();
    final clientName = _clientNameCtrl.text.trim();
    final clientPhone = _phoneCtrl.text.trim();
    final guestCount = int.tryParse(_guestsCtrl.text.trim()) ?? 0;
    if (name.isEmpty || clientName.isEmpty) return;

    final perPlate = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final advance = double.tryParse(_advanceCtrl.text.trim()) ?? 0;

    final event = EventModel(
      id: generateSafeId('event'),
      eventName: name,
      clientName: clientName,
      clientPhone: clientPhone,
      eventDate: _date,
      guestCount: guestCount,
      perPlatePrice: perPlate,
      totalAmount: perPlate * guestCount,
      advancePaid: advance,
      specialInstructions: _instructionsCtrl.text.trim().isEmpty
          ? null
          : _instructionsCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await EventService.createEvent(event);
      if (ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Event created ✓')));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text('Failed to create event: $e')));
      }
    }
  }
}
