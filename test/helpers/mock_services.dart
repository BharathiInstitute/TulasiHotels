/// Mock service classes for widget and integration tests.
///
/// All service classes in the app use **static-only** methods backed by
/// Firestore / FirebaseAuth, so they cannot be instantiated or mocked in the
/// traditional `extends Mock` sense.  Instead we provide thin wrapper mocks
/// that can be registered via mocktail's `registerFallbackValue` or used
/// directly in provider overrides where a service *instance* is needed.
///
/// For provider-level testing, prefer the overrides in `mock_providers.dart`
/// which replace the Riverpod providers that *call* these services.
library;

import 'package:mocktail/mocktail.dart';

// ── Service imports ──────────────────────────────────────────────────────────
import 'package:tulasihotels/features/billing/services/billing_service.dart';
import 'package:tulasihotels/features/orders/services/order_service.dart';
import 'package:tulasihotels/features/tables/services/table_service.dart';
import 'package:tulasihotels/features/staff/services/staff_service.dart';
import 'package:tulasihotels/features/staff/services/attendance_service.dart';
import 'package:tulasihotels/features/khata/services/khata_write_service.dart';
import 'package:tulasihotels/features/coupons/services/coupon_service.dart';
import 'package:tulasihotels/features/reservations/services/reservation_service.dart';
import 'package:tulasihotels/features/feedback/services/feedback_service.dart';
import 'package:tulasihotels/features/inventory/services/ingredient_service.dart';
import 'package:tulasihotels/features/inventory/services/vendor_service.dart';
import 'package:tulasihotels/features/inventory/services/wastage_service.dart';
import 'package:tulasihotels/features/super_admin/services/admin_firestore_service.dart';

// ── Mock classes ─────────────────────────────────────────────────────────────
//
// NOTE: Every service listed below is a concrete class whose public API
// consists entirely of **static** methods.  Mocktail's `Mock` mechanism works
// on *instance* methods, so these mocks are primarily useful for:
//
//   1. `registerFallbackValue(MockXxxService())` in setUpAll blocks.
//   2. Type-safe stubs if the service is ever refactored to use instance
//      methods or Riverpod-based dependency injection.
//
// For the current static architecture, the right testing strategy is to
// override the *Riverpod providers* that consume these services (see
// `mock_providers.dart`), not to mock the service classes directly.

class MockBillingService extends Mock implements BillingService {}

class MockOrderService extends Mock implements OrderService {}

class MockTableService extends Mock implements TableService {}

class MockStaffService extends Mock implements StaffService {}

class MockAttendanceService extends Mock implements AttendanceService {}

class MockKhataWriteService extends Mock implements KhataWriteService {}

class MockCouponService extends Mock implements CouponService {}

class MockReservationService extends Mock implements ReservationService {}

class MockFeedbackService extends Mock implements FeedbackService {}

class MockIngredientService extends Mock implements IngredientService {}

class MockVendorService extends Mock implements VendorService {}

class MockWastageService extends Mock implements WastageService {}

class MockAdminFirestoreService extends Mock implements AdminFirestoreService {}
