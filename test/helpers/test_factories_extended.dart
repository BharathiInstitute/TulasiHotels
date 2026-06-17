/// Extended test factories for hotel-domain models.
/// Provides sensible defaults — override only what your test cares about.
library;

import 'package:tulasihotels/models/attendance_model.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/cash_register_model.dart';
import 'package:tulasihotels/models/combo_model.dart';
import 'package:tulasihotels/models/complaint_model.dart';
import 'package:tulasihotels/models/coupon_model.dart';
import 'package:tulasihotels/models/equipment_model.dart';
import 'package:tulasihotels/models/event_model.dart';
import 'package:tulasihotels/models/feedback_model.dart';
import 'package:tulasihotels/models/ingredient_model.dart';
import 'package:tulasihotels/models/license_model.dart';
import 'package:tulasihotels/models/message_model.dart';
import 'package:tulasihotels/models/order_model.dart';
import 'package:tulasihotels/models/product_model.dart';
import 'package:tulasihotels/models/purchase_model.dart';
import 'package:tulasihotels/models/reservation_model.dart';
import 'package:tulasihotels/models/shift_model.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/models/table_model.dart';
import 'package:tulasihotels/models/task_model.dart';
import 'package:tulasihotels/models/vendor_model.dart';
import 'package:tulasihotels/models/wastage_model.dart';

AttendanceModel makeAttendance({
  String id = 'att-1',
  String staffId = 'staff-1',
  String staffName = 'Test Staff',
  DateTime? date,
  DateTime? clockIn,
  DateTime? clockOut,
  AttendanceStatus status = AttendanceStatus.clockedIn,
}) {
  return AttendanceModel(
    id: id,
    staffId: staffId,
    staffName: staffName,
    date: date ?? DateTime(2024, 1, 15),
    clockIn: clockIn ?? DateTime(2024, 1, 15, 9),
    clockOut: clockOut,
    status: status,
  );
}

CashMovement makeCashMovement({
  double amount = 100.0,
  String reason = 'Test movement',
  bool isInflow = true,
  DateTime? timestamp,
}) {
  return CashMovement(
    amount: amount,
    reason: reason,
    isInflow: isInflow,
    timestamp: timestamp ?? DateTime(2024, 1, 15, 10),
  );
}

CashRegisterModel makeCashRegister({
  String id = 'reg-1',
  String staffId = 'staff-1',
  String staffName = 'Test Staff',
  DateTime? openedAt,
  DateTime? closedAt,
  double openingBalance = 1000.0,
  double closingBalance = 0,
  double expectedBalance = 0,
  double variance = 0,
  List<CashMovement>? movements,
}) {
  return CashRegisterModel(
    id: id,
    staffId: staffId,
    staffName: staffName,
    openedAt: openedAt ?? DateTime(2024, 1, 15, 8),
    closedAt: closedAt,
    openingBalance: openingBalance,
    closingBalance: closingBalance,
    expectedBalance: expectedBalance,
    variance: variance,
    movements: movements ?? const [],
  );
}

ComboItem makeComboItem({
  String productId = 'prod-1',
  String name = 'Test Item',
  int quantity = 1,
  bool isSwappable = false,
  List<String>? swapOptions,
}) {
  return ComboItem(
    productId: productId,
    name: name,
    quantity: quantity,
    isSwappable: isSwappable,
    swapOptions: swapOptions,
  );
}

ComboModel makeCombo({
  String id = 'combo-1',
  String name = 'Test Combo',
  String? description,
  double price = 250.0,
  List<ComboItem>? items,
  bool isAvailable = true,
  DietaryTag dietaryTag = DietaryTag.none,
  DateTime? createdAt,
}) {
  return ComboModel(
    id: id,
    name: name,
    description: description,
    price: price,
    items: items ?? [makeComboItem()],
    isAvailable: isAvailable,
    dietaryTag: dietaryTag,
    createdAt: createdAt ?? DateTime(2024),
  );
}

ComplaintModel makeComplaint({
  String id = 'comp-1',
  String? orderId,
  String? customerName,
  String? customerPhone,
  ComplaintCategory category = ComplaintCategory.other,
  String description = 'Test complaint',
  ComplaintStatus status = ComplaintStatus.open,
  String? resolution,
  String? assignedTo,
  DateTime? createdAt,
  DateTime? resolvedAt,
}) {
  return ComplaintModel(
    id: id,
    orderId: orderId,
    customerName: customerName,
    customerPhone: customerPhone,
    category: category,
    description: description,
    status: status,
    resolution: resolution,
    assignedTo: assignedTo,
    createdAt: createdAt ?? DateTime(2024),
    resolvedAt: resolvedAt,
  );
}

