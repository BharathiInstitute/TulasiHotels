# TULASI HOTELS — Detailed Implementation Plan

> 105 Features • Flutter + Firebase • All screens, models, services, collections, Cloud Functions specified
> Generated from feature audit against current codebase (March 2026)

---

## CONVENTIONS (Follow existing patterns)

```
Model:      lib/models/{name}_model.dart        → fromFirestore(), toFirestore(), copyWith(), enums
Service:    lib/features/{feat}/services/        → static methods, _basePath = users/$uid
Provider:   lib/features/{feat}/providers/       → StreamProvider.autoDispose, StateProvider, derived Provider
Screen:     lib/features/{feat}/screens/         → ConsumerWidget, ref.watch(provider)
Widget:     lib/features/{feat}/widgets/         → Reusable UI components
Route:      lib/router/app_router.dart           → AppRoutes constant + GoRoute entry
Collection: users/{uid}/{collection}/{docId}     → User-scoped multi-tenant
Function:   functions/src/index.ts               → asia-south1, auth-guarded, .onCall or .onCreate triggers
Index:      firestore.indexes.json               → Composite indexes for where + orderBy queries
```

---

## PHASE 1 — Menu & Order Enhancements

### 1.1 Menu Enhancements (Features #1–7)

#### Model Changes — `ProductModel` (enhance existing)

**File:** [lib/models/product_model.dart](lib/models/product_model.dart)

Add fields:
```dart
// New fields to add to ProductModel
final String? descriptionEn;       // English description
final String? descriptionHi;       // Hindi description  
final String? descriptionTe;       // Telugu description
final bool isAvailable;            // #2 — Real-time availability toggle (default true)
final bool isSpecial;              // #3 — Daily special flag
final List<int>? availableDays;    // #3 — [1=Mon..7=Sun] null=every day
final DietaryTag dietaryTag;       // #5 — veg/nonVeg/egg/jain
final SpiceLevel spiceLevel;       // #5 — mild/medium/hot/extraHot
final List<String> allergens;      // #5 — ["nuts","dairy","gluten"]
final double? priceTakeaway;       // #4 — null = same as base price
final double? priceDelivery;       // #4 — null = same as base price
final String? kitchenStation;      // #20 — "main"/"tandoor"/"bar"/"chinese"
final String? comboId;             // #7 — links to combo group
```

New enums:
```dart
enum DietaryTag { veg, nonVeg, egg, jain, none }
enum SpiceLevel { mild, medium, hot, extraHot, na }
```

**Firestore:** existing `users/{uid}/products/{productId}` — add fields above

**UI Changes:**
| Screen | Change |
|--------|--------|
| [lib/features/products/widgets/add_product_modal.dart](lib/features/products/widgets/add_product_modal.dart) | Add: dietary tag dropdown, spice level, allergen chips, availability toggle, kitchen station, multi-price fields, description (3 languages) |
| [lib/features/products/screens/products_web_screen.dart](lib/features/products/screens/products_web_screen.dart) | Add: veg/non-veg badge on product cards, "unavailable" visual dimming, "Special ⭐" badge |
| [lib/features/billing/screens/billing_screen.dart](lib/features/billing/screens/billing_screen.dart) | Filter out `isAvailable == false` from product grid |

#### New Model — `ComboModel` (#7)

**File:** `lib/models/combo_model.dart` (NEW)

```dart
class ComboModel {
  final String id;
  final String name;                  // "South Indian Thali"
  final String? description;
  final double price;                 // Bundle price
  final List<ComboItem> items;        // Items included
  final bool isAvailable;
  final DietaryTag dietaryTag;
  final DateTime createdAt;
}

class ComboItem {
  final String productId;
  final String name;
  final int quantity;                 // Default qty in combo
  final bool isSwappable;            // Can customer swap this item?
  final List<String>? swapOptions;   // Alternative productIds
}
```

**Firestore:** `users/{uid}/combos/{comboId}`
**Service:** `lib/features/menu/services/combo_service.dart` — CRUD, stream
**Provider:** `lib/features/menu/providers/combo_provider.dart` — `combosStreamProvider`
**Screen:** `lib/features/menu/screens/combo_builder_screen.dart` — Drag items into combo, set price
**Widget:** `lib/features/menu/widgets/combo_card.dart` — Display in order screen

#### New Screen — Daily Specials (#3)

**File:** `lib/features/menu/screens/daily_specials_screen.dart` (NEW)

```
UI: Toggle list of products → mark as "Today's Special"
    Schedule: pick days of week for recurring specials
    Auto-reflects in order screen with ⭐ badge
```

**Provider:** `lib/features/menu/providers/specials_provider.dart`
```dart
final dailySpecialsProvider = Provider.autoDispose<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final today = DateTime.now().weekday; // 1=Mon..7=Sun
  return productsAsync.whenData((products) => products.where((p) =>
    p.isSpecial && (p.availableDays == null || p.availableDays!.contains(today))
  ).toList());
});
```

#### QR Code for Digital Menu (#6)

**File:** `lib/features/menu/widgets/table_qr_generator.dart` (NEW)

```
UI: Generate QR code per table → links to https://tulasihotels.web.app/menu/{uid}?table={tableId}
    Uses qr_flutter package (already in pubspec or add)
    Print QR as sticker / table tent card
```

**No Firestore needed** — QR encodes URL with uid + tableId params

---

### 1.2 Order Enhancements (Features #14–15, 20–23)

#### Split Bill (#14)

**File:** `lib/features/orders/screens/split_bill_screen.dart` (NEW)

```
UI: Two modes:
    1. Split by items — drag items to Person A / Person B columns
    2. Split equally — enter number of people, auto-divide total
    Each split generates a separate bill via BillingService
```

**Model:** Add to `BillModel`:
```dart
final String? parentBillId;    // If this bill was split from another
final int? splitIndex;          // Which split (1 of 3, 2 of 3, etc.)
```

**Service change:** `lib/features/billing/services/billing_service.dart`
```dart
static Future<List<BillModel>> createSplitBills({
  required OrderModel order,
  required List<List<OrderItem>> splits,  // Items per split
  required PaymentMethod paymentMethod,
  double? discountPercent,
}) async { ... }
```

#### Merge Orders (#14)

**Service change:** `lib/features/orders/services/order_service.dart`
```dart
static Future<OrderModel> mergeOrders({
  required String targetOrderId,
  required String sourceOrderId,
}) async {
  // Move items from source → target, cancel source, update table
}
```

**UI:** Button on OrdersScreen → select two orders → confirm merge

#### Repeat/Reorder (#15)

**File:** `lib/features/billing/widgets/reorder_button.dart` (NEW)

