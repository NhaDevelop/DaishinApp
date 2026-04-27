import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fuzzy/fuzzy.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/skeleton_loader.dart';
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
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    textInputAction: TextInputAction.search,
                                    decoration: InputDecoration(
                                      hintText: 'Search products...',
                                      hintStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                          fontSize: 14),
                                      prefixIcon: Icon(Icons.search,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                          size: 22),
                                      suffixIcon: IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.arrow_forward,
                                              color: Colors.white, size: 16),
                                        ),
                                        onPressed: () {
                                          final query = controller.text.trim();
                                          if (query.isNotEmpty) {
                                            productProvider.searchProducts(query);
                                          } else {
                                            productProvider.searchProducts('');
                                          }
                                        },
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
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
              loading: () => const ProductGridSkeleton(itemCount: 6),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            String? selectedId = productProvider.selectedCategoryId;

            void selectAndClose(String? id) {
              Navigator.pop(ctx);
              productProvider.filterByCategory(id);
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Filter by Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.08),
                  ),

                  // Scrollable list
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shrinkWrap: true,
                      children: [
                        // All Products option
                        _buildFilterTile(
                          context: context,
                          label: 'All Products',
                          isSelected: selectedId == null,
                          isBold: true,
                          onTap: () => selectAndClose(null),
                        ),

                        const SizedBox(height: 4),

                        // Categories with subcategories
                        ...categories.expand((category) {
                          final items = <Widget>[];

                          items.add(
                            _buildFilterTile(
                              context: context,
                              label: category.name,
                              isSelected: selectedId == category.id,
                              isBold: true,
                              onTap: () => selectAndClose(category.id),
                            ),
                          );

                          for (final sub in category.subCategories) {
                            items.add(
                              _buildSubFilterTile(
                                context: context,
                                label: sub.name,
                                isSelected: selectedId == sub.id,
                                onTap: () => selectAndClose(sub.id),
                              ),
                            );
                          }

                          items.add(const SizedBox(height: 4));
                          return items;
                        }),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterTile({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required bool isBold,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: primary.withOpacity(0.35), width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                  color: isSelected
                      ? primary
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primary, size: 20)
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubFilterTile({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withOpacity(0.08)
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: primary.withOpacity(0.3), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 15,
              color: isSelected
                  ? primary.withOpacity(0.7)
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.35),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.75),
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primary, size: 18)
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.25),
                size: 18,
              ),
          ],
        ),
      ),
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
