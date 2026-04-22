import 'dart:convert';

class ProductResponseDto {
  final int status;
  final String message;
  final List<ProductDto> data;

  ProductResponseDto({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ProductResponseDto.fromRawJson(String str) =>
      ProductResponseDto.fromJson(json.decode(str));

  factory ProductResponseDto.fromJson(Map<String, dynamic> json) =>
      ProductResponseDto(
        status: json["status"] ?? 0,
        message: json["message"] ?? "",
        data: json["data"] != null
            ? List<ProductDto>.from(
                json["data"].map((x) => ProductDto.fromJson(x)))
            : [],
      );
}

class ProductDto {
  final String id;
  final String image;
  final String titleEn;
  final String titleKh;
  final String titleJa;
  final String titleCh;
  final String price;
  final String promotionRate;
  final String promotionDayLeft;
  final String promotionMinQty;
  final String type;
  final String categoryEn;
  final String? originalPrice;
  final int isFavorite;
  final String? stock; // Stock/quantity available

  ProductDto({
    required this.id,
    required this.image,
    required this.titleEn,
    required this.titleKh,
    required this.titleJa,
    required this.titleCh,
    required this.price,
    required this.promotionRate,
    required this.promotionDayLeft,
    required this.promotionMinQty,
    required this.type,
    required this.categoryEn,
    this.originalPrice,
    required this.isFavorite,
    this.stock,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    // Handle price - can be either a number or string from API
    String priceStr = "0";
    if (json["price"] != null) {
      if (json["price"] is num) {
        priceStr = json["price"].toString();
      } else {
        priceStr = json["price"]?.toString() ?? "0";
      }
    }

    return ProductDto(
      id: json["id"]?.toString() ?? "",
      image: json["image"]?.toString() ?? "",
      titleEn: json["title_en"]?.toString() ?? "",
      titleKh: json["title_kh"]?.toString() ?? "",
      titleJa: json["title_ja"]?.toString() ?? "",
      titleCh: json["title_ch"]?.toString() ?? "",
      price: priceStr,
      promotionRate: json["promotion_rate"]?.toString() ?? "",
      promotionDayLeft: json["promotion_day_left"]?.toString() ?? "",
      promotionMinQty: json["promotion_min_qty"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "Regular",
      categoryEn: json["category_en"]?.toString() ?? "",
      originalPrice: json["original_price"]?.toString(),
      isFavorite: json["is_favorite"] is int
          ? json["is_favorite"]
          : int.tryParse(json["is_favorite"]?.toString() ?? "0") ?? 0,
      stock: json["stock"]?.toString() ?? json["qty"]?.toString(),
    );
  }
}
