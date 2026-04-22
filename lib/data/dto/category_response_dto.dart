class CategoryResponseDto {
  final int status;
  final String message;
  final List<CategoryDto> data;

  CategoryResponseDto({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CategoryResponseDto.fromJson(Map<String, dynamic> json) {
    return CategoryResponseDto(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List?)
              ?.map((e) => CategoryDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  bool get isSuccess => status == 1;
}

class CategoryDto {
  final String id;
  final String code;
  final String titleEn;
  final String titleKh;
  final String titleJa;
  final String titleCh;
  final List<CategoryDto> sub;

  CategoryDto({
    required this.id,
    required this.code,
    required this.titleEn,
    required this.titleKh,
    required this.titleJa,
    required this.titleCh,
    this.sub = const [],
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      titleEn: json['title_en'] ?? '',
      titleKh: json['title_kh'] ?? '',
      titleJa: json['title_ja'] ?? '',
      titleCh: json['title_ch'] ?? '',
      sub: (json['sub'] as List?)
              ?.map((e) => CategoryDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}