```
UI: On BillsHistoryScreen, each bill card gets "Reorder" button
    Tap → populate cart with same items → go to billing screen
```

**Provider change:** `lib/features/billing/providers/cart_provider.dart`
```dart
void populateFromBill(BillModel bill) {
  // Convert bill items back to cart items
}
```

#### Station-wise KOT Split (#20)

**Service change:** `lib/features/kitchen/services/kot_printer_service.dart`
```dart
static Future<void> printStationKOTs(OrderModel order) async {
  // Group items by p.kitchenStation
  // Print separate KOT per station to configured printer
}
```

**Settings addition:** `lib/features/settings/screens/hardware_settings_screen.dart`
```
UI: Map kitchen stations → printer assignments
    e.g., "Main Kitchen" → Bluetooth Printer 1
          "Bar" → WiFi Printer 2
```

**Firestore:** Add to user settings: `stationPrinters: Map<String, PrinterConfig>`

#### Preparation Timer (#21)

**Model change:** `OrderItem` — add field:
```dart
final DateTime? preparationStartedAt;   // Set when status → preparing
```

**UI change:** [lib/features/kitchen/screens/kitchen_display_screen.dart](lib/features/kitchen/screens/kitchen_display_screen.dart)
```
Add: Elapsed time badge on each order card (green < 10min, yellow < 15min, red > 15min)
     Configurable threshold in settings
     Timer updates every 30 seconds via periodic rebuild
```

#### Rush Order Flag (#23)

**Model change:** `OrderModel` — add field:
```dart
final bool isRush;   // default false
```

**UI changes:**
- NewOrderScreen: "🔥 Rush Order" toggle
- KDS: Rush orders appear at top with red border + 🔥 icon
- FCM: Rush orders trigger priority push via Cloud Function

**Cloud Function:** `functions/src/index.ts`
```typescript
export const onRushOrder = functions.region("asia-south1")
  .firestore.document("users/{uid}/orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before.isRush && after.isRush) {
      // Send FCM to all kitchen devices for this user
    }
  });
```

---

## PHASE 2 — Table & Floor + Reservations + Payments

### 2.1 Table Layout Enhancement (#25)

**Model change:** `TableModel` — add fields:
```dart
final double? posX;    // Grid position X (0.0–1.0 normalized)
final double? posY;    // Grid position Y
final String? shape;   // "square" / "round" / "long"
```

**File:** `lib/features/tables/screens/table_layout_editor.dart` (NEW)

```
UI: Canvas with draggable table widgets
    Tap table → resize, rename, change shape
    Save positions to Firestore
    Uses GestureDetector + Positioned widgets
```

### 2.2 Table Assignment (#27)

**Model change:** `TableModel` — add field:
```dart
final String? assignedServerId;
final String? assignedServerName;
```

**Service change:** `lib/features/tables/services/table_service.dart`
```dart
static Future<void> assignServer(String tableId, String staffId, String staffName) async { ... }
static Stream<List<TableModel>> serverTablesStream(String staffId) { ... }
```

**UI change:** TablesScreen → long-press table → "Assign Server" picker from active staff list

### 2.3 Table Reservation (#28, #89)

#### New Model — `ReservationModel`

**File:** `lib/models/reservation_model.dart` (NEW)

```dart
enum ReservationStatus { pending, confirmed, seated, cancelled, noShow }

class ReservationModel {
  final String id;
  final String? tableId;
  final String guestName;
  final String phone;
  final int partySize;
  final DateTime dateTime;           // Reservation date+time
  final int durationMinutes;         // Expected duration (default 90)
  final ReservationStatus status;
  final String? specialRequests;     // "Birthday cake", "High chair needed"
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

**Firestore:** `users/{uid}/reservations/{reservationId}`

**Index needed:**
```json
{
  "collectionGroup": "reservations",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "dateTime", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" }
  ]
}
```

**Service:** `lib/features/reservations/services/reservation_service.dart` (NEW)
```dart
class ReservationService {
  static Stream<List<ReservationModel>> todayReservationsStream() { ... }
  static Stream<List<ReservationModel>> upcomingReservationsStream() { ... }
  static Future<ReservationModel> createReservation({...}) async { ... }
  static Future<void> confirmReservation(String id) async { ... }
  static Future<void> seatReservation(String id, String tableId) async { ... }
  static Future<void> cancelReservation(String id) async { ... }
  static Future<bool> isTableAvailable(String tableId, DateTime dateTime) async { ... }
}
```

**Provider:** `lib/features/reservations/providers/reservation_provider.dart` (NEW)
```dart
final todayReservationsProvider = StreamProvider.autoDispose<List<ReservationModel>>((ref) { ... });
final upcomingReservationsProvider = StreamProvider.autoDispose<List<ReservationModel>>((ref) { ... });
final reservationDateFilterProvider = StateProvider<DateTime>((ref) => DateTime.now());
```

**Screen:** `lib/features/reservations/screens/reservations_screen.dart` (NEW)
```
UI: Calendar strip (today + next 7 days) at top
    List of reservations per day with status badges
    Tap → confirm / seat (assign table) / cancel
    FAB → create new reservation form
    
Fields: Guest name, phone, party size, date picker, time picker, duration, table (optional), special requests
```

**Widget:** `lib/features/reservations/widgets/reservation_card.dart` (NEW)

**Customer-facing (#89):** `lib/features/reservations/screens/customer_reservation_screen.dart` (NEW)
```
Web route: /reserve/{hotelId}
UI: Public form — name, phone, date, time, party size
    Shows available time slots based on table capacity
    Confirmation via WhatsApp (Phase 8)
```

**Route additions:**
```dart
static const String reservations = '/reservations';
static const String customerReserve = '/reserve/:hotelId';   // Public web route
```

**Navigation:** Add "Reservations" to nav index 10 (after Attendance)

### 2.4 Split Payment (#33)

**Model change:** `BillModel` — add field:
```dart
final List<PaymentSplit>? paymentSplits;   // null = single payment

class PaymentSplit {
  final PaymentMethod method;
  final double amount;
  final String? reference;   // UPI ref, card last 4
}
```

**UI change:** [lib/features/billing/widgets/payment_modal.dart](lib/features/billing/widgets/payment_modal.dart)
```
Add: "Split Payment" toggle
     Dynamic list of payment entries (method + amount)
     Validates total matches bill amount
     Each split tracked as PaymentSplit in bill
```

### 2.5 Discount & Coupon Engine (#34)

#### New Model — `CouponModel`

**File:** `lib/models/coupon_model.dart` (NEW)

```dart
enum CouponType { percentage, flat }

