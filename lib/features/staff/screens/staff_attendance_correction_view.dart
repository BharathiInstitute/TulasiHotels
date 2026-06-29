/// Per-staff attendance correction view — day-grouped records with
/// IN | OUT | DUR | IN LOC | OUT LOC columns and edit button per day.
/// Accessed from Staff Management screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/staff/services/attendance_service.dart';
import 'package:tulasihotels/models/attendance_model.dart';

class StaffAttendanceCorrectionView extends ConsumerStatefulWidget {
  final String staffId;
  final String staffName;
  final String? staffEmail;
  final String? staffRole;

  const StaffAttendanceCorrectionView({
    super.key,
    required this.staffId,
    required this.staffName,
    this.staffEmail,
    this.staffRole,
  });

  @override
  ConsumerState<StaffAttendanceCorrectionView> createState() =>
      _StaffAttendanceCorrectionViewState();
}

class _StaffAttendanceCorrectionViewState
    extends ConsumerState<StaffAttendanceCorrectionView> {
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
    final cs = Theme.of(context).colorScheme;

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
          // Date range chip
          GestureDetector(
            onTap: () => _pickRange(context),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${_fmt(_range.start)} – ${_fmt(_range.end)}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                  ),
                ],
              ),
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
          if (records.isEmpty) {
            return Center(
              child: Text(
                'No records for this period',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            );
          }

          // Summary
          final uniqueDays = records
              .map((r) => '${r.date.year}-${r.date.month}-${r.date.day}')
              .toSet()
              .length;
          int totalMinutes = 0;
          for (final r in records) {
            if (r.clockOut != null) {
              totalMinutes += r.clockOut!.difference(r.clockIn).inMinutes;
            }
          }
          final hh = (totalMinutes ~/ 60).toString().padLeft(2, '0');
          final mm = (totalMinutes % 60).toString().padLeft(2, '0');

          // Group by day, newest first
          final dayMap = <String, List<AttendanceModel>>{};
          for (final r in records) {
            final key =
                '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
            dayMap.putIfAbsent(key, () => []).add(r);
          }
          final sortedDays = dayMap.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              // Summary chips bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _Chip(label: 'Days: $uniqueDays'),
                    const SizedBox(width: 8),
                    _Chip(label: 'Hours: $hh:$mm'),
                    const SizedBox(width: 8),
                    _Chip(label: 'Records: ${records.length}'),
                  ],
                ),
              ),

              // Day groups
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: sortedDays.length,
                    itemBuilder: (context, i) => _DayGroup(
                      day: sortedDays[i],
                      records: dayMap[sortedDays[i]]!,
                      staffName: widget.staffName,
                      onEdited: () => setState(() {}),
                      ref: ref,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Summary Chip ───────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

// ── Day Group ──────────────────────────────────────────────────

class _DayGroup extends StatelessWidget {
  final String day;
  final List<AttendanceModel> records;
  final String staffName;
  final VoidCallback onEdited;
  final WidgetRef ref;

  const _DayGroup({
    required this.day,
    required this.records,
    required this.staffName,
    required this.onEdited,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Day total
    int totalMins = 0;
    for (final r in records) {
      if (r.clockOut != null) {
        totalMins += r.clockOut!.difference(r.clockIn).inMinutes;
      }
    }
    final hh = (totalMins ~/ 60).toString().padLeft(2, '0');
    final mm = (totalMins % 60).toString().padLeft(2, '0');

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
        // Day header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
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
                    if (records.length == 1)
                      Text(
                        'Doc: ${records.first.id}',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: Colors.green[700]),
                tooltip: 'Edit record',
                onPressed: () => _edit(context, records.first),
              ),
            ],
          ),
        ),

        // Column headers
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _Col('IN', flex: 2),
              _Col('OUT', flex: 2),
              _Col('DUR', flex: 2),
              _Col('IN LOC', flex: 2),
              _Col('OUT LOC', flex: 2),
            ],
          ),
        ),

        // Record rows
        ...records.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _fmtTime(r.clockIn),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    r.clockOut != null ? _fmtTime(r.clockOut!) : '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: r.clockOut == null ? cs.onSurfaceVariant : null,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    r.clockOut != null ? _dur(r.clockIn, r.clockOut!) : '-',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _LocText(
                    isInside: r.clockInInside,
                    hasLoc: r.hasClockInLocation,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _LocText(
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

  Future<void> _edit(BuildContext context, AttendanceModel record) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _EditRecordDialog(record: record, ref: ref),
    );
    if (result == true) onEdited();
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  static String _dur(DateTime i, DateTime o) {
    final d = o.difference(i);
    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';
  }
}

// ── Column Header ──────────────────────────────────────────────

class _Col extends StatelessWidget {
  final String text;
  final int flex;
  const _Col(this.text, {this.flex = 1});

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

// ── Location Text ──────────────────────────────────────────────

class _LocText extends StatelessWidget {
  final bool? isInside;
  final bool hasLoc;
  const _LocText({required this.isInside, required this.hasLoc});

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

// ── Edit Record Dialog ─────────────────────────────────────────

class _EditRecordDialog extends StatefulWidget {
  final AttendanceModel record;
  final WidgetRef ref;
  const _EditRecordDialog({required this.record, required this.ref});

  @override
  State<_EditRecordDialog> createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends State<_EditRecordDialog> {
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
    final cs = Theme.of(context).colorScheme;
    final r = widget.record;
    final dateLabel =
        '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit $dateLabel',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              r.staffName,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // Clock-in row
            _TimeRow(
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
            _TimeRow(
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
          widget.ref.read(authNotifierProvider).user?.ownerName ??
          widget.ref.read(authNotifierProvider).firebaseUser?.email ??
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
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

// ── Time Edit Row ──────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  final String label;
  final DateTime? dt;
  final Color color;
  final VoidCallback onEdit;

  const _TimeRow({
    required this.label,
    required this.dt,
    required this.color,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dtStr = dt != null
        ? '${dt!.year}-${dt!.month.toString().padLeft(2, '0')}-${dt!.day.toString().padLeft(2, '0')}'
              ' ${dt!.hour.toString().padLeft(2, '0')}:${dt!.minute.toString().padLeft(2, '0')}:00.000'
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
