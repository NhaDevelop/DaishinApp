import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:marquee/marquee.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../../utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../widgets/common/top_snackbar.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Ensure all products are loaded so we can find the favorites
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().super_loadProducts();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final allFavorites = favoritesProvider.favoriteProducts;

    // Fuzzy Search Implementation
    List<ProductModel> displayProducts;

    if (_searchQuery.isEmpty) {
      displayProducts = allFavorites;
    } else {
      // Setup Fuzzy Search
      final fuse = Fuzzy<ProductModel>(
        allFavorites,
        options: FuzzyOptions(
          keys: [
            WeightedKey(
              name: 'name',
              getter: (model) => model.name,
              weight: 1,
            ),
            WeightedKey(
              // Optional: Search description/category too if desired
              name: 'categoryName',
              getter: (model) => model.categoryName ?? '',
              weight: 0.5,
            ),
          ],
          threshold:
              0.4, // Sensitivity: lower = stricter, higher = more tolerant (0.0 - 1.0)
        ),
      );

      final result = fuse.search(_searchQuery);
      displayProducts = result.map((r) => r.item).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppBarLogo(),
            SizedBox(width: 8),
            Text('Favorites'),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Grid View Toggle
          PopupMenuButton<int>(
            icon: const Icon(Icons.grid_view),
            tooltip: 'Change Grid View',
            onSelected: (value) => favoritesProvider.setGridColumns(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.grid_view, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('2 Columns'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.grid_on, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('3 Columns'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 4,
                child: Row(
                  children: [
                    Icon(Icons.apps, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('4 Columns'),
                  ],
                ),
              ),
            ],
          ),
          // Notification Bell
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          // Profile Icon
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search favorites...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await favoritesProvider.refreshFavorites();
                  if (context.mounted) {
                    context.read<ProductProvider>().super_loadProducts();
                  }
                },
                child: favoritesProvider.isLoading &&
                        favoritesProvider.favoriteProducts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : displayProducts.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.favorite_border,
                                    size: 80,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No favorites yet'
                                        : 'No matches found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_searchQuery.isEmpty)
                                    Text(
                                      'Pull to refresh',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).disabledColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: favoritesProvider.gridColumns,
                              // CONTROL GRID HEIGHT HERE: Smaller number = Taller card
                              childAspectRatio: favoritesProvider.gridColumns ==
                                      2
                                  ? 0.75 // 2 Columns
                                  : (favoritesProvider.gridColumns == 4
                                      ? 0.52 // 4 Columns
                                      : 0.62), // 3 Columns (Default) - was 0.65
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: displayProducts.length,
                            itemBuilder: (context, index) {
                              return FavoriteProductCard(
                                  product: displayProducts[index]);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stateful Product Card with Quantity Controls
class FavoriteProductCard extends StatefulWidget {
  final ProductModel product;

  const FavoriteProductCard({super.key, required this.product});

  @override
  State<FavoriteProductCard> createState() => _FavoriteProductCardState();
}

class _FavoriteProductCardState extends State<FavoriteProductCard> {
  void _showQuantityDialog(BuildContext context) {
    int dialogQuantity = 1;
    final controller = TextEditingController(text: '$dialogQuantity');
    final cartProvider = context.read<CartProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Select Quantity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.product.name,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: dialogQuantity > 1
                          ? () {
                              setState(() {
                                dialogQuantity--;
                                controller.text = '$dialogQuantity';
                              });
                            }
                          : null,
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18),
                        decoration:
                            const InputDecoration(border: InputBorder.none),
                        onChanged: (val) {
                          final v = int.tryParse(val);
                          if (v != null && v > 0) {
                            dialogQuantity = v;
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          dialogQuantity++;
                          controller.text = '$dialogQuantity';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                try {
                  await cartProvider.addToCart(widget.product, dialogQuantity);
                  // Use the PARENT context (from _showQuantityDialog) which is still mounted
                  if (context.mounted) {
                    TopSnackBar.show(context,
                        '${widget.product.name} ($dialogQuantity) added to cart');
                  }
                } catch (e) {
                  if (context.mounted) {
                    TopSnackBar.show(context, 'Error: $e', isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.read<FavoritesProvider>();

    return GestureDetector(
      onTap: () => context.push('/products/${widget.product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12), // Slightly smaller radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12, // Reduced blur
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio:
                        1.25, // Made image container shorter (was 1.25)
                    child: Container(
                      color: Colors.grey[100],
                      child: widget.product.images.isNotEmpty
                          ? (widget.product.images.first.startsWith('http')
                              ? Image.network(
                                  widget.product.images.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.image_not_supported,
                                          size: 32, color: Colors.grey[400]),
                                )
                              : Image.asset(
                                  widget.product.images.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.image_not_supported,
                                          size: 32, color: Colors.grey[400]),
                                ))
                          : Icon(Icons.image_not_supported,
                              size: 32, color: Colors.grey[400]),
                    ),
                  ),
                ),
                // Delete button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () =>
                        favoritesProvider.toggleFavorite(widget.product),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6), // Even smaller padding
                child: Tooltip(
                  message: widget.product.name,
                  waitDuration: const Duration(milliseconds: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Name
                      SizedBox(
                        height: 20,
                        child: Marquee(
                          text: widget.product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          scrollAxis: Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          blankSpace: 20.0,
                          velocity: 30.0,
                          pauseAfterRound: const Duration(seconds: 1),
                          startPadding: 0.0, // Start immediately
                          accelerationDuration: const Duration(seconds: 1),
                          accelerationCurve: Curves.linear,
                          decelerationDuration:
                              const Duration(milliseconds: 500),
                          decelerationCurve: Curves.easeOut,
                          fadingEdgeStartFraction: 0.1,
                          fadingEdgeEndFraction: 0.1,
                        ),
                      ),
                      // const SizedBox(height: 2),
                      // Price with discount support
                      if (widget.product.hasDiscount)
                        Text(
                          Formatters.formatCurrency(widget.product.price),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        widget.product.hasDiscount
                            ? Formatters.formatCurrency(
                                widget.product.finalPrice)
                            : widget.product.displayPrice,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.red
                              : (widget.product.hasDiscount
                                  ? Colors.red
                                  : Theme.of(context).primaryColor),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Quantity Controls
                      // Add to Cart Button (Opens Dialog)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showQuantityDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Add to Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
