/// Custom date range picker dialog with explicit month navigation arrows.
///
/// Usage:
///   final range = await showCustomDateRangePicker(
///     context: context,
///     firstDate: DateTime(2024),
///     lastDate: DateTime.now(),
///     initialRange: currentRange,
///   );
library;

import 'package:flutter/material.dart';

/// Shows a custom date range picker dialog.
/// Returns the selected [DateTimeRange] or `null` if cancelled.
Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialRange,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (_) => _CustomDateRangePickerDialog(
      firstDate: firstDate,
      lastDate: lastDate,
      initialRange: initialRange,
    ),
  );
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class _CustomDateRangePickerDialog extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialRange;

  const _CustomDateRangePickerDialog({
    required this.firstDate,
    required this.lastDate,
    this.initialRange,
  });

  @override
  State<_CustomDateRangePickerDialog> createState() =>
      _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState
    extends State<_CustomDateRangePickerDialog> {
  late DateTime _displayedMonth;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
    // Show the month of the start date (or current month as fallback)
    _displayedMonth = DateTime(
      widget.initialRange?.start.year ?? DateTime.now().year,
      widget.initialRange?.start.month ?? DateTime.now().month,
    );
    // Clamp displayed month within allowed bounds
    _clampDisplayedMonth();
  }

  void _clampDisplayedMonth() {
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    if (_displayedMonth.isBefore(firstMonth)) _displayedMonth = firstMonth;
    if (_displayedMonth.isAfter(lastMonth)) _displayedMonth = lastMonth;
  }

  bool get _canGoPrev {
    final prev = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    return !prev.isBefore(firstMonth);
  }

  bool get _canGoNext {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    return !next.isAfter(lastMonth);
  }

  void _prevMonth() {
    if (!_canGoPrev) return;
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  void _onDayTapped(DateTime day) {
    if (day.isBefore(widget.firstDate) || day.isAfter(widget.lastDate)) return;
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        // Start a new selection
        _start = day;
        _end = null;
      } else {
        // Set the end date
        if (day.isBefore(_start!)) {
          _end = _start;
          _start = day;
        } else {
          _end = day;
        }
      }
    });
  }

  bool _isInRange(DateTime day) {
    if (_start == null || _end == null) return false;
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(_start!.year, _start!.month, _start!.day);
    final e = DateTime(_end!.year, _end!.month, _end!.day);
    return d.isAfter(s) && d.isBefore(e);
  }

  bool _isStart(DateTime day) {
    if (_start == null) return false;
    return day.year == _start!.year &&
        day.month == _start!.month &&
        day.day == _start!.day;
  }

  bool _isEnd(DateTime day) {
    if (_end == null) return false;
    return day.year == _end!.year &&
        day.month == _end!.month &&
        day.day == _end!.day;
  }

  bool _isDisabled(DateTime day) {
    return day.isBefore(widget.firstDate) || day.isAfter(widget.lastDate);
  }

  String _rangeLabel() {
    if (_start == null) return 'Select range';
    final s = _fmtDate(_start!);
    if (_end == null) return s;
    return '$s – ${_fmtDate(_end!)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Sunday = weekday 7 in Dart, so offset for Sunday-start grid:
    final firstWeekdayInMonth = DateTime(year, month).weekday % 7; // 0=Sun

    final primaryColor = cs.primary;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : cs.surface;
    final headerBg = isDark ? const Color(0xFF0F0F1E) : cs.surface;
    final onBgColor = isDark ? Colors.white : cs.onSurface;
    final mutedColor = isDark
        ? Colors.white38
        : cs.onSurface.withValues(alpha: 0.38);
    final rangeBg = primaryColor.withValues(alpha: 0.25);
    final canSave = _start != null && _end != null;

    return Dialog(
      backgroundColor: bgColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: onBgColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select range',
                          style: TextStyle(fontSize: 12, color: mutedColor),
                        ),
                        Text(
                          _rangeLabel(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: onBgColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: mutedColor,
                      size: 20,
                    ),
                    onPressed: () async {
                      // Fall back to Flutter built-in picker for keyboard input
                      Navigator.pop(context);
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: widget.firstDate,
                        lastDate: widget.lastDate,
                        initialDateRange: (_start != null && _end != null)
                            ? DateTimeRange(start: _start!, end: _end!)
                            : null,
                      );
                      if (picked != null && context.mounted) {
                        Navigator.of(context).pop(picked);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: canSave
                        ? () => Navigator.pop(
                            context,
                            DateTimeRange(start: _start!, end: _end!),
                          )
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: primaryColor.withValues(
                        alpha: 0.3,
                      ),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // ── Month navigation ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: _canGoPrev ? onBgColor : mutedColor,
                    ),
                    onPressed: _canGoPrev ? _prevMonth : null,
                  ),
                  Text(
                    '${_monthName(month)} $year',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: onBgColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: _canGoNext ? onBgColor : mutedColor,
                    ),
                    onPressed: _canGoNext ? _nextMonth : null,
                  ),
                ],
              ),
            ),

            // ── Day-of-week headers ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: mutedColor,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 4),

            // ── Calendar grid ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Column(
                children: List.generate(
                  ((firstWeekdayInMonth + daysInMonth) / 7).ceil(),
                  (week) {
                    return Row(
                      children: List.generate(7, (col) {
                        final dayNum = week * 7 + col - firstWeekdayInMonth + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const Expanded(child: SizedBox(height: 40));
                        }
                        final day = DateTime(year, month, dayNum);
                        final disabled = _isDisabled(day);
                        final isStart = _isStart(day);
                        final isEnd = _isEnd(day);
                        final inRange = _isInRange(day);
                        final selected = isStart || isEnd;

                        // Range highlight extends behind day circle
                        BoxDecoration? rowDeco;
                        if (inRange) {
                          rowDeco = BoxDecoration(color: rangeBg);
                        } else if (isStart && _end != null) {
                          rowDeco = BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, rangeBg],
                            ),
                          );
                        } else if (isEnd && _start != null) {
                          rowDeco = BoxDecoration(
                            gradient: LinearGradient(
                              colors: [rangeBg, Colors.transparent],
                            ),
                          );
                        }

                        return Expanded(
                          child: GestureDetector(
                            onTap: disabled ? null : () => _onDayTapped(day),
                            child: Container(
                              height: 40,
                              decoration: rowDeco,
                              child: Center(
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: selected
                                      ? BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                        )
                                      : null,
                                  child: Center(
                                    child: Text(
                                      '$dayNum',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                        color: disabled
                                            ? mutedColor
                                            : selected
                                            ? Colors.white
                                            : onBgColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    return '${months[dt.month]} ${dt.day}';
  }

  static String _monthName(int m) => [
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
  ][m];
}
