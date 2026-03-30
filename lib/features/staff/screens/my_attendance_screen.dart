/// My Attendance — read-only view for staff to see their own attendance history
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/screens/staff_attendance_detail_screen.dart';

class MyAttendanceScreen extends ConsumerWidget {
  const MyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(loggedInStaffProvider);

    if (staff == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return StaffAttendanceDetailScreen(
      staffId: staff.id,
      staffName: staff.name,
      staffRole: staff.role.displayName,
      staffEmoji: staff.role.emoji,
    );
  }
}
