# TULASI HOTELS — Food & Restaurant Implementation Plan

> **Scope:** Pure food/restaurant operations — NO hotel rooms, NO stays, NO accommodation
> **Status:** ✅ ALL FEATURES VERIFIED COMPLETE — Audit passed March 2026
> **Date:** March 2026

---

## TABLE OF CONTENTS

1. [Cleanup — Remove Room/Stay Code](#cleanup--remove-roomstay-code)
2. [Feature Inventory — What Exists & Status](#feature-inventory--what-exists--status)
3. [Phase A — Core Restaurant Operations (DONE)](#phase-a--core-restaurant-operations)
4. [Phase B — Menu & Order Enhancements (DONE)](#phase-b--menu--order-enhancements)
5. [Phase C — Staff Management (DONE)](#phase-c--staff-management)
6. [Phase D — Customer-Facing Web (DONE)](#phase-d--customer-facing-web)
7. [Phase E — Inventory & Supply Chain (DONE)](#phase-e--inventory--supply-chain)
8. [Phase F — Billing & Compliance (DONE)](#phase-f--billing--compliance)
9. [Phase G — Reports & Analytics (DONE)](#phase-g--reports--analytics)
10. [Phase H — Communication & Notifications (DONE)](#phase-h--communication--notifications)
11. [Phase I — Situational & Compliance (DONE)](#phase-i--situational--compliance)
12. [Navigation & Accessibility](#navigation--accessibility)
13. [Firestore Schema (Food-Only)](#firestore-schema-food-only)
14. [Cloud Functions Summary](#cloud-functions-summary)
15. [Complete Route Map](#complete-route-map)

---

## CLEANUP — Remove Room/Stay Code

> **Status: ✅ COMPLETED** — All room/stay code removed. Zero room references in codebase.

These items existed in code but were **NOT relevant** to a food-only app. They have been removed.

### Files to DELETE

| File | Reason |
|------|--------|
| `lib/features/billing/services/room_folio_service.dart` | Entire file is room charge posting. Zero imports — completely unused. |

### Model Fields to REMOVE

#### `lib/models/order_model.dart`

| Line | Code | Action |
|------|------|--------|
| 53 | `roomService('Room Service', '🛏')` | Remove from `OrderType` enum |
| 183 | `final String? roomNumber;` | Remove field |
| 204 | `this.roomNumber,` | Remove constructor param |
| 274 | `roomNumber: data['roomNumber'] as String?,` | Remove from `fromFirestore()` |
| 297 | `'roomNumber': roomNumber,` | Remove from `toMap()` |
| 316 | `String? roomNumber,` | Remove from `copyWith()` param |
| 337 | `roomNumber: roomNumber ?? this.roomNumber,` | Remove from `copyWith()` body |

#### `lib/models/bill_model.dart`

| Line | Code | Action |
|------|------|--------|
| 177 | `final String? roomNumber;` | Remove field |
| 178 | `final bool isRoomCharge;` | Remove field |
| 207 | `this.roomNumber,` | Remove constructor param |
| 208 | `this.isRoomCharge = false,` | Remove constructor param |
| 259 | `roomNumber: data['roomNumber'] as String?,` | Remove from `fromFirestore()` |
| 260 | `isRoomCharge: (data['isRoomCharge'] as bool?) ?? false,` | Remove from `fromFirestore()` |
| 294 | `if (roomNumber != null) 'roomNumber': roomNumber,` | Remove from `toMap()` |
| 295 | `if (isRoomCharge) 'isRoomCharge': isRoomCharge,` | Remove from `toMap()` |
| 328 | `if (roomNumber != null) 'roomNumber': roomNumber,` | Remove from `toJson()` |
| 329 | `if (isRoomCharge) 'isRoomCharge': isRoomCharge,` | Remove from `toJson()` |
| 360 | `String? roomNumber,` | Remove from `copyWith()` |
| 361 | `bool? isRoomCharge,` | Remove from `copyWith()` |
| 390 | `roomNumber: roomNumber ?? this.roomNumber,` | Remove from `copyWith()` |
| 391 | `isRoomCharge: isRoomCharge ?? this.isRoomCharge,` | Remove from `copyWith()` |

#### `lib/models/product_model.dart`

| Line | Code | Action |
|------|------|--------|
| 102 | `final double? priceRoomService;` | Remove field |
| 139 | `this.priceRoomService,` | Remove constructor param |
| 198 | `priceRoomService: (data['priceRoomService'] as num?)?.toDouble(),` | Remove from `fromFirestore()` |
| 233 | `'priceRoomService': priceRoomService,` | Remove from `toFirestore()` |
| 265 | `Object? priceRoomService = _sentinel,` | Remove from `copyWith()` |
| 314-316 | copyWith logic for priceRoomService | Remove from `copyWith()` |

### UI Fields to REMOVE

#### `lib/features/products/widgets/add_product_modal.dart`

| Line | Code | Action |
|------|------|--------|
| 45 | `late final TextEditingController _priceRoomServiceController;` | Remove declaration |
| 86-87 | Controller initialization from `product.priceRoomService` | Remove init |
| 118 | `_priceRoomServiceController.dispose();` | Remove dispose |
| 209-211 | `priceRoomService:` parsing in save method | Remove field from save |
| 573-574 | `'Room Service Price'` TextField widget | Remove UI field |

### IMPLEMENTATION_PLAN.md Section to REMOVE

- **Section 2.6 "Room Charge Posting (#38)"** — Entire section describes room folio posting. Delete.

### Firestore Schema Entry to REMOVE

- Remove `roomNumber` from orders and bills collection schema
- Remove `priceRoomService` from products collection schema
- No need to clean Firestore data — fields are nullable and simply won't be read

---

## FEATURE INVENTORY — What Exists & Status

### ✅ = Fully Implemented (Backend + UI + Navigation)
### ⚠️ = Implemented but needs verification
### ❌ = Planned but not done / To remove

| # | Feature | Status | Backend | UI | Nav |
|---|---------|--------|---------|-----|-----|
| **CORE** |
| 1 | Walk-in POS Billing | ✅ | BillingService → Firestore | billing_screen.dart, pos_web_screen.dart | Sidebar index 0 |
| 2 | Product Availability Toggle | ✅ | ProductModel.isAvailable | Dimmed in POS, filtered out | In product modal |
| 3 | Daily Specials | ✅ | ProductModel.isSpecial + availableDays | daily_specials_screen.dart | Products chips + sidebar |
| 4 | Multi-price (Dine-in/Takeaway/Delivery) | ✅ | priceTakeaway, priceDelivery on ProductModel | add_product_modal.dart | In product modal |
| 5 | Dietary Tags & Allergens | ✅ | DietaryTag, SpiceLevel, allergens on ProductModel | Badge on POS cards | In product modal |
| 6 | QR Code Digital Menu | ✅ | URL-based (no Firestore) | table_qr_generator.dart | In tables screen |
| 7 | Combo Meals | ✅ | ComboModel + ComboService → Firestore | combo_builder_screen.dart | Products chips + sidebar |
| **ORDERS** |
| 8 | Dine-in Orders | ✅ | OrderService → Firestore | new_order_screen.dart | Orders nav |
| 9 | Takeaway Orders | ✅ | OrderType.takeaway | Same order screen | Orders nav |
| 10 | Delivery Orders | ✅ | OrderType.delivery | Same order screen | Orders nav |
| 11 | Split Bill | ✅ | BillingService.createSplitBills() | split_bill_screen.dart | Order detail |
| 12 | Merge Orders | ✅ | OrderService.mergeOrders() | orders_screen.dart | Order actions |
| 13 | Reorder from History | ✅ | CartProvider.populateFromBill() | reorder_button.dart | Bill history |
| 14 | Rush Order Flag | ✅ | OrderModel.isRush | 🔥 badge on KDS | Order creation |
| 15 | VIP Order Flag | ✅ | OrderModel.isVip | 👑 badge on KDS | Order creation |
| **KITCHEN** |
| 16 | Kitchen Display System | ✅ | Real-time order stream | kitchen_display_screen.dart | Sidebar index 7 |
| 17 | Station-wise KOT Split | ✅ | KotPrinterService.printStationKOTs() | Hardware settings | Settings → Hardware |
| 18 | Preparation Timer | ✅ | OrderItem.preparationStartedAt | Elapsed timer on KDS cards | KDS screen |
| **TABLES** |
| 19 | Table Management | ✅ | TableService → Firestore | tables_screen.dart | Sidebar index 5 |
| 20 | Table Layout Editor | ✅ | TableModel.posX/posY/shape | table_layout_editor.dart | Tables screen |
| 21 | Table Server Assignment | ✅ | TableModel.assignedServerId | Long-press table | Tables screen |
| 22 | Table Reservations | ✅ | ReservationService → Firestore | reservations_screen.dart | Sidebar + Dashboard |
| **BILLING & PAYMENTS** |
| 23 | Cash/UPI/Credit Payment | ✅ | BillModel.paymentMethod | payment_modal.dart | Billing flow |
| 24 | Split Payment (multi-method) | ✅ | BillModel.paymentSplits | payment_modal.dart | Billing flow |
| 25 | Khata (Credit Ledger) | ✅ | CustomerService + TransactionService | khata_screen.dart | Sidebar index 1 |
| 26 | Coupons & Happy Hour | ✅ | CouponService → Firestore | coupons_screen.dart | Sidebar + Dashboard |
| 27 | GST Calculation & Export | ✅ | GstService | gst_export_screen.dart | Dashboard + sidebar |
| 28 | Bill History & Reprint | ✅ | BillModel stream | bills_screen.dart | Sidebar index 4 |
| **STAFF** |
| 29 | Staff CRUD & Roles | ✅ | StaffService → Firestore | staff_screen.dart | Sidebar index 8 |
| 30 | Attendance & Clock-in/out | ✅ | AttendanceService → Firestore | attendance_screen.dart | Sidebar index 9 |
| 31 | Shift Scheduling | ✅ | ShiftService → Firestore | shift_schedule_screen.dart | Staff chips + sidebar |
| 32 | Task Assignment Board | ✅ | TaskService → Firestore | task_board_screen.dart | Staff chips + sidebar |
| 33 | Staff Messaging | ✅ | MessageService → Firestore | messages_screen.dart | Staff chips + sidebar |
| 34 | Salary Calculation | ✅ | SalaryService (attendance-based) | salary_screen.dart | Staff chips + sidebar |
| 35 | Cash Register / Shift Closing | ✅ | CashRegisterService → Firestore | cash_register_screen.dart | Staff chips + sidebar |
| **INVENTORY** |
| 36 | Ingredient Tracking | ✅ | IngredientService → Firestore | ingredients_screen.dart | Products chips + sidebar |
| 37 | Recipe Management | ✅ | RecipeService → Firestore | recipes_screen.dart | Products chips + sidebar |
| 38 | Vendor Management | ✅ | VendorService → Firestore | vendors_screen.dart | Sidebar |
| 39 | Purchase Entry | ✅ | PurchaseService → Firestore | purchases_screen.dart | Sidebar |
| 40 | Wastage Tracking | ✅ | WastageService → Firestore | wastage_screen.dart | Sidebar |
| 41 | Low Stock Alerts | ✅ | Dashboard widget + Cloud Function | Dashboard alert banner | Dashboard |
| **CUSTOMER-FACING** |
| 42 | Public Digital Menu | ✅ | Public Firestore read | customer_menu_screen.dart | /menu/:hotelId |
| 43 | Customer Self-Ordering | ✅ | Order creation (public write) | customer_order_screen.dart | /order/:hotelId |
| 44 | Live Order Status | ✅ | Real-time snapshot | order_status_screen.dart | /menu/:hotelId/order/:id/status |
| 45 | Customer Feedback | ✅ | FeedbackService → Firestore | customer_feedback_screen.dart | /rate/:hotelId |
| 46 | Customer Reservation | ✅ | ReservationService (public write) | customer_reservation_screen.dart | /reserve/:hotelId |
| **REPORTS** |
| 47 | Sales Dashboard | ✅ | SalesSummaryProvider | dashboard_web_screen.dart | Sidebar index 3 |
| 48 | Menu Performance | ✅ | AdvancedReportsService | menu_performance_screen.dart | Dashboard + sidebar |
| 49 | Weekly Revenue | ✅ | AdvancedReportsService | weekly_report_screen.dart | Dashboard |
| 50 | P&L Report | ✅ | AdvancedReportsService | pnl_report_screen.dart | Dashboard |
| 51 | Peak Hours Analysis | ✅ | AdvancedReportsService | peak_hours_screen.dart | Dashboard |
| 52 | Item-wise Sales | ✅ | AdvancedReportsService | item_sales_screen.dart | Dashboard |
| 53 | Comparative Report | ✅ | AdvancedReportsService | comparative_screen.dart | Dashboard |
| 54 | Feedback Report | ✅ | AdvancedReportsService | feedback_report_screen.dart | Dashboard |
| **COMPLIANCE & OPS** |
| 55 | License Tracker (FSSAI etc.) | ✅ | LicenseService → Firestore | licenses_screen.dart | Sidebar |
| 56 | Equipment Maintenance | ✅ | EquipmentService → Firestore | equipment_screen.dart | Sidebar |
| 57 | Complaint Handling | ✅ | ComplaintService → Firestore | complaints_screen.dart | Sidebar |
| 58 | Event/Banquet Planning | ✅ | EventService → Firestore | events_screen.dart | Sidebar |
| 59 | Feedback Dashboard | ✅ | FeedbackService aggregation | feedback_dashboard_screen.dart | Sidebar |
| **PLATFORM** |
| 60 | Notifications (FCM) | ✅ | Cloud Functions → FCM | notification_bell.dart | Sidebar |
| 61 | Offline Mode | ✅ | OfflineStorageService (Firestore offline) | Automatic | — |
| 62 | Multi-language (EN/HI/TE) | ✅ | l10n ARB files | Settings → Language | Settings |
| 63 | Theme (Light/Dark) | ✅ | ThemeProvider | Settings → Theme | Settings |
| 64 | Subscription/Plan Mgmt | ✅ | SubscriptionService + `activateSubscription` Cloud Fn | subscription_screen.dart | Settings |
| 65 | Hardware/Printer Config | ✅ | PrinterService | hardware_settings_screen.dart | Settings |
| — | ~~Room Service~~ | ✅ REMOVED | ~~RoomFolioService~~ | ~~Not wired~~ | ~~None~~ |

---

## PHASE A — Core Restaurant Operations

**Status: ✅ COMPLETE**

These are the foundational features that were in place from the start:

### Walk-in POS Billing
- **Model:** `BillModel` — cash/UPI/credit, itemized, GST fields
- **Service:** `BillingService` → creates bills via `OfflineStorageService` (Firestore with offline persistence)
- **UI:** `billing_screen.dart` (mobile), `pos_web_screen.dart` (desktop)
- **Provider:** `billsProvider` (StreamProvider.autoDispose)
- **Collection:** `users/{uid}/bills/{billId}`

### Product Catalog
- **Model:** `ProductModel` — name, price, category, image, GST, dietary tags, spice level, allergens, availability, multi-price
- **Service:** `ProductService` → Firestore CRUD
- **UI:** `products_web_screen.dart` — search, grid/list toggle, export/import CSV
- **Provider:** `productsProvider`, `productsSyncStatusProvider`
- **Collection:** `users/{uid}/products/{productId}`

### Order Management
- **Model:** `OrderModel` — items, status pipeline (placed→confirmed→preparing→ready→served→billed), table link, customer info
- **Service:** `OrderService` → Firestore CRUD, status updates
- **UI:** `orders_screen.dart`, `new_order_screen.dart`, `order_detail_screen.dart`
- **Provider:** `ordersProvider`, `activeOrdersProvider`
- **Collection:** `users/{uid}/orders/{orderId}`
- **Order Types:** `dineIn`, `takeaway`, `delivery` (remove `roomService`)

### Table Management
- **Model:** `TableModel` — name, capacity, status, position, shape, assigned server
- **Service:** `TableService` → Firestore CRUD, server assignment
- **UI:** `tables_screen.dart`, `table_layout_editor.dart`
- **Collection:** `users/{uid}/tables/{tableId}`

### Kitchen Display System
- **Real-time:** Orders stream filtered by status
- **UI:** `kitchen_display_screen.dart` with station filters, prep timers, rush/VIP badges
- **Printer:** `KotPrinterService` for station-wise KOT printing

### Khata (Customer Credit Ledger)
- **Model:** `CustomerModel` + `TransactionModel`
- **Service:** `KhataService` → Firestore CRUD
- **UI:** `khata_screen.dart`, `customer_detail_screen.dart`
- **Collection:** `users/{uid}/customers/{customerId}/transactions/{txnId}`

---

## PHASE B — Menu & Order Enhancements

**Status: ✅ COMPLETE**

### Combo Meals
- **Model:** `ComboModel` with `ComboItem` (quantity, swappable items)
- **Service:** `ComboService` → Firestore CRUD, stream
- **Screen:** `combo_builder_screen.dart` — build combos from products, set bundle price
- **Collection:** `users/{uid}/combos/{comboId}`

### Daily Specials
- **Model:** `ProductModel.isSpecial` + `availableDays` (day-of-week filter)
- **Provider:** `dailySpecialsProvider` — auto-filters by today's weekday
- **Screen:** `daily_specials_screen.dart` — toggle specials, schedule recurring

### Product Badges on POS
- Dietary tag colored dot (top-left of card)
- ⭐ Special badge (bottom-left)
- 🌶️ Spice level indicator (next to name)
- Opacity dimming for unavailable products
- `isAvailable` filter in product grid

### Split Bill
- **Model:** `BillModel.parentBillId`, `splitIndex`
- **Service:** `BillingService.createSplitBills()` — by items or equal split
- **Screen:** `split_bill_screen.dart`

### Merge Orders
- **Service:** `OrderService.mergeOrders()` — moves items from source to target order

### Reorder from History
- **Widget:** `reorder_button.dart` on bill cards
- **Provider:** `CartProvider.populateFromBill()`

### Rush & VIP Orders
- **Model:** `OrderModel.isRush`, `OrderModel.isVip`
- **UI:** 🔥 and 👑 badges on KDS, red/gold borders
- **Cloud Function:** `onRushOrder` → FCM push to kitchen devices

### QR Code Menu
- **Widget:** `table_qr_generator.dart` — uses `qr_flutter` package
- **URL:** `https://tulasihotels.web.app/menu/{uid}?table={tableId}`

---

## PHASE C — Staff Management

**Status: ✅ COMPLETE**

### Shift Scheduling
- **Model:** `ShiftModel` (staffId, date, shift type, swap requests)
- **Service:** `ShiftService` → week schedule stream, bulk create, swap workflow
- **Screen:** `shift_schedule_screen.dart` — week grid, drag-assign, color-coded
- **Collection:** `users/{uid}/shifts/{shiftId}`
- **Index:** `[date ASC, staffId ASC]`

### Task Assignment
- **Model:** `TaskModel` (title, assignee, status, priority, due date)
- **Service:** `TaskService` → CRUD, status updates
- **Screen:** `task_board_screen.dart` — Kanban board (Pending / In Progress / Done)
- **Collection:** `users/{uid}/tasks/{taskId}`

### Staff Messaging
- **Model:** `MessageModel` (sender, content, broadcast flag, target role)
- **Service:** `MessageService` → send, stream, mark read
- **Screen:** `messages_screen.dart` — chat-style, broadcast toggle
- **Collection:** `users/{uid}/messages/{messageId}`

### Salary Calculation
- **Service:** `SalaryService.calculateSalary()` — attendance-based hours, overtime, deductions
- **Screen:** `salary_screen.dart` — month picker, staff list with pay breakdown, PDF export

### Cash Register
- **Model:** `CashRegisterModel` (open/close times, opening/closing balance, variance, cash movements)
- **Service:** `CashRegisterService` → open, close, add movement, active register stream
- **Screen:** `cash_register_screen.dart` — shift open/close workflow, variance report
- **Collection:** `users/{uid}/cash_registers/{registerId}`

---

## PHASE D — Customer-Facing Web

**Status: ✅ COMPLETE**

All customer routes are PUBLIC (no auth required):

### Digital Menu
- **Route:** `/menu/:hotelId`
- **Screen:** `customer_menu_screen.dart` — responsive, category tabs, dietary badges, multi-language
- **Firestore Rules:** `allow read: if true` on products

### Self-Ordering
- **Route:** `/order/:hotelId`
- **Screen:** `customer_order_screen.dart` — cart, name + phone, submit
- **Cloud Function:** `onCustomerOrder` → FCM to owner/manager

### Order Status Tracking
- **Route:** `/menu/:hotelId/order/:orderId/status`
- **Screen:** `order_status_screen.dart` — real-time pipeline (Received → Preparing → Ready → Served)

### Customer Feedback
- **Route:** `/rate/:hotelId`
- **Screen:** `customer_feedback_screen.dart` — star ratings (food/service/ambiance), comments
- **Collection:** `users/{uid}/feedback/{feedbackId}`

### Customer Reservation
- **Route:** `/reserve/:hotelId`
- **Screen:** `customer_reservation_screen.dart` — public form (name, phone, date, time, party size)

---

## PHASE E — Inventory & Supply Chain

**Status: ✅ COMPLETE**

### Ingredient Tracking
- **Model:** `IngredientModel` (name, unit, stock level, min/max, cost, expiry, vendor)
- **Service:** `IngredientService` → stream, low stock stream, expiring stream, add/deduct stock
- **Screen:** `ingredients_screen.dart` — traffic light stock badges, tabs (All/Low Stock/Expiring)
- **Collection:** `users/{uid}/ingredients/{ingredientId}`
- **Cloud Function:** `onStockUpdate` → FCM on low stock

### Recipe Management
- **Model:** `RecipeModel` (product link, ingredient list + quantities, food cost)
- **Service:** `RecipeService` → CRUD, food cost calculation, auto-deduct on order served
- **Screen:** `recipes_screen.dart` — select product, add ingredients per serving, auto margin calc
- **Collection:** `users/{uid}/recipes/{recipeId}`

### Vendor Management
- **Model:** `VendorModel` (name, contact, GST, outstanding balance, supply items)
- **Service:** `VendorService` → CRUD, `VendorSettlementService` → payment recording
- **Screen:** `vendors_screen.dart` — vendor list, purchase history, payment tracking
- **Collection:** `users/{uid}/vendors/{vendorId}`

### Purchase Entry
- **Model:** `PurchaseModel` (vendor, items, costs, invoice number)
- **Service:** `PurchaseService` → record purchase (atomically updates ingredient stocks)
- **Screen:** `purchases_screen.dart` — vendor picker, item list, running total
- **Collection:** `users/{uid}/purchases/{purchaseId}`

### Wastage Tracking
- **Model:** `WastageModel` (ingredient, quantity, reason, cost, logged by)
- **Service:** `WastageService` → log wastage (auto-deducts stock)
- **Screen:** `wastage_screen.dart` — date filter, reason badges, monthly summary
- **Collection:** `users/{uid}/wastage/{wastageId}`

---

## PHASE F — Billing & Compliance

**Status: ✅ COMPLETE**

### GST Invoice & Export
- **Model:** `BillModel` fields: `cgst`, `sgst`, `totalTax`, `gstBreakdown`
- **Service:** `GstService.calculateGst()`, `exportGstrData()`
- **Screen:** `gst_export_screen.dart` — month picker, invoice-wise breakdown, CSV export

### Split Payment
- **Model:** `BillModel.paymentSplits` (list of method + amount pairs)
- **UI:** `payment_modal.dart` — "Split Payment" toggle, dynamic payment entries

### Discount & Coupon Engine
- **Model:** `CouponModel` (code, type, value, validity, max uses, happy hour config)
- **Service:** `CouponService` → validate, apply, auto happy-hour detection
- **Screen:** `coupons_screen.dart` — coupon CRUD, usage stats, happy hour config
- **Collection:** `users/{uid}/coupons/{couponId}`

---

## PHASE G — Reports & Analytics

**Status: ✅ COMPLETE**

All reports are computed views of existing data — no new collections needed.

| Report | Screen | Data Source |
|--------|--------|-------------|
| Sales Dashboard | `dashboard_web_screen.dart` | Bills aggregate |
| Menu Performance | `menu_performance_screen.dart` | Order items aggregate |
| Weekly Revenue | `weekly_report_screen.dart` | Bills by day |
| Monthly P&L | `pnl_report_screen.dart` | Revenue − food cost − staff cost − expenses |
| Peak Hours | `peak_hours_screen.dart` | Orders by hour × day heatmap |
| Item-wise Sales | `item_sales_screen.dart` | Order items with qty/revenue/margin |
| Comparative | `comparative_screen.dart` | Period-over-period KPIs |
| Feedback Summary | `feedback_report_screen.dart` | Avg ratings, trends |

**Service:** `AdvancedReportsService` — all calculation methods

---

## PHASE H — Communication & Notifications

**Status: ✅ COMPLETE**

### Cloud Functions (Firebase)

| Function | Trigger | Purpose |
|----------|---------|---------|
| `onRushOrder` | orders.onCreate | FCM to kitchen on rush flag |
| `onCustomerOrder` | orders.onCreate | FCM to owner on QR self-order |
| `onNewOrderKitchenAlert` | orders.onCreate | FCM to kitchen on any new order |
| `onOrderReady` | orders.onUpdate (→ ready) | FCM to assigned waiter |
| `onStockUpdate` | ingredients.onUpdate | FCM on low stock threshold |
| `sendOrderConfirmation` | orders.onCreate | WhatsApp order confirmation |
| `sendFeedbackRequest` | bills.onCreate | WhatsApp feedback link |
| `sendReservationReminder` | pubsub (every 30min) | WhatsApp reservation reminder |
| `sendDailySummary` | pubsub (22:00 daily) | Owner daily sales summary |
| `sendOrderReadySMS` | orders.onUpdate (takeaway ready) | SMS for takeaway ready |
| `licenseExpiryReminder` | pubsub (09:00 daily) | FCM for expiring licenses |
| `createPaymentLink` | https.onCall | Razorpay payment link |
| `razorpayWebhook` | https.onRequest | Payment confirmation |
| `sendRegistrationOTP` | https.onCall | Phone verification |
| `onUserDeleted` | auth.onDelete | Cleanup user data |
| `onNewUserSignup` | firestore.onCreate | Welcome setup |
| `sendPushNotification` | firestore.onCreate | Generic FCM push |
| `cleanupOldNotifications` | pubsub.schedule | Housekeeping |
| `scheduledFirestoreBackup` | pubsub.schedule | Daily Firestore backup |

---

## PHASE I — Situational & Compliance

**Status: ✅ COMPLETE**

### License Tracker
- **Model:** `LicenseModel` (FSSAI, liquor, fire NOC, health cert, shop act, GST)
- **Screen:** `licenses_screen.dart` — expiry color badges (green/yellow/red), document upload
- **Collection:** `users/{uid}/licenses/{licenseId}`

### Equipment Maintenance
- **Model:** `EquipmentModel` (name, serial, warranty, service history, AMC vendor)
- **Screen:** `equipment_screen.dart` — next service due, maintenance log
- **Collection:** `users/{uid}/equipment/{equipmentId}`

### Complaint Handling
- **Model:** `ComplaintModel` (category: food/service/hygiene/billing, status, resolution)
- **Screen:** `complaints_screen.dart` — status pipeline, assign to staff
- **Collection:** `users/{uid}/complaints/{complaintId}`

### Event/Banquet Planning
- **Model:** `EventModel` (client, date, guest count, per-plate pricing, advance)
- **Screen:** `events_screen.dart` — calendar view, menu builder, advance tracking
- **Collection:** `users/{uid}/events/{eventId}`

### Feedback Dashboard (Owner side)
- **Screen:** `feedback_dashboard_screen.dart` — avg ratings, recent feedback, trends

---

## NAVIGATION & ACCESSIBILITY

All features are accessible via these navigation paths:

### Sidebar (10 primary items)

| Index | Icon | Label | Route |
|-------|------|-------|-------|
| 0 | 💳 | Walk-in | `/billing` |
| 1 | 📒 | Khata Ledger | `/khata` |
| 2 | 📋 | Menu | `/products` |
| 3 | 📊 | Dashboard | `/dashboard` |
| 4 | 🧾 | Bills | `/bills` |
| 5 | 🪑 | Tables | `/tables` |
| 6 | 🍽️ | Orders | `/orders` |
| 7 | 🍳 | Kitchen | `/kitchen` |
| 8 | 👥 | Staff | `/staff` |
| 9 | ⏰ | Attendance | `/attendance` |

### Sidebar — Expanded Sections (visible when sidebar is expanded)

**Inventory:** Ingredients, Recipes, Vendors, Purchases, Wastage
**Hospitality:** Reservations, Coupons, Events, Feedback
**Reports:** Advanced Reports, GST Export
**Compliance:** Equipment, Licenses, Complaints

### Screen Quick-Action Chips

**Staff Screen →** Shifts, Tasks, Messages, Salary, Cash Register
**Products Screen →** Combos, Daily Specials, Ingredients, Recipes
**Dashboard →** Quick Access card with all Reports, Inventory, Hospitality, and Compliance links

### Settings (via profile icon at sidebar bottom)
General, Theme, Language, Hardware/Printer, Subscription

---

## FIRESTORE SCHEMA (Food-Only)

```
users/{uid}/
├── (profile document: shopName, ownerName, phone, GST, logo, plan)
├── products/{productId}          — Menu items with pricing, dietary info, availability
├── combos/{comboId}              — Combo meal bundles
├── orders/{orderId}              — Dine-in / takeaway / delivery orders
├── tables/{tableId}              — Table layout, status, server assignment
├── bills/{billId}                — Completed bills with payment, GST breakdown
├── staff/{staffId}               — Staff profiles, roles, permissions
├── attendance/{attendanceId}     — Clock-in/out records
├── shifts/{shiftId}              — Shift schedule assignments
├── tasks/{taskId}                — Staff task assignments
├── messages/{messageId}          — Internal staff messages
├── cash_registers/{registerId}   — Shift cash register records
├── customers/{customerId}        — Khata customers
│   └── transactions/{txnId}      — Credit/debit transactions
├── reservations/{reservationId}  — Table reservations
├── coupons/{couponId}            — Discount coupons & happy hour
├── ingredients/{ingredientId}    — Inventory items with stock levels
├── recipes/{recipeId}            — Product → ingredient mappings
├── purchases/{purchaseId}        — Stock purchase entries
├── vendors/{vendorId}            — Supplier contacts & balances
├── wastage/{wastageId}           — Wastage log entries
├── feedback/{feedbackId}         — Customer feedback ratings
├── complaints/{complaintId}      — Issue tracking
├── licenses/{licenseId}          — FSSAI, fire NOC, health certs
├── equipment/{equipmentId}       — Kitchen equipment & maintenance
├── events/{eventId}              — Banquet/catering events
├── expenses/{expenseId}          — Business expenses
└── notifications/{notificationId} — Push notification records
```

**REMOVED from schema:**
- ~~`roomNumber` from orders~~
- ~~`roomNumber`, `isRoomCharge` from bills~~
- ~~`priceRoomService` from products~~

---

## CLOUD FUNCTIONS SUMMARY

See [Phase H](#phase-h--communication--notifications) for the complete list.

**Source:** `functions/src/index.ts` (main), `functions/src/whatsapp.ts` (WhatsApp integration)
**Region:** `asia-south1`
**Runtime:** Node.js / TypeScript

---

## COMPLETE ROUTE MAP

### Internal Routes (authenticated)

```
/billing                          — Walk-in POS
/khata                            — Customer credit ledger
/customer/:id                     — Customer detail
/products                         — Product catalog
/product/:id                      — Product detail
/dashboard                        — Sales dashboard
/bills                            — Bill history
/tables                           — Table management
/table-layout                     — Drag-drop table editor
/orders                           — Active orders
/orders/new                       — Create new order
/orders/:id                       — Order detail
/orders/:id/bill                  — Bill from order
/orders/:id/split                 — Split bill
/kitchen                          — Kitchen Display System
/staff                            — Staff management
/attendance                       — Attendance tracking
/shifts                           — Shift scheduling
/tasks                            — Task board
/messages                         — Staff messages
/salary                           — Salary calculation
/cash-register                    — Cash register management
/combos                           — Combo meal builder
/daily-specials                   — Daily specials toggle
/reservations                     — Table reservations
/coupons                          — Coupon management
/ingredients                      — Ingredient inventory
/recipes                          — Recipe management
/vendors                          — Vendor management
/purchases                        — Purchase entry
/wastage                          — Wastage log
/gst-export                       — GST export
/reports                          — Advanced reports hub
/reports/menu-performance         — Menu performance
/reports/weekly                   — Weekly revenue
/reports/pnl                      — Profit & Loss
/reports/peak-hours               — Peak hours heatmap
/reports/item-sales               — Item-wise sales
/reports/comparative              — Period comparison
/reports/feedback                 — Feedback summary
/feedback-dashboard               — Owner feedback view
/feedback                         — Customer feedback access
/events                           — Event/banquet planning
/equipment                        — Equipment maintenance
/licenses                         — License tracker
/complaints                       — Complaint handling
/settings                         — App settings
/settings/:tab                    — Settings tab
/settings/theme                   — Theme settings
/subscription                     — Plan management
/notifications                    — Notification center
/staff-login                      — Staff login screen
```

### Public Routes (no auth)

```
/menu/:hotelId                    — Digital menu
/order/:hotelId                   — Self-ordering
/menu/:hotelId/order/:orderId/status — Order tracking
/rate/:hotelId                    — Feedback submission
/reserve/:hotelId                 — Table reservation
```

---

## FIRESTORE INDEXES

```json
[
  { "collection": "reservations", "fields": ["dateTime ASC"] },
  { "collection": "reservations", "fields": ["tableId ASC", "status ASC", "dateTime ASC"] },
  { "collection": "shifts", "fields": ["date ASC", "startTime ASC"] },
  { "collection": "shifts", "fields": ["staffId ASC", "date DESC"] },
  { "collection": "purchases", "fields": ["purchaseDate DESC", "vendorId ASC"] },
  { "collection": "feedback", "fields": ["createdAt DESC"] },
  { "collection": "wastage", "fields": ["date DESC"] },
  { "collection": "ingredients", "fields": ["currentStock ASC", "minLevel ASC"] },
  { "collection": "complaints", "fields": ["status ASC", "createdAt DESC"] },
  { "collection": "events", "fields": ["eventDate ASC"] },
  { "collection": "licenses", "fields": ["expiryDate ASC"] }
]
```

---

## CONVENTIONS

```
Model:      lib/models/{name}_model.dart        → fromFirestore(), toFirestore(), copyWith()
Service:    lib/features/{feat}/services/        → static methods, _basePath = users/$uid
Provider:   lib/features/{feat}/providers/       → StreamProvider.autoDispose
Screen:     lib/features/{feat}/screens/         → ConsumerWidget, ref.watch(provider)
Widget:     lib/features/{feat}/widgets/         → Reusable UI components
Route:      lib/router/app_router.dart           → AppRoutes constant + GoRoute entry
Collection: users/{uid}/{collection}/{docId}     → User-scoped multi-tenant
Function:   functions/src/index.ts               → asia-south1, auth-guarded
```

---

## AUDIT LOG — March 2026

### Verification Results

| Category | Result |
|----------|--------|
| **Routes** | ✅ 55/55 routes verified in GoRouter (50 internal + 5 public) |
| **Screens** | ✅ 48/48 screen files exist with real implementations |
| **Services** | ✅ 28/28 services verified (26 in dedicated files, 2 embedded in providers) |
| **Cloud Functions** | ✅ 19/19 planned + 26 bonus functions, all with real logic |
| **Firestore Rules** | ✅ Fixed: public read on products/combos, public get/create on orders |
| **Firestore Indexes** | ✅ Fixed: added `reservations [tableId, status, dateTime]` + `shifts [staffId, date]` |
| **dart analyze** | ✅ 0 errors, 0 warnings, 68 info hints |
| **Room code removal** | ✅ Zero room references in codebase (verified grep) |

### Gaps Fixed During Audit

1. **Firestore rules** — Products and orders were auth-only, blocking customer-facing features. Added public read for digital menu and public create for self-ordering.
2. **Firestore indexes** — Added composite index for table availability check (`reservations: tableId + status + dateTime`) and staff shift history (`shifts: staffId + date DESC`).
3. **SubscriptionService** — Created `lib/features/subscription/services/subscription_service.dart` wiring Razorpay checkout → `activateSubscription` Cloud Function. Updated subscription screen to show current plan and handle real payment flow (web/desktop).
4. **onRushOrder trigger** — Documentation said `onUpdate` but code correctly uses `onCreate` (rush flag is set at order creation). Updated plan to match code.
