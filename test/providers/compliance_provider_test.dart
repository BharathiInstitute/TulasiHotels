/// Tests for compliance providers — provider declarations and types
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/compliance/providers/compliance_provider.dart';
import 'package:tulasihotels/models/complaint_model.dart';
import 'package:tulasihotels/models/equipment_model.dart';
import 'package:tulasihotels/models/event_model.dart';
import 'package:tulasihotels/models/license_model.dart';

void main() {
  group('Compliance stream providers', () {
    test('licensesProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          licensesProvider.overrideWith((_) => Stream.value(<LicenseModel>[])),
        ],
      );
      addTearDown(container.dispose);
      final value = container.read(licensesProvider);
      expect(value, isA<AsyncValue<List<LicenseModel>>>());
    });

    test('expiringLicensesProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          expiringLicensesProvider.overrideWith(
            (_) => Stream.value(<LicenseModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final value = container.read(expiringLicensesProvider);
      expect(value, isA<AsyncValue<List<LicenseModel>>>());
    });

    test('equipmentProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          equipmentProvider.overrideWith(
            (_) => Stream.value(<EquipmentModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final value = container.read(equipmentProvider);
      expect(value, isA<AsyncValue<List<EquipmentModel>>>());
    });

    test('equipmentNeedsServiceProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          equipmentNeedsServiceProvider.overrideWith(
            (_) => Stream.value(<EquipmentModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final value = container.read(equipmentNeedsServiceProvider);
      expect(value, isA<AsyncValue<List<EquipmentModel>>>());
    });

    test('activeComplaintsProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          activeComplaintsProvider.overrideWith(
            (_) => Stream.value(<ComplaintModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final value = container.read(activeComplaintsProvider);
      expect(value, isA<AsyncValue<List<ComplaintModel>>>());
    });

    test('allComplaintsProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          allComplaintsProvider.overrideWith(
            (_) => Stream.value(<ComplaintModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final value = container.read(allComplaintsProvider);
      expect(value, isA<AsyncValue<List<ComplaintModel>>>());
    });

    test('upcomingEventsProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          upcomingEventsProvider.overrideWith(
            (_) => Stream.value(<EventModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final value = container.read(upcomingEventsProvider);
      expect(value, isA<AsyncValue<List<EventModel>>>());
    });

    test('allEventsProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          allEventsProvider.overrideWith((_) => Stream.value(<EventModel>[])),
        ],
      );
      addTearDown(container.dispose);
      final value = container.read(allEventsProvider);
      expect(value, isA<AsyncValue<List<EventModel>>>());
    });
  });

  group('Compliance provider data flows', () {
    test('licensesProvider emits AsyncLoading initially', () {
      final container = ProviderContainer(
        overrides: [
          licensesProvider.overrideWith((_) => Stream.value(<LicenseModel>[])),
        ],
      );
      addTearDown(container.dispose);
      final value = container.read(licensesProvider);
      expect(value.isLoading, isTrue);
    });
  });
}