class CouponModel {
  final String id;
  final String code;              // "WELCOME20", "HAPPY50"
  final CouponType type;
  final double value;             // 20 (%) or 50 (₹)
  final double? minOrderAmount;
  final double? maxDiscount;      // Cap for percentage discounts
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? maxUses;             // null = unlimited
  final int usedCount;
  final bool isActive;
  final bool isHappyHour;        // Auto-apply during configured hours
  final int? happyHourStart;     // Hour (0-23)
  final int? happyHourEnd;
  final DateTime createdAt;
}
```

**Firestore:** `users/{uid}/coupons/{couponId}`

**Service:** `lib/features/coupons/services/coupon_service.dart` (NEW)
```dart
class CouponService {
  static Stream<List<CouponModel>> activeCouponsStream() { ... }
  static Future<CouponModel?> validateCoupon(String code, double orderAmount) async { ... }
  static Future<void> applyCoupon(String couponId) async { ... }   // increment usedCount
  static Future<CouponModel?> getActiveHappyHourCoupon() async { ... }
}
```

**Provider:** `lib/features/coupons/providers/coupon_provider.dart` (NEW)
```dart
final activeCouponsProvider = StreamProvider.autoDispose<List<CouponModel>>((ref) { ... });
final happyHourCouponProvider = FutureProvider.autoDispose<CouponModel?>((ref) { ... });
```

**Screen:** `lib/features/coupons/screens/coupons_screen.dart` (NEW)
```
UI: List of coupons with code, type, value, usage stats
    Create coupon form: code, type, value, validity, limits
    Toggle active/inactive
    Happy hour configuration
```

**UI change:** OrderBillingScreen → "Apply Coupon" field → validate → auto-calculate discount

---

## PHASE 3 — Staff Management Enhancements

### 3.1 Shift Scheduling (#43)

#### New Model — `ShiftModel`

**File:** `lib/models/shift_model.dart` (NEW)

```dart
enum ShiftType { morning, afternoon, evening, night, custom }

class ShiftModel {
  final String id;
  final String staffId;
  final String staffName;
  final StaffRole role;
  final ShiftType shiftType;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final bool isSwapRequested;
  final String? swapWithStaffId;
  final DateTime createdAt;
}
```

**Firestore:** `users/{uid}/shifts/{shiftId}`

**Index:**
```json
{
  "collectionGroup": "shifts",
  "fields": [
    { "fieldPath": "date", "order": "ASCENDING" },
    { "fieldPath": "staffId", "order": "ASCENDING" }
  ]
}
```

**Service:** `lib/features/staff/services/shift_service.dart` (NEW)
```dart
class ShiftService {
  static Stream<List<ShiftModel>> weekScheduleStream(DateTime weekStart) { ... }
  static Stream<List<ShiftModel>> staffShiftsStream(String staffId) { ... }
  static Future<void> createShift({...}) async { ... }
  static Future<void> bulkCreateWeekShifts(List<ShiftModel> shifts) async { ... }
  static Future<void> requestSwap(String shiftId, String swapWithStaffId) async { ... }
  static Future<void> approveSwap(String shiftId) async { ... }
}
```

**Provider:** `lib/features/staff/providers/shift_provider.dart` (NEW)
```dart
final weekStartProvider = StateProvider<DateTime>((ref) => _startOfWeek(DateTime.now()));
final weekScheduleProvider = StreamProvider.autoDispose<List<ShiftModel>>((ref) { ... });
final staffShiftsProvider = StreamProvider.autoDispose.family<List<ShiftModel>, String>((ref, staffId) { ... });
```

**Screen:** `lib/features/staff/screens/shift_schedule_screen.dart` (NEW)
```
UI: Week view grid — rows = staff, columns = days
    Drag to assign shifts
    Color-coded by shift type
    Publish button → saves all shifts
    Swap request notifications
```

**Route:** `static const String shifts = '/shifts';`

### 3.2 Task Assignment (#44)

#### New Model — `TaskModel`

**File:** `lib/models/task_model.dart` (NEW)

```dart
enum TaskStatus { pending, inProgress, completed, overdue }
enum TaskPriority { low, medium, high }

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String assignedToId;
  final String assignedToName;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
}
```

**Firestore:** `users/{uid}/tasks/{taskId}`

**Service:** `lib/features/staff/services/task_service.dart` (NEW)
```dart
class TaskService {
  static Stream<List<TaskModel>> activeTasks() { ... }
  static Stream<List<TaskModel>> staffTasks(String staffId) { ... }
  static Future<void> createTask({...}) async { ... }
  static Future<void> updateTaskStatus(String id, TaskStatus status) async { ... }
}
```

**Provider:** `lib/features/staff/providers/task_provider.dart` (NEW)

**Screen:** `lib/features/staff/screens/tasks_screen.dart` (NEW)
```
UI: Kanban board (3 columns: Pending / In Progress / Done)
    Draggable task cards
    Create task dialog: title, assign to, priority, due date
    Filter by staff member
```

**Route:** `static const String tasks = '/tasks';`

### 3.3 Staff Communication (#46)

#### New Model — `MessageModel`

**File:** `lib/models/message_model.dart` (NEW)

```dart
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final bool isBroadcast;        // Manager → all staff
  final String? targetRole;       // null = all, "waiter" = waiters only
  final DateTime createdAt;
  final bool isRead;
}
```

**Firestore:** `users/{uid}/messages/{messageId}`

**Service:** `lib/features/staff/services/message_service.dart` (NEW)
```dart
class MessageService {
  static Stream<List<MessageModel>> messagesStream() { ... }
  static Future<void> sendMessage(String content, {bool broadcast = false, String? targetRole}) async { ... }
  static Future<void> markRead(String messageId) async { ... }
}
```

**Screen:** `lib/features/staff/screens/messages_screen.dart` (NEW)
```
UI: Chat-like interface
    Broadcast toggle at top
    Role filter for targeted messages
    Staff sees messages relevant to their role
```

**Route:** `static const String messages = '/messages';`

### 3.4 Salary Calculation (#55)

**File:** `lib/features/staff/services/salary_service.dart` (NEW)

```dart
class SalaryService {
  static Future<SalarySlip> calculateSalary({
    required String staffId,
    required DateTime month,       // Any date in the target month
    required double baseSalary,
    double overtimeRatePerHour = 0,
    double deductions = 0,
    double advances = 0,
  }) async {
    // 1. Fetch all attendance records for the month
    // 2. Calculate total hours worked
    // 3. Calculate overtime (hours > 8/day)
    // 4. Return SalarySlip with breakdown
  }
}

