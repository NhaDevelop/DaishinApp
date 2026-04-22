import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fuzzy/fuzzy.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/product/product_card.dart';

import '../../../core/routes/route_names.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    // Sync with provider state on init
    final productProvider = context.read<ProductProvider>();
    _searchController =
        TextEditingController(text: productProvider.searchQuery);

    // Add scroll listener for scroll-to-top button
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Show button when scrolled down more than 300 pixels
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          // User requested: Refresh should reset to All Products (clearing category filters)
          productProvider.clearFilters();
          // Also ensure we are in 'All' mode if not already (though clearFilters usually handles data reset)
          productProvider.setFilterType(ProductFilterType.all);
        },
        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Ensure scrolling always works for RefreshIndicator
          controller: _scrollController,
          slivers: [
            // App Bar - Compact Design
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              centerTitle: false,
              title: Row(
                children: [
                  AppBarLogo(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      productProvider.selectedCategoryName ?? 'DAISHIN',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              actions: [
                // Hidden Products - Show in menu instead
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 22),
                  padding: const EdgeInsets.all(8),
                  onSelected: (value) {
                    if (value == 'hidden') {
                      context.push(RouteNames.hiddenProducts);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'hidden',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off_outlined),
                          SizedBox(width: 12),
                          Text('Hidden Products'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8), // Add right padding
              ],
            ),

            // Persistent Search Bar and Filter (Pinned)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchBarDelegate(
                minHeight: 80.0,
                maxHeight: 80.0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Autocomplete<ProductModel>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<ProductModel>.empty();
                                }
                                final query = textEditingValue.text;

                                // Fuzzy Search Implementation
                                final fuse = Fuzzy<ProductModel>(
                                  productProvider.allLoadedProducts,
                                  options: FuzzyOptions(
                                    keys: [
                                      WeightedKey(
                                        name: 'name',
                                        getter: (model) => model.name,
                                        weight: 1,
                                      ),
                                    ],
                                    threshold: 0.3,
                                  ),
                                );

                                final result = fuse.search(query);
                                return result.map((r) => r.item).take(5);
                              },
                              displayStringForOption: (ProductModel option) =>
                                  option.name,
                              fieldViewBuilder: (context, controller, focusNode,
                                  onFieldSubmitted) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search products...',
                                      hintStyle: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.6),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.6),
                                      ),
                                      suffixIcon: controller.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color
                                                    ?.withOpacity(0.6),
                                              ),
                                              onPressed: () {
                                                controller.clear();
                                                productProvider
                                                    .searchProducts('');
                                              },
                                            )
                                          : null,
                                      filled: false,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      productProvider.searchProducts(value);
                                    },
                                  ),
                                );
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: constraints.maxWidth,
                                      constraints:
                                          const BoxConstraints(maxHeight: 300),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final product =
                                              options.elementAt(index);
                                          return ListTile(
                                            leading: SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: product.images.isNotEmpty
                                                    ? (product.images.first
                                                            .startsWith('http')
                                                        ? Image.network(
                                                            product
                                                                .images.first,
                                                            fit: BoxFit.cover)
                                                        : Image.asset(
                                                            product
                                                                .images.first,
                                                            fit: BoxFit.cover))
                                                    : const Icon(Icons.image),
                                              ),
                                            ),
                                            title: Text(product.name,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            onTap: () {
                                              onSelected(product);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              onSelected: (ProductModel selection) {
                                context.push('/products/${selection.id}');
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filter Button
                      Container(
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.filter_list_rounded,
                              color: Theme.of(context).primaryColor),
                          tooltip: 'Filter',
                          onPressed: () {
                            _showCategoryFilterDialog(context, productProvider);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Product Filter (Always visible for quick access)
            SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip(
                        'All',
                        productProvider.filterType == ProductFilterType.all,
                        () {
                          productProvider.clearFilters();
                          productProvider.setFilterType(ProductFilterType.all);
                        },
                      ),
                      _buildFilterChip(
                        'Hot Items',
                        productProvider.filterType == ProductFilterType.hot,
                        () {
                          productProvider.setFilterType(ProductFilterType.hot);
                        },
                      ),
                      _buildFilterChip(
                        'Popular Products',
                        productProvider.filterType ==
                            ProductFilterType.featured,
                        () {
                          productProvider
                              .setFilterType(ProductFilterType.featured);
                        },
                      ),
                      _buildFilterChip(
                        'Business Use',
                        productProvider.filterType ==
                            ProductFilterType.business,
                        () {
                          productProvider
                              .setFilterType(ProductFilterType.business);
                        },
                      ),
                      _buildFilterChip(
                        'Retail Use',
                        productProvider.filterType == ProductFilterType.retails,
                        () {
                          productProvider
                              .setFilterType(ProductFilterType.retails);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Product Grid
            productProvider.filteredProductsState.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('Error: $error',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6))),
                    ],
                  ),
                ),
              ),
              success: (products) {
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 80,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: productProvider.filterType ==
                              ProductFilterType.hot
                          ? 0.55
                          : (productProvider.filterType == ProductFilterType.all
                              ? 0.56
                              : 0.60),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return ProductCard(product: product);
                      },
                      childCount: products.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (Theme.of(context).textTheme.bodyMedium?.color ??
                      Theme.of(context).colorScheme.onSurface),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryFilterDialog(
      BuildContext context, ProductProvider productProvider) {
    final categories = <CategoryModel>[];
    productProvider.categoriesState.when(
      loading: () {},
      error: (_) {},
      success: (data) => categories.addAll(data),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // All Products option
                ListTile(
                  title: const Text(
                    'All Products',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  leading: Radio<String?>(
                    value: null,
                    groupValue: productProvider.selectedCategoryId,
                    onChanged: (value) {
                      productProvider.filterByCategory(null);
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    productProvider.filterByCategory(null);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),

                // Categories with subcategories
                ...categories.expand((category) {
                  final items = <Widget>[];

                  // Add main category
                  items.add(
                    ListTile(
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      leading: Radio<String?>(
                        value: category.id,
                        groupValue: productProvider.selectedCategoryId,
                        onChanged: (value) {
                          productProvider.filterByCategory(category.id);
                          Navigator.pop(context);
                        },
                      ),
                      onTap: () {
                        productProvider.filterByCategory(category.id);
                        Navigator.pop(context);
                      },
                    ),
                  );

                  // Add subcategories with indentation
                  for (final subCategory in category.subCategories) {
                    items.add(
                      ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 32, right: 16),
                        title: Row(
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subCategory.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        leading: Radio<String?>(
                          value: subCategory.id,
                          groupValue: productProvider.selectedCategoryId,
                          onChanged: (value) {
                            productProvider.filterByCategory(subCategory.id);
                            Navigator.pop(context);
                          },
                        ),
                        onTap: () {
                          productProvider.filterByCategory(subCategory.id);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }

                  return items;
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickySearchBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickySearchBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
