/// Riverpod provider for geo-fence attendance settings.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/settings/models/attendance_settings_model.dart';
import 'package:tulasihotels/features/settings/services/attendance_settings_service.dart';

/// Watches attendance settings for the currently selected hotel.
/// Returns [AttendanceSettingsModel.empty] if no hotel is selected.
final attendanceSettingsProvider =
    StreamProvider.autoDispose<AttendanceSettingsModel>((ref) {
      final hotelId = ref.watch(currentHotelIdProvider);
      if (hotelId == null) {
        return Stream.value(AttendanceSettingsModel.empty);
      }
      return AttendanceSettingsService.stream(hotelId);
    });
