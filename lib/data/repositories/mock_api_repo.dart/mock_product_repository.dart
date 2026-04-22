// import '../abstract/product_repository.dart';
// import '../../models/product_model.dart';
// import '../../models/category_model.dart';

// class MockProductRepository implements ProductRepository {
//   @override
//   Future<List<ProductModel>> getProducts() async {
//     return [];
//   }

//   @override
//   Future<ProductModel> getProductById(String id) async {
//     throw Exception('Product not found');
//   }

//   @override
//   Future<List<CategoryModel>> getCategories() async {
//     return [];
//   }

//   @override
//   Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
//     return [];
//   }

//   @override
//   Future<List<ProductModel>> searchProducts(String query) async {
//     return [];
//   }

//   @override
//   Future<List<ProductModel>> getHotItems() async {
//     return [];
//   }

//   @override
//   Future<List<ProductModel>> getFeaturedProducts() async {
//     return [];
//   }

//   @override
//   Future<List<ProductModel>> getBusinessProducts() async {
//     return [];
//   }

//   @override
//   Future<List<ProductModel>> getRetailProducts() async {
//     return [];
//   }

//   @override
//   Future<List<String>?> toggleFavorite(String productId) async {
//     await Future.delayed(const Duration(milliseconds: 500));
//     // Mock logic
//     return []; // Return empty list or simulation of updated list
//   }

//   @override
//   Future<List<String>> getFavorites() async {
//     return []; // Mock empty favorites
//   }
// }
