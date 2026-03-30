/// Event/banquet management model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Individual menu item in an event
class EventMenuItem {
  final String productId;
  final String name;
  final int quantity;

  const EventMenuItem({
    required this.productId,
    required this.name,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
    };
  }

  factory EventMenuItem.fromMap(Map<String, dynamic> map) {
    return EventMenuItem(
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      quantity: (map['quantity'] as int?) ?? 1,
    );
  }
}

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

  const EventModel({
    required this.id,
    required this.eventName,
    required this.clientName,
    required this.clientPhone,
    required this.eventDate,
    this.guestCount = 0,
    this.menu = const [],
    this.perPlatePrice = 0,
    this.totalAmount = 0,
    this.advancePaid = 0,
    this.specialInstructions,
    required this.createdAt,
  });

  /// Outstanding balance
  double get balanceDue => totalAmount - advancePaid;

  /// Whether the event is upcoming
  bool get isUpcoming => eventDate.isAfter(DateTime.now());

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      eventName: (data['eventName'] as String?) ?? '',
      clientName: (data['clientName'] as String?) ?? '',
      clientPhone: (data['clientPhone'] as String?) ?? '',
      eventDate:
          (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      guestCount: (data['guestCount'] as int?) ?? 0,
      menu: (data['menu'] as List<dynamic>?)
              ?.map((e) => EventMenuItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      perPlatePrice: (data['perPlatePrice'] as num?)?.toDouble() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      advancePaid: (data['advancePaid'] as num?)?.toDouble() ?? 0,
      specialInstructions: data['specialInstructions'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventName': eventName,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'eventDate': Timestamp.fromDate(eventDate),
      'guestCount': guestCount,
      'menu': menu.map((e) => e.toMap()).toList(),
      'perPlatePrice': perPlatePrice,
      'totalAmount': totalAmount,
      'advancePaid': advancePaid,
      'specialInstructions': specialInstructions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  EventModel copyWith({
    String? eventName,
    String? clientName,
    String? clientPhone,
    DateTime? eventDate,
    int? guestCount,
    List<EventMenuItem>? menu,
    double? perPlatePrice,
    double? totalAmount,
    double? advancePaid,
    String? specialInstructions,
  }) {
    return EventModel(
      id: id,
      eventName: eventName ?? this.eventName,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      eventDate: eventDate ?? this.eventDate,
      guestCount: guestCount ?? this.guestCount,
      menu: menu ?? this.menu,
      perPlatePrice: perPlatePrice ?? this.perPlatePrice,
      totalAmount: totalAmount ?? this.totalAmount,
      advancePaid: advancePaid ?? this.advancePaid,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt,
    );
  }
}
