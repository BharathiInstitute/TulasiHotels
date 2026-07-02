/// Location service for staff attendance geo-tagging
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Result of a location capture attempt
class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;

  /// Whether the location is within the configured office geofence
  final bool isInsideGeofence;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.isInsideGeofence = false,
  });

  /// Human-readable status label
  String get statusLabel => isInsideGeofence ? 'Inside' : 'Outside';

  @override
  String toString() =>
      'LocationResult($latitude, $longitude, $statusLabel, ${address ?? "no address"})';
}

/// Service for capturing GPS location during attendance clock-in/out.
/// Works on Android, iOS, and Web (browser geolocation API).
class LocationService {
  LocationService._();

  // ── Geofence configuration ──
  // Default office location (can be overridden per hotel via Firestore later)
  static double _officeLat = 0;
  static double _officeLng = 0;
  static double _radiusMeters = 200; // 200m radius by default
  static bool _geofenceConfigured = false;

  /// Configure the office geofence center and radius.
  /// Call this on app init or when hotel selection changes.
  static void configureGeofence({
    required double latitude,
    required double longitude,
    double radiusMeters = 200,
  }) {
    _officeLat = latitude;
    _officeLng = longitude;
    _radiusMeters = radiusMeters;
    _geofenceConfigured = true;
    debugPrint(
      '📍 Geofence configured: ($latitude, $longitude) radius=${radiusMeters}m',
    );
  }

  /// Public: calculate distance (meters) between two GPS points
  static double distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) => _distanceMeters(lat1, lng1, lat2, lng2);

  /// Check if geofence is configured
  static bool get isGeofenceConfigured => _geofenceConfigured;

  /// Calculate distance between two GPS points using Haversine formula (meters)
  static double _distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  /// Check if given coordinates are inside the office geofence
  static bool isInsideOffice(double lat, double lng) {
    if (!_geofenceConfigured) return false;
    final distance = _distanceMeters(lat, lng, _officeLat, _officeLng);
    return distance <= _radiusMeters;
  }

  /// Capture current location with address.
  /// Returns null if location is unavailable or permission denied.
  /// Never throws — always returns null on failure.
  static Future<LocationResult?> captureLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('📍 Location services disabled');
        return null;
      }

      // Check & request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('📍 Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('📍 Location permission permanently denied');
        return null;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint(
        '📍 Got position: ${position.latitude}, ${position.longitude}',
      );

      // Reverse geocode to get address (non-critical — graceful fallback)
      String? address;
      try {
        // Skip geocoding on web (often fails with CORS)
        if (!kIsWeb) {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(const Duration(seconds: 5));

          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = <String>[
              if (p.name != null && p.name!.isNotEmpty) p.name!,
              if (p.subLocality != null && p.subLocality!.isNotEmpty)
                p.subLocality!,
              if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            ];
            address = parts.take(3).join(', ');
          }
        }
      } catch (e) {
        debugPrint('📍 Geocoding failed (non-critical): $e');
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        isInsideGeofence: isInsideOffice(position.latitude, position.longitude),
      );
    } catch (e) {
      debugPrint('📍 Location capture failed: $e');
      return null;
    }
  }
}
