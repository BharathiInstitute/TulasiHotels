/// Attendance tracking screen — current user clock in/out + records
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/staff/services/attendance_service.dart';
import 'package:tulasihotels/models/attendance_model.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: const _AttendanceBody(),
    );
  }
}

// ─── Body ──────────────────────────────────────────────────────

class _AttendanceBody extends ConsumerStatefulWidget {
  const _AttendanceBody();

  @override
  ConsumerState<_AttendanceBody> createState() => _AttendanceBodyState();
}

class _AttendanceBodyState extends ConsumerState<_AttendanceBody> {
  late DateTimeRange _range;

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
    final authState = ref.watch(authNotifierProvider);
    final uid = authState.firebaseUser?.uid;
    final userName =
        authState.user != null && authState.user!.ownerName.isNotEmpty
        ? authState.user!.ownerName
        : authState.firebaseUser?.email ?? 'User';
    final userEmail = authState.firebaseUser?.email ?? '';

    if (uid == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<List<AttendanceModel>>(
      stream: AttendanceService.staffAttendanceStream(
        staffId: uid,
        from: _range.start,
        to: _range.end,
      ),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final cs = Theme.of(context).colorScheme;

        // Today's record
        final today = DateTime.now();
        final todayRecords = records.where((r) {
          return r.date.year == today.year &&
              r.date.month == today.month &&
              r.date.day == today.day;
        }).toList();

        final isClockedIn = todayRecords.any(
          (r) => r.status == AttendanceStatus.clockedIn,
        );
        final todayRecord = todayRecords.isNotEmpty ? todayRecords.first : null;

        // Total hours this period
        double totalHours = 0;
        for (final r in records) {
          totalHours += r.hoursWorked;
        }
        final presentDays = records
            .map((r) => '${r.date.year}-${r.date.month}-${r.date.day}')
            .toSet()
            .length;

        return Scrollbar(
          thumbVisibility: true,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── User clock card ──────────────────────────────────
              _UserClockCard(
                userName: userName,
                userEmail: userEmail,
                isClockedIn: isClockedIn,
                todayRecord: todayRecord,
                onClockIn: () async {
                  await AttendanceService.clockIn(
                    staffId: uid,
                    staffName: userName,
                    source: ClockSource.admin,
                    captureLocation: false,
                  );
                },
                onClockOut: () async {
                  await AttendanceService.clockOut(
                    uid,
                    recordId: todayRecord?.id,
                    source: ClockSource.admin,
                    captureLocation: false,
                  );
                },
              ),

              const SizedBox(height: 12),

              // ── Month summary chips + date range picker ──────────
              Row(
                children: [
                  _SummaryChip(
                    icon: Icons.calendar_today,
                    label: 'Days',
                    value: '$presentDays',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    icon: Icons.schedule,
                    label: 'Hours',
                    value: totalHours.toStringAsFixed(1),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    icon: Icons.receipt_long,
                    label: 'Records',
                    value: '${records.length}',
                    color: Colors.orange,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(now.year, now.month + 1, 0),
                        initialDateRange: _range,
                      );
                      if (picked != null) setState(() => _range = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.date_range, size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${_fmt(_range.start)} – ${_fmt(_range.end)}',
                            style: TextStyle(fontSize: 11, color: cs.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Records list ─────────────────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting &&
                  records.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (records.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No attendance records for this period',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                )
              else ...[
                ...() {
                  final dayMap = <String, List<AttendanceModel>>{};
                  for (final r in records) {
                    final key =
                        '${r.date.year}-'
                        '${r.date.month.toString().padLeft(2, '0')}-'
                        '${r.date.day.toString().padLeft(2, '0')}';
                    dayMap.putIfAbsent(key, () => []).add(r);
                  }
                  final sortedDays = dayMap.keys.toList()
                    ..sort((a, b) => b.compareTo(a));
                  return sortedDays.map(
                    (day) => _DayRecord(day: day, records: dayMap[day]!),
                  );
                }(),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}';
}

// ─── User Clock Card ───────────────────────────────────────────

class _UserClockCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final bool isClockedIn;
  final AttendanceModel? todayRecord;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;

  const _UserClockCard({
    required this.userName,
    required this.userEmail,
    required this.isClockedIn,
    required this.todayRecord,
    required this.onClockIn,
    required this.onClockOut,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final dateStr =
        '${_dayName(now.weekday)}, ${now.day} ${_monthName(now.month)} ${now.year}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (userEmail.isNotEmpty)
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isClockedIn ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isClockedIn ? 'Active' : 'Off',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isClockedIn ? Colors.green : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (todayRecord != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.login, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    Text(
                      'In: ${_fmtTime(todayRecord!.clockIn)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (todayRecord!.clockOut != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.logout, size: 14, color: Colors.red[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Out: ${_fmtTime(todayRecord!.clockOut!)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${todayRecord!.hoursWorked.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isClockedIn ? onClockOut : onClockIn,
                icon: Icon(isClockedIn ? Icons.logout : Icons.login, size: 20),
                label: Text(
                  isClockedIn ? 'Clock Out' : 'Clock In',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: isClockedIn ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  static String _dayName(int w) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
  static String _monthName(int m) => [
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
  ][m - 1];
}

// ─── Summary Chip ──────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ─── Day Record ────────────────────────────────────────────────

class _DayRecord extends StatelessWidget {
  final String day; // YYYY-MM-DD
  final List<AttendanceModel> records;

  const _DayRecord({required this.day, required this.records});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final parts = day.split('-');
    final dt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final dayLabel =
        '${_dayName(dt.weekday)}, ${dt.day} ${_monthName(dt.month)}';

    double dayHours = 0;
    for (final r in records) {
      dayHours += r.hoursWorked;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  dayLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${dayHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          ...records.map(
            (r) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  Icon(Icons.login, size: 14, color: Colors.green[700]),
                  const SizedBox(width: 6),
                  Text(
                    _fmtTime(r.clockIn),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (r.clockOut != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.logout, size: 14, color: Colors.red[700]),
                    const SizedBox(width: 6),
                    Text(
                      _fmtTime(r.clockOut!),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (r.clockOut != null)
                    Text(
                      '${r.hoursWorked.toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  static String _dayName(int w) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
  static String _monthName(int m) => [
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
  ][m - 1];
}
