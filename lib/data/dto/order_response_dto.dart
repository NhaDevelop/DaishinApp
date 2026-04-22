import 'package:intl/intl.dart';
import 'package:daishin_order_app/data/models/address_model.dart';
import 'package:daishin_order_app/data/models/cart_item_model.dart';
import 'package:daishin_order_app/data/models/order_model.dart';

class OrderDto {
  final dynamic id;
  final String? referenceNo;
  final String? customer;
  final dynamic userId;
  final dynamic customerId;
  final List<dynamic>? items;
  final dynamic jsonSaleItems;
  final dynamic subtotal;
  final dynamic total; // Some responses use 'total' for subtotal
  final dynamic tax;
  final dynamic totalTax;
  final dynamic shippingFee;
  final dynamic shipping;
  final dynamic grandTotal;
  final String? paymentMethod;
  final String? saleStatus;
  final String? status;
  final String? deliveryStatus;
  final String? paymentStatus;
  final dynamic deliveryAddress;
  final String? deliveryDate;
  final String? attachment;
  final String? paymentReceiptUrl;
  final String? note;
  final String? notes;
  final dynamic totalItems;
  final String? date;
  final String? createdAt;
  final String? updatedAt;

  OrderDto({
    this.id,
    this.referenceNo,
    this.customer,
    this.userId,
    this.customerId,
    this.items,
    this.jsonSaleItems,
    this.subtotal,
    this.total,
    this.tax,
    this.totalTax,
    this.shippingFee,
    this.shipping,
    this.grandTotal,
    this.paymentMethod,
    this.saleStatus,
    this.status,
    this.deliveryStatus,
    this.paymentStatus,
    this.deliveryAddress,
    this.deliveryDate,
    this.attachment,
    this.paymentReceiptUrl,
    this.note,
    this.notes,
    this.totalItems,
    this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    // Debug: Print all available keys
    print('🔑 OrderDto JSON Keys for ID ${json['id']}: ${json.keys.toList()}');

    // Debug: Print ALL field values for date debugging
    print('📋 ALL VALUES for Order ${json['id']}:');
    print('   created_at: "${json['created_at']}"');
    print('   updated_at: "${json['updated_at']}"');
    print('   date: "${json['date']}"');
    print('   delivery_date: "${json['delivery_date']}"');
    print('   time: "${json['time']}"');
    print('   timestamp: "${json['timestamp']}"');

    return OrderDto(
      id: json['id'],
      referenceNo: json['reference_no']?.toString(),
      customer: json['customer']?.toString(),
      userId: json['user_id'],
      customerId: json['customer_id'],
      items: json['items'] as List<dynamic>?,
      jsonSaleItems: json['json_sale_items'],
      subtotal: json['subtotal'],
      total: json['total'],
      tax: json['tax'],
      totalTax: json['total_tax'],
      shippingFee: json['shipping_fee'],
      shipping: json['shipping'],
      grandTotal: json['grand_total'],
      paymentMethod: json['payment_method']?.toString(),
      saleStatus: json['sale_status']?.toString(),
      status: json['status']?.toString(),
      deliveryStatus: json['delivery_status']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      deliveryAddress: json['delivery_address'],
      deliveryDate: json['delivery_date']?.toString(),
      attachment: json['attachment']?.toString(),
      paymentReceiptUrl: json['payment_receipt_url']?.toString(),
      note: json['note']?.toString(),
      notes: json['notes']?.toString(),
      totalItems: json['total_items'],
      date: json['date']?.toString() ??
          json['order_date']?.toString() ??
          json['created_date']?.toString() ??
          json['timestamp']?.toString() ??
          json['created']?.toString() ??
          json['date_added']?.toString(),
      createdAt: json['created_at']?.toString() ?? json['time']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  OrderModel toDomain() {
    // 1. Parse Items
    List<CartItemModel> parsedItems = [];
    try {
      if (jsonSaleItems != null) {
        // TODO: Parse json_sale_items logic if needed
      } else if (items != null) {
        parsedItems = items!
            .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('⚠️ Could not parse items in DTO: $e');
      parsedItems = [];
    }

    // 2. Parse Address
    // Default values for missing address
    final defaultAddress = AddressModel(
      id: '0',
      userId: customerId?.toString() ?? userId?.toString() ?? '0',
      fullName: customer?.split('<').first.trim() ?? 'Guest',
      phone: '',
      addressLine1: '',
      city: 'Phnom Penh',
      country: 'Cambodia',
    );

    AddressModel parsedAddress;
    if (deliveryAddress != null && deliveryAddress is Map) {
      parsedAddress =
          AddressModel.fromJson(deliveryAddress as Map<String, dynamic>);
    } else if (deliveryAddress is String) {
      parsedAddress = AddressModel(
        id: defaultAddress.id,
        userId: defaultAddress.userId,
        fullName: defaultAddress.fullName,
        phone: defaultAddress.phone,
        addressLine1: deliveryAddress,
        city: defaultAddress.city,
        country: defaultAddress.country,
        isDefault: defaultAddress.isDefault,
      );
    } else {
      parsedAddress = defaultAddress;
    }

    // 3. Parse Dates
    print('🔍 DEBUG OrderDto - ID: $id');
    print('🔍 createdAt raw: "$createdAt"');
    print('🔍 date raw: "$date"');
    print('🔍 updatedAt raw: "$updatedAt"');

    DateTime? parseDateRobust(String? raw) {
      if (raw == null || raw.trim().isEmpty) return null;

      // Try Numeric Timestamp (Seconds or Milliseconds)
      final numVal = int.tryParse(raw);
      if (numVal != null && numVal > 0) {
        // Heuristic: If length > 10, likely ms. Else seconds.
        if (raw.length > 10) {
          return DateTime.fromMillisecondsSinceEpoch(numVal);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(numVal * 1000);
        }
      }

      final iso = DateTime.tryParse(raw);
      if (iso != null) return iso;
      try {
        return DateFormat('MMM d, y h:mm a').parseLoose(raw);
      } catch (_) {}
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parseLoose(raw);
      } catch (_) {}
      try {
        return DateFormat('dd/MM/yyyy HH:mm:ss').parseLoose(raw);
      } catch (_) {}
      try {
        return DateFormat('MM/dd/yyyy HH:mm:ss').parseLoose(raw);
      } catch (_) {}
      try {
        return DateFormat('dd-MM-yyyy HH:mm:ss').parseLoose(raw);
      } catch (_) {}

      print('❌ Failed to parse date string: "$raw"');
      return null;
    }

    final parsedCreatedAt = parseDateRobust(createdAt) ??
        parseDateRobust(date) ??
        parseDateRobust(updatedAt) ??
        DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day); // Fallback to Today Midnight

    final parsedUpdatedAt =
        updatedAt != null ? DateTime.tryParse(updatedAt!) : null;
    final parsedDeliveryDate =
        deliveryDate != null ? DateTime.tryParse(deliveryDate!) : null;

    // 4. Parse Numbers
    final parsedSubtotal = double.tryParse(subtotal?.toString() ?? '0') ??
        double.tryParse(total?.toString() ?? '0') ??
        0.0;

    final parsedTax = double.tryParse(tax?.toString() ?? '0') ??
        double.tryParse(totalTax?.toString() ?? '0') ??
        0.0;

    final parsedShipping = double.tryParse(shippingFee?.toString() ?? '0') ??
        double.tryParse(shipping?.toString() ?? '0') ??
        0.0;

    final parsedGrandTotal = double.tryParse(grandTotal?.toString() ?? '0') ??
        double.tryParse(total?.toString() ?? '0') ??
        0.0;

    return OrderModel(
      id: id.toString(),
      referenceNo: referenceNo,
      customerName: customer?.split('<').first.trim(),
      userId: customerId?.toString() ?? userId?.toString() ?? '0',
      items: parsedItems,
      subtotal: parsedSubtotal,
      tax: parsedTax,
      shippingFee: parsedShipping,
      total: parsedGrandTotal,
      paymentMethod: paymentMethod ?? 'Bank Transfer',
      status: saleStatus ?? status ?? 'pending',
      deliveryStatus: saleStatus ?? deliveryStatus ?? 'pending',
      paymentStatus: paymentStatus ?? 'pending',
      deliveryAddress: parsedAddress,
      deliveryDate: parsedDeliveryDate,
      paymentReceiptUrl: attachment ?? paymentReceiptUrl,
      notes: note ?? notes,
      totalItems: int.tryParse(totalItems?.toString() ?? ''),
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }
}
