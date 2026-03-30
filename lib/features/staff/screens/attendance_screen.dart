/// Attendance tracking screen — today's attendance + history
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/providers/attendance_provider.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/services/attendance_service.dart';
import 'package:tulasihotels/features/staff/screens/staff_attendance_detail_screen.dart';
import 'package:tulasihotels/models/attendance_model.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Attendance'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Today', icon: Icon(Icons.today)),
              Tab(text: 'History', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: const TabBarView(children: [_TodayTab(), _HistoryTab()]),
      ),
    );
  }
}

// ─── Today Tab ─────────────────────────────────────────────────

class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(todayAttendanceProvider);
    final activeStaffAsync = ref.watch(activeStaffStreamProvider);

    return attendanceAsync.when(
      data: (records) {
        return activeStaffAsync.when(
          data: (allStaff) {
            // Build a map of staffId -> today's record
            final clockedInIds = <String>{};
            for (final r in records) {
              if (r.status == AttendanceStatus.clockedIn) {
                clockedInIds.add(r.staffId);
              }
            }

            // Calculate total hours today
            double totalHoursToday = 0;
            for (final r in records) {
              if (r.status == AttendanceStatus.clockedOut) {
                totalHoursToday += r.hoursWorked;
              } else if (r.status == AttendanceStatus.clockedIn) {
                totalHoursToday +=
                    DateTime.now().difference(r.clockIn).inMinutes / 60.0;
              }
            }

            return Column(
              children: [
                // Summary card
                _TodaySummary(
                  total: allStaff.length,
                  present: records.map((r) => r.staffId).toSet().length,
                  clockedIn: clockedInIds.length,
                  totalHours: totalHoursToday,
                ),

                // Weekly insights comparison
                const _WeeklyInsights(),

                const Divider(height: 1),

                // Staff quick clock-in/out buttons
                Expanded(
                  child: allStaff.isEmpty
                      ? const Center(child: Text('No active staff members'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: allStaff.length,
                          itemBuilder: (context, index) {
                            final staff = allStaff[index];
                            final isClockedIn = clockedInIds.contains(staff.id);
                            final record = records
                                .where((r) => r.staffId == staff.id)
                                .toList();
                            final lastRecord = record.isNotEmpty
                                ? record.first
                                : null;

                            return _StaffAttendanceCard(
                              name: staff.name,
                              role: staff.role.displayName,
                              emoji: staff.role.emoji,
                              isClockedIn: isClockedIn,
                              lastRecord: lastRecord,
                              onClockIn: () async {
                                await AttendanceService.clockIn(
                                  staffId: staff.id,
                                  staffName: staff.name,
                                );
                              },
                              onClockOut: () async {
                                await AttendanceService.clockOut(
                                  staff.id,
                                  recordId: lastRecord?.id,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final int total;
  final int present;
  final int clockedIn;
  final double totalHours;

  const _TodaySummary({
    required this.total,
    required this.present,
    required this.clockedIn,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final absent = total - present;
    final attendanceRate = total > 0
        ? (present / total * 100).toStringAsFixed(0)
        : '0';
    final avgHoursPerStaff = present > 0
        ? (totalHours / present).toStringAsFixed(1)
        : '0';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              cs.primaryContainer.withValues(alpha: 0.4),
              cs.secondaryContainer.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title row
            Row(
              children: [
                Icon(Icons.dashboard_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  "Today's Overview",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const Spacer(),
                // Attendance rate badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _rateColor(
                      int.parse(attendanceRate),
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$attendanceRate% attendance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _rateColor(int.parse(attendanceRate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Main stats row
            Row(
              children: [
                _StatTile(
                  icon: Icons.people_alt_rounded,
                  label: 'Total',
                  value: '$total',
                  color: cs.primary,
                ),
                _StatTile(
                  icon: Icons.check_circle_rounded,
                  label: 'Present',
                  value: '$present',
                  color: Colors.green,
                ),
                _StatTile(
                  icon: Icons.circle,
                  label: 'Active',
                  value: '$clockedIn',
                  color: Colors.blue,
                ),
                _StatTile(
                  icon: Icons.cancel_rounded,
                  label: 'Absent',
                  value: '$absent',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hours summary row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Total: ${totalHours.toStringAsFixed(1)}h',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[800],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Avg: ${avgHoursPerStaff}h/staff',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _rateColor(int rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
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
      ),
    );
  }
}

// ─── Weekly Insights ───────────────────────────────────────────

class _WeeklyInsights extends ConsumerWidget {
  const _WeeklyInsights();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thisWeekAsync = ref.watch(thisWeekAttendanceProvider);
    final lastWeekAsync = ref.watch(lastWeekAttendanceProvider);

    return thisWeekAsync.when(
      data: (thisWeek) {
        return lastWeekAsync.when(
          data: (lastWeek) {
            // This week stats
            final twStaff = thisWeek.map((r) => r.staffId).toSet().length;
            double twHours = 0;
            for (final r in thisWeek) {
              twHours += r.hoursWorked;
            }
            final twDays = thisWeek
                .map((r) => '${r.date.year}-${r.date.month}-${r.date.day}')
                .toSet()
                .length;

            // Last week stats
            final lwStaff = lastWeek.map((r) => r.staffId).toSet().length;
            double lwHours = 0;
            for (final r in lastWeek) {
              lwHours += r.hoursWorked;
            }
            final lwDays = lastWeek
                .map((r) => '${r.date.year}-${r.date.month}-${r.date.day}')
                .toSet()
                .length;

            // Don't render if no data at all
            if (thisWeek.isEmpty && lastWeek.isEmpty) {
              return const SizedBox.shrink();
            }

            return _WeekComparisonCard(
              thisWeekSessions: thisWeek.length,
              lastWeekSessions: lastWeek.length,
              thisWeekHours: twHours,
              lastWeekHours: lwHours,
              thisWeekStaff: twStaff,
              lastWeekStaff: lwStaff,
              thisWeekDays: twDays,
              lastWeekDays: lwDays,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _WeekComparisonCard extends StatelessWidget {
  final int thisWeekSessions;
  final int lastWeekSessions;
  final double thisWeekHours;
  final double lastWeekHours;
  final int thisWeekStaff;
  final int lastWeekStaff;
  final int thisWeekDays;
  final int lastWeekDays;

  const _WeekComparisonCard({
    required this.thisWeekSessions,
    required this.lastWeekSessions,
    required this.thisWeekHours,
    required this.lastWeekHours,
    required this.thisWeekStaff,
    required this.lastWeekStaff,
    required this.thisWeekDays,
    required this.lastWeekDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Weekly Comparison',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CompareColumn(
                    label: 'This Week',
                    sessions: thisWeekSessions,
                    hours: thisWeekHours,
                    staff: thisWeekStaff,
                    isCurrent: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
                Expanded(
                  child: _CompareColumn(
                    label: 'Last Week',
                    sessions: lastWeekSessions,
                    hours: lastWeekHours,
                    staff: lastWeekStaff,
                    isCurrent: false,
                  ),
                ),
              ],
            ),
            // Trend indicator
            if (lastWeekHours > 0 || thisWeekHours > 0) ...[
              const SizedBox(height: 8),
              _TrendRow(
                thisWeekHours: thisWeekHours,
                lastWeekHours: lastWeekHours,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompareColumn extends StatelessWidget {
  final String label;
  final int sessions;
  final double hours;
  final int staff;
  final bool isCurrent;

  const _CompareColumn({
    required this.label,
    required this.sessions,
    required this.hours,
    required this.staff,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isCurrent ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${hours.toStringAsFixed(1)}h',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isCurrent ? Colors.orange[700] : cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$sessions sessions · $staff staff',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _TrendRow extends StatelessWidget {
  final double thisWeekHours;
  final double lastWeekHours;

  const _TrendRow({required this.thisWeekHours, required this.lastWeekHours});

  @override
  Widget build(BuildContext context) {
    final diff = thisWeekHours - lastWeekHours;
    final pct = lastWeekHours > 0
        ? (diff / lastWeekHours * 100).toStringAsFixed(0)
        : '—';
    final isUp = diff > 0;
    final isFlat = diff.abs() < 0.1;
    final color = isFlat
        ? Colors.grey
        : isUp
        ? Colors.green
        : Colors.red;
    final icon = isFlat
        ? Icons.trending_flat
        : isUp
        ? Icons.trending_up
        : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            isFlat
                ? 'Consistent with last week'
                : '${isUp ? '+' : ''}${diff.toStringAsFixed(1)}h ($pct%) vs last week',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffAttendanceCard extends StatelessWidget {
  final String name;
  final String role;
  final String emoji;
  final bool isClockedIn;
  final AttendanceModel? lastRecord;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;

  const _StaffAttendanceCard({
    required this.name,
    required this.role,
    required this.emoji,
    required this.isClockedIn,
    required this.lastRecord,
    required this.onClockIn,
    required this.onClockOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isClockedIn ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),

            // Staff info
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),

            // Name and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (lastRecord != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      isClockedIn
                          ? 'In: ${_formatTime(lastRecord!.clockIn)}'
                          : lastRecord!.clockOut != null
                          ? 'In: ${_formatTime(lastRecord!.clockIn)} | Out: ${_formatTime(lastRecord!.clockOut!)}'
                          : '',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Clock in/out button
            FilledButton.tonalIcon(
              onPressed: isClockedIn ? onClockOut : onClockIn,
              icon: Icon(isClockedIn ? Icons.logout : Icons.login, size: 18),
              label: Text(
                isClockedIn ? 'Clock Out' : 'Clock In',
                style: const TextStyle(fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isClockedIn
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                foregroundColor: isClockedIn ? Colors.red : Colors.green,
              ),
            ),
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
}

// ─── History Tab ───────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attendanceHistoryProvider);
    final staffFilter = ref.watch(attendanceStaffFilterProvider);
    final activeStaffAsync = ref.watch(activeStaffStreamProvider);

    return Column(
      children: [
        // Staff filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: activeStaffAsync.when(
            data: (allStaff) {
              return SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // "All Staff" chip
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: const Text('All Staff'),
                        selected: staffFilter == null,
                        onSelected: (_) {
                          ref
                                  .read(attendanceStaffFilterProvider.notifier)
                                  .state =
                              null;
                        },
                      ),
                    ),
                    // Individual staff chips
                    for (final staff in allStaff)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          avatar: Text(
                            staff.role.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          label: Text(staff.name),
                          selected: staffFilter == staff.id,
                          onSelected: (_) {
                            ref
                                .read(attendanceStaffFilterProvider.notifier)
                                .state = staffFilter == staff.id
                                ? null
                                : staff.id;
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),

        const Divider(height: 1),

        // Records grouped by staff
        Expanded(
          child: historyAsync.when(
            data: (records) {
              // Filter by selected staff
              final filtered = staffFilter != null
                  ? records.where((r) => r.staffId == staffFilter).toList()
                  : records;

              if (filtered.isEmpty) {
                return const Center(child: Text('No attendance records'));
              }

              // Compute aggregate stats for the header
              final uniqueStaff = filtered.map((r) => r.staffId).toSet();
              final uniqueDays = filtered
                  .map((r) => '${r.date.year}-${r.date.month}-${r.date.day}')
                  .toSet();
              double totalHrs = 0;
              for (final r in filtered) {
                totalHrs += r.hoursWorked;
              }

              // Group by staff
              final grouped = <String, List<AttendanceModel>>{};
              for (final record in filtered) {
                grouped.putIfAbsent(record.staffId, () => []).add(record);
              }

              // Sort staff groups by name
              final staffIds = grouped.keys.toList()
                ..sort((a, b) {
                  final nameA = grouped[a]!.first.staffName;
                  final nameB = grouped[b]!.first.staffName;
                  return nameA.compareTo(nameB);
                });

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: staffIds.length + 1, // +1 for summary header
                itemBuilder: (context, index) {
                  // First item: summary bar
                  if (index == 0) {
                    return _HistorySummaryCard(
                      totalRecords: filtered.length,
                      uniqueStaff: uniqueStaff.length,
                      uniqueDays: uniqueDays.length,
                      totalHours: totalHrs,
                    );
                  }
                  final staffIndex = index - 1;
                  final staffId = staffIds[staffIndex];
                  final staffRecords = grouped[staffId]!;
                  final staffName = staffRecords.first.staffName;

                  // Calculate total hours for this staff member
                  double totalHours = 0;
                  for (final r in staffRecords) {
                    totalHours += r.hoursWorked;
                  }

                  return _StaffHistorySection(
                    staffId: staffId,
                    staffName: staffName,
                    records: staffRecords,
                    totalHours: totalHours,
                    totalSessions: staffRecords.length,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}

// ─── History Summary Card ──────────────────────────────────────

class _HistorySummaryCard extends StatelessWidget {
  final int totalRecords;
  final int uniqueStaff;
  final int uniqueDays;
  final double totalHours;

  const _HistorySummaryCard({
    required this.totalRecords,
    required this.uniqueStaff,
    required this.uniqueDays,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final avgHoursPerDay = uniqueDays > 0
        ? (totalHours / uniqueDays).toStringAsFixed(1)
        : '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              Colors.indigo.withValues(alpha: 0.07),
              Colors.purple.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  size: 18,
                  color: Colors.indigo[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Period Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniStat(
                  label: 'Records',
                  value: '$totalRecords',
                  icon: Icons.receipt_long_rounded,
                  color: Colors.blue,
                ),
                _MiniStat(
                  label: 'Staff',
                  value: '$uniqueStaff',
                  icon: Icons.people_rounded,
                  color: cs.primary,
                ),
                _MiniStat(
                  label: 'Days',
                  value: '$uniqueDays',
                  icon: Icons.calendar_month_rounded,
                  color: Colors.green,
                ),
                _MiniStat(
                  label: 'Hours',
                  value: totalHours.toStringAsFixed(1),
                  icon: Icons.schedule_rounded,
                  color: Colors.orange,
                ),
                _MiniStat(
                  label: 'Avg/Day',
                  value: avgHoursPerDay,
                  icon: Icons.trending_up_rounded,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Staff History Section (grouped) ───────────────────────────

class _StaffHistorySection extends StatelessWidget {
  final String staffId;
  final String staffName;
  final List<AttendanceModel> records;
  final double totalHours;
  final int totalSessions;

  const _StaffHistorySection({
    required this.staffId,
    required this.staffName,
    required this.records,
    required this.totalHours,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff header with summary — tap to open detail panel
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StaffAttendanceDetailScreen(
                    staffId: staffId,
                    staffName: staffName,
                    staffRole: '',
                    staffEmoji: '👤',
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      staffName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  // Summary badges
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalSessions sessions',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${totalHours.toStringAsFixed(1)}h total',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          // Individual records
          for (int i = 0; i < records.length; i++) ...[
            _HistoryRow(record: records[i]),
            if (i < records.length - 1)
              Divider(
                height: 1,
                indent: 50,
                endIndent: 16,
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final AttendanceModel record;
  const _HistoryRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = record.hoursWorked;
    final isStillIn = record.status == AttendanceStatus.clockedIn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isStillIn
                  ? Colors.green.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              isStillIn ? Icons.login : Icons.logout,
              size: 16,
              color: isStillIn
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),

          // Date
          SizedBox(
            width: 44,
            child: Text(
              '${record.date.day}/${record.date.month}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Time range
          Expanded(
            child: Text(
              'In: ${_formatTime(record.clockIn)}'
              '${record.clockOut != null ? '  →  Out: ${_formatTime(record.clockOut!)}' : ''}',
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Duration or "Still in" badge
          if (isStillIn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Still in',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            )
          else if (hours > 0)
            Text(
              '${hours.toStringAsFixed(1)}h',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
