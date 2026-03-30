/// Reservation card widget for displaying a reservation
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tulasihotels/models/reservation_model.dart';

class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: name + status chip
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reservation.guestName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _StatusChip(status: reservation.status),
                ],
              ),
              const SizedBox(height: 8),

              // Details
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(dateFormat.format(reservation.dateTime)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(timeFormat.format(reservation.dateTime)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Text('${reservation.partySize} guests'),
                  const SizedBox(width: 16),
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 4),
                  Text(reservation.phone),
                ],
              ),

              if (reservation.specialRequests != null &&
                  reservation.specialRequests!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reservation.specialRequests!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Actions
              if (reservation.status == ReservationStatus.pending) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        child: const Text('Cancel'),
                      ),
                    if (onConfirm != null) ...[
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onConfirm,
                        child: const Text('Confirm'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ReservationStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ReservationStatus.pending:
        color = Colors.orange;
      case ReservationStatus.confirmed:
        color = Colors.green;
      case ReservationStatus.seated:
        color = Colors.blue;
      case ReservationStatus.cancelled:
        color = Colors.red;
      case ReservationStatus.noShow:
        color = Colors.red.shade900;
    }

    return Chip(
      label: Text(
        status.displayName,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
