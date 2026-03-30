/// Staff attendance detail panel — full calendar view + records for one staff member
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/services/attendance_service.dart';
import 'package:tulasihotels/models/attendance_model.dart';

class StaffAttendanceDetailScreen extends ConsumerStatefulWidget {
  final String staffId;
  final String staffName;
  final String staffRole;
  final String staffEmoji;

  const StaffAttendanceDetailScreen({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.staffRole,
    required this.staffEmoji,
  });

  @override
  ConsumerState<StaffAttendanceDetailScreen> createState() =>
      _StaffAttendanceDetailScreenState();
}

class _StaffAttendanceDetailScreenState
    extends ConsumerState<StaffAttendanceDetailScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  DateTimeRange? _customRange;

  // Attendance data loaded for the visible month
  List<AttendanceModel> _monthRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _isLoading = true);
    final from = DateTime(_focusedMonth.year, _focusedMonth.month);
    final to = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
      23,
      59,
      59,
    );
    try {
      final records = await AttendanceService.staffAttendanceStream(
        staffId: widget.staffId,
        from: from,
        to: to,
      ).first;
      if (mounted) {
        setState(() {
          _monthRecords = records;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedDay = null;
    });
    _loadMonth();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() {
      _focusedMonth = next;
      _selectedDay = null;
    });
    _loadMonth();
  }

  // Build a map: day-of-month -> list of records
  Map<int, List<AttendanceModel>> get _dayRecords {
    final map = <int, List<AttendanceModel>>{};
    for (final r in _monthRecords) {
      map.putIfAbsent(r.date.day, () => []).add(r);
    }
    return map;
  }

  // Records for selected day, or all month if none selected
  List<AttendanceModel> get _displayRecords {
    if (_selectedDay != null) {
      return _monthRecords
          .where((r) => r.date.day == _selectedDay!.day)
          .toList();
    }
    return _monthRecords;
  }

  // Monthly stats
  double get _totalHours {
    double h = 0;
    for (final r in _monthRecords) {
      h += r.hoursWorked;
    }
    return h;
  }

  int get _totalSessions => _monthRecords.length;

  int get _daysPresent => _dayRecords.keys.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
    ).weekday;
    // Monday = 1, Sunday = 7 — offset so Mon is column 0
    final startOffset = (firstWeekday - 1) % 7;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.staffEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.staffName, style: const TextStyle(fontSize: 16)),
                  Text(
                    widget.staffRole,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Custom date range filter
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Custom Date Range',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange:
                    _customRange ??
                    DateTimeRange(
                      start: DateTime(_focusedMonth.year, _focusedMonth.month),
                      end: DateTime.now(),
                    ),
              );
              if (picked != null) {
                setState(() {
                  _customRange = picked;
                  _focusedMonth = DateTime(
                    picked.start.year,
                    picked.start.month,
                  );
                  _selectedDay = null;
                });
                await _loadMonth();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Monthly stats bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: cs.primaryContainer.withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatBadge(
                  label: 'Days Present',
                  value: '$_daysPresent',
                  color: Colors.green,
                ),
                _StatBadge(
                  label: 'Sessions',
                  value: '$_totalSessions',
                  color: Colors.blue,
                ),
                _StatBadge(
                  label: 'Total Hours',
                  value: _totalHours.toStringAsFixed(1),
                  color: Colors.orange,
                ),
                _StatBadge(
                  label: 'Avg/Day',
                  value: _daysPresent > 0
                      ? (_totalHours / _daysPresent).toStringAsFixed(1)
                      : '0',
                  color: cs.primary,
                ),
              ],
            ),
          ),

          // ── Calendar month nav ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _focusedMonth.year == now.year &&
                          _focusedMonth.month == now.month
                      ? null
                      : _nextMonth,
                ),
              ],
            ),
          ),

          // ── Calendar grid ──
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  // Weekday headers
                  Row(
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 4),

                  // Day cells
                  ...List.generate(((startOffset + daysInMonth) / 7).ceil(), (
                    week,
                  ) {
                    return Row(
                      children: List.generate(7, (col) {
                        final dayIndex = week * 7 + col - startOffset + 1;
                        if (dayIndex < 1 || dayIndex > daysInMonth) {
                          return const Expanded(child: SizedBox(height: 44));
                        }
                        final dayRecords = _dayRecords[dayIndex];
                        final hasRecords =
                            dayRecords != null && dayRecords.isNotEmpty;
                        final isToday =
                            _focusedMonth.year == now.year &&
                            _focusedMonth.month == now.month &&
                            dayIndex == now.day;
                        final isSelected =
                            _selectedDay != null &&
                            _selectedDay!.day == dayIndex;
                        final isFuture = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month,
                          dayIndex,
                        ).isAfter(now);

                        // Total hours this day
                        double dayHours = 0;
                        if (hasRecords) {
                          for (final r in dayRecords) {
                            dayHours += r.hoursWorked;
                          }
                        }

                        return Expanded(
                          child: GestureDetector(
                            onTap: isFuture
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedDay = null;
                                      } else {
                                        _selectedDay = DateTime(
                                          _focusedMonth.year,
                                          _focusedMonth.month,
                                          dayIndex,
                                        );
                                      }
                                    });
                                  },
                            child: Container(
                              height: 44,
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary.withValues(alpha: 0.15)
                                    : hasRecords
                                    ? Colors.green.withValues(alpha: 0.08)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: isToday
                                    ? Border.all(color: cs.primary, width: 1.5)
                                    : isSelected
                                    ? Border.all(color: cs.primary, width: 1.5)
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$dayIndex',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isToday || isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isFuture
                                          ? cs.onSurface.withValues(alpha: 0.25)
                                          : isSelected
                                          ? cs.primary
                                          : null,
                                    ),
                                  ),
                                  if (hasRecords)
                                    Text(
                                      '${dayHours.toStringAsFixed(1)}h',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),

          const Divider(height: 16),

          // ── Records list header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  _selectedDay != null
                      ? '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                      : 'All ${_monthName(_focusedMonth.month)} records',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_displayRecords.length} records',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                if (_selectedDay != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _selectedDay = null),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Records list ──
          Expanded(
            child: _displayRecords.isEmpty
                ? Center(
                    child: Text(
                      _selectedDay != null
                          ? 'No records for this day'
                          : 'No attendance records this month',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _displayRecords.length,
                    itemBuilder: (context, index) {
                      return _DetailRecordCard(
                        record: _displayRecords[index],
                        isOwner: _isOwner,
                        onEdit: () => _showEditDialog(_displayRecords[index]),
                        onDelete: () => _confirmDelete(_displayRecords[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
      // FAB for owner to add manual record
      floatingActionButton: _isOwner
          ? FloatingActionButton(
              onPressed: _showAddRecordDialog,
              tooltip: 'Add Manual Record',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  bool get _isOwner => ref.read(loggedInStaffProvider) == null;

  Future<void> _showAddRecordDialog() async {
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay clockInTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay clockOutTime = const TimeOfDay(hour: 17, minute: 0);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Manual Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
                subtitle: const Text('Date'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.login, color: Colors.green[600]),
                title: Text(clockInTime.format(ctx)),
                subtitle: const Text('Clock In'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: clockInTime,
                  );
                  if (picked != null) {
                    setDialogState(() => clockInTime = picked);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red[400]),
                title: Text(clockOutTime.format(ctx)),
                subtitle: const Text('Clock Out'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: clockOutTime,
                  );
                  if (picked != null) {
                    setDialogState(() => clockOutTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      await AttendanceService.addManualRecord(
        staffId: widget.staffId,
        staffName: widget.staffName,
        date: selectedDate,
        clockIn: DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          clockInTime.hour,
          clockInTime.minute,
        ),
        clockOut: DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          clockOutTime.hour,
          clockOutTime.minute,
        ),
      );
      await _loadMonth();
    }
  }

  Future<void> _showEditDialog(AttendanceModel record) async {
    TimeOfDay clockInTime = TimeOfDay(
      hour: record.clockIn.hour,
      minute: record.clockIn.minute,
    );
    TimeOfDay? clockOutTime = record.clockOut != null
        ? TimeOfDay(
            hour: record.clockOut!.hour,
            minute: record.clockOut!.minute,
          )
        : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.login, color: Colors.green[600]),
                title: Text(clockInTime.format(ctx)),
                subtitle: const Text('Clock In'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: clockInTime,
                  );
                  if (picked != null) {
                    setDialogState(() => clockInTime = picked);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red[400]),
                title: Text(clockOutTime?.format(ctx) ?? 'Not set'),
                subtitle: const Text('Clock Out'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime:
                        clockOutTime ?? const TimeOfDay(hour: 17, minute: 0),
                  );
                  if (picked != null) {
                    setDialogState(() => clockOutTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final date = record.date;
      await AttendanceService.updateRecord(
        record.id,
        clockIn: DateTime(
          date.year,
          date.month,
          date.day,
          clockInTime.hour,
          clockInTime.minute,
        ),
        clockOut: clockOutTime != null
            ? DateTime(
                date.year,
                date.month,
                date.day,
                clockOutTime!.hour,
                clockOutTime!.minute,
              )
            : null,
        status: clockOutTime != null ? AttendanceStatus.clockedOut : null,
      );
      await _loadMonth();
    }
  }

  Future<void> _confirmDelete(AttendanceModel record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
          'Delete attendance record from '
          '${record.date.day}/${record.date.month}/${record.date.year}?\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AttendanceService.deleteRecord(record.id);
      await _loadMonth();
    }
  }

  static String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}

// ─── Stat Badge ────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Detail Record Card ────────────────────────────────────────

class _DetailRecordCard extends StatelessWidget {
  final AttendanceModel record;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DetailRecordCard({
    required this.record,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = record.hoursWorked;
    final isStillIn = record.status == AttendanceStatus.clockedIn;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Date column
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isStillIn
                    ? Colors.green.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${record.date.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isStillIn ? Colors.green : null,
                    ),
                  ),
                  Text(
                    _monthAbbr(record.date.month),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Time details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.login, size: 14, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        'In: ${_formatTime(record.clockIn)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  if (record.clockOut != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.logout, size: 14, color: Colors.red[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Out: ${_formatTime(record.clockOut!)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Duration / status
            if (isStillIn)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              )
            else if (hours > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${hours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

            // Owner edit/delete actions
            if (isOwner) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'delete') onDelete?.call();
                },
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String _monthAbbr(int month) {
    const abbrs = [
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
    return abbrs[month];
  }
}
