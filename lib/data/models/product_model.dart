class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? unit;
  final int stock;
  final String categoryId;
  final String? categoryName;
  final List<String> images;
  final bool isActive;
  final DateTime createdAt;
  final double? discountPercentage; // Discount percentage (0-100)
  final double? discountPrice; // Fixed discount price
  final bool isFavorite; // Whether this product is favorited by the user
  final String? promotionDayLeft;
  final String? productType;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.unit,
    required this.stock,
    required this.categoryId,
    this.categoryName,
    required this.images,
    this.isActive = true,
    required this.createdAt,
    this.discountPercentage,
    this.discountPrice,
    this.isFavorite = false,
    this.promotionDayLeft,
    this.productType,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String?,
      stock: json['stock'] as int,
      categoryId: json['category_id'].toString(),
      categoryName: json['category_name'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      discountPercentage: json['discount_percentage'] != null
          ? (json['discount_percentage'] as num).toDouble()
          : null,
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      promotionDayLeft: json['promotion_day_left'] as String?,
      productType: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'stock': stock,
      'category_id': categoryId,
      'category_name': categoryName,
      'images': images,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'discount_percentage': discountPercentage,
      'discount_price': discountPrice,
      'promotion_day_left': promotionDayLeft,
      'type': productType,
    };
  }

  bool get isInStock => stock > 0;

  bool get hasDiscount => discountPercentage != null || discountPrice != null;

  double get finalPrice {
    if (discountPrice != null) {
      return discountPrice!;
    } else if (discountPercentage != null) {
      return price * (1 - discountPercentage! / 100);
    }
    return price;
  }

  double? get savings {
    if (!hasDiscount) return null;
    return price - finalPrice;
  }

  String get displayPrice => '\$${price.toStringAsFixed(2)}';

  String get displayFinalPrice => '\$${finalPrice.toStringAsFixed(2)}';
}
