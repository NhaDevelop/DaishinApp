import 'product_model.dart';

class CartItemModel {
  final String id;
  final ProductModel product;
  final int quantity;
  final double unitPrice;

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Check if 'product' is present (standard cart item) or if it's a flattened order item
    ProductModel product;

    if (json['product'] != null && json['product'] is Map) {
      product = ProductModel.fromJson(json['product'] as Map<String, dynamic>);
    } else {
      // Handle flattened structure from Order API
      product = ProductModel(
        id: json['product_id']?.toString() ?? '0',
        name: json['product_name']?.toString() ?? 'Unknown Product',
        description: json['product_code']?.toString() ?? '',
        price: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
        stock: 99, // default
        categoryId: '0',
        images: [], // No images in order item response usually
        createdAt: DateTime.now(),
        unit: json['unit_quantity']?.toString(), // maybe?
      );
    }

    return CartItemModel(
      id: json['id'].toString(),
      product: product,
      quantity:
          double.tryParse(json['quantity']?.toString() ?? '0')?.toInt() ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  double get totalPrice => unitPrice * quantity;

  CartItemModel copyWith({
    String? id,
    ProductModel? product,
    int? quantity,
    double? unitPrice,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}
