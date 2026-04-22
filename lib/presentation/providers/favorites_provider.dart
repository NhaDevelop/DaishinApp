import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/abstract/product_repository.dart';
import '../../data/models/product_model.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<String> _favoriteIds = [];
  final List<ProductModel> _favoriteProducts = [];
  final ProductRepository _productRepository;
  bool _isLoading = false;
  int _gridColumns = 3; // Default 3 columns

  List<String> get favoriteIds => _favoriteIds;
  List<ProductModel> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;
  int get gridColumns => _gridColumns;

  FavoritesProvider(this._productRepository) {
    _loadFavorites();
    _loadGridPreference();
  }

  /// Load grid columns preference
  Future<void> _loadGridPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _gridColumns = prefs.getInt('favorite_grid_columns') ?? 3;
    notifyListeners();
  }

  /// Update and save grid columns preference
  Future<void> setGridColumns(int columns) async {
    _gridColumns = columns;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('favorite_grid_columns', columns);
  }

  /// Load favorites from Backend API
  Future<void> _loadFavorites({bool showLoading = true}) async {
    try {
      print('🔄 FavoritesProvider: Starting to load favorites from API...');
      if (showLoading) {
        _isLoading = true;
        notifyListeners();
      }

      // getFavorites now returns List<ProductModel>
      final products = await _productRepository.getFavorites();
      print(
          '📥 FavoritesProvider: Received ${products.length} favorite products from repository');

      _favoriteProducts.clear();
      _favoriteProducts.addAll(products);

      _favoriteIds.clear();
      _favoriteIds.addAll(products.map((p) => p.id));

      print(
          '✅ FavoritesProvider: Loaded ${_favoriteIds.length} favorites into provider');
    } catch (e, stackTrace) {
      print('❌ FavoritesProvider: Error loading favorites from API: $e');
      print('Stack trace: $stackTrace');
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
      print('🏁 FavoritesProvider: Finished loading favorites');
    }
  }

  /// Reload favorites
  Future<void> refreshFavorites() async {
    await _loadFavorites(showLoading: true);
  }

  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final productId = product.id;
    // 1. Optimistic update (UI)
    final wasFavorite = _favoriteIds.contains(productId);
    if (wasFavorite) {
      _favoriteIds.remove(productId);
      // Remove from product list immediately to update Favorites Screen
      _favoriteProducts.removeWhere((p) => p.id == productId);
    } else {
      _favoriteIds.add(productId);
      // Add to product list immediately
      _favoriteProducts.add(product);
    }
    notifyListeners();

    // 2. Sync with API
    try {
      final updatedFavorites =
          await _productRepository.toggleFavorite(productId);
      if (updatedFavorites != null) {
        print('✅ API Sync successful for $productId');
        if (updatedFavorites.isNotEmpty) {
          _favoriteProducts.clear();
          _favoriteProducts.addAll(updatedFavorites);

          _favoriteIds.clear();
          _favoriteIds.addAll(updatedFavorites.map((p) => p.id));
          notifyListeners();
        } else if (wasFavorite && _favoriteProducts.isEmpty) {
          // If we removed an item and our local list is now empty,
          // and server returned empty, we assume truly empty.
        }
      } else {
        print('⚠️ API Sync failed for $productId');
        // On failure, revert
        if (!wasFavorite) {
          // If we were adding, and it failed, we must remove it.
          _favoriteIds.remove(productId);
          _favoriteProducts.removeWhere((p) => p.id == productId);
        } else {
          // If we were removing and failed, add it back
          _favoriteIds.add(productId);
          if (!_favoriteProducts.any((p) => p.id == productId)) {
            _favoriteProducts.add(product);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error syncing favorite to API: $e');
      // Same strategy on error
      if (!wasFavorite) {
        _favoriteIds.remove(productId);
        _favoriteProducts.removeWhere((p) => p.id == productId);
      } else {
        _favoriteIds.add(productId);
        if (!_favoriteProducts.any((p) => p.id == productId)) {
          _favoriteProducts.add(product);
        }
      }
      notifyListeners();
    }
  }

  Future<void> clearFavorites() async {
    _favoriteIds.clear();
    notifyListeners();
  }
}
