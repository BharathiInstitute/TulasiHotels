/// Admin view of a specific staff member's attendance.
/// Same table format as MyAttendanceScreen — DATE | CHECK IN | LOCATION |
/// CHECK OUT | LOCATION | HOURS — but accessible by admin for any staff.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/services/attendance_service.dart';
import 'package:tulasihotels/models/attendance_model.dart';

class AdminStaffAttendancePanel extends ConsumerStatefulWidget {
  final String staffId;
  final String staffName;
  final String? staffEmail;
  final String? staffRole;

  const AdminStaffAttendancePanel({
    super.key,
    required this.staffId,
    required this.staffName,
    this.staffEmail,
    this.staffRole,
  });

  @override
  ConsumerState<AdminStaffAttendancePanel> createState() =>
      _AdminStaffAttendancePanelState();
}

class _AdminStaffAttendancePanelState
    extends ConsumerState<AdminStaffAttendancePanel> {
  late DateTimeRange _range;
  bool _isClockingIn = false;
  bool _isClockingOut = false;

  // Tracked from stream so AppBar can show correct button state
  bool _isClockedIn = false;
  String? _activeRecordId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.staffName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (widget.staffEmail != null)
              Text(
                widget.staffEmail!,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          // Clock In / Clock Out buttons — left of role chip
          if (_isClockingIn)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (!_isClockedIn)
            TextButton.icon(
              onPressed: _clockIn,
              icon: const Icon(Icons.login, size: 16),
              label: const Text('Clock In'),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            )
          else if (_isClockingOut)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => _clockOut(_activeRecordId),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Clock Out'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          if (widget.staffRole != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Chip(
                label: Text(
                  widget.staffRole!,
                  style: const TextStyle(fontSize: 11),
                ),
                visualDensity: VisualDensity.compact,
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: AttendanceService.staffAttendanceStream(
          staffId: widget.staffId,
          from: _range.start,
          to: _range.end,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!;
          final today = DateTime(now.year, now.month, now.day);
          final todayRecords = records
              .where(
                (r) =>
                    r.date.year == today.year &&
                    r.date.month == today.month &&
                    r.date.day == today.day,
              )
              .toList();
          final activeRecords = todayRecords
              .where((r) => r.clockOut == null)
              .toList();
          final isClockedIn = activeRecords.isNotEmpty;
          final currentRecord = isClockedIn ? activeRecords.first : null;

          // Sync clock state to widget state so AppBar can react
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                (_isClockedIn != isClockedIn ||
                    _activeRecordId != currentRecord?.id)) {
              setState(() {
                _isClockedIn = isClockedIn;
                _activeRecordId = currentRecord?.id;
              });
            }
          });

          // Month total
          double totalMinutes = 0;
          for (final r in records) {
            if (r.clockOut != null) {
              totalMinutes += r.clockOut!.difference(r.clockIn).inMinutes;
            } else if (r.status == AttendanceStatus.clockedIn) {
              totalMinutes += now.difference(r.clockIn).inMinutes;
            }
          }
          final monthHours = (totalMinutes / 60).floor();
          final monthMins = (totalMinutes % 60).floor();

          return Column(
            children: [
              // ── Header bar ──────────────────────────────────
              _buildHeaderBar(
                context,
                now: now,
                isClockedIn: isClockedIn,
                currentRecord: currentRecord,
                monthHours: monthHours,
                monthMins: monthMins,
              ),

              // ── Date range filter ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _DateChip(
                      label: 'From: ${_fmtDate(_range.start)}',
                      onTap: () => _pickRange(context),
                    ),
                    const SizedBox(width: 12),
                    _DateChip(
                      label: 'To: ${_fmtDate(_range.end)}',
                      onTap: () => _pickRange(context),
                    ),
                  ],
                ),
              ),

              // ── Table header ─────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    _TH('DATE', flex: 3),
                    _TH('CHECK IN', flex: 2),
                    _TH('LOCATION', flex: 2),
                    _TH('CHECK OUT', flex: 2),
                    _TH('LOCATION', flex: 2),
                    _TH('HOURS', flex: 2),
                  ],
                ),
              ),

              // ── Table rows ───────────────────────────────────
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Text(
                          'No attendance records for this period',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: records.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                        itemBuilder: (_, i) =>
                            _AttendanceRow(record: records[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderBar(
    BuildContext context, {
    required DateTime now,
    required bool isClockedIn,
    required AttendanceModel? currentRecord,
    required int monthHours,
    required int monthMins,
  }) {
    final cs = Theme.of(context).colorScheme;

    String inOfficeDuration = '';
    if (currentRecord != null) {
      final diff = now.difference(currentRecord.clockIn);
      inOfficeDuration = diff.inHours > 0
          ? '${diff.inHours}h ${diff.inMinutes % 60}m'
          : '${diff.inMinutes}m';
    }
    final isInsideGeofence = currentRecord?.clockInInside == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: _fmtDay(now),
                  color: cs.onSurface,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.access_time_filled,
                  label:
                      'Month: $monthHours:${monthMins.toString().padLeft(2, '0')} hrs',
                  color: Colors.blue,
                  isBold: true,
                ),
                if (isClockedIn) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.location_on,
                    label: isInsideGeofence
                        ? 'Inside ($inOfficeDuration)'
                        : 'Outside ($inOfficeDuration)',
                    color: isInsideGeofence ? Colors.green : Colors.orange,
                    isBold: true,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Admin Clock In / Clock Out buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: (isClockedIn || _isClockingIn) ? null : _clockIn,
                icon: _isClockingIn
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login, size: 16),
                label: const Text('Clock In'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.outline),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: (!isClockedIn || _isClockingOut)
                    ? null
                    : () => _clockOut(currentRecord?.id),
                icon: _isClockingOut
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout, size: 16),
                label: const Text('Clock Out'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clockIn() async {
    setState(() => _isClockingIn = true);
    try {
      await AttendanceService.clockIn(
        staffId: widget.staffId,
        staffName: widget.staffName,
        source: ClockSource.admin,
        captureLocation: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.staffName} clocked in'),
            backgroundColor: Colors.green,
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
      if (mounted) setState(() => _isClockingIn = false);
    }
  }

  Future<void> _clockOut(String? recordId) async {
    setState(() => _isClockingOut = true);
    try {
      await AttendanceService.clockOut(
        widget.staffId,
        recordId: recordId,
        source: ClockSource.admin,
        captureLocation: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.staffName} clocked out'),
            backgroundColor: Colors.orange,
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
      if (mounted) setState(() => _isClockingOut = false);
    }
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  static String _fmtDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';
  }

  static String _fmtDay(DateTime dt) {
    const weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[dt.weekday]}, ${dt.day} ${months[dt.month]}';
  }
}