class SalarySlip {
  final String staffId;
  final String staffName;
  final DateTime month;
  final int totalDays;
  final int presentDays;
  final double totalHours;
  final double overtimeHours;
  final double baseSalary;
  final double overtimePay;
  final double deductions;
  final double advances;
  final double netSalary;
}
```

**Screen:** `lib/features/staff/screens/salary_screen.dart` (NEW)
```
UI: Month picker at top
    Staff list with: Name | Present Days | Hours | Base | Net
    Tap → detailed salary slip
    Export to PDF
```

### 3.5 Cash Register / Shift Closing (#37 enhance)

#### New Model — `CashRegisterModel`

**File:** `lib/models/cash_register_model.dart` (NEW)

```dart
class CashRegisterModel {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingBalance;
  final double closingBalance;
  final double expectedBalance;     // Calculated from transactions
  final double variance;            // closing - expected
  final List<CashMovement> movements;   // Cash in / cash out entries
}

class CashMovement {
  final double amount;
  final String reason;       // "Cash sale", "Petty cash", "Cash deposit"
  final bool isInflow;
  final DateTime timestamp;
}
```

**Firestore:** `users/{uid}/cash_registers/{registerId}`

**Service:** `lib/features/billing/services/cash_register_service.dart` (NEW)
```dart
class CashRegisterService {
  static Future<CashRegisterModel> openRegister(String staffId, double openingBalance) async { ... }
  static Future<void> closeRegister(String registerId, double closingBalance) async { ... }
  static Future<void> addCashMovement(String registerId, CashMovement movement) async { ... }
  static Stream<CashRegisterModel?> activeRegisterStream(String staffId) { ... }
}
```

**Screen:** `lib/features/billing/screens/cash_register_screen.dart` (NEW)
```
UI: Open shift → enter opening cash amount
    During shift → shows running total, cash in/out buttons
    Close shift → enter closing amount → show variance report
    History → past shift reports
```

---

## PHASE 4 — Customer-Facing Web (QR Menu + Self-Order)

### 4.1 Customer Web Menu (#85, #6)

**Route:** `/menu/:hotelId` — PUBLIC (no auth required)

**Firestore read:** Read `users/{hotelId}/products` where `isAvailable == true`
**Security rule:** Allow read on products if request path matches public menu pattern

**Firestore Rules addition:**
```
match /users/{uid}/products/{productId} {
  allow read: if true;   // Public menu access
  allow write: if request.auth != null && request.auth.uid == uid;
}
```

**Screen:** `lib/features/customer/screens/customer_menu_screen.dart` (NEW)
```
UI: Beautiful responsive web menu
    Hotel logo + name header (from users/{hotelId} profile)
    Category tabs (horizontal scroll)
    Item cards: image, name, price, veg/non-veg badge, spice level
    Multi-language toggle (EN/HI/TE)
    "View in ₹" pricing
    No login required
    
    If ?table=T5 in URL → show "Order from Table 5" button
```

**Widget files:**
- `lib/features/customer/widgets/menu_item_card.dart`
- `lib/features/customer/widgets/category_tabs.dart`
- `lib/features/customer/widgets/menu_header.dart`

### 4.2 Customer Self-Ordering (#16)

**Route:** `/menu/:hotelId/order` — PUBLIC

**Screen:** `lib/features/customer/screens/customer_order_screen.dart` (NEW)
```
UI: Cart sidebar / bottom sheet
    Add items from menu → quantity picker → item notes
    Enter name + phone
    Submit order → creates order with status "placed" + confirmation shown
    
    Writes to: users/{hotelId}/orders/{orderId}
    orderType: dineIn (if table param) or takeaway
    Sets: customerName, customerPhone from form
```

**Model change:** `OrderModel` — add fields:
```dart
final String? customerName;
final String? customerPhone;
final bool isCustomerOrder;    // true = placed via QR, needs staff confirmation
```

**Cloud Function:** `functions/src/index.ts`
```typescript
export const onCustomerOrder = functions.region("asia-south1")
  .firestore.document("users/{uid}/orders/{orderId}")
  .onCreate(async (snapshot, context) => {
    const order = snapshot.data();
    if (order.isCustomerOrder) {
      // Send FCM to owner/manager devices: "New customer order from Table X"
    }
  });
```

**Firestore Rules:** Allow create on orders for authenticated AND anonymous users (customer orders)
```
match /users/{uid}/orders/{orderId} {
  allow read: if request.auth != null && request.auth.uid == uid;
  allow create: if true;   // Customer self-order (validated by Cloud Function)
  allow update, delete: if request.auth != null && request.auth.uid == uid;
}
```

### 4.3 Customer Order Status (#87)

**Route:** `/menu/:hotelId/order/:orderId/status` — PUBLIC

**Screen:** `lib/features/customer/screens/order_status_screen.dart` (NEW)
```
UI: Real-time order status tracker
    Visual pipeline: Received ✓ → Preparing → Ready → Served
    Estimated time display
    Auto-redirected here after self-order submission
    
    Reads: users/{hotelId}/orders/{orderId} — real-time snapshot listener
```

**Firestore Rules:** Allow read on specific order by orderId (customer tracking)
```
match /users/{uid}/orders/{orderId} {
  allow read: if true;   // Customer can track their own order
}
```

### 4.4 Customer Feedback (#86)

#### New Model — `FeedbackModel`

**File:** `lib/models/feedback_model.dart` (NEW)

```dart
class FeedbackModel {
  final String id;
  final String? orderId;
  final String? billId;
  final String? customerName;
  final String? customerPhone;
  final int foodRating;          // 1-5
  final int serviceRating;       // 1-5
  final int ambianceRating;      // 1-5
  final String? comments;
  final DateTime createdAt;
}
```

**Firestore:** `users/{uid}/feedback/{feedbackId}`

**Service:** `lib/features/customer/services/feedback_service.dart` (NEW)
```dart
class FeedbackService {
  static Future<void> submitFeedback(FeedbackModel feedback) async { ... }
  static Stream<List<FeedbackModel>> feedbackStream({DateTime? from, DateTime? to}) { ... }
  static Future<FeedbackSummary> getFeedbackSummary(DateTime month) async { ... }
}
```

**Screen:** `lib/features/customer/screens/feedback_screen.dart` (NEW) — PUBLIC
```
Route: /menu/:hotelId/feedback?orderId=X
UI: Star ratings for Food / Service / Ambiance
    Optional text comments
    Submit → Thank you screen
    No login needed
```

**Owner Screen:** `lib/features/customer/screens/feedback_dashboard_screen.dart` (NEW)
```
UI: Average ratings display (food/service/ambiance)
    Recent feedback list with ratings
    Monthly trend chart
    Negative feedback flagged in red
