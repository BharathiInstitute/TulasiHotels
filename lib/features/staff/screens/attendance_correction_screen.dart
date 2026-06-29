/// Attendance Correction — admin screen for viewing and correcting all staff records
/// Shows users grouped with Days/Hours/Records summary, expandable day-grouped records,
/// and an inline edit dialog for correcting clock-in/out times.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/staff/screens/admin_staff_attendance_panel.dart';
import 'package:tulasihotels/features/staff/services/attendance_service.dart';
import 'package:tulasihotels/models/attendance_model.dart';

// ── Providers ──────────────────────────────────────────────────

final correctionDateRangeProvider = StateProvider<DateTimeRange>((_) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month),
    end: DateTime(now.year, now.month + 1, 0),
  );
});

final correctionUserFilterProvider = StateProvider<String?>((_) => null);

final correctionRecordsProvider =
    StreamProvider.autoDispose<List<AttendanceModel>>((ref) {
      final range = ref.watch(correctionDateRangeProvider);
      return AttendanceService.attendanceStream(
        from: range.start,
        to: range.end,
      );
    });

// ── Main Screen ────────────────────────────────────────────────

/// Reusable panel — no Scaffold, embeds into tabs or standalone screens.
class AttendanceCorrectionPanel extends ConsumerWidget {
  const AttendanceCorrectionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(correctionDateRangeProvider);
    final userFilter = ref.watch(correctionUserFilterProvider);
    final recordsAsync = ref.watch(correctionRecordsProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ── Toolbar ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.tune, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              const Text(
                'Attendance Correction',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _pickRange(context, ref, range),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month, size: 13, color: cs.primary),
                      const SizedBox(width: 5),
                      Text(
                        '${_fmtShort(range.start)} – ${_fmtShort(range.end)}',
                        style: TextStyle(fontSize: 11, color: cs.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              recordsAsync.whenOrNull(
                    data: (records) {
                      final allUsers =
                          records.map((r) => r.staffName).toSet().toList()
                            ..sort();
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: userFilter,
                          items: [
                            const DropdownMenuItem(child: Text('All users')),
                            ...allUsers.map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(
                                  u,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              ref
                                      .read(
                                        correctionUserFilterProvider.notifier,
                                      )
                                      .state =
                                  v,
                          style: TextStyle(fontSize: 13, color: cs.onSurface),
                          iconSize: 18,
                        ),
                      );
                    },
                  ) ??
                  const SizedBox(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(correctionRecordsProvider),
              ),
            ],
          ),
        ),