// ── Table Header Cell ──────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final int flex;

  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Date Chip ──────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

// ── Info Chip ──────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isBold;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attendance Table Row ───────────────────────────────────────

class _AttendanceRow extends StatelessWidget {
  final AttendanceModel record;

  const _AttendanceRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isStillIn = record.status == AttendanceStatus.clockedIn;

    String hoursStr;
    if (record.clockOut != null) {
      final diff = record.clockOut!.difference(record.clockIn);
      hoursStr =
          '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')} hrs';
    } else {
      final diff = DateTime.now().difference(record.clockIn);
      hoursStr =
          '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')} hrs';
    }

    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '${record.date.day.toString().padLeft(2, '0')} ${months[record.date.month]} ${record.date.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // DATE
          Expanded(
            flex: 3,
            child: Text(
              dateStr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          // CHECK IN
          Expanded(
            flex: 2,
            child: Text(
              _fmtTime(record.clockIn),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          // CHECK IN LOCATION
          Expanded(
            flex: 2,
            child: _LocBadge(
              isInside: record.clockInInside,
              hasLoc: record.hasClockInLocation,
            ),
          ),
          // CHECK OUT
          Expanded(
            flex: 2,
            child: Text(
              record.clockOut != null ? _fmtTime(record.clockOut!) : '-',
              style: TextStyle(
                fontSize: 13,
                color: record.clockOut == null ? cs.onSurfaceVariant : null,
              ),
            ),
          ),
          // CHECK OUT LOCATION
          Expanded(
            flex: 2,
            child: record.clockOut != null
                ? _LocBadge(
                    isInside: record.clockOutInside,
                    hasLoc: record.hasClockOutLocation,
                  )
                : const SizedBox.shrink(),
          ),
          // HOURS
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  hoursStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isStillIn ? Colors.green[700] : null,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.expand_more, size: 18, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// ── Location Badge ─────────────────────────────────────────────

class _LocBadge extends StatelessWidget {
  final bool? isInside;
  final bool hasLoc;

  const _LocBadge({required this.isInside, required this.hasLoc});

  @override
  Widget build(BuildContext context) {
    if (!hasLoc) {
      return Text(
        '-',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    final inside = isInside ?? false;
    return Text(
      inside ? 'Inside' : 'Outside',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: inside ? Colors.green[700] : Colors.orange[700],
      ),
    );
  }
}