```

---

## PHASE 5 — Inventory & Recipe Management

### 5.1 Ingredient Tracking (#73, #74, #78)

#### New Model — `IngredientModel`

**File:** `lib/models/ingredient_model.dart` (NEW)

```dart
enum IngredientUnit { kg, g, liter, ml, pieces, dozen, packet }

class IngredientModel {
  final String id;
  final String name;
  final IngredientUnit unit;
  final double currentStock;
  final double minLevel;            // Reorder level
  final double? maxLevel;
  final double costPerUnit;         // Purchase cost
  final String? vendorId;
  final String? vendorName;
  final DateTime? expiryDate;       // #78
  final String? batchNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

**Firestore:** `users/{uid}/ingredients/{ingredientId}`

**Service:** `lib/features/inventory/services/ingredient_service.dart` (NEW)
```dart
class IngredientService {
  static Stream<List<IngredientModel>> ingredientsStream() { ... }
  static Stream<List<IngredientModel>> lowStockStream() { ... }
  static Stream<List<IngredientModel>> expiringStream(int daysAhead) { ... }
  static Future<void> addStock(String id, double quantity, double cost, {String? batch, DateTime? expiry}) async { ... }
  static Future<void> deductStock(String id, double quantity) async { ... }
}
```

**Provider:** `lib/features/inventory/providers/ingredient_provider.dart` (NEW)
```dart
final ingredientsProvider = StreamProvider.autoDispose<List<IngredientModel>>((ref) { ... });
final lowStockProvider = StreamProvider.autoDispose<List<IngredientModel>>((ref) { ... });
final expiringItemsProvider = StreamProvider.autoDispose<List<IngredientModel>>((ref) { ... });
```

**Screen:** `lib/features/inventory/screens/ingredients_screen.dart` (NEW)
```
UI: Ingredient list with current stock, min level, cost
    Traffic light badges: green (ok), yellow (low), red (critical)
    Tap → detail page with stock history
    FAB → add new ingredient
    
    Tabs: All | Low Stock | Expiring Soon
```

**Route:** `static const String ingredients = '/ingredients';`

### 5.2 Purchase Entry (#74)

#### New Model — `PurchaseModel`

**File:** `lib/models/purchase_model.dart` (NEW)

```dart
class PurchaseModel {
  final String id;
  final String? vendorId;
  final String? vendorName;
  final List<PurchaseItem> items;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final String? invoiceNumber;
  final DateTime purchaseDate;
  final DateTime createdAt;
}

class PurchaseItem {
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final double unitCost;
  final String? batchNumber;
  final DateTime? expiryDate;
}
```

**Firestore:** `users/{uid}/purchases/{purchaseId}`

**Service:** `lib/features/inventory/services/purchase_service.dart` (NEW)
```dart
class PurchaseService {
  static Future<void> recordPurchase(PurchaseModel purchase) async {
    // 1. Save purchase document
    // 2. Update ingredient stock (batch add)
    // 3. Update ingredient cost (weighted average)
  }
  static Stream<List<PurchaseModel>> purchaseHistoryStream({DateTime? from, DateTime? to}) { ... }
}
```

**Screen:** `lib/features/inventory/screens/purchase_entry_screen.dart` (NEW)
```
UI: Vendor picker (or "Cash purchase")
    Add items: ingredient picker → quantity → cost → batch → expiry
    Running total at bottom
    Save → updates all ingredient stocks atomically
```

### 5.3 Recipe & Auto-Deduction (#64, #75)

#### New Model — `RecipeModel`

**File:** `lib/models/recipe_model.dart` (NEW)

```dart
class RecipeModel {
  final String id;
  final String productId;            // Links to menu item
  final String productName;
  final List<RecipeIngredient> ingredients;
  final double foodCost;             // Calculated sum of ingredient costs
  final DateTime createdAt;
}

class RecipeIngredient {
  final String ingredientId;
  final String ingredientName;
  final double quantity;             // Amount needed per serving
  final IngredientUnit unit;
}
```

**Firestore:** `users/{uid}/recipes/{recipeId}`

**Service:** `lib/features/inventory/services/recipe_service.dart` (NEW)
```dart
class RecipeService {
  static Stream<List<RecipeModel>> recipesStream() { ... }
  static Future<void> saveRecipe(RecipeModel recipe) async { ... }
  static Future<double> calculateFoodCost(String productId) async { ... }
  static Future<void> deductIngredientsForOrder(OrderModel order) async {
    // For each order item → find recipe → deduct ingredients
    // Called when order status → "served"
  }
}
```

**Screen:** `lib/features/inventory/screens/recipe_editor_screen.dart` (NEW)
```
UI: Select menu item
    Add ingredients: search ingredient → quantity per serving
    Auto-calculated food cost at bottom
    Auto-calculated margin (sell price - food cost)
```

**Auto-deduction trigger:** In `OrderService.updateItemStatus()` — when item → served:
```dart
if (status == OrderItemStatus.served) {
  await RecipeService.deductIngredientsForOrder(order);
}
```

### 5.4 Vendor Management (#49, #56)

#### New Model — `VendorModel`

**File:** `lib/models/vendor_model.dart` (NEW)

```dart
class VendorModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final double balance;             // Outstanding amount
  final List<String> supplyItems;   // Ingredient names they supply
  final DateTime createdAt;
}
```

**Firestore:** `users/{uid}/vendors/{vendorId}`

**Service:** `lib/features/inventory/services/vendor_service.dart` (NEW)
**Provider:** `lib/features/inventory/providers/vendor_provider.dart` (NEW)

**Screen:** `lib/features/inventory/screens/vendors_screen.dart` (NEW)
```
UI: Vendor list with name, phone, outstanding balance
    Tap → detail page with purchase history + payments
    Record payment modal
    Generate purchase order
```

### 5.5 Wastage Tracking (#77)

#### New Model — `WastageModel`

**File:** `lib/models/wastage_model.dart` (NEW)

```dart
enum WastageReason { expired, spoiled, kitchenError, overProduction, other }

class WastageModel {
  final String id;
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final IngredientUnit unit;
  final WastageReason reason;
  final String? notes;
  final double estimatedCost;
  final DateTime date;
  final String? loggedBy;           // Staff who logged it
  final DateTime createdAt;
}
```

**Firestore:** `users/{uid}/wastage/{wastageId}`

**Service:** `lib/features/inventory/services/wastage_service.dart` (NEW)

**Screen:** `lib/features/inventory/screens/wastage_log_screen.dart` (NEW)
```
UI: Date filter at top
    List of wastage entries with reason badges
    FAB → log new wastage: pick ingredient, quantity, reason
    Save → deducts from ingredient stock
    Monthly wastage summary chart at top
```

### 5.6 Low Stock Alerts (#76)

**Cloud Function:** `functions/src/index.ts`
```typescript
export const onStockUpdate = functions.region("asia-south1")
  .firestore.document("users/{uid}/ingredients/{ingredientId}")
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    if (after.currentStock <= after.minLevel) {
      // Send FCM push to owner + manager: "Low stock: {name} ({currentStock} {unit} remaining)"
      // Write notification to users/{uid}/notifications
    }
  });
```

---

## PHASE 6 — Billing & Compliance Enhancements

### 6.1 GST Invoice Enhancement (#40 enhance, #54)

**Model change:** `ProductModel` — add field:
```dart
final String? hsnCode;           // HSN/SAC code for GST
final double gstRate;            // 5% default, 18% for AC, 0% for exempt
```

**Model change:** `BillModel` — add fields:
```dart
final double cgst;               // Central GST
final double sgst;               // State GST
final double totalTax;
final List<GstLineItem>? gstBreakdown;

class GstLineItem {
  final String hsnCode;
  final double taxableAmount;
  final double gstRate;
  final double cgst;
  final double sgst;
}
```

**Service:** `lib/features/billing/services/gst_service.dart` (NEW)
```dart
class GstService {
  static GstBreakdown calculateGst(List<BillItem> items) { ... }
  static Future<List<Map<String, dynamic>>> exportGstrData(DateTime month) async {
    // Compile GSTR-1 ready data: invoice-wise summary
    // Returns list of {invoiceNo, date, taxableValue, cgst, sgst, total}
  }
}
```

**Screen:** `lib/features/billing/screens/gst_export_screen.dart` (NEW)
```
UI: Month picker
    Summary: Total taxable, CGST, SGST, Total tax
    Table: Invoice-wise breakdown
    Export CSV button → GSTR-1 format
```

### 6.2 Vendor Settlement (#56)

**Service:** `lib/features/inventory/services/vendor_settlement_service.dart` (NEW)
```dart
class VendorSettlementService {
  static Future<void> recordPayment(String vendorId, double amount, PaymentMethod method) async { ... }
  static Stream<double> vendorBalanceStream(String vendorId) { ... }
  static Future<List<PurchaseModel>> unpaidPurchases(String vendorId) async { ... }
}
```

**UI:** Vendor detail screen → "Record Payment" button → amount + method → updates balance

### 6.3 Auto-Reconciliation (#97)

**Cloud Function:** `functions/src/index.ts`
```typescript
export const razorpayReconciliation = functions.region("asia-south1")
  .pubsub.schedule("every day 06:00")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    // 1. Fetch yesterday's Razorpay settlements via API
    // 2. Match with bills in Firestore
    // 3. Flag mismatches → write to users/{uid}/reconciliation_flags
  });
```

---

## PHASE 7 — Reports & Intelligence

### 7.1 Reports Infrastructure

All reports build on existing data. No new collections needed — these are read-only computed views.

**New Service:** `lib/features/reports/services/advanced_reports_service.dart` (NEW)

```dart
class AdvancedReportsService {
  // #47 Menu Performance
  static Future<MenuPerformanceReport> menuPerformance(DateTime weekStart) async { ... }
  
  // #51 Weekly Revenue
  static Future<WeeklyRevenueReport> weeklyRevenue(DateTime weekStart) async { ... }
  
  // #53 Monthly P&L
  static Future<ProfitLossReport> monthlyPnL(DateTime month) async { ... }
  
  // #81 Peak Hour Analysis  
  static Future<Map<int, int>> peakHourAnalysis(DateTime from, DateTime to) async { ... }
  
  // #82 Item-wise Sales
  static Future<List<ItemSalesReport>> itemWiseSales(DateTime from, DateTime to) async { ... }
  
  // #84 Comparative
  static Future<ComparativeReport> comparative(DateTime period1Start, DateTime period2Start) async { ... }
}
```

**Report Models:**
```dart
class MenuPerformanceReport {
  final List<({String name, int quantity, double revenue})> topSellers;
  final List<({String name, int quantity, double revenue})> slowMovers;
  final List<({String name, double margin})> lowMarginItems;
}

class WeeklyRevenueReport {
  final List<({DateTime date, double revenue, int orders, int covers})> dailyBreakdown;
  final Map<String, double> paymentModeBreakdown;
  final double avgTicketSize;
  final int peakHour;
}

class ProfitLossReport {
  final double revenue;
  final double foodCost;         // From recipe deductions
  final double staffCost;        // From salary calculations
  final double expenses;         // From expenses collection
  final double netProfit;
  final double foodCostPercent;
}
```

**Screens:**
| Screen | File | UI |
|--------|------|-----|
| Menu Performance | `lib/features/reports/screens/menu_performance_screen.dart` | Top 10 / Bottom 10 items, margins |
| Weekly Revenue | `lib/features/reports/screens/weekly_report_screen.dart` | Day-by-day bar chart, payment pie |
| Monthly P&L | `lib/features/reports/screens/pnl_report_screen.dart` | Revenue - Costs = Profit waterfall |
| Peak Hours | `lib/features/reports/screens/peak_hours_screen.dart` | Heatmap grid (hour × day of week) |
| Item Sales | `lib/features/reports/screens/item_sales_screen.dart` | Sortable table with qty, revenue, margin |
| Comparisons | `lib/features/reports/screens/comparative_screen.dart` | Side-by-side KPIs with trend arrows |
| Feedback Summary (#58) | `lib/features/reports/screens/feedback_report_screen.dart` | Avg ratings, trends, word cloud |

**Route:** `static const String reports = '/reports';` with sub-routes

---

## PHASE 8 — WhatsApp & Communication (Needs External API)

### 8.1 WhatsApp Business API Integration

**Cloud Function:** `functions/src/whatsapp.ts` (NEW)

```typescript
import * as functions from "firebase-functions";

const MSG91_AUTH_KEY = process.env.MSG91_AUTH_KEY;
const MSG91_TEMPLATE_NAMESPACE = process.env.MSG91_TEMPLATE_NAMESPACE;

// #90 Order Confirmation
export const sendOrderConfirmation = functions.region("asia-south1")
  .firestore.document("users/{uid}/orders/{orderId}")
  .onCreate(async (snapshot, context) => {
    const order = snapshot.data();
    if (order.customerPhone) {
      await sendWhatsApp(order.customerPhone, "order_confirmation", {
        orderNumber: order.orderNumber,
        items: order.items.map(i => i.name).join(", "),
        eta: "20 minutes",
      });
    }
  });

// #93 Feedback Request
export const sendFeedbackRequest = functions.region("asia-south1")
  .firestore.document("users/{uid}/bills/{billId}")
  .onCreate(async (snapshot, context) => {
    const bill = snapshot.data();
    if (bill.customerPhone) {
      const feedbackUrl = `https://tulasihotels.web.app/menu/${context.params.uid}/feedback?billId=${context.params.billId}`;
      await sendWhatsApp(bill.customerPhone, "feedback_request", {
        hotelName: "...",
        feedbackLink: feedbackUrl,
      });
    }
  });