        // ── List ──
        Expanded(
          child: recordsAsync.when(
            data: (allRecords) {
              final records = userFilter != null
                  ? allRecords
                        .where(
                          (r) =>
                              r.staffName == userFilter ||
                              r.staffId == userFilter,
                        )
                        .toList()
                  : allRecords;

              if (records.isEmpty) {
                return Center(
                  child: Text(
                    'No records for this period',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                );
              }

              final grouped = <String, List<AttendanceModel>>{};
              for (final r in records) {
                grouped.putIfAbsent(r.staffId, () => []).add(r);
              }
              final staffIds = grouped.keys.toList()
                ..sort(
                  (a, b) => grouped[a]!.first.staffName.compareTo(
                    grouped[b]!.first.staffName,
                  ),
                );

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: staffIds.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final staffId = staffIds[i];
                  final staffRecords = grouped[staffId]!;
                  return _UserAttendanceCard(
                    staffId: staffId,
                    staffName: staffRecords.first.staffName,
                    records: staffRecords,
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

  Future<void> _pickRange(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange current,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: current,
    );
    if (picked != null) {
      ref.read(correctionDateRangeProvider.notifier).state = picked;
    }
  }

  static String _fmtShort(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

/// Standalone screen wrapper — wraps AttendanceCorrectionPanel in a Scaffold.
class AttendanceCorrectionScreen extends StatelessWidget {
  const AttendanceCorrectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AttendanceCorrectionPanel());
  }
}

// ── User Attendance Card ───────────────────────────────────────

class _UserAttendanceCard extends ConsumerStatefulWidget {
  final String staffId;
  final String staffName;
  final List<AttendanceModel> records;

  const _UserAttendanceCard({
    required this.staffId,
    required this.staffName,
    required this.records,
  });

  @override
  ConsumerState<_UserAttendanceCard> createState() =>
      _UserAttendanceCardState();
}

class _UserAttendanceCardState extends ConsumerState<_UserAttendanceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Compute summary
    final uniqueDays = widget.records
        .map((r) => '${r.date.year}-${r.date.month}-${r.date.day}')
        .toSet()
        .length;
    int totalMinutes = 0;
    for (final r in widget.records) {
      if (r.clockOut != null) {
        totalMinutes += r.clockOut!.difference(r.clockIn).inMinutes;
      }
    }
    final hh = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final mm = (totalMinutes % 60).toString().padLeft(2, '0');

    // Group by date for expanded view
    final dayGroups = _groupByDay(widget.records);
    final sortedDays = dayGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.04),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(8))
                    : BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.staffName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _SummaryChip(label: 'Days: $uniqueDays'),
                            const SizedBox(width: 6),
                            _SummaryChip(label: 'Hours: $hh:$mm'),
                            const SizedBox(width: 6),
                            _SummaryChip(
                              label: 'Records: ${widget.records.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // View full panel button
                  IconButton(
                    icon: Icon(
                      Icons.person_search,
                      size: 20,
                      color: cs.primary,
                    ),
                    tooltip: 'View attendance panel',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminStaffAttendancePanel(
                          staffId: widget.staffId,
                          staffName: widget.staffName,
                        ),
                      ),
                    ),
                  ),
                  // Expand/collapse toggle
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Icon(
                      _expanded ? Icons.expand_less : Icons.chevron_right,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded day records
          if (_expanded) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            ...sortedDays.map(
              (day) => _DayRecordGroup(
                day: day,
                records: dayGroups[day]!,
                staffName: widget.staffName,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, List<AttendanceModel>> _groupByDay(
    List<AttendanceModel> records,
  ) {
    final map = <String, List<AttendanceModel>>{};
    for (final r in records) {
      final key =
          '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }
}

// ── Summary Chip ───────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  const _SummaryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(4),
        color: cs.surface,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }
}

// ── Day Record Group ───────────────────────────────────────────

class _DayRecordGroup extends ConsumerWidget {
  final String day; // "YYYY-MM-DD"
  final List<AttendanceModel> records;
  final String staffName;

  const _DayRecordGroup({
    required this.day,
    required this.records,
    required this.staffName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Day total
    int totalMinutes = 0;
    for (final r in records) {
      if (r.clockOut != null) {
        totalMinutes += r.clockOut!.difference(r.clockIn).inMinutes;
      }
    }
    final hh = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final mm = (totalMinutes % 60).toString().padLeft(2, '0');

    // Format day
    final parts = day.split('-');
    final dt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final dayLabel =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header row
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staffName,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    // Show doc IDs for reference
                    if (records.length == 1)
                      Text(
                        'Doc ID: ${records.first.id}',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              // Edit button — only editable when single record for the day
              if (records.length == 1)
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: Colors.green[700]),
                  tooltip: 'Edit record',
                  onPressed: () => _showEditDialog(context, ref, records.first),
                )
              else
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text('${records.length} records'),
                  onPressed: () => _showEditDialog(context, ref, records.first),
                ),
            ],
          ),
        ),

