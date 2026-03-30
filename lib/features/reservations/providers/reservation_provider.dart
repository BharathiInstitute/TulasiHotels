/// Reservation providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/reservations/services/reservation_service.dart';
import 'package:tulasihotels/models/reservation_model.dart';

/// Stream today's reservations
final todayReservationsProvider =
    StreamProvider.autoDispose<List<ReservationModel>>((ref) {
  return ReservationService.todayReservationsStream();
});

/// Stream upcoming reservations (next 7 days)
final upcomingReservationsProvider =
    StreamProvider.autoDispose<List<ReservationModel>>((ref) {
  return ReservationService.upcomingReservationsStream();
});

/// Date filter for reservation calendar
final reservationDateFilterProvider =
    StateProvider<DateTime>((ref) => DateTime.now());
