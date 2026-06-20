/// Providers for multi-hotel management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/hotels/models/hotel_info.dart';
import 'package:tulasihotels/features/hotels/services/hotel_service.dart';

/// Stream of all hotels the current user has access to
final hotelsStreamProvider = StreamProvider<List<HotelInfo>>((ref) {
  return HotelService.hotelsStream().handleError((error) {
    // Return empty list on permission errors (new user, no collection yet)
    return <HotelInfo>[];
  });
});

/// Currently selected hotel ID (persists across the session)
final currentHotelIdProvider = StateProvider<String?>((ref) => null);

/// The currently selected hotel info (derived from list + selected ID)
final currentHotelProvider = Provider<HotelInfo?>((ref) {
  final hotelId = ref.watch(currentHotelIdProvider);
  if (hotelId == null) return null;

  final hotelsAsync = ref.watch(hotelsStreamProvider);
  return hotelsAsync.whenOrNull(
    data: (hotels) {
      try {
        return hotels.firstWhere((h) => h.id == hotelId);
      } catch (_) {
        return null;
      }
    },
  );
});

/// Whether the user has selected a hotel to work in
final hasSelectedHotelProvider = Provider<bool>((ref) {
  return ref.watch(currentHotelIdProvider) != null;
});