        // Column headers
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _ColHeader('IN', flex: 2),
              _ColHeader('OUT', flex: 2),
              _ColHeader('DUR', flex: 2),
              _ColHeader('IN LOC', flex: 2),
              _ColHeader('OUT LOC', flex: 2),
            ],
          ),
        ),

        // Record rows
        ...records.map(
          (r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // IN
                Expanded(
                  flex: 2,
                  child: Text(
                    _fmtTime(r.clockIn),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                // OUT
                Expanded(
                  flex: 2,
                  child: Text(
                    r.clockOut != null ? _fmtTime(r.clockOut!) : '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: r.clockOut == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
                // DUR
                Expanded(
                  flex: 2,
                  child: Text(
                    r.clockOut != null
                        ? _duration(r.clockIn, r.clockOut!)
                        : '-',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                // IN LOC
                Expanded(
                  flex: 2,
                  child: _LocBadge(
                    isInside: r.clockInInside,
                    hasLoc: r.hasClockInLocation,
                  ),
                ),
                // OUT LOC
                Expanded(
                  flex: 2,
                  child: _LocBadge(
                    isInside: r.clockOutInside,
                    hasLoc: r.hasClockOutLocation,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Day total
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Day Total: $hh:$mm',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
      ],
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    AttendanceModel record,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _EditDialog(record: record),
    );
    if (result == true) {
      ref.invalidate(correctionRecordsProvider);
    }
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  static String _duration(DateTime clockIn, DateTime clockOut) {
    final diff = clockOut.difference(clockIn);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Column Header ──────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final String text;
  final int flex;
  const _ColHeader(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
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
    final color = inside ? Colors.green : Colors.orange;
    return Text(
      inside ? 'Inside' : 'Outside',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color[700],
      ),
    );
  }
}

// ── Edit Dialog ────────────────────────────────────────────────

class _EditDialog extends ConsumerStatefulWidget {
  final AttendanceModel record;
  const _EditDialog({required this.record});

  @override
  ConsumerState<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends ConsumerState<_EditDialog> {
  late DateTime _clockIn;
  late DateTime? _clockOut;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clockIn = widget.record.clockIn;
    _clockOut = widget.record.clockOut;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateLabel =
        '${widget.record.date.year}-${widget.record.date.month.toString().padLeft(2, '0')}-${widget.record.date.day.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Edit $dateLabel',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.record.staffName,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),

            const SizedBox(height: 20),

            // Clock-in row
            _TimeEditRow(
              label: 'in',
              dt: _clockIn,
              color: Colors.green,
              onEdit: () async {
                final updated = await _pickDateTime(context, _clockIn);
                if (updated != null) setState(() => _clockIn = updated);
              },
            ),

            const SizedBox(height: 10),

            // Clock-out row
            _TimeEditRow(
              label: 'out',
              dt: _clockOut,
              color: Colors.red,
              onEdit: () async {
                final base = _clockOut ?? _clockIn;
                final updated = await _pickDateTime(context, base);
                if (updated != null) setState(() => _clockOut = updated);
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: cs.error, fontSize: 12)),
            ],

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _saving ? null : _save,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[700],
                    side: BorderSide(color: Colors.green[700]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    // Validate
    if (_clockOut != null && _clockOut!.isBefore(_clockIn)) {
      setState(() => _error = 'Clock-out must be after clock-in');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final editorName =
          ref.read(authNotifierProvider).user?.ownerName ??
          ref.read(authNotifierProvider).firebaseUser?.email ??
          'Admin';
      await AttendanceService.updateRecord(
        widget.record.id,
        clockIn: _clockIn,
        clockOut: _clockOut,
        status: _clockOut != null ? AttendanceStatus.clockedOut : null,
        editedBy: editorName,
        editNote: 'Manually corrected',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    // Pick date
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return null;

    // Pick time
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

// ── Time Edit Row ──────────────────────────────────────────────

class _TimeEditRow extends StatelessWidget {
  final String label;
  final DateTime? dt;
  final Color color;
  final VoidCallback onEdit;

  const _TimeEditRow({
    required this.label,
    required this.dt,
    required this.color,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dtStr = dt != null
        ? '${dt!.year}-${dt!.month.toString().padLeft(2, '0')}-${dt!.day.toString().padLeft(2, '0')} '
              '${dt!.hour.toString().padLeft(2, '0')}:${dt!.minute.toString().padLeft(2, '0')}:00.000'
        : 'Not set';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Expanded(child: Text(dtStr, style: const TextStyle(fontSize: 13))),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.edit, size: 18, color: Colors.green[700]),
            ),
          ),
        ],
      ),
    );
  }
}
