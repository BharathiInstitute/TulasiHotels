/// Customer-facing reservation screen (no auth required)
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerReservationScreen extends StatefulWidget {
  final String hotelId;
  const CustomerReservationScreen({super.key, required this.hotelId});

  @override
  State<CustomerReservationScreen> createState() => _CustomerReservationScreenState();
}

class _CustomerReservationScreenState extends State<CustomerReservationScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _guestCount = 2;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  bool _submitted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reservation Confirmed')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_available, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              Text(
                'Reservation Request Sent!',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You will receive a confirmation shortly.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => setState(() => _submitted = false),
                child: const Text('Make Another Reservation'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve a Table'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book Your Table', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),

            // Name
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Phone
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Guest count
            Text('Number of Guests', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filled(
                  onPressed: _guestCount > 1
                      ? () => setState(() => _guestCount--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_guestCount',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton.filled(
                  onPressed: _guestCount < 20
                      ? () => setState(() => _guestCount++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Special Requests (optional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submitReservation,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_available),
                label: const Text('Reserve Table'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReservation() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone number are required')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final reservationDateTime = DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute,
      );

      await FirebaseFirestore.instance
          .collection('users/${widget.hotelId}/reservations')
          .add({
        'customerName': name,
        'customerPhone': phone,
        'dateTime': Timestamp.fromDate(reservationDateTime),
        'guestCount': _guestCount,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'status': 'pending',
        'isCustomerBooking': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit reservation: $e')),
        );
      }
    } finally {
      setState(() => _submitting = false);
    }
  }
}
