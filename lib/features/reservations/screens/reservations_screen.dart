/// Reservations management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/permissions/widgets/permission_denied_view.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/features/reservations/providers/reservation_provider.dart';
import 'package:tulasihotels/features/reservations/services/reservation_service.dart';
import 'package:tulasihotels/router/app_router.dart';
import 'package:tulasihotels/models/reservation_model.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reservationPermissions = ref.watch(
      routePermissionProvider(AppRoutes.reservations),
    );
    final todayAsync = ref.watch(todayReservationsProvider);
    final upcomingAsync = ref.watch(upcomingReservationsProvider);
    final theme = Theme.of(context);

    if (!reservationPermissions.isResolved) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!reservationPermissions.canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reservations')),
        body: PermissionDeniedView(
          message: PermissionCenter.deniedViewMessage(AppRoutes.reservations),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: reservationPermissions.canCreate
            ? () => _showReservationForm(context)
            : null,
        icon: const Icon(Icons.add),
        label: const Text('New Reservation'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Today tab ──────────────────────────────────────────────────
          todayAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (reservations) => reservations.isEmpty
                ? const Center(child: Text('No reservations for today'))
                : _ReservationList(
                    reservations: reservations,
                    theme: theme,
                    showDate: false,
                    onAction: _handleAction,
                  ),
          ),
          // ── Upcoming tab (tomorrow onward) ─────────────────────────────
          upcomingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (all) {
              // Exclude today — show only tomorrow+
              final today = DateTime.now();
              final startOfTomorrow = DateTime(
                today.year,
                today.month,
                today.day,
              ).add(const Duration(days: 1));
              final upcoming = all
                  .where((r) => !r.dateTime.isBefore(startOfTomorrow))
                  .toList();
              return upcoming.isEmpty
                  ? const Center(child: Text('No upcoming reservations'))
                  : _ReservationList(
                      reservations: upcoming,
                      theme: theme,
                      showDate: true,
                      onAction: _handleAction,
                    );
            },
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, String reservationId) {
    final permissions = ref.read(routePermissionProvider(AppRoutes.reservations));
    switch (action) {
      case 'confirm':
        if (!permissions.canUpdate) return;
        ReservationService.confirmReservation(reservationId, permissions);
        break;
      case 'cancel':
        if (!permissions.canDelete) return;
        ReservationService.deleteReservation(reservationId, permissions);
        break;
      case 'noshow':
        if (!permissions.canUpdate) return;
        ReservationService.markNoShow(reservationId, permissions);
        break;
    }
  }

  void _showReservationForm(BuildContext context) {
    final permissions = ref.read(routePermissionProvider(AppRoutes.reservations));
    if (!permissions.canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            PermissionCenter.deniedActionMessage(
              AppRoutes.reservations,
              PermissionAction.create,
            ),
          ),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final partySizeCtrl = TextEditingController(text: '2');
    var selectedDate = DateTime.now();
    var selectedTime = TimeOfDay.now();
    var isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'New Reservation',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Guest Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: partySizeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Party Size',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                            );
                            if (date != null) {
                              setModalState(() => selectedDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setModalState(() => selectedTime = time);
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            final dateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            final reservation = ReservationModel(
                              id: generateSafeId('res'),
                              guestName: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              partySize: int.tryParse(partySizeCtrl.text) ?? 2,
                              dateTime: dateTime,
                              createdAt: DateTime.now(),
                            );
                            try {
                              await ReservationService.createReservation(
                                reservation,
                                permissions,
                              );
                              if (context.mounted) Navigator.of(context).pop();
                            } finally {
                              if (context.mounted) {
                                setModalState(() => isSubmitting = false);
                              }
                            }
                          },
                    child: Text(
                      isSubmitting ? 'Creating...' : 'Create Reservation',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Shared reservation list widget ──────────────────────────────────────────

class _ReservationList extends StatelessWidget {
  const _ReservationList({
    required this.reservations,
    required this.theme,
    required this.showDate,
    required this.onAction,
  });

  final List<ReservationModel> reservations;
  final ThemeData theme;
  final bool showDate;
  final void Function(String action, String reservationId) onAction;

  Color _statusColor(ReservationStatus status) {
    return switch (status) {
      ReservationStatus.pending => theme.colorScheme.tertiaryContainer,
      ReservationStatus.confirmed => theme.colorScheme.primaryContainer,
      ReservationStatus.seated => theme.colorScheme.secondaryContainer,
      ReservationStatus.cancelled => theme.colorScheme.errorContainer,
      ReservationStatus.noShow => theme.colorScheme.surfaceContainerHighest,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final res = reservations[index];
        final timeStr = TimeOfDay.fromDateTime(res.dateTime).format(context);
        final dateStr = showDate
            ? '${res.dateTime.day}/${res.dateTime.month}/${res.dateTime.year} • $timeStr'
            : timeStr;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(res.status),
              child: Text(res.status.emoji),
            ),
            title: Text(res.guestName),
            subtitle: Text('${res.partySize} guests • $dateStr • ${res.phone}'),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => onAction(action, res.id),
              itemBuilder: (ctx) => [
                if (res.status == ReservationStatus.pending)
                  const PopupMenuItem(value: 'confirm', child: Text('Confirm')),
                if (res.status == ReservationStatus.confirmed)
                  const PopupMenuItem(
                    value: 'seat',
                    child: Text('Seat Guests'),
                  ),
                const PopupMenuItem(value: 'cancel', child: Text('Delete')),
                const PopupMenuItem(value: 'noshow', child: Text('No-Show')),
              ],
            ),
          ),
        );
      },
    );
  }
}