CouponModel makeCoupon({
  String id = 'coupon-1',
  String code = 'TEST10',
  CouponType type = CouponType.percentage,
  double value = 10.0,
  double? minOrderAmount,
  double? maxDiscount,
  DateTime? validFrom,
  DateTime? validUntil,
  int? maxUses,
  int usedCount = 0,
  bool isActive = true,
  bool isHappyHour = false,
  int? happyHourStart,
  int? happyHourEnd,
  DateTime? createdAt,
}) {
  return CouponModel(
    id: id,
    code: code,
    type: type,
    value: value,
    minOrderAmount: minOrderAmount,
    maxDiscount: maxDiscount,
    validFrom: validFrom,
    validUntil: validUntil,
    maxUses: maxUses,
    usedCount: usedCount,
    isActive: isActive,
    isHappyHour: isHappyHour,
    happyHourStart: happyHourStart,
    happyHourEnd: happyHourEnd,
    createdAt: createdAt ?? DateTime(2024),
  );
}

ServiceRecord makeServiceRecord({
  DateTime? date,
  String description = 'Routine service',
  double cost = 500.0,
  String? vendorName,
}) {
  return ServiceRecord(
    date: date ?? DateTime(2024, 6),
    description: description,
    cost: cost,
    vendorName: vendorName,
  );
}

EquipmentModel makeEquipment({
  String id = 'equip-1',
  String name = 'Test Oven',
  String? brand,
  String? serialNumber,
  DateTime? purchaseDate,
  double? purchaseCost,
  DateTime? warrantyUntil,
  DateTime? lastServiceDate,
  DateTime? nextServiceDue,
  String? amcVendor,
  String? amcPhone,
  List<ServiceRecord>? serviceHistory,
  DateTime? createdAt,
}) {
  return EquipmentModel(
    id: id,
    name: name,
    brand: brand,
    serialNumber: serialNumber,
    purchaseDate: purchaseDate,
    purchaseCost: purchaseCost,
    warrantyUntil: warrantyUntil,
    lastServiceDate: lastServiceDate,
    nextServiceDue: nextServiceDue,
    amcVendor: amcVendor,
    amcPhone: amcPhone,
    serviceHistory: serviceHistory ?? const [],
    createdAt: createdAt ?? DateTime(2024),
  );
}

EventMenuItem makeEventMenuItem({
  String productId = 'prod-1',
  String name = 'Test Dish',
  int quantity = 1,
}) {
  return EventMenuItem(productId: productId, name: name, quantity: quantity);
}

EventModel makeEvent({
  String id = 'event-1',
  String eventName = 'Test Event',
  String clientName = 'Test Client',
  String clientPhone = '9876543210',
  DateTime? eventDate,
  int guestCount = 50,
  List<EventMenuItem>? menu,
  double perPlatePrice = 500.0,
  double totalAmount = 25000.0,
  double advancePaid = 5000.0,
  String? specialInstructions,
  DateTime? createdAt,
}) {
  return EventModel(
    id: id,
    eventName: eventName,
    clientName: clientName,
    clientPhone: clientPhone,
    eventDate: eventDate ?? DateTime(2024, 12, 25),
    guestCount: guestCount,
    menu: menu ?? [makeEventMenuItem()],
    perPlatePrice: perPlatePrice,
    totalAmount: totalAmount,
    advancePaid: advancePaid,
    specialInstructions: specialInstructions,
    createdAt: createdAt ?? DateTime(2024),
  );
}

FeedbackModel makeFeedback({
  String id = 'fb-1',
  String? orderId,
  String? billId,
  String? customerName,
  String? customerPhone,
  int foodRating = 4,
  int serviceRating = 4,
  int ambianceRating = 4,
  String? comments,
  DateTime? createdAt,
}) {
  return FeedbackModel(
    id: id,
    orderId: orderId,
    billId: billId,
    customerName: customerName,
    customerPhone: customerPhone,
    foodRating: foodRating,
    serviceRating: serviceRating,
    ambianceRating: ambianceRating,
    comments: comments,
    createdAt: createdAt ?? DateTime(2024),
  );
}