// #94 Reservation Reminder
export const sendReservationReminder = functions.region("asia-south1")
  .pubsub.schedule("every 30 minutes")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    // Find reservations 2 hours from now → send reminder
  });

// #105 Daily Summary
export const sendDailySummary = functions.region("asia-south1")
  .pubsub.schedule("every day 22:00")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    // Aggregate today's revenue, orders, top items → push to owner
  });

async function sendWhatsApp(phone: string, templateId: string, params: Record<string, string>) {
  // MSG91 WhatsApp API call
}
```

### 8.2 FCM Triggers (#102, #103, #104)

**Cloud Function additions:** `functions/src/index.ts`

```typescript
// #102 Kitchen alert on new order
export const onNewOrderKitchenAlert = functions.region("asia-south1")
  .firestore.document("users/{uid}/orders/{orderId}")
  .onCreate(async (snapshot, context) => {
    // Send FCM to kitchen devices: "New order #{orderNumber} - Table {tableName}"
  });

// #103 Server alert when order ready
export const onOrderReady = functions.region("asia-south1")
  .firestore.document("users/{uid}/orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status !== "ready" && after.status === "ready") {
      // Send FCM to assigned waiter: "Order #{orderNumber} ready for Table {tableName}"
    }
  });

// #104 Low stock alert (moved to Phase 5 triggers)
```

### 8.3 SMS Fallback (#99)

**Cloud Function:** `functions/src/sms.ts` (NEW)
```typescript
export const sendOrderReadySMS = functions.region("asia-south1")
  .firestore.document("users/{uid}/orders/{orderId}")
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    if (after.status === "ready" && after.orderType === "takeaway" && after.customerPhone) {
      // Send SMS via MSG91: "Your order #{orderNumber} is ready for pickup!"
    }
  });
