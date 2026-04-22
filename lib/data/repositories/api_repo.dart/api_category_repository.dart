import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:daishin_order_app/core/utils/api_helper.dart';
import 'package:daishin_order_app/core/constants/api_constants.dart';
import 'package:daishin_order_app/data/models/category_model.dart';
import 'package:daishin_order_app/data/dto/category_response_dto.dart';

class ApiCategoryRepository {
  final ApiHelper _apiHelper = ApiHelper.instance;

  Future<List<CategoryModel>> getCategories() async {
    print('🌐 ApiCategoryRepository: Starting category fetch...');

    // Check network first
    final hasNetwork = await _apiHelper.hasNetwork();
    print('📡 Network available: $hasNetwork');

    if (!hasNetwork) {
      throw Exception('No internet connection. Please check your network.');
    }

    try {
      const url = '${ApiConstants.baseUrl}${ApiConstants.categories}';
      print('🔗 Fetching from: $url');

      final response = await _apiHelper.dio.get(
        url,
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        // Handle Map response (successful case)
        if (response.data is Map<String, dynamic>) {
          final dto = CategoryResponseDto.fromJson(response.data);
          print(
              '✅ DTO parsed successfully. Status: ${dto.status}, Message: ${dto.message}');
          print('📊 Categories count: ${dto.data.length}');

          if (dto.isSuccess) {
            final categories = dto.data.map((e) => _mapDtoToModel(e)).toList();
            print('🎯 Mapped ${categories.length} categories to models');
            return categories;
          } else {
            throw Exception(dto.message);
          }
        }
        // Handle String response (if server returns JSON string)
        else if (response.data is String) {
          print('⚠️ Response is String, parsing JSON...');
          final jsonMap = json.decode(response.data);
          final dto = CategoryResponseDto.fromJson(jsonMap);

          if (dto.isSuccess) {
            return dto.data.map((e) => _mapDtoToModel(e)).toList();
          } else {
            throw Exception(dto.message);
          }
        } else {
          throw const FormatException('Invalid response format');
        }
      } else {
        throw Exception(
            'Failed to load categories. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 ApiCategoryRepository Error: $e');
      if (e is DioException) {
        print('🔴 DioException details: ${e.message}');
        throw Exception(e.message ?? 'Network error occurred');
      }
      rethrow;
    }
  }

  // Helper method to map DTO to Domain Model (CDPV Architecture)
  CategoryModel _mapDtoToModel(CategoryDto dto) {
    return CategoryModel(
      id: dto.id,
      code: dto.code,
      titleEn: dto.titleEn,
      titleKh: dto.titleKh,
      titleJa: dto.titleJa,
      titleCh: dto.titleCh,
      subCategories: dto.sub.map((subDto) => _mapDtoToModel(subDto)).toList(),
    );
  }
}
