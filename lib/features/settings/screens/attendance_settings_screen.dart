/// Owner-only screen for configuring geo-fence attendance settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/settings/models/attendance_settings_model.dart';
import 'package:tulasihotels/features/settings/providers/attendance_settings_provider.dart';
import 'package:tulasihotels/features/settings/services/attendance_settings_service.dart';

/// Standalone screen wrapper — used on mobile and when navigated to directly.
class AttendanceSettingsScreen extends ConsumerWidget {
  const AttendanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: AttendanceSettingsBody(),
        ),
      ),
    );
  }
}

/// Embeddable body — used inside SettingsWebScreen on desktop.
class AttendanceSettingsBody extends ConsumerStatefulWidget {
  const AttendanceSettingsBody({super.key});

  @override
  ConsumerState<AttendanceSettingsBody> createState() =>
      _AttendanceSettingsBodyState();
}

class _AttendanceSettingsBodyState
    extends ConsumerState<AttendanceSettingsBody> {
  bool _saving = false;
  bool _capturingLocation = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(attendanceSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (settings) => _buildBody(context, cs, settings),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme cs,
    AttendanceSettingsModel settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Info banner ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: cs.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'When geo-fence is ON, staff must be within the set radius '
                  'of the store to clock in or out.',
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Toggle ───────────────────────────────────────────────
        _SectionCard(
          child: SwitchListTile(
            value: settings.requireGeoFence,
            onChanged: _saving
                ? null
                : (val) => _save(settings.copyWith(requireGeoFence: val)),
            title: const Text(
              'Require Geo-Fence',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              settings.requireGeoFence
                  ? 'Staff must be on-site to clock in/out'
                  : 'Staff can clock in/out from anywhere',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            secondary: Icon(
              settings.requireGeoFence
                  ? Icons.location_on
                  : Icons.location_off_outlined,
              color: settings.requireGeoFence
                  ? Colors.green
                  : cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Radius slider ────────────────────────────────────────
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.radar, color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Allowed Radius',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${settings.geoFenceRadius}m',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: settings.geoFenceRadius.toDouble().clamp(50, 500),
                  min: 50,
                  max: 500,
                  divisions: 9,
                  label: '${settings.geoFenceRadius}m',
                  onChanged: _saving
                      ? null
                      : (val) => _save(
                          settings.copyWith(geoFenceRadius: val.round()),
                        ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '50m',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '500m',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (settings.geoFenceRadius < 50)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'GPS accuracy is ~10–30m indoors. Minimum 50m recommended.',
                          style: TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Store location ────────────────────────────────────────
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.store, color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Store Location',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (settings.hasLocation)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${settings.storeLatitude!.toStringAsFixed(5)}, '
                            '${settings.storeLongitude!.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Store location not set yet.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Stand at your store and tap the button below to capture its location.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _capturingLocation
                        ? null
                        : () => _captureStoreLocation(settings),
                    icon: _capturingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(
                      _capturingLocation
                          ? 'Getting GPS...'
                          : settings.hasLocation
                          ? 'Update Store Location'
                          : 'Set Store Location',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Summary ────────────────────────────────────────────────
        if (settings.requireGeoFence && !settings.hasLocation)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Geo-fence is ON but store location is not set. '
                    'Staff will not be able to clock in/out.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _save(AttendanceSettingsModel updated) async {
    final hotelId = ref.read(currentHotelIdProvider);
    if (hotelId == null) return;
    setState(() => _saving = true);
    try {
      await AttendanceSettingsService.save(hotelId, updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _captureStoreLocation(AttendanceSettingsModel settings) async {
    setState(() => _capturingLocation = true);
    try {
      // Check location services
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(
          'Location services are disabled. Please enable them in device settings.',
        );
        return;
      }

      // Check / request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError(
          'Location permission permanently denied. Enable in device settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      await _save(
        settings.copyWith(
          storeLatitude: position.latitude,
          storeLongitude: position.longitude,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Store location saved: '
              '${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Could not get location. Please try again.');
    } finally {
      if (mounted) setState(() => _capturingLocation = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}

// ── Section Card helper ──────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}
