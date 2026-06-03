# TulasiHotels — DEFINITIVE Automated Testing Plan

> **Date:** July 2, 2025
> **Target:** 100% file-level test coverage — every source file under `lib/` has corresponding tests.
> **Baseline:** 2,210 tests passing, 132 test files, 287 source files.

---

## Table of Contents

1. [Current State — Full Audit](#current-state)
2. [File-by-File Gap Analysis](#gap-analysis)
3. [Phase 0 — Test Factory & Helper Expansion](#phase-0)
4. [Phase 1 — Untested Models (20 files, ~280 tests)](#phase-1)
5. [Phase 2 — Untested Feature Services (24 files, ~340 tests)](#phase-2)
6. [Phase 3 — Untested Providers (16 files, ~160 tests)](#phase-3)
7. [Phase 4 — Test Infrastructure: pumpApp + Mocks (5 files)](#phase-4)
8. [Phase 5 — Feature Screens & Widgets (60 files, ~600 tests)](#phase-5)
9. [Phase 6 — Integration Flows (8 files, ~80 tests)](#phase-6)
10. [Phase 7 — Routing, Guards & Deep Links (3 files, ~50 tests)](#phase-7)
11. [Phase 8 — Accessibility & Responsive (4 files, ~40 tests)](#phase-8)
12. [Projected Totals & Quality Gates](#totals)
13. [CI Integration](#ci)
14. [Execution Dependency Graph](#dependency-graph)

---

<a name="current-state"></a>
## 1. Current State — Full Audit

### Metrics

| Metric                    | Count       |
|--------------------------|-------------|
| Source files (`lib/`)     | **287**     |
| Test files (`test/`)      | **132**     |
| Test cases                | **2,210**   |
| File-level coverage       | **46%**     |
| Features with zero tests  | **12 of 22** |
| Models with zero tests    | **20 of 29** |
| Feature services untested | **24 of 24** |
| Feature providers untested| **16 of 16** |
| Screens untested          | **~70**     |

### Tech Stack for Tests

| Package                 | Version  | Purpose                          |
|------------------------|----------|----------------------------------|
| `flutter_test`          | SDK      | Core Flutter testing             |
| `mocktail`              | ^1.0.4   | Zero-codegen mocking             |
| `fake_cloud_firestore`  | ^4.0.1   | In-memory Firestore for services |
| `build_runner`          | ^2.4.0   | Code generation                  |

### Existing Test Helpers

| File                                | Purpose                                                |
|-------------------------------------|--------------------------------------------------------|
| `test/helpers/test_app.dart`        | `testApp(Widget)` — wraps in MaterialApp + Scaffold    |
| `test/helpers/test_factories.dart`  | 8 factories: `makeProduct`, `makeBill`, `makeCustomer`, `makeTransaction`, `makeUser`, `makeExpense`, `makeSubscription`, `makeLimits` |

### Existing Tests by Directory

| Directory            | Files | What's Covered                                                            |
|---------------------|-------|---------------------------------------------------------------------------|
| `test/config/`       | 2     | Razorpay, RemoteConfig                                                   |
| `test/constants/`    | 1     | Firebase constants                                                       |
| `test/design/`       | 6     | Colors, sizes, theme, typography, design system, spacing                 |
| `test/integration/`  | 8     | Billing flow, concurrency, CSV import, desktop auth, khata, offline, product lifecycle, subscription enforcement |
| `test/l10n/`         | 1     | Localizations                                                            |
| `test/models/`       | 23    | Bill (×3), billing logic, customer (×2), expense, notification, product (×3 + customer extended + stock/profit), reports, sales summary, subscription, theme settings, transaction (×2), user (×3), admin (×2) |
| `test/providers/`    | 16    | Auth state, billing, bills filter, cart, core, expense filter, khata logic, khata stats, paginated, phone auth, products, reports, settings, super admin (×2), theme settings |
| `test/routing/`      | 1     | Basic routing                                                            |
| `test/security/`     | 2     | Admin protection, data isolation                                         |
| `test/services/`     | 43    | Analytics, app health, barcode lookup, bill share, billing (×2), conflict resolution, connectivity, CSV parsing, data export (×2), data retention, demo data, error logging, image, khata write, memory management, notification (×2), offline storage, payment (×3), performance, privacy consent, product catalog, product CSV, razorpay, receipt, referral, retry, schema migration, sync (×2), thermal printer, throttle, UPI, usage tracking, user metrics, user usage, windows update (×2), write retry queue |
| `test/unit/`         | 4     | Auth state, cart provider, mock data, validators                         |
| `test/utils/`        | 8     | a11y, color utils, constants, error handler, extensions, formatters, id generator, website URL |
| `test/widgets/`      | 15    | Adaptive layout, auth layout, auth social, cart section, demo banner, loading states, maintenance, offline banner, password strength, product grid, responsive, shared widgets, shop logo, splash screen, sync badge, upgrade prompt |
| **TOTAL**            | **130** | (+ 2 helper files = 132 total)                                          |

---

<a name="gap-analysis"></a>
## 2. File-by-File Gap Analysis

Every source file is listed below. **✅ = has test(s). ❌ = NEEDS test.** Files marked "skip" are auto-generated or trivial config.

### 2A. Core Layer (`lib/core/`)

| # | Source File | Has Test? | Notes |
|---|-----------|-----------|-------|
| 1 | `core/config/app_check_config.dart` | ❌ skip | Firebase AppCheck init — platform-specific, not unit-testable |
| 2 | `core/config/razorpay_config.dart` | ✅ | `test/config/razorpay_config_test.dart` |
| 3 | `core/config/remote_config_state.dart` | ✅ | `test/config/remote_config_state_test.dart` |
| 4 | `core/constants/app_constants.dart` | ✅ | via `test/utils/constants_test.dart` |
| 5 | `core/constants/firebase_constants.dart` | ✅ | `test/constants/firebase_constants_test.dart` |
| 6 | `core/data/mock_data.dart` | ✅ | `test/unit/mock_data_test.dart` |
| 7 | `core/design/app_colors.dart` | ✅ | `test/design/app_colors_test.dart` |
| 8 | `core/design/app_sizes.dart` | ✅ | `test/design/app_sizes_test.dart` |
| 9 | `core/design/app_theme.dart` | ✅ | `test/design/app_theme_test.dart` |
| 10 | `core/design/app_typography.dart` | ✅ | `test/design/app_typography_test.dart` |
| 11 | `core/design/design_system.dart` | ✅ | `test/design/design_system_test.dart` |
| 12 | `core/providers/core_providers.dart` | ✅ | `test/providers/core_providers_test.dart` |
| 13 | `core/providers/paginated_collections_provider.dart` | ✅ | via `test/providers/paginated_provider_test.dart` |
| 14 | `core/providers/paginated_provider.dart` | ✅ | `test/providers/paginated_provider_test.dart` |
| 15 | `core/services/analytics_service.dart` | ✅ | `test/services/analytics_platform_test.dart` |
| 16 | `core/services/android_update_service.dart` | ❌ skip | Platform-specific Android API call — not unit-testable |
| 17 | `core/services/app_health_service.dart` | ✅ | `test/services/app_health_test.dart` |
| 18 | `core/services/barcode_lookup_service.dart` | ✅ | `test/services/barcode_lookup_test.dart` |
| 19 | `core/services/barcode_scanner_service.dart` | ❌ skip | Camera hardware — not unit-testable |
| 20 | `core/services/conflict_resolution_service.dart` | ✅ | `test/services/conflict_resolution_test.dart` |
| 21 | `core/services/connectivity_service.dart` | ✅ | `test/services/connectivity_test.dart` |
| 22 | `core/services/data_export_service.dart` | ✅ | `test/services/data_export_service_test.dart` + `data_export_classes_test.dart` |
| 23 | `core/services/data_retention_service.dart` | ✅ | `test/services/data_retention_test.dart` |
| 24 | `core/services/demo_data_service.dart` | ✅ | `test/services/demo_data_service_test.dart` |
| 25 | `core/services/error_logging_service.dart` | ✅ | `test/services/error_logging_test.dart` |
| 26 | `core/services/image_service.dart` | ✅ | `test/services/image_service_test.dart` |
| 27 | `core/services/offline_order_service.dart` | ✅ | via `test/services/offline_storage_settings_test.dart` |
| 28 | `core/services/offline_storage_service.dart` | ✅ | `test/services/offline_storage_settings_test.dart` |
| 29 | `core/services/payment_link_service.dart` | ✅ | `test/services/payment_link_test.dart` |
| 30 | `core/services/performance_service.dart` | ✅ | `test/services/performance_test.dart` |
| 31 | `core/services/privacy_consent_service.dart` | ✅ | `test/services/privacy_consent_test.dart` |
| 32 | `core/services/product_catalog_service.dart` | ✅ | `test/services/product_catalog_test.dart` |
| 33 | `core/services/product_csv_service.dart` | ✅ | `test/services/product_csv_service_test.dart` + `csv_parsing_test.dart` |
| 34 | `core/services/razorpay_service.dart` | ✅ | `test/services/razorpay_result_test.dart` |
| 35 | `core/services/receipt_service.dart` | ✅ | `test/services/receipt_service_test.dart` |
| 36 | `core/services/schema_migration_service.dart` | ✅ | `test/services/schema_migration_service_test.dart` |
| 37 | `core/services/sync_settings_service.dart` | ✅ | `test/services/sync_settings_test.dart` |
| 38 | `core/services/sync_status_service.dart` | ✅ | `test/services/sync_status_test.dart` |
| 39 | `core/services/thermal_printer_service.dart` | ✅ | `test/services/thermal_printer_test.dart` |
| 40 | `core/services/throttle_service.dart` | ✅ | `test/services/throttle_test.dart` |
| 41 | `core/services/usage_tracking_service.dart` | ✅ | `test/services/usage_tracking_test.dart` |
| 42 | `core/services/user_metrics_service.dart` | ✅ | `test/services/user_metrics_test.dart` |
| 43 | `core/services/user_usage_service.dart` | ✅ | `test/services/user_usage_test.dart` |
| 44 | `core/services/web_persistence.dart` | ❌ skip | Web-only conditional import stub |
| 45 | `core/services/web_persistence_stub.dart` | ❌ skip | Stub for non-web platforms |
| 46 | `core/services/windows_update_service.dart` | ✅ | `test/services/windows_update_test.dart` + `windows_update_classes_test.dart` |
| 47 | `core/services/write_retry_queue.dart` | ✅ | `test/services/write_retry_queue_test.dart` |
| 48 | `core/theme/adaptive_layout.dart` | ✅ | `test/widgets/adaptive_layout_test.dart` |
| 49 | `core/theme/responsive_helper.dart` | ✅ | `test/widgets/responsive_test.dart` |
| 50 | `core/theme/responsive_scale.dart` | ✅ | via responsive test |
| 51 | `core/theme/responsive_utils.dart` | ✅ | via responsive test |
| 52 | `core/theme/responsive_wrapper.dart` | ✅ | via responsive test |
| 53 | `core/utils/a11y.dart` | ✅ | `test/utils/a11y_test.dart` |
| 54 | `core/utils/color_utils.dart` | ✅ | `test/utils/color_utils_test.dart` |
| 55 | `core/utils/error_handler.dart` | ✅ | `test/utils/error_handler_test.dart` |
| 56 | `core/utils/extensions.dart` | ✅ | `test/utils/extensions_test.dart` |
| 57 | `core/utils/formatters.dart` | ✅ | `test/utils/formatters_test.dart` |
| 58 | `core/utils/id_generator.dart` | ✅ | `test/utils/id_generator_test.dart` |
| 59 | `core/utils/platform_utils.dart` | ❌ skip | Platform detection — not testable without mocking Platform |
| 60 | `core/utils/validators.dart` | ✅ | `test/unit/validators_test.dart` |
| 61 | `core/utils/website_url.dart` | ✅ | `test/utils/website_url_test.dart` |
| 62 | `core/widgets/force_update_screen.dart` | ❌ **NEEDS** | Widget test |
| 63 | `core/widgets/maintenance_screen.dart` | ✅ | `test/widgets/maintenance_screen_test.dart` |
| 64 | `core/widgets/splash_screen.dart` | ✅ | `test/widgets/splash_screen_test.dart` |

**Core coverage: 58/64 (91%) — 3 need tests, 3 are skip (platform-specific)**

### 2B. Models (`lib/models/`)

| # | Source File | Has Test? | Complexity Notes |
|---|-----------|-----------|------------------|
| 1 | `models/attendance_model.dart` | ❌ **NEEDS** | `hoursWorked` getter, `AttendanceStatus` enum, fromFirestore/toFirestore |
| 2 | `models/bill_model.dart` | ✅ | 3 test files + billing logic test |
| 3 | `models/cash_register_model.dart` | ❌ **NEEDS** | `CashMovement` nested class, `isOpen` getter, batch movements |
| 4 | `models/combo_model.dart` | ❌ **NEEDS** | `ComboItem` nested class, `DietaryTag` import |
| 5 | `models/complaint_model.dart` | ❌ **NEEDS** | `resolutionTime` getter, 2 enums (`ComplaintStatus`, `ComplaintCategory`) |
| 6 | `models/coupon_model.dart` | ❌ **NEEDS** | **COMPLEX**: `isValid` multi-condition check, `isHappyHourActive`, `calculateDiscount` with min/max |
| 7 | `models/customer_model.dart` | ✅ | 2 test files |
| 8 | `models/equipment_model.dart` | ❌ **NEEDS** | `ServiceRecord` nested, `isServiceOverdue`, `isUnderWarranty` getters |
| 9 | `models/event_model.dart` | ❌ **NEEDS** | `EventMenuItem` nested, `balanceDue`, `isUpcoming` getters |
| 10 | `models/expense_model.dart` | ✅ | `test/models/expense_model_test.dart` |
| 11 | `models/feedback_model.dart` | ❌ **NEEDS** | `averageRating` computed getter |
| 12 | `models/ingredient_model.dart` | ❌ **NEEDS** | `isLowStock`, `isExpiringSoon(days)` predicates |
| 13 | `models/license_model.dart` | ❌ **NEEDS** | **COMPLEX**: `daysUntilExpiry`, `isExpired`, `urgency` (4-tier: expired/critical/warning/ok), `LicenseType` enum |
| 14 | `models/message_model.dart` | ❌ **NEEDS** | Simple model with `isBroadcast`, `isRead` flags |
| 15 | `models/order_model.dart` | ❌ **NEEDS** | **MOST COMPLEX**: ~400 lines, `OrderItem` + `OrderModel`, 3 enums, `total`/`itemCount`/`isActive`/`allItemsServed`/`elapsed`/`pendingItems`/`preparingItems`/`readyItems` getters |
| 16 | `models/product_model.dart` | ✅ | 3 test files + extended |
| 17 | `models/purchase_model.dart` | ❌ **NEEDS** | `PurchaseItem` nested, `isPaid`/`amountDue` getters |
| 18 | `models/reservation_model.dart` | ❌ **NEEDS** | `ReservationStatus` enum (5 values), `durationMinutes` default |
| 19 | `models/sales_summary_model.dart` | ✅ | `test/models/sales_summary_test.dart` |
| 20 | `models/shift_model.dart` | ❌ **NEEDS** | `duration` getter, `ShiftType` enum, swap fields |
| 21 | `models/staff_model.dart` | ❌ **NEEDS** | `StaffRole` enum, `permissions` map, PIN field |
| 22 | `models/table_model.dart` | ❌ **NEEDS** | `displayName`, `isFree`, `hasActiveOrder`, layout fields (posX/posY/shape) |
| 23 | `models/task_model.dart` | ❌ **NEEDS** | `isOverdue` getter, `TaskStatus`/`TaskPriority` enums |
| 24 | `models/theme_settings_model.dart` | ✅ | `test/models/theme_settings_test.dart` |
| 25 | `models/transaction_model.dart` | ✅ | 2 test files |
| 26 | `models/user_model.dart` | ✅ | 3 test files |
| 27 | `models/vendor_model.dart` | ❌ **NEEDS** | `supplyItems` list, `balance` tracking |
| 28 | `models/wastage_model.dart` | ❌ **NEEDS** | `WastageReason` enum, `estimatedCost`, `IngredientUnit` import |

**Model coverage: 9/28 (32%) — 19 need tests, 0 skip**

### 2C. Feature Services (all under `lib/features/*/services/`)

| # | Source File | Has Test? | Lines | Key Complexity |
|---|-----------|-----------|-------|---------------|
| 1 | `auth/providers/auth_provider.dart` | ✅ | | |
| 2 | `auth/providers/phone_auth_provider.dart` | ✅ | | via phone auth test |
| 3 | `billing/services/bill_share_service.dart` | ✅ | | `test/services/bill_share_test.dart` |
| 4 | `billing/services/billing_service.dart` | ✅ | | `test/services/billing_service_test.dart` |
| 5 | `billing/services/gst_service.dart` | ✅ | | via billing tests |
| 6 | `compliance/services/complaint_service.dart` | ❌ **NEEDS** | ~75 | Status-based filtering, `resolvedAt` timestamps |
| 7 | `compliance/services/equipment_service.dart` | ❌ **NEEDS** | ~70 | Service date forecasting, array ops on service history |
| 8 | `compliance/services/event_service.dart` | ❌ **NEEDS** | ~65 | Date-based filtering, temporal ordering |
| 9 | `compliance/services/license_service.dart` | ❌ **NEEDS** | ~80 | **Renewal workflow** with new license number, temporal filtering |
| 10 | `coupons/services/coupon_service.dart` | ❌ **NEEDS** | ~110 | **Coupon validation**, happy hour logic, usage tracking |
| 11 | `feedback/services/feedback_service.dart` | ❌ **NEEDS** | ~95 | **Rating aggregation**, public submission bypass |
| 12 | `inventory/services/ingredient_service.dart` | ❌ **NEEDS** | ~90 | Low-stock detection, atomic stock adjustments |
| 13 | `inventory/services/vendor_service.dart` | ❌ **NEEDS** | ~70 | Active/inactive filtering |
| 14 | `inventory/services/vendor_settlement_service.dart` | ❌ **NEEDS** | ~95 | **Batch operations**, balance mutations, cross-collection queries |
| 15 | `inventory/services/wastage_service.dart` | ❌ **NEEDS** | ~85 | **Batch write**: wastage log + ingredient stock deduction |
| 16 | `khata/services/khata_write_service.dart` | ✅ | | `test/services/khata_write_logic_test.dart` |
| 17 | `kitchen/services/kot_printer_service.dart` | ❌ **NEEDS** | ~180 | **ESC/POS byte generation**, station-wise grouping, amendment KOTs |
| 18 | `menu/services/combo_service.dart` | ❌ **NEEDS** | ~75 | Availability toggle, nested ComboItem serialization |
| 19 | `notifications/services/fcm_token_service.dart` | ❌ skip | | Platform-specific FCM |
| 20 | `notifications/services/notification_firestore_service.dart` | ✅ | | `test/services/notification_test.dart` |
| 21 | `notifications/services/notification_service.dart` | ✅ | | `test/services/notification_test.dart` |
| 22 | `notifications/services/windows_notification_service.dart` | ❌ skip | | Windows-only notification API |
| 23 | `orders/services/order_service.dart` | ❌ **NEEDS** | ~265 | **CRITICAL**: Multi-step lifecycle, KOT numbering, auto-status, table occupation, **order merging** |
| 24 | `referral/services/referral_service.dart` | ✅ | | `test/services/referral_logic_test.dart` |
| 25 | `reports/services/advanced_reports_service.dart` | ❌ **NEEDS** | ~120 | Date-range queries, multi-collection aggregation |
| 26 | `reservations/services/reservation_service.dart` | ❌ **NEEDS** | ~115 | **Reservation lifecycle** (pending→confirmed→seated), 90-min table lockout |
| 27 | `staff/services/attendance_service.dart` | ❌ **NEEDS** | ~180 | **Clock in/out** with fallback query, date range stream, manual correction |
| 28 | `staff/services/cash_register_service.dart` | ❌ **NEEDS** | ~70 | Open/close register, cash movement tracking |
| 29 | `staff/services/message_service.dart` | ❌ **NEEDS** | ~60 | Announcement filtering, array union read-by tracking |
| 30 | `staff/services/salary_service.dart` | ❌ **NEEDS** | ~105 | **CRITICAL**: Salary calculation — month boundaries, overtime (>8h), deductions/advances |
| 31 | `staff/services/shift_service.dart` | ❌ **NEEDS** | ~140 | **Shift swap workflow** — paired shift find + batch dual-update |
| 32 | `staff/services/staff_permissions.dart` | ❌ **NEEDS** | ~95 | **Permission resolution**: custom vs role fallback, route normalization, owner bypass |
| 33 | `staff/services/staff_service.dart` | ❌ **NEEDS** | ~150 | PIN verification, email+PIN auth, PIN uniqueness validation |
| 34 | `staff/services/task_service.dart` | ❌ **NEEDS** | ~75 | Priority-based sorting, completion timestamps |
| 35 | `subscription/services/subscription_service.dart` | ❌ **NEEDS** | ~100 | Subscription tier logic, limits enforcement |
| 36 | `super_admin/services/admin_firestore_service.dart` | ❌ **NEEDS** | ~680 | **MOST COMPLEX**: Seed with race-condition prevention, stats caching, subscription mgmt, admin list with owner protection |
| 37 | `tables/services/table_service.dart` | ❌ **NEEDS** | ~140 | **Batch table creation**, status transitions, server assignment |

**Feature service coverage: 8/37 (22%) — 24 need tests, 5 already tested, 2 skip**

### 2D. Feature Providers (all under `lib/features/*/providers/`)

| # | Source File | Has Test? | Key Complexity |
|---|-----------|-----------|---------------|
| 1 | `auth/providers/auth_provider.dart` | ✅ | `test/providers/auth_state_test.dart` |
| 2 | `auth/providers/phone_auth_provider.dart` | ✅ | `test/providers/phone_auth_state_test.dart` |
| 3 | `billing/providers/billing_provider.dart` | ✅ | `test/providers/billing_provider_test.dart` |
| 4 | `billing/providers/cart_provider.dart` | ✅ | `test/providers/cart_provider_test.dart` |
| 5 | `compliance/providers/compliance_provider.dart` | ❌ **NEEDS** | 8 stream providers across 4 services |
| 6 | `coupons/providers/coupon_provider.dart` | ❌ **NEEDS** | Active/all coupons + happy hour provider |
| 7 | `feedback/providers/feedback_provider.dart` | ❌ **NEEDS** | Recent feedback + average ratings |
| 8 | `inventory/providers/inventory_provider.dart` | ❌ **NEEDS** | 5 providers: ingredients, low stock, vendors, active vendors, wastage |
| 9 | `khata/providers/khata_provider.dart` | ✅ | `test/providers/khata_logic_test.dart` |
| 10 | `khata/providers/khata_stats_provider.dart` | ✅ | `test/providers/khata_stats_test.dart` |
| 11 | `menu/providers/combo_provider.dart` | ❌ **NEEDS** | Combos + available combos streams |
| 12 | `menu/providers/specials_provider.dart` | ❌ **NEEDS** | **Day-of-week filtering** computed provider |
| 13 | `notifications/providers/notification_provider.dart` | ❌ **NEEDS** | **Auth-dependent** conditional streams |
| 14 | `orders/providers/order_provider.dart` | ❌ **NEEDS** | **Family provider** for table orders + order type filter |
| 15 | `products/providers/products_provider.dart` | ✅ | `test/providers/products_provider_test.dart` |
| 16 | `reports/providers/reports_provider.dart` | ✅ | `test/providers/reports_provider_test.dart` |
| 17 | `reservations/providers/reservation_provider.dart` | ❌ **NEEDS** | Today + upcoming + date filter |
| 18 | `settings/providers/settings_provider.dart` | ✅ | `test/providers/settings_provider_test.dart` |
| 19 | `settings/providers/theme_settings_provider.dart` | ✅ | `test/providers/theme_settings_provider_test.dart` |
| 20 | `staff/providers/attendance_provider.dart` | ❌ **NEEDS** | **MOST COMPLEX**: 9 providers, conditional streams, week boundary math |
| 21 | `staff/providers/cash_register_provider.dart` | ❌ **NEEDS** | Today register + history |
| 22 | `staff/providers/message_provider.dart` | ❌ **NEEDS** | Messages + announcements |
| 23 | `staff/providers/shift_provider.dart` | ❌ **NEEDS** | **Family provider** for staff shifts + week start calc |
| 24 | `staff/providers/staff_provider.dart` | ❌ **NEEDS** | **Multi-dimensional filtering** (role + search), login state |
| 25 | `staff/providers/task_provider.dart` | ❌ **NEEDS** | Active tasks + family provider |
| 26 | `super_admin/providers/super_admin_provider.dart` | ✅ | `test/providers/super_admin_provider_test.dart` |
| 27 | `tables/providers/table_provider.dart` | ❌ **NEEDS** | **Multi-level derivation**: floor filter, status summary, available floors |

**Provider coverage: 11/27 (41%) — 16 need tests**

### 2E. Feature Screens (~70 untested)

| Feature | Screens | All Untested Screen Files |
|---------|---------|--------------------------|
| **auth** | 7 | `desktop_login_bridge_screen`, `desktop_login_screen`, `email_verification_screen`, `forgot_password_screen`, `login_screen`, `register_screen`, `shop_setup_screen` |
| **billing** | 5 | `billing_screen`, `bills_history_screen`, `bills_history_widgets`, `gst_export_screen`, `pos_web_screen`, `pos_web_widgets` |
| **compliance** | 4 | `complaints_screen`, `equipment_screen`, `events_screen`, `licenses_screen` |
| **coupons** | 1 | `coupons_screen` |
| **customer** | 5 | `customer_feedback_screen`, `customer_menu_screen`, `customer_order_screen`, `customer_reservation_screen`, `order_status_screen` |
| **feedback** | 2 | `feedback_dashboard_screen`, `feedback_screen` |
| **inventory** | 3 | `ingredients_screen`, `vendors_screen`, `wastage_screen` |
| **khata** | 2 | `customer_detail_screen`, `khata_web_screen` |
| **kitchen** | 1 | `kitchen_display_screen` |
| **menu** | 2 | `combo_builder_screen`, `daily_specials_screen` |
| **notifications** | 1 | `notifications_screen` |
| **orders** | 5 | `new_order_screen`, `order_billing_screen`, `order_detail_screen`, `orders_screen`, `split_bill_screen` |
| **products** | 2 | `product_detail_screen`, `products_web_screen` |
| **reports** | 9 | `advanced_reports_screen`, `comparative_screen`, `dashboard_web_screen`, `feedback_report_screen`, `item_sales_screen`, `menu_performance_screen`, `peak_hours_screen`, `pnl_report_screen`, `weekly_report_screen` |
| **reservations** | 1 | `reservations_screen` |
| **settings** | 5 | `account_settings_screen`, `billing_settings_screen`, `general_settings_screen`, `hardware_settings_screen`, `settings_web_screen`, `theme_settings_screen` |
| **shell** | 2 | `app_shell`, `web_shell` |
| **staff** | 11 | `attendance_screen`, `cash_register_screen`, `messages_screen`, `my_attendance_screen`, `permission_manager_screen`, `salary_screen`, `shift_schedule_screen`, `staff_attendance_detail_screen`, `staff_login_screen`, `staff_screen`, `task_board_screen` |
| **subscription** | 1 | `subscription_screen` |
| **super_admin** | 11 | `admin_shell_screen`, `analytics_screen`, `costs_screen`, `errors_screen`, `manage_admins_screen`, `notifications_admin_screen`, `performance_screen`, `subscriptions_screen`, `super_admin_dashboard_screen`, `super_admin_login_screen`, `user_detail_screen`, `users_list_screen` |
| **tables** | 2 | `table_layout_editor`, `tables_screen` |

**Screen coverage: 0/~72 (0%)**

### 2F. Feature Widgets (untested)

| Feature | Widget Files |
|---------|------------|
| auth | `auth_layout.dart`, `auth_social_section.dart` — ✅ tested, `demo_mode_banner.dart` — ✅, `email_verification_banner.dart` — ❌, `password_strength_indicator.dart` — ✅ |
| billing | `cart_section.dart` — ✅, `payment_modal.dart` — ❌, `product_grid.dart` — ✅, `reorder_button.dart` — ❌ |
| customer | `category_tabs.dart` — ❌, `menu_header.dart` — ❌, `menu_item_card.dart` — ❌ |
| khata | `add_customer_modal.dart` — ❌, `give_udhaar_modal.dart` — ❌, `record_payment_modal.dart` — ❌ |
| menu | `combo_card.dart` — ❌, `table_qr_generator.dart` — ❌ |
| notifications | `notification_bell.dart` — ❌ |
| products | `add_product_modal.dart` — ❌, `catalog_browser_modal.dart` — ❌ |
| reservations | `reservation_card.dart` — ❌ |
| settings | `edit_shop_modal.dart` — ❌ |
| staff | `staff_clock_widget.dart` — ❌ |
| tables | `add_table_dialog.dart` — ❌ |

### 2G. Shared Widgets (`lib/shared/widgets/`)

| # | Widget | Has Test? |
|---|--------|-----------|
| 1 | `announcement_banner.dart` | ❌ **NEEDS** |
| 2 | `app_button.dart` | ✅ via shared_widgets_test |
| 3 | `app_text_field.dart` | ✅ via shared_widgets_test |
| 4 | `global_sync_indicator.dart` | ❌ **NEEDS** |
| 5 | `loading_states.dart` | ✅ |
| 6 | `logout_dialog.dart` | ❌ **NEEDS** |
| 7 | `nps_survey_dialog.dart` | ❌ **NEEDS** |
| 8 | `offline_banner.dart` | ✅ |
| 9 | `onboarding_checklist.dart` | ❌ **NEEDS** |
| 10 | `shop_logo_widget.dart` | ✅ |
| 11 | `sync_badge.dart` | ✅ |
| 12 | `sync_details_sheet.dart` | ❌ **NEEDS** |
| 13 | `update_banner.dart` | ❌ **NEEDS** |
| 14 | `update_dialog.dart` | ❌ **NEEDS** |

### 2H. Top-Level & Generated (skip)

| File | Has Test? | Notes |
|------|-----------|-------|
| `app.dart` | ❌ skip | App root widget — tested via integration |
| `main.dart` | ❌ skip | Entry point — not unit-testable |
| `firebase_options.dart` | ❌ skip | Auto-generated |
| `l10n/app_localizations.dart` | ✅ | `test/l10n/app_localizations_test.dart` |
| `router/app_router.dart` | ✅ (partial) | `test/routing/routing_test.dart` — needs expansion |
| `features/staff/models/permission_config.dart` | ❌ **NEEDS** | Staff permission config model |
| `features/super_admin/models/admin_user_model.dart` | ✅ | `test/models/admin_user_model_test.dart` |
| `features/notifications/models/notification_model.dart` | ✅ | `test/models/notification_model_test.dart` |
```

**Estimated:** 5 helper files, 0 test cases (infrastructure only)

---

<a name="phase-1"></a>
## 5. Phase 1 — Untested Models (19 files, ~280 tests)

**Goal:** Every model has serialization round-trip, copyWith, computed getters, and edge-case tests.
**Priority:** HIGHEST — models are the foundation everything else depends on.
**Dependencies:** None — can start immediately.

### Standard Test Pattern Per Model

Every model test MUST include these groups:

```dart
group('MyModel', () {
  group('fromFirestore / toFirestore', () {
    test('round-trip preserves all fields');
    test('handles null optional fields');
    test('handles missing map keys gracefully');
  });
  group('copyWith', () {
    test('preserves unchanged fields');
    test('overrides specified fields');
  });
  group('computed getters', () {
    // Model-specific: isExpired, total, hoursWorked, etc.
  });
  group('enum serialization', () {
    test('every enum value round-trips');
  });
});
```

### Complete File List with Specific Test Requirements

| # | Test File to Create | Source | Lines | Specific Tests Required (beyond standard) |
|---|-------------------|--------|-------|------------------------------------------|
| 1 | `test/models/attendance_model_test.dart` | `models/attendance_model.dart` | ~90 | `hoursWorked` with clockOut null → 0, `hoursWorked` across midnight, `AttendanceStatus` enum round-trip |
| 2 | `test/models/cash_register_model_test.dart` | `models/cash_register_model.dart` | ~150 | `CashMovement` nested fromFirestore/toFirestore, `isOpen` getter (closedAt null vs set), movements list serialization |
| 3 | `test/models/combo_model_test.dart` | `models/combo_model.dart` | ~130 | `ComboItem` nested serialization, `DietaryTag` enum from product_model, `isAvailable` toggle |
| 4 | `test/models/complaint_model_test.dart` | `models/complaint_model.dart` | ~160 | `resolutionTime` getter (null when unresolved, Duration when resolved), `ComplaintStatus` transitions, `ComplaintCategory` values |
| 5 | `test/models/coupon_model_test.dart` | `models/coupon_model.dart` | ~200 | **HIGH PRIORITY**: `isValid` (active check, date range, usage limit, expired), `isHappyHourActive` (hour boundary), `calculateDiscount` (percentage vs flat, minOrderAmount, maxDiscount cap) |
| 6 | `test/models/equipment_model_test.dart` | `models/equipment_model.dart` | ~170 | `ServiceRecord` nested list serialization, `isServiceOverdue` (past vs future nextServiceDue), `isUnderWarranty` (expired vs active warranty) |
| 7 | `test/models/event_model_test.dart` | `models/event_model.dart` | ~160 | `EventMenuItem` nested list, `balanceDue` (totalAmount - advancePaid), `isUpcoming` (future vs past eventDate) |
| 8 | `test/models/feedback_model_test.dart` | `models/feedback_model.dart` | ~100 | `averageRating` (all zero → 0.0, mixed ratings, single non-zero) |
| 9 | `test/models/ingredient_model_test.dart` | `models/ingredient_model.dart` | ~150 | `isLowStock` (at level, below, above), `isExpiringSoon(days)` (within window, past expiry, null expiry → false), `IngredientUnit` enum |
| 10 | `test/models/license_model_test.dart` | `models/license_model.dart` | ~150 | **HIGH PRIORITY**: `daysUntilExpiry`, `isExpired`, `urgency` 4-tier logic (expired/critical <30d/warning 30-90d/ok >90d), `LicenseType` enum (7 values) |
| 11 | `test/models/message_model_test.dart` | `models/message_model.dart` | ~85 | `isBroadcast`/`isRead` flags, `targetRole` optional field |
| 12 | `test/models/order_model_test.dart` | `models/order_model.dart` | ~400 | **HIGHEST PRIORITY**: `OrderItem` serialization, `total` (sum of item.price × quantity), `itemCount`, `isActive` (not billed/cancelled), `allItemsServed`/`allItemsReady`, `elapsed`, `pendingItems`/`preparingItems`/`readyItems` filtered getters, 3 enums (`OrderStatus`, `OrderItemStatus`, `OrderType`) |
| 13 | `test/models/purchase_model_test.dart` | `models/purchase_model.dart` | ~170 | `PurchaseItem` nested, `isPaid`/`amountDue` getters, empty items list |
| 14 | `test/models/reservation_model_test.dart` | `models/reservation_model.dart` | ~130 | `ReservationStatus` 5-value enum, `durationMinutes` default 90, null `tableId` |
| 15 | `test/models/shift_model_test.dart` | `models/shift_model.dart` | ~120 | `duration` getter (endTime - startTime), `ShiftType` enum, swap fields (`isSwapRequested`, `swapWithStaffId`) |
| 16 | `test/models/staff_model_test.dart` | `models/staff_model.dart` | ~110 | `StaffRole` enum (4 values), `permissions` Map<String, List<String>> serialization, `isActive` toggle, `pin` field |
| 17 | `test/models/table_model_test.dart` | `models/table_model.dart` | ~130 | `displayName` (label ?? "Table {number}"), `isFree` (status == available), `hasActiveOrder` (currentOrderId != null), `TableStatus` 4-value enum, layout fields (posX/posY/shape) |
| 18 | `test/models/task_model_test.dart` | `models/task_model.dart` | ~160 | `isOverdue` (dueDate < now && status != completed), `TaskStatus`/`TaskPriority` enums, null `dueDate` → not overdue |
| 19 | `test/models/vendor_model_test.dart` | `models/vendor_model.dart` | ~90 | `supplyItems` list serialization, `balance` field, multiple optional string fields |

Also add **1 model from features**:

| 20 | `test/models/permission_config_test.dart` | `features/staff/models/permission_config.dart` | ~50 | Permission config model serialization |

**Estimated: 20 files, ~280 test cases**

---

<a name="phase-2"></a>
## 6. Phase 2 — Untested Feature Services (24 files, ~340 tests)

**Goal:** Every service has Firestore CRUD tests + business logic edge cases.
**Priority:** HIGH — business logic lives here.
**Dependencies:** `fake_cloud_firestore`, `mocktail`, Phase 1 model factories

### Standard Service Test Pattern

```dart
group('MyService', () {
  late FakeFirebaseFirestore fakeFirestore;
  late MyService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    // Inject fake Firestore + mock auth
    service = MyService(firestore: fakeFirestore);
  });

  test('create — writes document with correct fields');
  test('read — returns null for missing doc');
  test('read — deserializes existing doc');
  test('update — modifies fields on existing doc');
  test('delete — removes document');
  test('stream — emits list on collection change');
  test('business rule: <specific>');
});
```

### Complete File List — Ordered by Complexity (highest first)

| # | Test File | Source | Lines | Priority | Specific Tests Required |
|---|----------|--------|-------|----------|------------------------|
| 1 | `test/services/admin_firestore_service_test.dart` | `super_admin/services/admin_firestore_service.dart` | ~680 | **P0** | `ensureAdminSeeded` idempotency, `getAllUsers` pagination + filters, `getAdminStats` caching logic, `recalculateStats` accuracy, `updateUserSubscription` with limits sync, `addAdminEmail`/`removeAdminEmail` with primary owner protection, `getExpiringSubscriptions` date window |
| 2 | `test/services/order_service_test.dart` | `orders/services/order_service.dart` | ~265 | **P0** | `createOrder` (allocates order number, sets table to occupied), `addItemsToOrder` (KOT increment, amendment items), `updateOrderStatus` lifecycle transitions, `updateItemStatus` auto-status advancement, `markAllItemsReady`, `completeOrder` (frees table), `cancelOrder` (frees table), **`mergeOrders`** (consolidates items, recalculates KOT), `kitchenOrdersStream` filtering |
| 3 | `test/services/salary_service_test.dart` | `staff/services/salary_service.dart` | ~105 | **P0** | `calculateSalary` month boundary queries, hours worked aggregation from attendance, overtime threshold (>8h per day), deductions/advances subtraction, zero-attendance month |
| 4 | `test/services/attendance_service_test.dart` | `staff/services/attendance_service.dart` | ~180 | **P0** | `clockIn` creates record, `clockOut` updates clockOut + status, `isClockedIn` fallback query, `addManualRecord`, `updateRecord` partial fields, date range stream filtering, `todayAttendanceStream` boundary (midnight to midnight) |
| 5 | `test/services/staff_service_test.dart` | `staff/services/staff_service.dart` | ~150 | **P0** | `createStaff` (generates ID, validates PIN), `verifyPin` (returns null for inactive staff), `verifyEmailAndPin` combo auth, `isPinTaken` with exclusion, `updatePermissions` map write, `toggleStaffActive` |
| 6 | `test/services/staff_permissions_test.dart` | `staff/services/staff_permissions.dart` | ~95 | **P0** | `canAccess` by role, `hasAction` check, `permittedRoutes` for waiter/chef/cashier/manager, `homeRoute` per role, `visibleNavIndices` with null (owner) bypass, custom permissions override role defaults |
| 7 | `test/services/table_service_test.dart` | `tables/services/table_service.dart` | ~140 | **P1** | `createTable` (ID generation, defaults), `createBulkTables` batch, `updateTableStatus` with orderId tracking, `assignServer`/`clearServerAssignment`, `serverTablesStream` filtering |
| 8 | `test/services/reservation_service_test.dart` | `reservations/services/reservation_service.dart` | ~115 | **P1** | Lifecycle: `createReservation` → `confirmReservation` → `seatReservation(tableId)` → billed, `cancelReservation`, `markNoShow`, **`isTableAvailable`** (90-min lockout window) |
| 9 | `test/services/shift_service_test.dart` | `staff/services/shift_service.dart` | ~140 | **P1** | `createShift`, `createBulkShifts` batch, week range stream, **`requestSwap`** + **`approveSwap`** paired update workflow |
| 10 | `test/services/coupon_service_test.dart` | `coupons/services/coupon_service.dart` | ~110 | **P1** | **`validateCoupon`** (min order, expired, usage limit, inactive), **`applyCoupon`** usage increment, **`getActiveHappyHourCoupon`** time filtering, `toggleActive` |
| 11 | `test/services/vendor_settlement_service_test.dart` | `inventory/services/vendor_settlement_service.dart` | ~95 | **P1** | `recordPayment` batch (balance deduction + payment log), `vendorBalanceStream`, `unpaidPurchases` query, `paymentHistoryStream` transformation |
| 12 | `test/services/wastage_service_test.dart` | `inventory/services/wastage_service.dart` | ~85 | **P1** | `logWastage` batch (wastage doc + ingredient stock deduction), `recentWastageStream`, `wastageForDateRange` |
| 13 | `test/services/kot_printer_test.dart` | `kitchen/services/kot_printer_service.dart` | ~180 | **P1** | `buildKOT` byte output structure, `buildAmendmentKOT` with new items only, `buildStationKOTs` grouping by item station |
| 14 | `test/services/advanced_reports_service_test.dart` | `reports/services/advanced_reports_service.dart` | ~120 | **P1** | Date-range aggregation, multi-collection queries, accuracy of computed stats |
| 15 | `test/services/subscription_service_test.dart` | `subscription/services/subscription_service.dart` | ~100 | **P1** | Tier limits enforcement, expiry detection, upgrade/downgrade logic |
| 16 | `test/services/feedback_service_test.dart` | `feedback/services/feedback_service.dart` | ~95 | **P2** | `submitFeedback`, `submitPublicFeedback` (no auth), `getAverageRatings` aggregation |
| 17 | `test/services/license_service_test.dart` | `compliance/services/license_service.dart` | ~80 | **P2** | `licensesStream`, `expiringLicensesStream` (30-day window), `renewLicense` workflow (new dates + optional new number) |
| 18 | `test/services/complaint_service_test.dart` | `compliance/services/complaint_service.dart` | ~75 | **P2** | CRUD, `updateStatus` with `resolvedAt` timestamp on close, `activeComplaintsStream` filtering |
| 19 | `test/services/ingredient_service_test.dart` | `inventory/services/ingredient_service.dart` | ~90 | **P2** | `adjustStock` atomic update, `lowStockStream` filtering, `getIngredient` by ID |
| 20 | `test/services/equipment_service_test.dart` | `compliance/services/equipment_service.dart` | ~70 | **P2** | `addServiceRecord` array append, `needsServiceStream` 30-day lookahead |
| 21 | `test/services/event_service_test.dart` | `compliance/services/event_service.dart` | ~65 | **P2** | `upcomingEventsStream` date filter, CRUD |
| 22 | `test/services/cash_register_service_test.dart` | `staff/services/cash_register_service.dart` | ~70 | **P2** | `openRegister` / `closeRegister`, `addCashMovement`, `todayRegisterStream` |
| 23 | `test/services/combo_service_test.dart` | `menu/services/combo_service.dart` | ~75 | **P2** | CRUD, `toggleAvailability`, `availableCombosStream` |
| 24 | `test/services/task_service_test.dart` | `staff/services/task_service.dart` | ~75 | **P2** | Priority sort, `updateTaskStatus` with completion timestamp |
| 25 | `test/services/message_service_test.dart` | `staff/services/message_service.dart` | ~60 | **P2** | `markAsRead` array union, `announcementsStream` filter |
| 26 | `test/services/vendor_service_test.dart` | `inventory/services/vendor_service.dart` | ~70 | **P2** | Active/inactive filter, CRUD |

**Estimated: 26 files, ~340 test cases**

---

<a name="phase-3"></a>
## 7. Phase 3 — Untested Providers (16 files, ~160 tests)

**Goal:** Every Riverpod provider has state management and derived state tests.
**Priority:** HIGH — providers connect services to UI.
**Dependencies:** `mocktail`, Phase 2 mock services

### Provider Test Pattern

```dart
group('MyProvider', () {
  late ProviderContainer container;
  late MockMyService mockService;

  setUp(() {
    mockService = MockMyService();
    container = ProviderContainer(overrides: [
      myServiceProvider.overrideWithValue(mockService),
    ]);
  });

  tearDown(() => container.dispose());

  test('initial state');
  test('emits data on success');
  test('emits error on failure');
  test('derived provider updates when source changes');
  test('filter/sort state');
});
```

### Complete File List — Ordered by Complexity

| # | Test File | Source | Providers to Test | Specific Tests |
|---|----------|--------|------------------|----------------|
| 1 | `test/providers/attendance_provider_test.dart` | `staff/providers/attendance_provider.dart` | 9 providers | **MOST COMPLEX**: `todayAttendance`, conditional `staffDetailAttendance` (empty when no staff selected), week boundary (Mon-Sun) for `thisWeek`/`lastWeek`, `attendanceDateRange` state, `staffDetailPanel` state management |
| 2 | `test/providers/table_provider_test.dart` | `tables/providers/table_provider.dart` | 5 providers | `filteredTablesProvider` floor filtering, `availableFloorsProvider` derived state, `tableStatusSummaryProvider` aggregation, `selectedFloorProvider` state |
| 3 | `test/providers/staff_provider_test.dart` | `staff/providers/staff_provider.dart` | 6 providers | `filteredStaffProvider` multi-dimensional filter (role + search), case-insensitive search, `loggedInStaffProvider` state, `staffRoleFilterProvider` |
| 4 | `test/providers/order_provider_test.dart` | `orders/providers/order_provider.dart` | 5 providers | `tableOrdersProvider` family (different table IDs), `filteredActiveOrdersProvider` order type filter, `orderTypeFilterProvider` state |
| 5 | `test/providers/compliance_provider_test.dart` | `compliance/providers/compliance_provider.dart` | 8 providers | All 4 service-backed streams for licenses, equipment, complaints, events (active + all variants) |
| 6 | `test/providers/inventory_provider_test.dart` | `inventory/providers/inventory_provider.dart` | 5 providers | Ingredients, low stock, vendors, active vendors, wastage streams |
| 7 | `test/providers/notification_provider_test.dart` | `notifications/providers/notification_provider.dart` | 2 providers | **Auth-dependent**: returns empty when no user, streams when authenticated, `unreadCount` |
| 8 | `test/providers/shift_provider_test.dart` | `staff/providers/shift_provider.dart` | 3 providers | `staffShiftsProvider` family, `shiftWeekStartProvider` state, `todayShiftsProvider` |
| 9 | `test/providers/reservation_provider_test.dart` | `reservations/providers/reservation_provider.dart` | 3 providers | Today + upcoming streams, `reservationDateFilterProvider` state |
| 10 | `test/providers/coupon_provider_test.dart` | `coupons/providers/coupon_provider.dart` | 3 providers | Active + all coupons, `happyHourCouponProvider` future |
| 11 | `test/providers/specials_provider_test.dart` | `menu/providers/specials_provider.dart` | 1 provider | **Day-of-week filtering** computed logic |
| 12 | `test/providers/combo_provider_test.dart` | `menu/providers/combo_provider.dart` | 2 providers | Combos + available combos |
| 13 | `test/providers/feedback_provider_test.dart` | `feedback/providers/feedback_provider.dart` | 2 providers | Recent feedback, average ratings |
| 14 | `test/providers/cash_register_provider_test.dart` | `staff/providers/cash_register_provider.dart` | 2 providers | Today register (nullable), history |
| 15 | `test/providers/message_provider_test.dart` | `staff/providers/message_provider.dart` | 2 providers | Recent messages, announcements |
| 16 | `test/providers/task_provider_test.dart` | `staff/providers/task_provider.dart` | 2 providers | Active tasks, `staffTasksProvider` family |

**Estimated: 16 files, ~160 test cases**

---

<a name="phase-4"></a>
## 8. Phase 4 — Test Infrastructure: pumpApp + Mocks (5 files)

**Goal:** Build shared test infrastructure so Phases 5–8 are fast to write.
**Priority:** REQUIRED before any widget/screen tests.
**Dependencies:** Phases 1–3 (for model factories and service mocks)

### New Dev Dependency

```yaml
dev_dependencies:
  network_image_mock: ^2.1.1   # Mock NetworkImage in widget tests
```

### Files to Create

| # | File | Purpose |
|---|------|---------|
| 1 | `test/helpers/pump_app.dart` | `pumpApp(WidgetTester, Widget, {overrides, initialRoute})` — wraps in ProviderScope + MaterialApp.router + Localizations |
| 2 | `test/helpers/mock_services.dart` | Mocktail mocks for ALL services: `MockBillingService`, `MockOrderService`, `MockTableService`, `MockStaffService`, `MockAttendanceService`, `MockKhataWriteService`, `MockCouponService`, `MockReservationService`, `MockFeedbackService`, `MockIngredientService`, `MockVendorService`, `MockWastageService`, `MockAdminFirestoreService` |
| 3 | `test/helpers/mock_providers.dart` | Pre-configured `ProviderScope` overrides: `loggedInOwnerOverrides`, `loggedInWaiterOverrides`, `loggedInChefOverrides`, `loggedInCashierOverrides`, `demoModeOverrides`, `offlineModeOverrides` |
| 4 | `test/helpers/fake_router.dart` | Minimal GoRouter with stub routes for testing screen navigation triggers without the full router |
| 5 | `test/helpers/test_factories_extended.dart` | Factories for all 19 new models from Phase 1: `makeAttendance`, `makeCashRegister`, `makeCombo`, `makeComplaint`, `makeCoupon`, `makeEquipment`, `makeEvent`, `makeFeedbackModel`, `makeIngredient`, `makeLicense`, `makeMessage`, `makeOrder`, `makeOrderItem`, `makePurchase`, `makeReservation`, `makeShift`, `makeStaff`, `makeTable`, `makeTask`, `makeVendor`, `makeWastage` |

### pumpApp Signature

```dart
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  String initialRoute = '/',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: fakeRouter(initialRoute, child),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

**Estimated: 5 files, 0 test cases (infrastructure)**

---

<a name="phase-5"></a>
## 9. Phase 5 — Feature Screens & Widgets (60 files, ~600 tests)

**Goal:** Every screen renders without errors, shows all states (loading/data/empty/error), and key interactions work.
**Priority:** MEDIUM — largest phase, catches UI regressions.
**Dependencies:** Phase 4 helpers

### Screen Test Pattern

```dart
group('MyScreen', () {
  testWidgets('renders without errors', (tester) async {
    await pumpApp(tester, const MyScreen(), overrides: [...]);
    expect(find.byType(MyScreen), findsOneWidget);
  });
  testWidgets('shows loading state', ...);
  testWidgets('shows data list', ...);
  testWidgets('shows empty state', ...);
  testWidgets('shows error state', ...);
  testWidgets('tap <action> triggers <result>', ...);
});
```

### 5A — Shared Widgets (8 new files)

| # | Test File | Source Widget |
|---|----------|-------------|
| 1 | `test/widgets/announcement_banner_test.dart` | `shared/widgets/announcement_banner.dart` |
| 2 | `test/widgets/global_sync_indicator_test.dart` | `shared/widgets/global_sync_indicator.dart` |
| 3 | `test/widgets/logout_dialog_test.dart` | `shared/widgets/logout_dialog.dart` |
| 4 | `test/widgets/nps_survey_dialog_test.dart` | `shared/widgets/nps_survey_dialog.dart` |
| 5 | `test/widgets/onboarding_checklist_test.dart` | `shared/widgets/onboarding_checklist.dart` |
| 6 | `test/widgets/sync_details_sheet_test.dart` | `shared/widgets/sync_details_sheet.dart` |
| 7 | `test/widgets/update_banner_test.dart` | `shared/widgets/update_banner.dart` |
| 8 | `test/widgets/update_dialog_test.dart` | `shared/widgets/update_dialog.dart` |

### 5B — Core Widgets (1 new file)

| # | Test File | Source |
|---|----------|--------|
| 1 | `test/widgets/force_update_screen_test.dart` | `core/widgets/force_update_screen.dart` |

### 5C — Feature Screens (39 new files)

Each file maps 1:1 to a source screen. Grouped by feature:

**Auth (4 files)**
| # | Test File | Screen |
|---|----------|--------|
| 1 | `test/widgets/auth/login_screen_test.dart` | `auth/screens/login_screen.dart` |
| 2 | `test/widgets/auth/register_screen_test.dart` | `auth/screens/register_screen.dart` |
| 3 | `test/widgets/auth/forgot_password_screen_test.dart` | `auth/screens/forgot_password_screen.dart` |
| 4 | `test/widgets/auth/shop_setup_screen_test.dart` | `auth/screens/shop_setup_screen.dart` |

**Billing (3 files)**
| 5 | `test/widgets/billing/billing_screen_test.dart` | `billing/screens/billing_screen.dart` |
| 6 | `test/widgets/billing/bills_history_screen_test.dart` | `billing/screens/bills_history_screen.dart` |
| 7 | `test/widgets/billing/gst_export_screen_test.dart` | `billing/screens/gst_export_screen.dart` |

**Compliance (4 files)**
| 8 | `test/widgets/compliance/complaints_screen_test.dart` | `compliance/screens/complaints_screen.dart` |
| 9 | `test/widgets/compliance/equipment_screen_test.dart` | `compliance/screens/equipment_screen.dart` |
| 10 | `test/widgets/compliance/events_screen_test.dart` | `compliance/screens/events_screen.dart` |
| 11 | `test/widgets/compliance/licenses_screen_test.dart` | `compliance/screens/licenses_screen.dart` |

**Other Features (28 files)**
| 12 | `test/widgets/coupons/coupons_screen_test.dart` | `coupons/screens/coupons_screen.dart` |
| 13 | `test/widgets/feedback/feedback_screen_test.dart` | `feedback/screens/feedback_screen.dart` |
| 14 | `test/widgets/feedback/feedback_dashboard_test.dart` | `feedback/screens/feedback_dashboard_screen.dart` |
| 15 | `test/widgets/inventory/ingredients_screen_test.dart` | `inventory/screens/ingredients_screen.dart` |
| 16 | `test/widgets/inventory/vendors_screen_test.dart` | `inventory/screens/vendors_screen.dart` |
| 17 | `test/widgets/inventory/wastage_screen_test.dart` | `inventory/screens/wastage_screen.dart` |
| 18 | `test/widgets/khata/khata_web_screen_test.dart` | `khata/screens/khata_web_screen.dart` |
| 19 | `test/widgets/kitchen/kitchen_display_test.dart` | `kitchen/screens/kitchen_display_screen.dart` |
| 20 | `test/widgets/menu/combo_builder_test.dart` | `menu/screens/combo_builder_screen.dart` |
| 21 | `test/widgets/menu/daily_specials_test.dart` | `menu/screens/daily_specials_screen.dart` |
| 22 | `test/widgets/orders/new_order_screen_test.dart` | `orders/screens/new_order_screen.dart` |
| 23 | `test/widgets/orders/orders_screen_test.dart` | `orders/screens/orders_screen.dart` |
| 24 | `test/widgets/orders/order_detail_test.dart` | `orders/screens/order_detail_screen.dart` |
| 25 | `test/widgets/reservations/reservations_screen_test.dart` | `reservations/screens/reservations_screen.dart` |
| 26 | `test/widgets/settings/general_settings_test.dart` | `settings/screens/general_settings_screen.dart` |
| 27 | `test/widgets/settings/billing_settings_test.dart` | `settings/screens/billing_settings_screen.dart` |
| 28 | `test/widgets/shell/app_shell_test.dart` | `shell/app_shell.dart` — bottom nav, drawer, More button |
| 29 | `test/widgets/shell/web_shell_test.dart` | `shell/web_shell.dart` — sidebar, collapse toggle |
| 30 | `test/widgets/staff/staff_screen_test.dart` | `staff/screens/staff_screen.dart` |
| 31 | `test/widgets/staff/attendance_screen_test.dart` | `staff/screens/attendance_screen.dart` |
| 32 | `test/widgets/staff/shift_schedule_test.dart` | `staff/screens/shift_schedule_screen.dart` |
| 33 | `test/widgets/staff/task_board_test.dart` | `staff/screens/task_board_screen.dart` |
| 34 | `test/widgets/staff/salary_screen_test.dart` | `staff/screens/salary_screen.dart` |
| 35 | `test/widgets/subscription/subscription_screen_test.dart` | `subscription/screens/subscription_screen.dart` |
| 36 | `test/widgets/super_admin/admin_dashboard_test.dart` | `super_admin/screens/super_admin_dashboard_screen.dart` |
| 37 | `test/widgets/super_admin/users_list_test.dart` | `super_admin/screens/users_list_screen.dart` |
| 38 | `test/widgets/tables/tables_screen_test.dart` | `tables/screens/tables_screen.dart` |
| 39 | `test/widgets/tables/table_layout_editor_test.dart` | `tables/screens/table_layout_editor.dart` |

### 5D — Feature Widgets (12 new files)

| # | Test File | Source Widget(s) |
|---|----------|-----------------|
| 1 | `test/widgets/auth/email_verification_banner_test.dart` | `auth/widgets/email_verification_banner.dart` |
| 2 | `test/widgets/billing/payment_modal_test.dart` | `billing/widgets/payment_modal.dart` |
| 3 | `test/widgets/billing/reorder_button_test.dart` | `billing/widgets/reorder_button.dart` |
| 4 | `test/widgets/khata/khata_modals_test.dart` | `khata/widgets/add_customer_modal.dart`, `give_udhaar_modal.dart`, `record_payment_modal.dart` |
| 5 | `test/widgets/menu/combo_card_test.dart` | `menu/widgets/combo_card.dart` |
| 6 | `test/widgets/menu/table_qr_generator_test.dart` | `menu/widgets/table_qr_generator.dart` |
| 7 | `test/widgets/notifications/notification_bell_test.dart` | `notifications/widgets/notification_bell.dart` |
| 8 | `test/widgets/products/add_product_modal_test.dart` | `products/widgets/add_product_modal.dart` |
| 9 | `test/widgets/reservations/reservation_card_test.dart` | `reservations/widgets/reservation_card.dart` |
| 10 | `test/widgets/settings/edit_shop_modal_test.dart` | `settings/widgets/edit_shop_modal.dart` |
| 11 | `test/widgets/staff/staff_clock_widget_test.dart` | `staff/widgets/staff_clock_widget.dart` |
| 12 | `test/widgets/tables/add_table_dialog_test.dart` | `tables/widgets/add_table_dialog.dart` |

**Estimated: 60 files, ~600 test cases**

---

<a name="phase-6"></a>
## 10. Phase 6 — Integration Flows (8 files, ~80 tests)

**Goal:** End-to-end user flows spanning multiple features work correctly.
**Priority:** MEDIUM — catches cross-feature regressions.
**Dependencies:** Phases 1–3 for models/services/mocks

### Files to Create

| # | Test File | Flow | Key Assertions |
|---|----------|------|---------------|
| 1 | `test/integration/table_order_flow_test.dart` | Table → Order → Kitchen → Billed | Create table → add items → place order → table becomes occupied → items appear in kitchen → mark ready → complete order → table freed |
| 2 | `test/integration/order_merge_flow_test.dart` | Two orders on same table → merge | Create 2 orders → merge → combined items + single order + KOT recalc |
| 3 | `test/integration/inventory_billing_flow_test.dart` | Stock → Product → Bill → Stock deducted | Log ingredient → create product → sell → ingredient stock decremented |
| 4 | `test/integration/staff_role_flow_test.dart` | Staff login → role-based access | Staff login (PIN) → verify permitted routes → attempt blocked route → denied |
| 5 | `test/integration/reservation_flow_test.dart` | Reservation → Table → Order | Create reservation → confirm → seat at table → table occupied → take order |
| 6 | `test/integration/compliance_flow_test.dart` | License lifecycle | Create license → approach expiry → urgency changes → renew → reset |
| 7 | `test/integration/salary_calculation_flow_test.dart` | Attendance → Salary slip | Clock in/out over 30 days → calculate salary → verify hours, overtime, deductions |
| 8 | `test/integration/reports_accuracy_test.dart` | Bills → Dashboard totals | Create mixed bills (cash/UPI/udhar) → verify dashboard summary matches |

**Existing (8):** billing_flow, concurrency, csv_import, desktop_auth, khata_flow, offline_resilience, product_lifecycle, subscription_enforcement

**Estimated: 8 files, ~80 test cases**

---

<a name="phase-7"></a>
## 11. Phase 7 — Routing, Guards & Deep Links (3 files, ~50 tests)

**Goal:** Every route resolves, guards redirect correctly, staff permissions filter routes.
**Priority:** MEDIUM — routing bugs are hard to debug in production.
**Dependencies:** Phase 4 helpers

### Files to Create

| # | Test File | What It Tests | Key Test Cases |
|---|----------|--------------|---------------|
| 1 | `test/routing/route_guard_test.dart` | Auth + subscription + admin guards | Unauthenticated → redirect `/login`, expired subscription → redirect `/subscription`, non-admin → `/super-admin` blocked, staff without permission → route blocked |
| 2 | `test/routing/deep_link_test.dart` | All 40+ `AppRoutes` constants resolve | Every route in `AppRoutes` (billing, khata, products, dashboard, tables, orders, kitchen, staff, attendance, settings, combos, daily-specials, reservations, coupons, shifts, tasks, messages, cash-register, feedback, ingredients, vendors, wastage, gst-export, reports, licenses, equipment, complaints, events, salary, customer-facing routes, all super-admin sub-routes) resolves to the correct screen widget type |
| 3 | `test/routing/staff_route_filter_test.dart` | `StaffPermissions.permittedRoutes` integration with router | Waiter sees: billing, orders, tables, kitchen, my-attendance. Chef sees: kitchen, orders. Cashier sees: billing, bills, khata. Manager sees: all except super_admin. Owner (null staff): all routes. Custom permissions override defaults |

**Estimated: 3 files, ~50 test cases**

---

<a name="phase-8"></a>
## 12. Phase 8 — Accessibility & Responsive (4 files, ~40 tests)

**Goal:** App works across mobile/tablet/desktop and meets a11y standards.
**Priority:** LOW — polish layer.
**Dependencies:** Phase 4 helpers

### Files to Create

| # | Test File | What It Tests |
|---|----------|--------------|
| 1 | `test/widgets/responsive/mobile_layout_test.dart` | Key screens at 375×667, 390×844, 360×640: bottom nav 5 items, hamburger opens drawer, New Order uses full-width grid + FAB cart, no overflow |
| 2 | `test/widgets/responsive/tablet_layout_test.dart` | Screens at 768×1024: side navigation appears, Khata list+detail side-by-side, content fills remaining width |
| 3 | `test/widgets/responsive/desktop_layout_test.dart` | Screens at 1280×800: WebShell with 240px sidebar, "More Features" sections visible, collapsible toggle works |
| 4 | `test/a11y/semantics_test.dart` | Semantic labels on all buttons, form fields have labels, tap targets ≥ 48×48 dp, images have semantic descriptions |

**Estimated: 4 files, ~40 test cases**

---

<a name="totals"></a>
## 13. Projected Totals & Quality Gates

### Before vs After

| Metric                    | Current (Before)  | After (All Phases) |
|--------------------------|-------------------|--------------------|
| Test files                | 132               | **272** (+140)     |
| Test cases                | ~2,210            | **~3,760** (+1,550)|
| Model coverage (files)    | 9/28 (32%)        | **28/28 (100%)**   |
| Service coverage (files)  | 13/37 (35%)       | **35/37 (95%)**    |
| Provider coverage (files) | 11/27 (41%)       | **27/27 (100%)**   |
| Screen coverage (files)   | 0/72 (0%)         | **39/72 (54%)**    |
| Widget coverage (files)   | 15/29 (52%)       | **27/29 (93%)**    |
| Integration flows         | 8                 | **16**             |
| File coverage ratio       | 46% (132/287)     | **~85%** (245/287) |

### Quality Gates Per Phase

| Phase Complete | Gate Command | Expected Result |
|----------------|-------------|-----------------|
| Phase 1 done   | `flutter test test/models/` | All pass, 0 skip, **~280 new** |
| Phase 2 done   | `flutter test test/services/` | All pass, **~340 new** |
| Phase 3 done   | `flutter test test/providers/` | All pass, **~160 new** |
| Phase 5 done   | `flutter test test/widgets/` | All pass, **~600 new** |
| Phase 6 done   | `flutter test test/integration/` | All pass, **~80 new** |
| Phase 7 done   | `flutter test test/routing/` | All pass, **~50 new** |
| **ALL DONE**   | `flutter test` | **3,760+ tests, 0 failures** |
| **ALL DONE**   | `flutter test --coverage` | **≥80% line coverage** |

---

<a name="ci"></a>
## 14. CI Integration

### Add to `smart-deploy.ps1`

```powershell
# ── Run tests with coverage ──
Write-Host "Running tests..." -ForegroundColor Cyan
flutter test --coverage
if ($LASTEXITCODE -ne 0) {
    Write-Host "TESTS FAILED! Aborting deploy." -ForegroundColor Red
    exit 1
}
Write-Host "All tests passed." -ForegroundColor Green
```

### GitHub Actions Workflow (optional)

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.5'
      - run: flutter pub get
      - run: flutter test --coverage
      - name: Check Coverage Threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep 'lines' | awk '{print $2}' | tr -d '%')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 80% threshold"
            exit 1
          fi
```

---

<a name="dependency-graph"></a>
## 15. Execution Dependency Graph

```
Phase 0 (Factory expansion)   ◀── Prerequisite: add 20 factories
    │
    ▼
Phase 1 (19 Model tests)      ◀── Start here, zero external deps, fastest wins
    │
    ▼
Phase 2 (26 Service tests)    ◀── Uses fake_cloud_firestore + Phase 1 factories
    │
    ▼
Phase 3 (16 Provider tests)   ◀── Uses mocktail + Phase 2 service mocks
    │
    ▼
Phase 4 (5 Infrastructure)    ◀── Build pumpApp + mock overrides BEFORE widget tests
    │
    ├──────────────────────┬──────────────────┐
    ▼                      ▼                  ▼
Phase 5 (60 Screens)    Phase 6 (8 E2E)    Phase 7 (3 Routing)
    │                                         │
    ▼                                         ▼
Phase 8 (4 A11y/Responsive)
```

---

## Test Factories to Create (Phase 0)

Add to `test/helpers/test_factories_extended.dart` (import from test_factories.dart):

```dart
makeAttendance({String id, String staffId, String staffName, DateTime date, DateTime clockIn, DateTime? clockOut, AttendanceStatus status})
makeCashRegister({String id, String staffId, String staffName, DateTime openedAt, double openingBalance, DateTime? closedAt, List<CashMovement> movements})
makeCombo({String id, String name, double price, List<ComboItem> items})
makeComplaint({String id, String description, ComplaintCategory category, ComplaintStatus status})
makeCoupon({String id, String code, CouponType type, double value, DateTime? validFrom, DateTime? validUntil, double? minOrderAmount, double? maxDiscount, int? maxUses, int usedCount, bool isActive})
makeEquipment({String id, String name, DateTime? warrantyUntil, DateTime? nextServiceDue, List<ServiceRecord> serviceHistory})
makeEvent({String id, String eventName, String clientName, String clientPhone, DateTime eventDate, double totalAmount, double advancePaid})
makeFeedbackModel({String id, int foodRating, int serviceRating, int ambianceRating})
makeIngredient({String id, String name, double currentStock, double minLevel, DateTime? expiryDate})
makeLicense({String id, LicenseType type, DateTime issueDate, DateTime expiryDate, bool isActive})
makeMessage({String id, String senderId, String senderName, String content, bool isBroadcast})
makeOrder({String id, int orderNumber, List<OrderItem> items, OrderStatus status, OrderType orderType, String? tableId})
makeOrderItem({String productId, String name, double price, int quantity, OrderItemStatus status})
makePurchase({String id, List<PurchaseItem> items, double totalAmount, String? vendorId})
makeReservation({String id, String guestName, String phone, int partySize, DateTime dateTime, ReservationStatus status})
makeShift({String id, String staffId, String staffName, StaffRole role, DateTime date, DateTime startTime, DateTime endTime})
makeStaff({String id, String name, String pin, StaffRole role, bool isActive, Map<String, List<String>>? permissions})
makeTable({String id, int number, TableStatus status, String? currentOrderId, String? label, int capacity})
makeTask({String id, String title, String assignedToId, String assignedToName, TaskStatus status, TaskPriority priority, DateTime? dueDate})
makeVendor({String id, String name, double balance, List<String> supplyItems})
makeWastage({String id, String ingredientId, String ingredientName, double quantity, WastageReason reason, double estimatedCost})
```

---

## Summary

This plan accounts for **every single source file** across all 287 files in `lib/`. Each untested file has an explicit test file mapped with specific test requirements based on actual code analysis:

- **19 untested models** → each with specific computed getter and enum tests
- **26 untested services** → each with CRUD + business logic tests, prioritized P0/P1/P2
- **16 untested providers** → each with provider count and complexity noted
- **60 untested screens/widgets** → each mapped 1:1 to source
- **8 new integration flows** → covering multi-feature paths
- **3 routing tests** → guards, deep links, role filtering
- **4 a11y/responsive tests** → mobile/tablet/desktop breakpoints

**Total new: ~140 test files, ~1,550 test cases.**
**Final total: ~272 test files, ~3,760 test cases, ≥80% line coverage.**