```

---

## PHASE 9 — Situational & Compliance

### 9.1 License Tracker (#61)

#### New Model — `LicenseModel`

**File:** `lib/models/license_model.dart` (NEW)

```dart
enum LicenseType { fssai, liquor, fireNoc, healthCert, shopAct, gst, other }

class LicenseModel {
  final String id;
  final LicenseType type;
  final String? licenseNumber;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? issuingAuthority;
  final String? documentUrl;        // Firebase Storage path
  final bool isActive;
  final DateTime createdAt;
}
```

**Firestore:** `users/{uid}/licenses/{licenseId}`

**Service:** `lib/features/compliance/services/license_service.dart` (NEW)
**Screen:** `lib/features/compliance/screens/license_tracker_screen.dart` (NEW)
```
UI: List of licenses with expiry dates
    Color badges: green (>90 days), yellow (30-90 days), red (<30 days)
    Upload document scan
    Renewal reminder via FCM push (Cloud Function)
```

**Cloud Function:**
```typescript
export const licenseExpiryReminder = functions.region("asia-south1")
  .pubsub.schedule("every day 09:00")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    // Find licenses expiring in 30 days → push notification to owner
  });
```

### 9.2 Equipment Maintenance (#63)

#### New Model — `EquipmentModel`

**File:** `lib/models/equipment_model.dart` (NEW)

```dart
class EquipmentModel {
  final String id;
  final String name;                // "Commercial Refrigerator"
  final String? brand;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? purchaseCost;
  final DateTime? warrantyUntil;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDue;
  final String? amcVendor;
  final String? amcPhone;
  final List<ServiceRecord> serviceHistory;
  final DateTime createdAt;
}

class ServiceRecord {
  final DateTime date;
  final String description;
  final double cost;
  final String? vendorName;
}
```

**Firestore:** `users/{uid}/equipment/{equipmentId}`
**Service:** `lib/features/compliance/services/equipment_service.dart` (NEW)
**Screen:** `lib/features/compliance/screens/equipment_screen.dart` (NEW)

### 9.3 Customer Complaint Handling (#66)

#### New Model — `ComplaintModel`

**File:** `lib/models/complaint_model.dart` (NEW)

```dart
enum ComplaintStatus { open, investigating, resolved, closed }
enum ComplaintCategory { food, service, hygiene, billing, other }

class ComplaintModel {
  final String id;
  final String? orderId;
  final String? customerName;
  final String? customerPhone;
  final ComplaintCategory category;
  final String description;
  final ComplaintStatus status;
  final String? resolution;
  final String? assignedTo;          // Staff ID handling it
  final DateTime createdAt;
  final DateTime? resolvedAt;
}
```

**Firestore:** `users/{uid}/complaints/{complaintId}`
**Service:** `lib/features/compliance/services/complaint_service.dart` (NEW)
**Screen:** `lib/features/compliance/screens/complaints_screen.dart` (NEW)
```
UI: Complaint list with status badges and category icons
    Create: link to order, describe issue, assign to staff
    Resolve: add resolution notes, mark resolved
    Dashboard: open count, avg resolution time
```

### 9.4 VIP Guest Handling (#69)

**Model change:** `OrderModel` — add field:
```dart
final bool isVip;
```

**UI changes:**
- NewOrderScreen: "VIP 👑" toggle
- KDS: VIP orders highlighted with gold border + crown icon
- FCM push to owner when VIP order placed

### 9.5 Event/Banquet Menu (#70)

#### New Model — `EventModel`

**File:** `lib/models/event_model.dart` (NEW)

```dart
class EventModel {
  final String id;
  final String eventName;
  final String clientName;
  final String clientPhone;
  final DateTime eventDate;
  final int guestCount;
  final List<EventMenuItem> menu;
  final double perPlatePrice;
  final double totalAmount;
  final double advancePaid;
  final String? specialInstructions;
  final DateTime createdAt;
}

class EventMenuItem {
  final String productId;
  final String name;
  final int quantity;                // Plates/servings
}
```

**Firestore:** `users/{uid}/events/{eventId}`
**Service:** `lib/features/events/services/event_service.dart` (NEW)
**Screen:** `lib/features/events/screens/events_screen.dart` (NEW)
```
UI: Calendar view of upcoming events
    Create: client details, date, guest count, menu builder, per-plate pricing
    Track advance payment
    Generate order from event on the day
