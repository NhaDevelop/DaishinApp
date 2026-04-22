class SaleOrderDetailResponseDto {
  final int status;
  final String message;
  final SaleOrderDetailDto? data;

  SaleOrderDetailResponseDto({
    required this.status,
    required this.message,
    this.data,
  });

  factory SaleOrderDetailResponseDto.fromJson(Map<String, dynamic> json) {
    return SaleOrderDetailResponseDto(
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status'].toString()) ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? SaleOrderDetailDto.fromJson(json['data'])
          : null,
    );
  }
}

class SaleOrderDetailDto {
  final int id;
  final String? customerId; // API returns string "1060"
  final dynamic total; // Can be int or double
  final dynamic totalVat; // Can be string "4.81"
  final dynamic totalPlt;
  final dynamic grandTotal;
  final String? deliveryDate;
  final List<SaleOrderItemDto> items;

  // Add biller/customer info if needed later

  SaleOrderDetailDto({
    required this.id,
    this.customerId,
    this.total,
    this.totalVat,
    this.totalPlt,
    this.grandTotal,
    this.deliveryDate,
    required this.items,
  });

  factory SaleOrderDetailDto.fromJson(Map<String, dynamic> json) {
    return SaleOrderDetailDto(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      customerId: json['customer_id']?.toString(),
      total: json['total'],
      totalVat: json['total_vat'],
      totalPlt: json['total_plt'],
      grandTotal: json['grand_total'],
      deliveryDate: json['add_ons_delivery_date'],
      items: (json['item'] as List<dynamic>?)
              ?.map((e) => SaleOrderItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SaleOrderItemDto {
  final String id;
  final String name;
  final dynamic originalPrice;
  final dynamic price;
  final dynamic quantity; // API returns int, but sometimes string?
  final dynamic subtotal;
  final String? image;

  SaleOrderItemDto({
    required this.id,
    required this.name,
    this.originalPrice,
    this.price,
    this.quantity,
    this.subtotal,
    this.image,
  });

  factory SaleOrderItemDto.fromJson(Map<String, dynamic> json) {
    return SaleOrderItemDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      originalPrice: json['original_price'],
      price: json['price'],
      quantity: json['quantity'],
      subtotal: json['subtotal'],
      image: json['image'],
    );
  }
}
