/// Staff self-service clock-in/out widget — prominent card for staff home view
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/services/attendance_service.dart';
import 'package:tulasihotels/features/staff/providers/attendance_provider.dart';
import 'package:tulasihotels/models/attendance_model.dart';

class StaffClockWidget extends ConsumerStatefulWidget {
  const StaffClockWidget({super.key});

  @override
  ConsumerState<StaffClockWidget> createState() => _StaffClockWidgetState();
}

class _StaffClockWidgetState extends ConsumerState<StaffClockWidget> {
  Timer? _timer;
  bool _isActioning = false;

  @override
  void initState() {
    super.initState();
    // Update elapsed time every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(loggedInStaffProvider);
    if (staff == null) return const SizedBox.shrink();

    final todayAsync = ref.watch(todayAttendanceProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return todayAsync.when(
      data: (records) {
        // Find this staff's records for today
        final myRecords = records.where((r) => r.staffId == staff.id).toList();
        final activeRecord = myRecords
            .where((r) => r.status == AttendanceStatus.clockedIn)
            .toList();
        final isClockedIn = activeRecord.isNotEmpty;
        final currentRecord = isClockedIn ? activeRecord.first : null;

        // Calculate today's total time
        int todayMinutes = 0;
        for (final r in myRecords) {
          if (r.status == AttendanceStatus.clockedOut) {
            todayMinutes += r.workedMinutes;
          } else if (r.status == AttendanceStatus.clockedIn) {
            // Still active — calculate running time
            todayMinutes += DateTime.now().difference(r.clockIn).inMinutes;
          }
        }

        // Elapsed string for current session
        String elapsed = '';
        if (currentRecord != null) {
          final diff = DateTime.now().difference(currentRecord.clockIn);
          final h = diff.inHours;
          final m = diff.inMinutes % 60;
          elapsed = h > 0 ? '${h}h ${m}m' : '${m}m';
        }

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isClockedIn
                    ? [
                        Colors.green.withValues(alpha: 0.08),
                        Colors.green.withValues(alpha: 0.02),
                      ]
                    : [
                        cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        cs.surface,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: status + today's hours
                Row(
                  children: [
                    // Status dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isClockedIn ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isClockedIn ? 'Clocked In' : 'Not Clocked In',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isClockedIn
                            ? Colors.green[700]
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // Today's total
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Today: ${_formatMinutes(todayMinutes)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Timer / session info
                if (isClockedIn && currentRecord != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Since ${_formatTime(currentRecord.clockIn)} · $elapsed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  // Location tag
                  if (currentRecord.clockInAddress != null &&
                      currentRecord.clockInAddress!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            currentRecord.clockInAddress!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],

                // Sessions summary
                if (myRecords.length > 1 ||
                    (myRecords.length == 1 && !isClockedIn)) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${myRecords.length} session${myRecords.length != 1 ? 's' : ''} today',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],

                const SizedBox(height: 14),

                // Big clock-in/out button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isActioning
                        ? null
                        : () => _handleClockAction(
                            isClockedIn: isClockedIn,
                            currentRecordId: currentRecord?.id,
                            staffId: staff.id,
                            staffName: staff.name,
                            todayMinutes: todayMinutes,
                          ),
                    icon: _isActioning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isClockedIn ? Icons.logout : Icons.login),
                    label: Text(
                      isClockedIn ? 'Clock Out' : 'Clock In',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isClockedIn
                          ? Colors.red[600]
                          : Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _handleClockAction({
    required bool isClockedIn,
    String? currentRecordId,
    required String staffId,
    required String staffName,
    required int todayMinutes,
  }) async {
    if (isClockedIn) {
      // Confirm clock-out
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Clock Out'),
          content: Text(
            'You have worked ${_formatMinutes(todayMinutes)} today.\n'
            'Are you sure you want to clock out?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clock Out'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isActioning = true);
    try {
      String message;
      if (isClockedIn) {
        await AttendanceService.clockOut(staffId, recordId: currentRecordId);
        message = 'Clocked out successfully';
      } else {
        final record = await AttendanceService.clockIn(
          staffId: staffId,
          staffName: staffName,
        );
        final addr = record.clockInAddress;
        message = addr != null && addr.isNotEmpty
            ? 'Clocked in · $addr'
            : 'Clocked in at ${_formatTime(record.clockIn)}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isClockedIn ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String _formatMinutes(int totalMinutes) {
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