```

### 9.6 Seasonal Menu Planning (#60)

**Model change:** `ProductModel` — add fields:
```dart
final DateTime? seasonStart;
final DateTime? seasonEnd;
final String? seasonTag;         // "Summer", "Diwali Special"
```

**UI:** Products screen → "Seasonal" tab → filter by season → bulk toggle availability by date range

### 9.7 Offline Emergency Mode (#71)

Already partially supported via `OfflineStorageService` and demo mode. Enhance:

**Service:** `lib/core/services/offline_order_service.dart` (NEW)
```dart
class OfflineOrderService {
  static Future<void> saveOfflineOrder(OrderModel order) async {
    // Save to SharedPreferences as JSON
  }
  static Future<List<OrderModel>> getPendingOfflineOrders() async { ... }
  static Future<void> syncOfflineOrders() async {
    // Upload all pending offline orders to Firestore when back online
  }
}
```

---

## COMPLETE FIRESTORE SCHEMA

```
users/{uid}/
├── (profile document)
├── products/{productId}          ← Enhanced: dietary, variants, station, HSN
├── combos/{comboId}              ← NEW Phase 1
├── orders/{orderId}              ← Enhanced: customerName, isVip
├── tables/{tableId}              ← Enhanced: posX/Y, assignedServer
├── bills/{billId}                ← Enhanced: splits, GST breakdown
├── staff/{staffId}               ← Existing
├── attendance/{attendanceId}     ← Existing
├── shifts/{shiftId}              ← NEW Phase 3
├── tasks/{taskId}                ← NEW Phase 3
├── messages/{messageId}          ← NEW Phase 3
├── cash_registers/{registerId}   ← NEW Phase 3
├── customers/{customerId}        ← Existing (Khata)
│   └── transactions/{txnId}
├── reservations/{reservationId}  ← NEW Phase 2
├── coupons/{couponId}            ← NEW Phase 2
├── ingredients/{ingredientId}    ← NEW Phase 5
├── recipes/{recipeId}            ← NEW Phase 5
├── purchases/{purchaseId}        ← NEW Phase 5
├── vendors/{vendorId}            ← NEW Phase 5
├── wastage/{wastageId}           ← NEW Phase 5
├── feedback/{feedbackId}         ← NEW Phase 4
├── complaints/{complaintId}      ← NEW Phase 9
├── licenses/{licenseId}          ← NEW Phase 9
├── equipment/{equipmentId}       ← NEW Phase 9
├── events/{eventId}              ← NEW Phase 9
├── expenses/{expenseId}          ← Existing
├── notifications/{notificationId} ← Existing
└── reconciliation_flags/{flagId}  ← NEW Phase 6
```

## CLOUD FUNCTIONS SUMMARY

| Function | Trigger | Phase |
|----------|---------|-------|
| `onRushOrder` | orders.onUpdate (isRush) | 1 |
| `onCustomerOrder` | orders.onCreate (isCustomerOrder) | 4 |
| `onNewOrderKitchenAlert` | orders.onCreate | 8 |
| `onOrderReady` | orders.onUpdate (→ ready) | 8 |
| `onStockUpdate` | ingredients.onUpdate (low stock) | 5 |
| `sendOrderConfirmation` | orders.onCreate (WhatsApp) | 8 |
| `sendFeedbackRequest` | bills.onCreate (WhatsApp) | 8 |
| `sendReservationReminder` | pubsub.schedule (30min) | 8 |
| `sendDailySummary` | pubsub.schedule (22:00) | 8 |
| `sendOrderReadySMS` | orders.onUpdate (takeaway ready) | 8 |
| `licenseExpiryReminder` | pubsub.schedule (09:00) | 9 |
| `razorpayReconciliation` | pubsub.schedule (06:00) | 6 |
| Existing: `createPaymentLink` | https.onCall | ✅ Done |
| Existing: `razorpayWebhook` | https.onRequest | ✅ Done |
| Existing: `sendRegistrationOTP` | https.onCall | ✅ Done |
| Existing: `onUserDeleted` | auth.onDelete | ✅ Done |
| Existing: `onNewUserSignup` | firestore.onCreate | ✅ Done |
| Existing: `sendPushNotification` | firestore.onCreate | ✅ Done |
| Existing: `cleanupOldNotifications` | pubsub.schedule | ✅ Done |
| Existing: `scheduledFirestoreBackup` | pubsub.schedule | ✅ Done |

## FIRESTORE INDEXES TO ADD

```json
[
  { "collection": "reservations", "fields": ["dateTime ASC", "status ASC"] },
  { "collection": "shifts", "fields": ["date ASC", "staffId ASC"] },
  { "collection": "purchases", "fields": ["purchaseDate DESC", "vendorId ASC"] },
  { "collection": "feedback", "fields": ["createdAt DESC"] },
  { "collection": "wastage", "fields": ["date DESC"] },
  { "collection": "ingredients", "fields": ["currentStock ASC", "minLevel ASC"] },
  { "collection": "complaints", "fields": ["status ASC", "createdAt DESC"] },
  { "collection": "events", "fields": ["eventDate ASC"] },
  { "collection": "licenses", "fields": ["expiryDate ASC"] }
]
```

## NEW ROUTES SUMMARY

```dart
// Phase 1
// No new routes — enhancements to existing screens

// Phase 2
static const String reservations = '/reservations';
static const String customerReserve = '/reserve/:hotelId';

// Phase 3
static const String shifts = '/shifts';
static const String tasks = '/tasks';
static const String messages = '/messages';
static const String cashRegister = '/cash-register';
static const String salary = '/salary';

// Phase 4
static const String customerMenu = '/menu/:hotelId';
static const String customerOrder = '/menu/:hotelId/order';
static const String customerOrderStatus = '/menu/:hotelId/order/:orderId/status';
static const String customerFeedback = '/menu/:hotelId/feedback';
static const String feedbackDashboard = '/feedback';

// Phase 5
static const String ingredients = '/ingredients';
static const String purchases = '/purchases';
static const String recipes = '/recipes';
static const String vendors = '/vendors';
static const String wastageLog = '/wastage';

// Phase 6
static const String gstExport = '/gst-export';

// Phase 7
static const String reports = '/reports';        // Sub-routes for each report type

// Phase 9
static const String licenses = '/licenses';
static const String equipment = '/equipment';
static const String complaints = '/complaints';
static const String events = '/events';
```

## FILE COUNT ESTIMATE

| Category | New Files | Enhanced Files |
|----------|-----------|---------------|
| Models | 14 | 3 (Product, Order, Bill) |
| Services | 18 | 4 (Order, Billing, KOT, Table) |
| Providers | 12 | 2 (Products, Cart) |
| Screens | 24 | 5 (Products, KDS, Billing, OrderBilling, Tables) |
| Widgets | 10 | 3 (AddProduct, PaymentModal, ProductGrid) |
| Cloud Functions | 12 new | — |
| **Total** | **~90 new files** | **~17 enhanced** |
