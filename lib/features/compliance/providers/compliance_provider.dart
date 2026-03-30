/// Compliance providers — licenses, equipment, complaints, events
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/compliance/services/license_service.dart';
import 'package:tulasihotels/features/compliance/services/equipment_service.dart';
import 'package:tulasihotels/features/compliance/services/complaint_service.dart';
import 'package:tulasihotels/features/compliance/services/event_service.dart';
import 'package:tulasihotels/models/license_model.dart';
import 'package:tulasihotels/models/equipment_model.dart';
import 'package:tulasihotels/models/complaint_model.dart';
import 'package:tulasihotels/models/event_model.dart';

/// Stream all licenses
final licensesProvider = StreamProvider.autoDispose<List<LicenseModel>>((ref) {
  return LicenseService.licensesStream();
});

/// Stream licenses expiring within 30 days
final expiringLicensesProvider =
    StreamProvider.autoDispose<List<LicenseModel>>((ref) {
  return LicenseService.expiringLicensesStream();
});

/// Stream all equipment
final equipmentProvider =
    StreamProvider.autoDispose<List<EquipmentModel>>((ref) {
  return EquipmentService.equipmentStream();
});

/// Stream equipment needing service
final equipmentNeedsServiceProvider =
    StreamProvider.autoDispose<List<EquipmentModel>>((ref) {
  return EquipmentService.needsServiceStream();
});

/// Stream active complaints
final activeComplaintsProvider =
    StreamProvider.autoDispose<List<ComplaintModel>>((ref) {
  return ComplaintService.activeComplaintsStream();
});

/// Stream all complaints
final allComplaintsProvider =
    StreamProvider.autoDispose<List<ComplaintModel>>((ref) {
  return ComplaintService.allComplaintsStream();
});

/// Stream upcoming events
final upcomingEventsProvider =
    StreamProvider.autoDispose<List<EventModel>>((ref) {
  return EventService.upcomingEventsStream();
});

/// Stream all events
final allEventsProvider = StreamProvider.autoDispose<List<EventModel>>((ref) {
  return EventService.allEventsStream();
});
