import 'package:daishin_order_app/data/dto/order_response_dto.dart';
import 'address_model.dart';
import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final String? referenceNo; 
  final String? customerName; 
  final String userId;
  final List<CartItemModel> items;
  final double subtotal;
  final double tax;
  final double shippingFee;
  final double total;
  final String paymentMethod;
  final String status; 
  final String deliveryStatus; // Delivery status: pending, in_transit, delivered
  final String paymentStatus; // Payment status: pending, paid, failed
  final AddressModel deliveryAddress;
  final DateTime? deliveryDate; // Expected/actual delivery date
  final String? paymentReceiptUrl;
  final String? notes;
  final int? totalItems; // Total number of items in the order
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    this.referenceNo,
    this.customerName,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shippingFee,
    required this.total,
    required this.paymentMethod,
    required this.status,
    this.deliveryStatus = 'pending',
    this.paymentStatus = 'pending',
    required this.deliveryAddress,
    this.deliveryDate,
    this.paymentReceiptUrl,
    this.notes,
    this.totalItems,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderDto.fromJson(json).toDomain();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference_no': referenceNo,
      'customer': customerName,
      'user_id': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping_fee': shippingFee,
      'total': total,
      'payment_method': paymentMethod,
      'status': status,
      'delivery_status': deliveryStatus,
      'payment_status': paymentStatus,
      'delivery_address': deliveryAddress.toJson(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'payment_receipt_url': paymentReceiptUrl,
      'notes': notes,
      'total_items': totalItems,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  DateTime get estimatedDeliveryDate {
    return deliveryDate ?? createdAt.add(const Duration(days: 3));
  }
}
