/// Tests for ConnectivityService â€” ConnectivityStatus enum
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/core/services/connectivity_service.dart';

void main() {
  // â”€â”€ ConnectivityStatus enum â”€â”€

  group('ConnectivityStatus', () {
    test('has 2 values', () {
      expect(ConnectivityStatus.values.length, 2);
    });

    test('online is available', () {
      expect(ConnectivityStatus.online, isNotNull);
      expect(ConnectivityStatus.online.name, 'online');
    });

    test('offline is available', () {
      expect(ConnectivityStatus.offline, isNotNull);
      expect(ConnectivityStatus.offline.name, 'offline');
    });

    test('values are distinct', () {
      expect(ConnectivityStatus.online, isNot(ConnectivityStatus.offline));
    });
  });
}
