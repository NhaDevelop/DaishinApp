import 'dart:convert';
import '../../../core/utils/api_helper.dart';
import '../../../core/constants/api_constants.dart';
import '../../dto/product_response_dto.dart';
import '../abstract/product_repository.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import 'api_category_repository.dart';
import '../../../presentation/providers/auth_provider.dart';

class ApiProductRepository implements ProductRepository {
  final ApiCategoryRepository _categoryRepository = ApiCategoryRepository();
  final AuthProvider _authProvider;

  ApiProductRepository(this._authProvider);

  String get _customerId {
    final user = _authProvider.currentUser;
    if (user == null) {
      return '50'; // Fallback to default customer ID
    }
    return user.id;
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    // Use REAL API only - no fallback
    return await _categoryRepository.getCategories();
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      // Fetch all categories first
      final categories = await _categoryRepository.getCategories();
      if (categories.isEmpty) return [];

      print(
          '📦 Loading products from ${categories.length} categories in batches...');

      // Load products in batches of 3 categories at a time to avoid overwhelming the network
      const batchSize = 3;
      final allProducts = <ProductModel>[];

      for (var i = 0; i < categories.length; i += batchSize) {
        final end = (i + batchSize < categories.length)
            ? i + batchSize
            : categories.length;
        final batch = categories.sublist(i, end);

        print(
            '📥 Loading batch ${(i ~/ batchSize) + 1}/${(categories.length / batchSize).ceil()}: ${batch.map((c) => c.name).join(", ")}');

        // Fetch products for this batch in parallel
        final batchFutures =
            batch.map((category) => getProductsByCategory(category.id));
        final batchResults = await Future.wait(batchFutures);

        // Add all products from this batch
        for (final products in batchResults) {
          allProducts.addAll(products);
        }

        print('✅ Batch complete. Total products so far: ${allProducts.length}');
      }

      // Remove duplicates (in case a product appears in multiple categories)
      final uniqueProducts = <String, ProductModel>{};
      for (final product in allProducts) {
        uniqueProducts[product.id] = product;
      }

      print(
          '🎉 Finished loading all products. Total unique products: ${uniqueProducts.length}');
      return uniqueProducts.values.toList();
    } catch (e) {
      print('❌ Error fetching all products: $e');
      return [];
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      const url = '${ApiConstants.baseUrl}${ApiConstants.productDetail}';
      print('🔗 Fetching product detail for ID $id from: $url');

      final response = await ApiHelper.instance.dio.get(
        url,
        queryParameters: {
          'id': id,
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        try {
          // Import the DTO at the top of the file
          final jsonData = response.data is String
              ? json.decode(response.data)
              : response.data;

          if (jsonData == null) {
            print('⚠️ Decoded JSON is null for product $id');
            throw Exception('Product not found');
          }

          if (jsonData is! Map<String, dynamic>) {
            print('❌ Decoded JSON is not a Map: ${jsonData.runtimeType}');
            throw Exception('Invalid response format');
          }

          // Parse response using DTO
          final data = _parseProductDetailResponse(jsonData);

          print(
              '📊 API Status: ${data['status']}, Message: ${data['message']}');

          if (data['status'] == 1 &&
              data['data'] != null &&
              data['data'].isNotEmpty) {
            final productDto = data['data'][0];
            final product = _mapDetailDtoToModel(productDto);
            print('✅ Successfully fetched product detail for ID $id');
            return product;
          } else {
            print(
                '⚠️ API returned status ${data['status']}: ${data['message']}');
            throw Exception('Product not found');
          }
        } catch (parseError) {
          print('❌ Error parsing product detail response: $parseError');
          print('Raw response data: ${response.data}');
          rethrow;
        }
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching product by ID $id: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      // Note: ApiConstants.productsByCategory already contains query parameters (/?page=...).
      // We need to concatenate it with the base URL to form a complete URL.
      // Dio's queryParameters argument appends to existing ones using '&'.
      // So requesting productsByCategory with {'id': categoryId} results in:
      // https://api-project.camboinfo.com/?page=...&short_title=demo-order&id=123

      // Build the complete URL using the new endpoint format
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.productsByCategory(categoryId)}';
      print('🔗 Fetching products for category $categoryId from: $url');

      final response = await ApiHelper.instance.dio.get(url);

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        try {
          // Handle case where body might be a string (sometimes happens with bad APIs)
          final ProductResponseDto data;

          if (response.data is String) {
            print('⚠️ Response is String, parsing JSON...');
            final jsonData = json.decode(response.data);
            print('✅ JSON decoded successfully');

            // Check if jsonData is null
            if (jsonData == null) {
              print('⚠️ Decoded JSON is null for category $categoryId');
              return [];
            }

            // Check if jsonData is a Map
            if (jsonData is! Map<String, dynamic>) {
              print(
                  '❌ Decoded JSON is not a Map for category $categoryId: ${jsonData.runtimeType}');
              return [];
            }

            data = ProductResponseDto.fromJson(jsonData);
          } else if (response.data is Map<String, dynamic>) {
            print('✅ Response is already Map');
            data = ProductResponseDto.fromJson(response.data);
          } else {
            print('❌ Unexpected response type: ${response.data.runtimeType}');
            return [];
          }

          print('📊 API Status: ${data.status}, Message: ${data.message}');
          print('📦 Products count: ${data.data.length}');

          if (data.status == 1) {
            final products = data.data
                .map((dto) => _mapDtoToModel(dto, categoryId))
                .toList();
            print(
                '✅ Successfully mapped ${products.length} products for category $categoryId');
            return products;
          } else {
            print('⚠️ API returned status ${data.status}: ${data.message}');
            // If status is not 1 (e.g. 0 or error), return empty list instead of throwing
            // to prevent UI crashes if one category is empty/fails
            return [];
          }
        } catch (parseError) {
          print(
              '❌ Error parsing response for category $categoryId: $parseError');
          print('Raw response data: ${response.data}');
          return [];
        }
      }
      print('⚠️ Non-200 status code: ${response.statusCode}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error fetching products by category $categoryId: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  ProductModel _mapDtoToModel(ProductDto dto, String categoryId) {
    print('🔍 Mapping product: ${dto.titleEn}, raw price: "${dto.price}"');

    double price = 0.0;
    try {
      price = double.parse(dto.price);
      print('✅ Parsed price: $price');
    } catch (e) {
      print('❌ Failed to parse price "${dto.price}": $e');
    }

    double originalPrice = 0.0;
    if (dto.originalPrice != null && dto.originalPrice!.isNotEmpty) {
      try {
        originalPrice = double.parse(dto.originalPrice!);
        print('✅ Parsed original price: $originalPrice');
      } catch (e) {
        print('❌ Failed to parse original price "${dto.originalPrice}": $e');
      }
    }

    // Use original price as base price if available, otherwise use price (which might be sale price)
    // This fixes the issue where price (sale price) was treated as original price and discounted again
    final double basePrice = (originalPrice > 0) ? originalPrice : price;

    double? discountPercentage;
    if (dto.promotionRate.isNotEmpty) {
      try {
        discountPercentage = double.parse(dto.promotionRate);
      } catch (_) {}
    }

    // Parse stock from API if available, otherwise use large number to indicate "in stock"
    int stock = 9999; // Default to large number (effectively unlimited)
    if (dto.stock != null && dto.stock!.isNotEmpty) {
      try {
        stock = int.parse(dto.stock!);
        print('✅ Parsed stock: $stock for product ${dto.titleEn}');
      } catch (e) {
        print('⚠️ Failed to parse stock "${dto.stock}": $e, using default');
      }
    }

    return ProductModel(
      id: dto.id,
      name: dto.titleEn.isNotEmpty
          ? dto.titleEn
          : (dto.titleJa.isNotEmpty ? dto.titleJa : 'Unknown Product'),
      description: dto
          .titleJa, // Use Japanese title as description for now purely for data preservation
      price: basePrice,
      stock: stock, // Use parsed stock from API or default
      categoryId: categoryId,
      categoryName: dto.categoryEn.isNotEmpty ? dto.categoryEn : null,
      images: [dto.image],
      createdAt: DateTime.now(),
      isActive: true, // dto.type == 'Regular' ?
      discountPercentage: discountPercentage,
      isFavorite: dto.isFavorite == 1, // Convert int to bool
      promotionDayLeft:
          dto.promotionDayLeft.isNotEmpty ? dto.promotionDayLeft : null,
      productType:
          (dto.type.isNotEmpty && dto.type != 'Regular') ? dto.type : null,
    );
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      if (query.isEmpty) return [];

      print('🔍 Searching products with query: "$query"');

      // Get all products first
      final allProducts = await getProducts();

      // Filter products by name (case-insensitive)
      final searchResults = allProducts.where((product) {
        final productName = product.name.toLowerCase();
        final searchQuery = query.toLowerCase();
        return productName.contains(searchQuery);
      }).toList();

      print('✅ Found ${searchResults.length} products matching "$query"');
      return searchResults;
    } catch (e) {
      print('❌ Error searching products: $e');
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getHotItems() async {
    try {
      // Append customer_id so backend knows who to check favorites for
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.productPromotion}&customer_id=$_customerId';
      print('🔥 Fetching hot items from: $url');

      final response = await ApiHelper.instance.dio.get(url);

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final ProductResponseDto data;

          if (response.data is String) {
            print('⚠️ Response is String, parsing JSON...');
            final jsonData = json.decode(response.data);
            data = ProductResponseDto.fromJson(jsonData);
          } else if (response.data is Map<String, dynamic>) {
            data = ProductResponseDto.fromJson(response.data);
          } else {
            print('❌ Unexpected response type: ${response.data.runtimeType}');
            return [];
          }

          if (data.status == 1) {
            final products =
                data.data.map((dto) => _mapDtoToModel(dto, 'hot')).toList();
            print('✅ Successfully loaded ${products.length} hot items');
            return products;
          } else {
            print('⚠️ API returned status ${data.status}: ${data.message}');
            return [];
          }
        } catch (parseError) {
          print('❌ Error parsing hot items response: $parseError');
          return [];
        }
      }
      print('⚠️ Non-200 status code: ${response.statusCode}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error fetching hot items: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      const url = '${ApiConstants.orderBaseUrl}${ApiConstants.productFeatured}';
      print('🌟 Fetching featured products from: $url');

      final response = await ApiHelper.instance.dio.get(url);

      if (response.statusCode == 200) {
        try {
          final ProductResponseDto data;
          if (response.data is String) {
            final jsonData = json.decode(response.data);
            data = ProductResponseDto.fromJson(jsonData);
          } else if (response.data is Map<String, dynamic>) {
            data = ProductResponseDto.fromJson(response.data);
          } else {
            return [];
          }

          if (data.status == 1) {
            final products = data.data
                .map((dto) => _mapDtoToModel(dto, 'featured'))
                .toList();
            print('✅ Successfully loaded ${products.length} featured products');
            return products;
          }
        } catch (parseError) {
          print('❌ Error parsing featured products: $parseError');
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching featured products: $e');
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getRetailProducts() async {
    try {
      const url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.productRetailUse}';
      print('🛒 Fetching retail products from: $url');

      final response = await ApiHelper.instance.dio.get(url);

      if (response.statusCode == 200) {
        try {
          final ProductResponseDto data;
          if (response.data is String) {
            final jsonData = json.decode(response.data);
            data = ProductResponseDto.fromJson(jsonData);
          } else if (response.data is Map<String, dynamic>) {
            data = ProductResponseDto.fromJson(response.data);
          } else {
            return [];
          }

          if (data.status == 1) {
            final products = data.data
                .map((dto) => _mapDtoToModel(dto, 'Retail use'))
                .toList();
            print('✅ Successfully loaded ${products.length} retail products');
            return products;
          }
        } catch (parseError) {
          print('❌ Error parsing retail products: $parseError');
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching retail products: $e');
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getBusinessProducts() async {
    try {
      const url = '${ApiConstants.orderBaseUrl}${ApiConstants.productBusiness}';
      print('🌟 Fetching business products from: $url');

      final response = await ApiHelper.instance.dio.get(url);

      if (response.statusCode == 200) {
        try {
          final ProductResponseDto data;
          if (response.data is String) {
            final jsonData = json.decode(response.data);
            data = ProductResponseDto.fromJson(jsonData);
          } else if (response.data is Map<String, dynamic>) {
            data = ProductResponseDto.fromJson(response.data);
          } else {
            return [];
          }

          if (data.status == 1) {
            final products = data.data
                .map((dto) => _mapDtoToModel(dto, 'business'))
                .toList();
            print('✅ Successfully loaded ${products.length} business products');
            return products;
          }
        } catch (parseError) {
          print('❌ Error parsing business products: $parseError');
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<ProductModel>?> toggleFavorite(String productId) async {
    try {
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.toggleFavorite(productId, _customerId)}';
      print(
          '❤️ Toggling favorite for product $productId (customer: $_customerId) at: $url');

      final response = await ApiHelper.instance.dio.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData;
        if (response.data is String) {
          jsonData = json.decode(response.data);
        } else {
          jsonData = response.data;
        }

        if (jsonData['status'] == 1) {
          print('✅ Successfully toggled favorite for product $productId');

          // Parse updated favorite list from response
          final List<dynamic> data = jsonData['data'] ?? [];
          if (data.isNotEmpty && data[0] is Map) {
            final item = data[0];
            if (item['favorite_products'] != null) {
              final List<dynamic> productsJson = item['favorite_products'];
              final products = productsJson
                  .map((pJson) {
                    if (pJson is Map<String, dynamic>) {
                      try {
                        final dto = ProductDto.fromJson(pJson);
                        return _mapDtoToModel(dto, 'Favorites');
                      } catch (e) {
                        print(
                            '❌ Error parsing favorite product in toggle response: $e');
                        return null;
                      }
                    }
                    return null;
                  })
                  .where((p) => p != null)
                  .cast<ProductModel>()
                  .toList();

              print(
                  '📋 Updated favorites list from server: ${products.length} items');
              return products;
            }
          }

          // Return empty list if no update provided, but success
          return [];
        } else {
          print('⚠️ Failed to toggle favorite: ${jsonData['message']}');
        }
      }
      return null;
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      return null;
    }
  }

  @override
  Future<List<ProductModel>> getFavorites() async {
    try {
      // Try to fetch from backend endpoint first
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.getFavorites(_customerId)}';
      print('❤️ Fetching favorites from backend: $url');

      final response = await ApiHelper.instance.dio.get(url);
      print('❤️ Favorites API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData;
        if (response.data is String) {
          final dataStr = response.data as String;
          if (dataStr.trim().startsWith('<')) {
            return [];
          }
          jsonData = json.decode(dataStr);
        } else {
          jsonData = response.data;
        }

        if (jsonData['status'] == 1) {
          final List<dynamic> data = jsonData['data'] ?? [];
          final products = data
              .map((item) {
                if (item is Map<String, dynamic>) {
                  try {
                    final dto = ProductDto.fromJson(item);
                    return _mapDtoToModel(dto, 'Favorites');
                  } catch (e) {
                    print('❌ Error parsing favorite product: $e');
                    return null;
                  }
                }
                return null;
              })
              .where((p) => p != null)
              .cast<ProductModel>()
              .toList();

          print(
              '✅ Successfully fetched ${products.length} favorite products from backend API');
          return products;
        } else {
          print(
              '⚠️ Backend returned status ${jsonData['status']}, message: ${jsonData['message'] ?? 'No message'}, returning empty list');
          return [];
        }
      }

      return [];
    } catch (e) {
      print('❌ Error fetching favorites from backend: $e');
      return [];
    }
  }

  // Helper method to parse product detail response
  Map<String, dynamic> _parseProductDetailResponse(Map<String, dynamic> json) {
    return {
      'status': json['status'] ?? 0,
      'message': json['message'] ?? '',
      'data': json['data'] != null
          ? List<Map<String, dynamic>>.from(json['data'])
          : [],
    };
  }

  // Helper method to map product detail DTO to model
  ProductModel _mapDetailDtoToModel(Map<String, dynamic> dto) {
    // Parse prices - API provides both original and discounted price
    double originalPrice = 0.0;
    double salePrice = 0.0;

    try {
      originalPrice = _parseDouble(dto['original_price']);
      salePrice = _parseDouble(dto['price']);
    } catch (_) {}

    // Use original_price as the base price
    // If there's a sale price different from original, calculate discount percentage
    double? discountPercentage;
    if (dto['promotion_rate'] != null &&
        dto['promotion_rate'].toString().isNotEmpty) {
      try {
        final rateStr =
            dto['promotion_rate'].toString().replaceAll('%', '').trim();
        discountPercentage = double.parse(rateStr);
      } catch (_) {}
    } else if (originalPrice > 0 &&
        salePrice > 0 &&
        salePrice < originalPrice) {
      // Calculate discount percentage if not provided
      discountPercentage = ((originalPrice - salePrice) / originalPrice) * 100;
    }

    // Extract category ID and name from category string (e.g., "Beverage, Japanese SHOCHU, ")
    String categoryId = '';
    String? categoryName;
    if (dto['category_en'] != null) {
      final categoriesStr = dto['category_en'].toString();
      final categories = categoriesStr
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();

      if (categories.isNotEmpty) {
        categoryId = categories.first;
        // Join categories with ' > ' for better display (e.g., "Beverage > Japanese SHOCHU")
        categoryName = categories.join(' > ');
      }
    }

    return ProductModel(
      id: dto['id']?.toString() ?? '',
      name: dto['title_en']?.toString().isNotEmpty == true
          ? dto['title_en'].toString()
          : (dto['title_ja']?.toString().isNotEmpty == true
              ? dto['title_ja'].toString()
              : 'Unknown Product'),
      description: dto['title_ja']?.toString() ?? '',
      price: originalPrice,
      unit: dto['unit']?.toString(),
      stock: 100, // Default stock as API doesn't provide it
      categoryId: categoryId,
      categoryName: categoryName,
      images: [dto['image']?.toString() ?? ''],
      createdAt: DateTime.now(),
      isActive: true,
      discountPercentage: discountPercentage,
      promotionDayLeft: dto['promotion_day_left']?.toString(),
      productType: (dto['type'] != null &&
              dto['type'].toString().isNotEmpty &&
              dto['type'].toString().toLowerCase() != 'regular')
          ? dto['type'].toString()
          : null,
    );
  }

  // Helper to parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
