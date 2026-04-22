import 'package:flutter/foundation.dart';
import '../../data/repositories/abstract/product_repository.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../core/utils/async_value.dart';

enum ProductFilterType { all, hot, featured, business, retails }

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository;

  ProductProvider(this._productRepository);

  AsyncValue<List<ProductModel>> _productsState = const AsyncValue.loading();
  AsyncValue<List<ProductModel>> _hiddenProductsState =
      const AsyncValue.loading();
  AsyncValue<List<ProductModel>> _filteredProductsState =
      const AsyncValue.loading();
  AsyncValue<List<ProductModel>> _listingState =
      const AsyncValue.loading(); // Separate state for product list screen
  AsyncValue<List<ProductModel>> _hotItemsState = const AsyncValue.loading();
  AsyncValue<List<ProductModel>> _featuredItemsState =
      const AsyncValue.loading();
  AsyncValue<List<ProductModel>> _businessItemsState =
      const AsyncValue.loading();
  AsyncValue<List<ProductModel>> _retailItemsState = const AsyncValue.loading();
  AsyncValue<List<CategoryModel>> _categoriesState = const AsyncValue.loading();

  String? _selectedCategoryId;
  String _searchQuery = '';
  ProductFilterType _filterType = ProductFilterType.hot; // Default to hot

  AsyncValue<List<ProductModel>> get productsState => _productsState;
  AsyncValue<List<ProductModel>> get hiddenProductsState =>
      _hiddenProductsState;
  AsyncValue<List<ProductModel>> get filteredProductsState =>
      _filteredProductsState;
  AsyncValue<List<ProductModel>> get listingState => _listingState;
  AsyncValue<List<ProductModel>> get hotItemsState => _hotItemsState;
  AsyncValue<List<ProductModel>> get featuredItemsState => _featuredItemsState;
  AsyncValue<List<ProductModel>> get businessItemsState => _businessItemsState;
  AsyncValue<List<CategoryModel>> get categoriesState => _categoriesState;
  AsyncValue<List<ProductModel>> get retailItemsState => _retailItemsState;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  ProductFilterType get filterType => _filterType;

  /// Get the name of the currently selected category
  String? get selectedCategoryName {
    if (_selectedCategoryId == null) return null;
    return _categoriesState.when(
      loading: () => null,
      error: (_) => null,
      success: (categories) =>
          _findCategoryName(categories, _selectedCategoryId!),
    );
  }

  /// Get all currently loaded products from all states
  List<ProductModel> get allLoadedProducts {
    final Set<String> productIds = {};
    final List<ProductModel> allProducts = [];

    void addProducts(AsyncValue<List<ProductModel>> state) {
      state.when(
        loading: () {},
        error: (_) {},
        success: (products) {
          for (var product in products) {
            if (!productIds.contains(product.id)) {
              productIds.add(product.id);
              allProducts.add(product);
            }
          }
        },
      );
    }

    addProducts(_productsState);
    addProducts(_hotItemsState);
    addProducts(_featuredItemsState);
    addProducts(_businessItemsState);
    addProducts(_retailItemsState);
    addProducts(_filteredProductsState);

    return allProducts;
  }

  /// Load hot items
  Future<void> loadHotItems() async {
    // Only set loading if we don't have data yet
    if (!_hotItemsState.hasData) {
      _hotItemsState = const AsyncValue.loading();
      notifyListeners();
    }

    try {
      print('🔥 ProductProvider: Loading hot items...');
      final hotItems = await _productRepository.getHotItems();
      _hotItemsState = AsyncValue.success(hotItems);

      if (_filterType == ProductFilterType.hot) {
        _filteredProductsState = _hotItemsState;
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error loading hot items: $e');
      _hotItemsState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Load featured items
  // Load retail items
  Future<void> loadRetailProducts() async {
    // Only set loading if we don't have data yet
    if (!_retailItemsState.hasData) {
      _retailItemsState = const AsyncValue.loading();
      notifyListeners();
    }

    try {
      print('🛒 ProductProvider: Loading retail products...');
      final retailItems = await _productRepository.getRetailProducts();
      _retailItemsState = AsyncValue.success(retailItems);

      if (_filterType == ProductFilterType.retails) {
        _filteredProductsState = _retailItemsState;
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error loading retail products: $e');
      _retailItemsState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Load featured items
  Future<void> loadFeaturedProducts() async {
    // Only set loading if we don't have data yet
    if (!_featuredItemsState.hasData) {
      _featuredItemsState = const AsyncValue.loading();
      notifyListeners();
    }

    try {
      print('🌟 ProductProvider: Loading featured products...');
      final featuredItems = await _productRepository.getFeaturedProducts();
      _featuredItemsState = AsyncValue.success(featuredItems);

      if (_filterType == ProductFilterType.featured) {
        _filteredProductsState = _featuredItemsState;
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error loading featured products: $e');
      _featuredItemsState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Load business items
  Future<void> loadBusinessProducts() async {
    // Only set loading if we don't have data yet
    if (!_businessItemsState.hasData) {
      _businessItemsState = const AsyncValue.loading();
      notifyListeners();
    }

    try {
      print('🏢 ProductProvider: Loading business products...');
      final businessItems = await _productRepository.getBusinessProducts();
      _businessItemsState = AsyncValue.success(businessItems);

      if (_filterType == ProductFilterType.business) {
        _filteredProductsState = _businessItemsState;
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error loading business products: $e');
      _businessItemsState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Toggle filter type
  /// Toggle filter type
  void setFilterType(ProductFilterType type) {
    _filterType = type;

    // Helper to switch state immediately if data is available
    // or trigger load if not
    void switchState(
        AsyncValue<List<ProductModel>> sourceState, Function loadFunction) {
      if (sourceState.hasData) {
        _filteredProductsState = sourceState;
        notifyListeners();
        // Optionally trigger a background refresh?
        // loadFunction();
      } else {
        _filteredProductsState = const AsyncValue.loading();
        notifyListeners();
        loadFunction();
      }
    }

    switch (type) {
      case ProductFilterType.hot:
        switchState(_hotItemsState, loadHotItems);
        break;
      case ProductFilterType.retails:
        switchState(_retailItemsState, loadRetailProducts);
        break;
      case ProductFilterType.featured:
        switchState(_featuredItemsState, loadFeaturedProducts);
        break;
      case ProductFilterType.business:
        switchState(_businessItemsState, loadBusinessProducts);
        break;
      case ProductFilterType.all:
        if (_selectedCategoryId != null) {
          _filteredProductsState = const AsyncValue.loading();
          notifyListeners();
          filterByCategory(_selectedCategoryId);
        } else {
          // Check if we have main products loaded
          if (_productsState.hasData) {
            _filteredProductsState = _productsState;
            notifyListeners();
          } else {
            _filteredProductsState = const AsyncValue.loading();
            notifyListeners();
            super_loadProducts();
          }
        }
        break;
    }
  }

  Future<void> loadProducts() async {
    // Optimization: Only load the data required for the current filter
    // This prevents loading all data (heavy) on startup
    switch (_filterType) {
      case ProductFilterType.hot:
        await loadHotItems();
        break;
      case ProductFilterType.featured:
        await loadFeaturedProducts();
        break;
      case ProductFilterType.business:
        await loadBusinessProducts();
        break;
      case ProductFilterType.retails:
        await loadRetailProducts();
        break;
      case ProductFilterType.all:
        await super_loadProducts();
        break;
    }
  }

  Future<void> super_loadProducts() async {
    // Only set loading if we don't have data yet
    if (!_productsState.hasData) {
      _productsState = const AsyncValue.loading();
      if (_filterType == ProductFilterType.all) {
        _filteredProductsState = const AsyncValue.loading();
      }
    }
    _hiddenProductsState = const AsyncValue.success([]);
    notifyListeners();

    try {
      print('📦 ProductProvider: Loading all products for home screen...');
      final allProducts = await _productRepository.getProducts();

      final activeProducts = allProducts.where((p) => p.isActive).toList();
      final hiddenProducts = allProducts.where((p) => !p.isActive).toList();

      _productsState = AsyncValue.success(activeProducts);

      if (_filterType == ProductFilterType.all) {
        _filteredProductsState = AsyncValue.success(activeProducts);
      }
      // Initialize listing state with all products
      _listingState = AsyncValue.success(activeProducts);

      _hiddenProductsState = AsyncValue.success(hiddenProducts);
      notifyListeners();
    } catch (e) {
      print('❌ Error loading products: $e');
      _productsState = AsyncValue.error(e);
      if (_filterType == ProductFilterType.all) {
        _filteredProductsState = AsyncValue.error(e);
      }
      _listingState = AsyncValue.error(e);
      _hiddenProductsState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Load categories
  Future<void> loadCategories() async {
    print('🔵 ProductProvider: Loading categories...');
    _categoriesState = const AsyncValue.loading();
    notifyListeners();

    try {
      final categories = await _productRepository.getCategories();
      print(
          '✅ ProductProvider: Loaded ${categories.length} categories from API');
      print('📋 Categories: ${categories.map((c) => c.name).join(", ")}');
      _categoriesState = AsyncValue.success(categories);
      notifyListeners();
    } catch (e) {
      print('❌ ProductProvider: Error loading categories: $e');
      _categoriesState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Filter by category
  Future<void> filterByCategory(String? categoryId) async {
    print(
        '🔍 ProductProvider: filterByCategory called with categoryId: $categoryId');
    _selectedCategoryId = categoryId;
    _listingState = const AsyncValue.loading();
    notifyListeners();

    try {
      // Force switch to 'All' mode when a category is selected
      _filterType = ProductFilterType.all;

      print('📡 Fetching products for category: ${categoryId ?? "ALL"}');
      final allProducts = categoryId == null
          ? await _productRepository.getProducts()
          : await _productRepository.getProductsByCategory(categoryId);

      // Filter to show only active products
      var activeProducts = allProducts.where((p) => p.isActive).toList();

      // Client-side filtering: Ensure product actually belongs to the selected category
      // This works around API issues where subcategory requests might return parent products
      if (categoryId != null) {
        _categoriesState.when(
          loading: () {},
          error: (_) {},
          success: (categories) {
            final categoryName = _findCategoryName(categories, categoryId);
            if (categoryName != null) {
              print('🔍 Client-side filtering for category: "$categoryName"');
              final initialCount = activeProducts.length;

              activeProducts = activeProducts.where((p) {
                if (p.categoryName == null) return false;
                // Check if category name appears in the product's category path
                return p.categoryName!
                    .toLowerCase()
                    .contains(categoryName.toLowerCase());
              }).toList();

              print(
                  '📉 Filtered from $initialCount to ${activeProducts.length} products');
            }
          },
        );
      }

      print(
          '✅ Got ${activeProducts.length} active products for category: ${categoryId ?? "ALL"}');
      _listingState =
          AsyncValue.success(activeProducts); // Update listing state

      // Update filteredProductsState since we forced 'All' mode
      _filteredProductsState = AsyncValue.success(activeProducts);

      notifyListeners();
    } catch (e) {
      print('❌ Error filtering by category $categoryId: $e');
      _listingState = AsyncValue.error(e);
      // Ensure we don't leave filteredProductsState in valid state if failed
      if (_filterType == ProductFilterType.all) {
        _filteredProductsState = AsyncValue.error(e);
      }
      notifyListeners();
    }
  }

  String? _findCategoryName(List<CategoryModel> categories, String id) {
    for (var category in categories) {
      if (category.id == id) return category.name;

      if (category.subCategories.isNotEmpty) {
        final subMatch = _findCategoryName(category.subCategories, id);
        if (subMatch != null) return subMatch;
      }
    }
    return null;
  }

  /// Search products (Updates Listing Screen State)
  Future<void> searchProducts(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      if (_filterType == ProductFilterType.all) {
        // Reset to category filter if exists, or all products
        await filterByCategory(_selectedCategoryId);
      } else {
        // Restore the current filter type view
        setFilterType(_filterType);
      }
      return;
    }

    _listingState = const AsyncValue.loading();
    notifyListeners();

    try {
      final allProducts = await _productRepository.searchProducts(query);
      // Filter to show only active products
      final activeProducts = allProducts.where((p) => p.isActive).toList();
      _listingState = AsyncValue.success(activeProducts);
      _filteredProductsState = AsyncValue.success(activeProducts);
      notifyListeners();
    } catch (e) {
      _listingState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Get product by ID
  /// First checks in-memory cache, then falls back to API call
  Future<ProductModel> getProductById(String id) async {
    // First, try to find the product in already loaded products
    try {
      final cachedProduct = allLoadedProducts.firstWhere(
        (product) => product.id == id,
      );
      print('✅ Found product $id in cache');
      return cachedProduct;
    } catch (e) {
      // Product not in cache, fetch from API
      print('⚠️ Product $id not in cache, fetching from API...');
      return await _productRepository.getProductById(id);
    }
  }

  /// Get related products (same category, excluding current product)
  /// Uses already-loaded products for better performance and reliability
  List<ProductModel> getRelatedProducts(String productId, String? categoryName,
      {int limit = 10}) {
    try {
      print(
          '🔍 Getting related products for productId: $productId, categoryName: $categoryName');

      if (categoryName == null || categoryName.isEmpty) {
        print('⚠️ No category name provided, returning empty list');
        return [];
      }

      // Get all loaded products from memory
      final allProducts = allLoadedProducts;
      print('📦 Total loaded products: ${allProducts.length}');

      // Filter products by same category name, excluding current product
      final relatedProducts = allProducts
          .where((p) {
            // Must be active
            if (!p.isActive) return false;

            // Must not be the current product
            if (p.id == productId) return false;

            // Must have matching category name
            if (p.categoryName == null) return false;

            // Check if category names match (case-insensitive)
            // Also handle subcategories (e.g., "Beverage > Japanese SAKE" matches "Beverage")
            final productCategory = p.categoryName!.toLowerCase();
            final targetCategory = categoryName.toLowerCase();

            // Exact match or one contains the other (for subcategories)
            return productCategory == targetCategory ||
                productCategory.contains(targetCategory) ||
                targetCategory.contains(productCategory);
          })
          .take(limit)
          .toList();

      print('✅ Found ${relatedProducts.length} related products');
      return relatedProducts;
    } catch (e) {
      print('❌ Error loading related products: $e');
      return [];
    }
  }

  /// Clear filters
  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    // Restore listing state to match all products
    _productsState.when(
        loading: () => loadProducts(),
        error: (e) => loadProducts(),
        success: (data) {
          _listingState = AsyncValue.success(data);

          if (_filterType == ProductFilterType.all) {
            _filteredProductsState = AsyncValue.success(data);
          }

          notifyListeners();
        });
  }

  /// Toggle product visibility (admin feature)
  Future<void> toggleProductVisibility(String productId) async {
    try {
      // Call repository method (cast to access mock-specific method)
      final mockRepo = _productRepository as dynamic;
      await mockRepo.toggleProductVisibility(productId);

      // Reload products to reflect changes
      await loadProducts();
    } catch (e) {
      // Handle error silently or show notification
      debugPrint('Error toggling product visibility: $e');
    }
  }
}
