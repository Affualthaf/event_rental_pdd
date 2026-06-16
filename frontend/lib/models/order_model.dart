import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final String city;
  final String zip;
  final String eventName;
  final String specialInstructions;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;
  // Vendor-facing fields
  final String vendorId;
  final int trackingStep;   // 0=Placed,1=Confirmed,2=Prepared,3=Out for Delivery,4=Delivered
  final String trackingNote;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.zip,
    required this.eventName,
    required this.specialInstructions,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.vendorId = '',
    this.trackingStep = 0,
    this.trackingNote = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'city': city,
      'zip': zip,
      'eventName': eventName,
      'specialInstructions': specialInstructions,
      'items': items.map((x) => x.toMap()).toList(),
      'total': total,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'vendorId': vendorId,
      'trackingStep': trackingStep,
      'trackingNote': trackingNote,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      customerName: map['customerName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      zip: map['zip'] ?? '',
      eventName: map['eventName'] ?? '',
      specialInstructions: map['specialInstructions'] ?? '',
      items: List<OrderItem>.from(map['items']?.map((x) => OrderItem.fromMap(x)) ?? []),
      total: (map['total'] ?? 0).toDouble(),
      status: map['status'] ?? 'Processing',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      vendorId: map['vendorId'] ?? '',
      trackingStep: (map['trackingStep'] ?? 0) as int,
      trackingNote: map['trackingNote'] ?? '',
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final int days;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.days,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'days': days,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      days: map['days'] ?? 1,
    );
  }
}