IngredientModel makeIngredient({
  String id = 'ing-1',
  String name = 'Test Flour',
  IngredientUnit unit = IngredientUnit.kg,
  double currentStock = 100.0,
  double minLevel = 10.0,
  double? maxLevel,
  double costPerUnit = 50.0,
  String? vendorId,
  String? vendorName,
  DateTime? expiryDate,
  String? batchNumber,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return IngredientModel(
    id: id,
    name: name,
    unit: unit,
    currentStock: currentStock,
    minLevel: minLevel,
    maxLevel: maxLevel,
    costPerUnit: costPerUnit,
    vendorId: vendorId,
    vendorName: vendorName,
    expiryDate: expiryDate,
    batchNumber: batchNumber,
    createdAt: createdAt ?? DateTime(2024),
    updatedAt: updatedAt,
  );
}

LicenseModel makeLicense({
  String id = 'lic-1',
  LicenseType type = LicenseType.fssai,
  String? licenseNumber,
  DateTime? issueDate,
  DateTime? expiryDate,
  String? issuingAuthority,
  String? documentUrl,
  bool isActive = true,
  DateTime? createdAt,
}) {
  return LicenseModel(
    id: id,
    type: type,
    licenseNumber: licenseNumber,
    issueDate: issueDate ?? DateTime(2024),
    expiryDate: expiryDate ?? DateTime(2025),
    issuingAuthority: issuingAuthority,
    documentUrl: documentUrl,
    isActive: isActive,
    createdAt: createdAt ?? DateTime(2024),
  );
}

MessageModel makeMessage({
  String id = 'msg-1',
  String senderId = 'user-1',
  String senderName = 'Test User',
  String content = 'Hello test',
  bool isBroadcast = false,
  String? targetRole,
  DateTime? createdAt,
  bool isRead = false,
}) {
  return MessageModel(
    id: id,
    senderId: senderId,
    senderName: senderName,
    content: content,
    isBroadcast: isBroadcast,
    targetRole: targetRole,
    createdAt: createdAt ?? DateTime(2024),
    isRead: isRead,
  );
}

OrderItem makeOrderItem({
  String productId = 'prod-1',
  String name = 'Test Dish',
  double price = 200.0,
  int quantity = 1,
  String unit = 'piece',
  String? itemNotes,
  OrderItemStatus status = OrderItemStatus.pending,
  int kotNumber = 1,
  DateTime? preparationStartedAt,
  String? kitchenStation,
}) {
  return OrderItem(
    productId: productId,
    name: name,
    price: price,
    quantity: quantity,
    unit: unit,
    itemNotes: itemNotes,
    status: status,
    kotNumber: kotNumber,
    preparationStartedAt: preparationStartedAt,
    kitchenStation: kitchenStation,
  );
}

OrderModel makeOrder({
  String id = 'order-1',
  int orderNumber = 1,
  String? tableId,
  String? tableName,
  List<OrderItem>? items,
  OrderStatus status = OrderStatus.placed,
  OrderType orderType = OrderType.dineIn,
  String? waiterId,
  String? waiterName,
  String? notes,
  int currentKotNumber = 1,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isRush = false,
  String? customerName,
  String? customerPhone,
  bool isCustomerOrder = false,
  bool isVip = false,
}) {
  return OrderModel(
    id: id,
    orderNumber: orderNumber,
    tableId: tableId,
    tableName: tableName,
    items: items ?? [makeOrderItem()],
    status: status,
    orderType: orderType,
    waiterId: waiterId,
    waiterName: waiterName,
    notes: notes,
    currentKotNumber: currentKotNumber,
    createdAt: createdAt ?? DateTime(2024),
    updatedAt: updatedAt ?? DateTime(2024),
    isRush: isRush,
    customerName: customerName,
    customerPhone: customerPhone,
    isCustomerOrder: isCustomerOrder,
    isVip: isVip,
  );
}

PurchaseItem makePurchaseItem({
  String ingredientId = 'ing-1',
  String ingredientName = 'Test Flour',
  double quantity = 10.0,
  double unitCost = 50.0,
  String? batchNumber,
  DateTime? expiryDate,
}) {
  return PurchaseItem(
    ingredientId: ingredientId,
    ingredientName: ingredientName,
    quantity: quantity,
    unitCost: unitCost,
    batchNumber: batchNumber,
    expiryDate: expiryDate,
  );
}

PurchaseModel makePurchase({
  String id = 'pur-1',
  String? vendorId,
  String? vendorName,
  List<PurchaseItem>? items,
  double totalAmount = 5000.0,
  PaymentMethod paymentMethod = PaymentMethod.cash,
  String? invoiceNumber,
  DateTime? purchaseDate,
  DateTime? createdAt,
}) {
  return PurchaseModel(
    id: id,
    vendorId: vendorId,
    vendorName: vendorName,
    items: items ?? [makePurchaseItem()],
    totalAmount: totalAmount,
    paymentMethod: paymentMethod,
    invoiceNumber: invoiceNumber,
    purchaseDate: purchaseDate ?? DateTime(2024, 1, 15),
    createdAt: createdAt ?? DateTime(2024),
  );
}

ReservationModel makeReservation({
  String id = 'res-1',
  String? tableId,
  String guestName = 'Test Guest',
  String phone = '9876543210',
  int partySize = 4,
  DateTime? dateTime,
  int durationMinutes = 90,
  ReservationStatus status = ReservationStatus.pending,
  String? specialRequests,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return ReservationModel(
    id: id,
    tableId: tableId,
    guestName: guestName,
    phone: phone,
    partySize: partySize,
    dateTime: dateTime ?? DateTime(2024, 12, 25, 19),
    durationMinutes: durationMinutes,
    status: status,
    specialRequests: specialRequests,
    createdAt: createdAt ?? DateTime(2024),
    updatedAt: updatedAt,
  );
}

ShiftModel makeShift({
  String id = 'shift-1',
  String staffId = 'staff-1',
  String staffName = 'Test Staff',
  StaffRole role = StaffRole.waiter,
  ShiftType shiftType = ShiftType.morning,
  DateTime? date,
  DateTime? startTime,
  DateTime? endTime,
  String? notes,
  bool isSwapRequested = false,
  String? swapWithStaffId,
  DateTime? createdAt,
}) {
  return ShiftModel(
    id: id,
    staffId: staffId,
    staffName: staffName,
    role: role,
    shiftType: shiftType,
    date: date ?? DateTime(2024, 1, 15),
    startTime: startTime ?? DateTime(2024, 1, 15, 6),
    endTime: endTime ?? DateTime(2024, 1, 15, 14),
    notes: notes,
    isSwapRequested: isSwapRequested,
    swapWithStaffId: swapWithStaffId,
    createdAt: createdAt ?? DateTime(2024),
  );
}

StaffModel makeStaff({
  String id = 'staff-1',
  String name = 'Test Staff',
  String? email,
  String? phone,
  StaffRole role = StaffRole.waiter,
  String pin = '1234',
  bool isActive = true,
  DateTime? createdAt,
  DateTime? updatedAt,
  Map<String, List<String>>? permissions,
}) {
  return StaffModel(
    id: id,
    name: name,
    email: email,
    phone: phone,
    role: role,
    pin: pin,
    isActive: isActive,
    createdAt: createdAt ?? DateTime(2024),
    updatedAt: updatedAt,
    permissions: permissions,
  );
}

TableModel makeTable({
  String id = 'table-1',
  int number = 1,
  String? label,
  int capacity = 4,
  int floor = 0,
  TableStatus status = TableStatus.available,
  String? currentOrderId,
  DateTime? createdAt,
  DateTime? updatedAt,
  double? posX,
  double? posY,
  String? shape,
  String? assignedServerId,
  String? assignedServerName,
}) {
  return TableModel(
    id: id,
    number: number,
    label: label,
    capacity: capacity,
    floor: floor,
    status: status,
    currentOrderId: currentOrderId,
    createdAt: createdAt ?? DateTime(2024),
    updatedAt: updatedAt,
    posX: posX,
    posY: posY,
    shape: shape,
    assignedServerId: assignedServerId,
    assignedServerName: assignedServerName,
  );
}

TaskModel makeTask({
  String id = 'task-1',
  String title = 'Test Task',
  String? description,
  String assignedToId = 'staff-1',
  String assignedToName = 'Test Staff',
  TaskStatus status = TaskStatus.pending,
  TaskPriority priority = TaskPriority.medium,
  DateTime? dueDate,
  DateTime? createdAt,
  DateTime? completedAt,
}) {
  return TaskModel(
    id: id,
    title: title,
    description: description,
    assignedToId: assignedToId,
    assignedToName: assignedToName,
    status: status,
    priority: priority,
    dueDate: dueDate,
    createdAt: createdAt ?? DateTime(2024),
    completedAt: completedAt,
  );
}

VendorModel makeVendor({
  String id = 'vendor-1',
  String name = 'Test Vendor',
  String? phone,
  String? email,
  String? address,
  String? gstNumber,
  double balance = 0,
  List<String>? supplyItems,
  DateTime? createdAt,
}) {
  return VendorModel(
    id: id,
    name: name,
    phone: phone,
    email: email,
    address: address,
    gstNumber: gstNumber,
    balance: balance,
    supplyItems: supplyItems ?? const [],
    createdAt: createdAt ?? DateTime(2024),
  );
}

WastageModel makeWastage({
  String id = 'waste-1',
  String ingredientId = 'ing-1',
  String ingredientName = 'Test Flour',
  double quantity = 5.0,
  IngredientUnit unit = IngredientUnit.kg,
  WastageReason reason = WastageReason.other,
  String? notes,
  double estimatedCost = 250.0,
  DateTime? date,
  String? loggedBy,
  DateTime? createdAt,
}) {
  return WastageModel(
    id: id,
    ingredientId: ingredientId,
    ingredientName: ingredientName,
    quantity: quantity,
    unit: unit,
    reason: reason,
    notes: notes,
    estimatedCost: estimatedCost,
    date: date ?? DateTime(2024, 1, 15),
    loggedBy: loggedBy,
    createdAt: createdAt ?? DateTime(2024),
  );
}
