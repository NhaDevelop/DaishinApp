class CategoryModel {
  final String id;
  final String code;
  final String titleEn;
  final String titleKh;
  final String titleJa;
  final String titleCh;
  final List<CategoryModel> subCategories;

  CategoryModel({
    required this.id,
    required this.code,
    required this.titleEn,
    required this.titleKh,
    required this.titleJa,
    required this.titleCh,
    this.subCategories = const [],
  });

  // Helper to get name (defaults to EN, can be enhanced with locale)
  String get name => titleEn;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      titleEn: json['title_en'] ?? '',
      titleKh: json['title_kh'] ?? '',
      titleJa: json['title_ja'] ?? '',
      titleCh: json['title_ch'] ?? '',
      subCategories: (json['sub'] as List?)
              ?.map((e) => CategoryModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title_en': titleEn,
      'title_kh': titleKh,
      'title_ja': titleJa,
      'title_ch': titleCh,
      'sub': subCategories.map((e) => e.toJson()).toList(),
    };
  }
}
