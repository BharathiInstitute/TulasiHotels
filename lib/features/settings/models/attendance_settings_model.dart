/// Model for geo-fence attendance settings stored per hotel.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSettingsModel {
  /// Whether geo-fence enforcement is active
  final bool requireGeoFence;

  /// Hotel/store GPS latitude (set by owner)
  final double? storeLatitude;

  /// Hotel/store GPS longitude (set by owner)
  final double? storeLongitude;

  /// Allowed clock-in/out radius in meters
  final int geoFenceRadius;

  const AttendanceSettingsModel({
    this.requireGeoFence = false,
    this.storeLatitude,
    this.storeLongitude,
    this.geoFenceRadius = 100,
  });

  /// Default / empty settings
  static const empty = AttendanceSettingsModel();

  bool get hasLocation => storeLatitude != null && storeLongitude != null;

  AttendanceSettingsModel copyWith({
    bool? requireGeoFence,
    double? storeLatitude,
    double? storeLongitude,
    int? geoFenceRadius,
  }) {
    return AttendanceSettingsModel(
      requireGeoFence: requireGeoFence ?? this.requireGeoFence,
      storeLatitude: storeLatitude ?? this.storeLatitude,
      storeLongitude: storeLongitude ?? this.storeLongitude,
      geoFenceRadius: geoFenceRadius ?? this.geoFenceRadius,
    );
  }

  factory AttendanceSettingsModel.fromFirestore(Map<String, dynamic> data) {
    return AttendanceSettingsModel(
      requireGeoFence: data['requireGeoFence'] as bool? ?? false,
      storeLatitude: (data['storeLatitude'] as num?)?.toDouble(),
      storeLongitude: (data['storeLongitude'] as num?)?.toDouble(),
      geoFenceRadius: (data['geoFenceRadius'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requireGeoFence': requireGeoFence,
      if (storeLatitude != null) 'storeLatitude': storeLatitude,
      if (storeLongitude != null) 'storeLongitude': storeLongitude,
      'geoFenceRadius': geoFenceRadius,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
