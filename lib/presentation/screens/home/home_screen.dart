import 'package:daishin_order_app/data/models/product_model.dart';
import 'package:daishin_order_app/data/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fuzzy/fuzzy.dart';
import '../../providers/cart_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product/product_card.dart';

import '../../../core/routes/route_names.dart';
import '../../../utils/formatters.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/top_snackbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    // _searchController.dispose(); // Owned by Autocomplete now
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    await context.read<ProductProvider>().loadProducts();
    await context.read<ProductProvider>().loadCategories();
  }

  Future<void> _addToCart(BuildContext context, product) async {
    try {
      await context.read<CartProvider>().addToCart(product, 1);
      if (mounted) {
        TopSnackBar.show(context, '${product.name} added to cart');
      }
    } catch (e) {
      if (mounted) {
        TopSnackBar.show(context, 'Error: $e', isError: true);
      }
    }
  }

  void _showCategoryFilterBottomSheet(
    BuildContext context,
    List categories,
    ProductProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.filter_list_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filter by Category',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Select a category to filter products',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Categories List
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 +
                          MediaQuery.of(context)
                              .padding
                              .bottom, // Add bottom safe areaF
                    ),
                    children: [
                      // All Products Card
                      _buildFilterCategoryCard(
                        context,
                        'All Products',
                        Icons.grid_view_rounded,
                        null,
                        provider,
                        [],
                      ),

                      const SizedBox(height: 12),

                      // Category Cards
                      ...categories.map((category) {
                        return _buildFilterCategoryCard(
                          context,
                          category.name,
                          _getCategoryIcon(category.name),
                          category.id,
                          provider,
                          category.subCategories,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSubCategoryBottomSheet(
    BuildContext context,
    CategoryModel category,
    ProductProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content height
            children: [
              // Content
              Flexible(
                child: ListView(
                  shrinkWrap: true, // Wraps content height
                  padding: EdgeInsets.zero,
                  children: [
                    // Category Header (Beverage)
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.1), // Low opacity red background
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getCategoryIcon(category.name),
                            color: Theme.of(context).primaryColor, size: 28),
                      ),
                      title: Text(category.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                            '${category.subCategories.length} subcategories',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 13)),
                      ),
                      trailing: const Icon(Icons.keyboard_arrow_up,
                          color: Colors.grey),
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

                    // Subcategories List
                    ...category.subCategories.map((sub) {
                      return Column(
                        children: [
                          _buildStyledSubCategoryItem(context, sub.name, sub.id,
                              provider, Icons.sell_outlined),
                          Divider(
                              height: 1,
                              indent: 64, // Indent to align with text
                              color: Colors.grey.withOpacity(0.1)),
                        ],
                      );
                    }),

                    // All Beverage Option (Last)
                    _buildStyledSubCategoryItem(context, 'All ${category.name}',
                        category.id, provider, Icons.grid_view_rounded,
                        isBold: true),
                    const SizedBox(
                        height: 20 + 10), // Bottom padding + Safe area
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyledSubCategoryItem(BuildContext context, String name,
      String id, ProductProvider provider, IconData icon,
      {bool isBold = false}) {
    return ListTile(
      onTap: () {
        provider.filterByCategory(id);
        Navigator.pop(context);
        context.go('${RouteNames.home}/browse');
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, size: 22, color: Colors.grey[500]),
      title: Text(name,
          style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface)),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600]),
    );
  }

  Widget _buildFilterCategoryCard(
    BuildContext context,
    String name,
    IconData icon,
    String? categoryId,
    ProductProvider provider,
    List subCategories,
  ) {
    final isSelected = provider.selectedCategoryId == categoryId;
    final hasSubCategories = subCategories.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color:
                    isSelected ? Colors.white : Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            subtitle: hasSubCategories
                ? Text(
                    '${subCategories.length} subcategories',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                if (hasSubCategories && !isSelected)
                  const Icon(Icons.expand_more, size: 20),
              ],
            ),
            onTap: () {
              provider.filterByCategory(categoryId);
              Navigator.pop(context);
              // Navigate to product list screen
              context.go('${RouteNames.home}/browse');
            },
          ),

          // Subcategories
          if (hasSubCategories)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subCategories.map((subCategory) {
                      final isSubSelected =
                          provider.selectedCategoryId == subCategory.id;
                      return InkWell(
                        onTap: () {
                          provider.filterByCategory(subCategory.id);
                          Navigator.pop(context);
                          // Navigate to product list screen
                          context.go('${RouteNames.home}/browse');
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSubSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: isSubSelected
                                ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSubSelected)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.check,
                                      size: 16, color: Colors.white),
                                ),
                              Text(
                                subCategory.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSubSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSubSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    // final cartProvider = context.watch<CartProvider>(); // Unused after removing AppBar cart icon

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _refreshProducts,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Modern App Bar with DAISHIN Theme
              SliverAppBar(
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 0,
                title: const Row(
                  children: [
                    // DAISHIN Logo
                    AppBarLogo(),
                    SizedBox(width: 12),
                    Text(
                      'DAISHIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Notification Bell
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: Colors.white),
                        // Optional: Add notification badge
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    tooltip: 'Notifications',
                    onPressed: () {
                      // TODO: Navigate to notifications screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Notifications coming soon!')),
                      );
                    },
                  ),
                  // Profile Icon
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                    tooltip: 'Profile',
                    onPressed: () => context.push(RouteNames.profile),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

// Search Bar with Autocomplete
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchBarDelegate(
                  minHeight: 80.0,
                  maxHeight: 80.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Consumer<ProductProvider>(
                      builder: (context, productProvider, child) {
                        // Use all available loaded products for search suggestions
                        return _buildSearchField(
                            context, productProvider.allLoadedProducts);
                      },
                    ),
                  ),
                ),
              ),

              // Categories Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Menu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // const SizedBox(width: 8),
                              // Consumer<ProductProvider>(
                              //   builder: (context, provider, _) {
                              //     return provider.categoriesState.when(
                              //       loading: () => const SizedBox(),
                              //       error: (_) => const SizedBox(),
                              //       success: (categories) {
                              //         return IconButton(
                              //           tooltip: 'Filter Category',
                              //           padding: EdgeInsets.zero,
                              //           icon: Icon(
                              //             Icons.filter_list_rounded,
                              //             size: 20,
                              //             color: Theme.of(context)
                              //                         .colorScheme
                              //                         .brightness ==
                              //                     Brightness.dark
                              //                 ? Colors.white
                              //                 : Theme.of(context).primaryColor,
                              //           ),
                              //           onPressed: () {
                              //             _showCategoryFilterBottomSheet(
                              //                 context, categories, provider);
                              //           },
                              //         );
                              //       },
                              //     );
                              //   },
                              // ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // Switch to Products tab
                              context.go('${RouteNames.home}/browse');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'See All',
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Theme.of(context).primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildCategoryItem(
                              context,
                              'Hot Item',
                              Icons.local_fire_department_rounded,
                              () {
                                context
                                    .read<ProductProvider>()
                                    .setFilterType(ProductFilterType.hot);
                                context.go('${RouteNames.home}/browse');
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildCategoryItem(
                              context,
                              'Retails',
                              Icons.store_rounded,
                              () {
                                context
                                    .read<ProductProvider>()
                                    .setFilterType(ProductFilterType.retails);
                                context.go('${RouteNames.home}/browse');
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildCategoryItem(
                              context,
                              'Business Use',
                              Icons.business_center_rounded,
                              () {
                                context
                                    .read<ProductProvider>()
                                    .setFilterType(ProductFilterType.business);
                                context.go('${RouteNames.home}/browse');
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildCategoryItem(
                              context,
                              'Popular',
                              Icons.trending_up_rounded,
                              () {
                                context
                                    .read<ProductProvider>()
                                    .setFilterType(ProductFilterType.featured);
                                context.go('${RouteNames.home}/browse');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Categories Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('${RouteNames.home}/categories');
                            },
                            child: Text(
                              'See All',
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context).primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: Consumer<ProductProvider>(
                        builder: (context, provider, _) {
                          return provider.categoriesState.when(
                            loading: () => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            error: (_) => const SizedBox(),
                            success: (categories) {
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  return _buildCategoryItem(
                                    context,
                                    category.name,
                                    _getCategoryIcon(category.name),
                                    () {
                                      if (category.subCategories.isEmpty) {
                                        // No subcategories, filter directly
                                        provider.filterByCategory(category.id);
                                        context.go('${RouteNames.home}/browse');
                                      } else {
                                        // Show sheet with subcategories
                                        _showSubCategoryBottomSheet(
                                            context, category, provider);
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Flash Sale Banner (Optional)
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to products screen with hot items filter
                    context.go('${RouteNames.home}/browse');
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Special Offer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Shop Now',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Products Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Consumer<ProductProvider>(
                      builder: (context, provider, _) {
                    // Determine Icon and Title based on filter type
                    IconData headerIcon;
                    String headerTitle;

                    switch (provider.filterType) {
                      case ProductFilterType.hot:
                        headerIcon = Icons.local_fire_department;
                        headerTitle = 'Hot Products';
                        break;
                      case ProductFilterType.featured:
                        headerIcon = Icons.star_rounded;
                        headerTitle = 'Popular Products';
                        break;
                      case ProductFilterType.business:
                        headerIcon = Icons.business_center_rounded;
                        headerTitle = 'Business Use';
                        break;
                      case ProductFilterType.retails:
                        headerIcon = Icons.store_rounded;
                        headerTitle = 'Retail Use';
                        break;
                      case ProductFilterType.all:
                        headerIcon = Icons.grid_view_rounded;
                        headerTitle = 'All Products';
                        break;
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              headerIcon,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              headerTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Dropdown Filter
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ProductFilterType>(
                              value: provider.filterType,
                              isDense: true,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context).primaryColor,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: ProductFilterType.hot,
                                  child: Text(
                                    'Hot Items',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ProductFilterType.featured,
                                  child: Text(
                                    'Popular Products',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ProductFilterType.business,
                                  child: Text(
                                    'Business Use',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ProductFilterType.retails,
                                  child: Text(
                                    'Retail Use',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ProductFilterType.all,
                                  child: Text(
                                    'All Products',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (ProductFilterType? newValue) async {
                                if (newValue != null) {
                                  provider.setFilterType(newValue);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),

              // Products Grid
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  return productProvider.filteredProductsState.when(
                    loading: () => const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    error: (error) =>
                        const SliverToBoxAdapter(child: SizedBox()),
                    success: (products) {
                      // Show all products
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: productProvider.filterType ==
                                    ProductFilterType.hot
                                ? 0.55 // Taller for Hot Items (Badges + Timer)
                                : (productProvider.filterType ==
                                        ProductFilterType.all
                                    ? 0.56 // Slightly taller for All (mixed content)
                                    : 0.60), // Compact for other filters
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
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String name,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          // Removed fixed width: 80
          // Use constraints or let parent decide
          constraints: const BoxConstraints(minWidth: 70),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.brightness ==
                          Brightness.dark
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.brightness ==
                          Brightness.dark
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'rice and noodle':
        return Icons.rice_bowl_rounded;
      case 'seaweed and pickles':
        return Icons.eco_rounded;
      case 'other food':
        return Icons.fastfood_rounded;
      case 'confectionary':
        return Icons.cake_rounded;
      case 'non-food':
        return Icons.shopping_basket_rounded;
      case 'meat':
        return Icons.set_meal_rounded;
      case 'chilled':
        return Icons.ac_unit_rounded;
      case 'frozen':
        return Icons.ac_unit;
      case 'beverage':
        return Icons.local_drink_rounded;
      case 'seasoning':
        return Icons.local_dining_rounded;
      case 'pet food':
        return Icons.pets_rounded;
      case 'bread':
        return Icons.bakery_dining_rounded;
      case 'gyomu':
        return Icons.business_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Widget _buildSearchField(
      BuildContext context, List<ProductModel> allProducts) {
    return Autocomplete<ProductModel>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<ProductModel>.empty();
        }

        final query = textEditingValue.text;

        // Fuzzy Search Implementation
        final fuse = Fuzzy<ProductModel>(
          allProducts,
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
      displayStringForOption: (ProductModel option) => option.name,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Sync with our controller
        _searchController = controller;
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
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14),
              prefixIcon: Icon(Icons.search,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                    controller.clear(); // Clear input
                    context.read<ProductProvider>().searchProducts(query);
                    // Switch to ProductListScreen tab (index 2)
                    context.read<ProductProvider>().searchProducts(query);
                    context.read<NavigationProvider>().setIndex(2);
                  }
                },
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (query) {
              if (query.isNotEmpty) {
                controller.clear(); // Clear input
                context.read<ProductProvider>().searchProducts(query);
                // Switch to ProductListScreen tab (index 2)
                context.read<NavigationProvider>().setIndex(2);
              }
            },
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                shrinkWrap: true,
                itemCount: options.length + 1, // +1 for "See all" option
                itemBuilder: (context, index) {
                  if (index == options.length) {
                    // "See all results" option
                    return InkWell(
                      onTap: () {
                        final query = _searchController.text.trim();
                        if (query.isNotEmpty) {
                          _searchController.clear(); // Clear input
                          context.read<ProductProvider>().searchProducts(query);
                          // Switch to ProductListScreen tab (index 2)
                          context.read<NavigationProvider>().setIndex(2);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: Theme.of(context).dividerColor),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search,
                                size: 18,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'See all results',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final product = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(product);
                      _searchController.clear(); // Clear input
                      context.push('/products/${product.id}');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      child: Row(
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 50,
                              height: 50,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: product.images.isNotEmpty
                                  ? (product.images.first.startsWith('http')
                                      ? Image.network(
                                          product.images.first,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.image,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5),
                                          ),
                                        )
                                      : Image.asset(
                                          product.images.first,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.image,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5),
                                          ),
                                        ))
                                  : Icon(Icons.image,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Product Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.formatCurrency(product.price),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (ProductModel selection) {
        // Navigation is handled in the onTap of the list item.
        // Doing it here would cause double navigation because onTap calls this AND we have a manual onTap handler.
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
