import 'dart:convert';

class ProductDetailResponseDto {
  final int status;
  final String message;
  final List<ProductDetailDto> data;

  ProductDetailResponseDto({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ProductDetailResponseDto.fromRawJson(String str) =>
      ProductDetailResponseDto.fromJson(json.decode(str));

  factory ProductDetailResponseDto.fromJson(Map<String, dynamic> json) =>
      ProductDetailResponseDto(
        status: json["status"] ?? 0,
        message: json["message"] ?? "",
        data: json["data"] != null
            ? List<ProductDetailDto>.from(
                json["data"].map((x) => ProductDetailDto.fromJson(x)))
            : [],
      );
}

class ProductDetailDto {
  final String id;
  final String image;
  final String titleEn;
  final String titleKh;
  final String titleJa;
  final String titleCh;
  final String brand;
  final String categoryEn;
  final String categoryKh;
  final String categoryJp;
  final String categoryCh;
  final double originalPrice;
  final double price;
  final String promotionRate;
  final String promotionDayLeft;
  final String promotionDayLeftDate;
  final int promotionMinQty;
  final String unit;
  final String type;
  final int isFavorite;

  ProductDetailDto({
    required this.id,
    required this.image,
    required this.titleEn,
    required this.titleKh,
    required this.titleJa,
    required this.titleCh,
    required this.brand,
    required this.categoryEn,
    required this.categoryKh,
    required this.categoryJp,
    required this.categoryCh,
    required this.originalPrice,
    required this.price,
    required this.promotionRate,
    required this.promotionDayLeft,
    required this.promotionDayLeftDate,
    required this.promotionMinQty,
    required this.unit,
    required this.type,
    required this.isFavorite,
  });

  factory ProductDetailDto.fromJson(Map<String, dynamic> json) =>
      ProductDetailDto(
        id: json["id"]?.toString() ?? "",
        image: json["image"]?.toString() ?? "",
        titleEn: json["title_en"]?.toString() ?? "",
        titleKh: json["title_kh"]?.toString() ?? "",
        titleJa: json["title_ja"]?.toString() ?? "",
        titleCh: json["title_ch"]?.toString() ?? "",
        brand: json["brand"]?.toString() ?? "",
        categoryEn: json["category_en"]?.toString() ?? "",
        categoryKh: json["category_kh"]?.toString() ?? "",
        categoryJp: json["category_jp"]?.toString() ?? "",
        categoryCh: json["category_ch"]?.toString() ?? "",
        originalPrice: _parseDouble(json["original_price"]),
        price: _parseDouble(json["price"]),
        promotionRate: json["promotion_rate"]?.toString() ?? "",
        promotionDayLeft: json["promotion_day_left"]?.toString() ?? "",
        promotionDayLeftDate: json["promotion_day_left_date"]?.toString() ?? "",
        promotionMinQty: _parseInt(json["promotion_min_qty"]),
        unit: json["unit"]?.toString() ?? "",
        type: json["type"]?.toString() ?? "Regular",
        isFavorite: _parseInt(json["is_favorite"]),
      );

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
