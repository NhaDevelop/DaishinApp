class CartResponseDto {
  final int status;
  final String message;
  final CartDataDto? data;

  CartResponseDto({
    required this.status,
    required this.message,
    this.data,
  });

  factory CartResponseDto.fromJson(Map<String, dynamic> json) {
    return CartResponseDto(
      status: json['status'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? CartDataDto.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class CartDataDto {
  final int id;
  final String customerId;
  final String date;
  final String time;
  final double total;
  final double totalVat;
  final double totalPlt;
  final double grandTotal;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String customerEmail;
  final List<CartItemDto> items;

  CartDataDto({
    required this.id,
    required this.customerId,
    required this.date,
    required this.time,
    required this.total,
    required this.totalVat,
    required this.totalPlt,
    required this.grandTotal,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.customerEmail,
    required this.items,
  });

  factory CartDataDto.fromJson(Map<String, dynamic> json) {
    return CartDataDto(
      id: json['id'] as int? ?? 0,
      customerId: json['customer_id']?.toString() ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      totalVat: double.tryParse(json['total_vat']?.toString() ?? '0') ?? 0.0,
      totalPlt: double.tryParse(json['total_plt']?.toString() ?? '0') ?? 0.0,
      grandTotal:
          double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0.0,
      customerName: json['customer_name'] as String? ?? '',
      customerAddress: json['customer_address'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      customerEmail: json['customer_email'] as String? ?? '',
      items: (json['item'] as List<dynamic>?)
              ?.map(
                  (item) => CartItemDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'date': date,
      'time': time,
      'total': total,
      'total_vat': totalVat,
      'total_plt': totalPlt,
      'grand_total': grandTotal,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'item': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CartItemDto {
  final String id;
  final String name;
  final double originalPrice;
  final double price;
  final int quantity;
  final double subtotal;
  final double itemTax;
  final double discountRate;
  final double discountAmount;
  final String discountType;
  final String image;

  CartItemDto({
    required this.id,
    required this.name,
    required this.originalPrice,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.itemTax,
    required this.discountRate,
    required this.discountAmount,
    required this.discountType,
    required this.image,
  });

  factory CartItemDto.fromJson(Map<String, dynamic> json) {
    // Debug print to find image key
    print('📦 Cart Item JSON Keys: ${json.keys.toList()}');

    return CartItemDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      originalPrice:
          double.tryParse(json['original_price']?.toString() ?? '0') ?? 0.0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      itemTax: double.tryParse(json['item_tax']?.toString() ?? '0') ?? 0.0,
      discountRate:
          double.tryParse(json['discount_rate']?.toString() ?? '0') ?? 0.0,
      discountAmount:
          double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      discountType: json['discount_type']?.toString() ?? '',
      image: json['image'] as String? ??
          json['photo'] as String? ??
          json['thumb'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'original_price': originalPrice,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'item_tax': itemTax,
      'discount_rate': discountRate,
      'discount_amount': discountAmount,
      'discount_type': discountType,
    };
  }
}
