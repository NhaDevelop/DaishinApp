import '../../models/product_model.dart';
import '../../models/category_model.dart';

abstract class ProductRepository {
  /// Get all products
  Future<List<ProductModel>> getProducts();

  /// Get product by ID
  Future<ProductModel> getProductById(String id);

  /// Get all categories
  Future<List<CategoryModel>> getCategories();

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String categoryId);

  /// Search products by name
  Future<List<ProductModel>> searchProducts(String query);

  /// Get hot/promotional items
  Future<List<ProductModel>> getHotItems();
    
  /// Get featured/popular items
  Future<List<ProductModel>> getFeaturedProducts();

  /// Get business use items
  Future<List<ProductModel>> getBusinessProducts();

  /// Get retail use items
  Future<List<ProductModel>> getRetailProducts();

  /// Toggle favorite status. Returns updated list of favorite Products if successful, null otherwise.
  Future<List<ProductModel>?> toggleFavorite(String productId);

  /// Get user's favorite products (Full models)
  Future<List<ProductModel>> getFavorites();
}
