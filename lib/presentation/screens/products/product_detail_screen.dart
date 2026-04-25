import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../../utils/formatters.dart';
import '../../../core/routes/route_names.dart';
import '../../widgets/common/top_snackbar.dart';
import 'package:marquee/marquee.dart';
import '../../widgets/product/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0; // For image carousel
  late TextEditingController _quantityController;
  bool _isLoading = true;
  dynamic _product;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '$_quantity');
    _loadProduct();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final productProvider = context.read<ProductProvider>();
      final product = await productProvider.getProductById(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    if (_product == null) return;

    try {
      final cartProvider = context.read<CartProvider>();
      await cartProvider.addToCart(_product, _quantity);

      if (mounted) {
        TopSnackBar.show(context, 'Added $_quantity ${_product.name} to cart');
      }
    } catch (e) {
      if (mounted) {
        TopSnackBar.show(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Product not found'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Standard App Bar
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  leading: IconButton(
                    icon: ClipOval(
                      child: Image.asset(
                        'assets/images/daishin_logo.jpg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    onPressed: () => context.pop(),
                  ),
                  title: const Text(
                    'Product Detail',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    // Favorite Button
                    Consumer<FavoritesProvider>(
                      builder: (context, favProvider, _) {
                        final isFavorite = favProvider.isFavorite(_product.id);
                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                            size: 24,
                          ),
                          onPressed: () => favProvider.toggleFavorite(_product),
                        );
                      },
                    ),
                    // Cart Button
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Consumer<CartProvider>(
                        builder: (context, cartProvider, _) {
                          final itemCount = cartProvider.itemCount;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () => context.go(RouteNames.cart),
                              ),
                              if (itemCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      itemCount > 99 ? '99+' : '$itemCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Image Carousel Section (Moved from AppBar)
                SliverToBoxAdapter(
                  child: Container(
                    height: 380,
                    color: isDark ? Colors.grey[900] : Colors.white,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Product Image Carousel
                        _product.images.isNotEmpty
                            ? PageView.builder(
                                itemCount: _product.images.length,
                                onPageChanged: (index) {
                                  setState(() => _currentImageIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  final imageUrl = _product.images[index];
                                  return imageUrl.startsWith('http')
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 80,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        )
                                      : Image.asset(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 80,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                              ),

                        // Indicators
                        if (_product.images.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _product.images.length,
                                (index) => Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? Theme.of(context).primaryColor
                                        : Colors.white.withOpacity(0.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Gradient Overlay
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black12,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.3],
                            ),
                          ),
                        ),

                        // Discount Badge
                        if (_product.discountPercentage != null &&
                            _product.discountPercentage! > 0)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '-${_product.discountPercentage!.toStringAsFixed(0)}% OFF',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Product Details
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    // Removed transform: overlap not needed with standard app bar
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Type & Category Row
                          Row(
                            children: [
                              // Product Type Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: (_product.productType != null &&
                                          _product.productType!
                                              .trim()
                                              .isNotEmpty &&
                                          _product.productType!.toLowerCase() !=
                                              'regular')
                                      ? Colors.orange
                                      : Colors.blue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _formatProductType(_product.productType),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Category Badge
                              if (_product.categoryName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _product.categoryName!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Product Name

                          SizedBox(
                            height: 32,
                            child: Marquee(
                              text: _product.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                              ),
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              blankSpace: 20.0,
                              velocity: 30.0,
                              pauseAfterRound: const Duration(seconds: 1),
                              startPadding: 0.0,
                              accelerationDuration: const Duration(seconds: 1),
                              accelerationCurve: Curves.linear,
                              decelerationDuration:
                                  const Duration(milliseconds: 500),
                              decelerationCurve: Curves.easeOut,
                              fadingEdgeStartFraction: 0.1,
                              fadingEdgeEndFraction: 0.1,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Promotion Days Left
                          if (_product.promotionDayLeft != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 18,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Promotion ends in ${_product.promotionDayLeft}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Price Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[850] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Price',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            Formatters.formatCurrency(
                                              _product.hasDiscount
                                                  ? _product.finalPrice
                                                  : _product.price,
                                            ),
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: _product.hasDiscount
                                                  ? const Color(0xFFF44336)
                                                  : const Color(0xFFF44336),
                                            ),
                                          ),
                                          if (_product.hasDiscount) ...[
                                            const SizedBox(width: 8),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4),
                                              child: Text(
                                                Formatters.formatCurrency(
                                                    _product.price),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[500],
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  decorationColor:
                                                      Colors.grey[500],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (_product.hasDiscount)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Discount ${_product.discountPercentage?.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Product Description
                          Text(
                            'Product Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _product.description.isNotEmpty
                                ? _product.description
                                : 'No description available for this product.',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[700],
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Related Products
                          Consumer<ProductProvider>(
                            builder: (context, ref, _) {
                              final relatedProducts = ref.allLoadedProducts
                                  .where((p) =>
                                      p.categoryName == _product.categoryName &&
                                      p.id != _product.id)
                                  .take(6)
                                  .toList();

                              if (relatedProducts.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Related Products',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 340,
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      physics: const BouncingScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: relatedProducts.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (context, index) {
                                        return SizedBox(
                                          width: 180,
                                          child: ProductCard(
                                            product: relatedProducts[index],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Quantity Selector
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[850]
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(16)),
                                onTap: _quantity > 1
                                    ? () => setState(() {
                                          _quantity--;
                                          _quantityController.text =
                                              '$_quantity';
                                        })
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Icon(
                                    Icons.remove,
                                    size: 20,
                                    color: _quantity > 1
                                        ? (isDark
                                            ? Colors.white
                                            : Colors.black87)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: TextField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  final newQuantity = int.tryParse(value);
                                  if (newQuantity != null &&
                                      newQuantity > 0 &&
                                      newQuantity <= _product.stock) {
                                    setState(() {
                                      _quantity = newQuantity;
                                    });
                                  }
                                },
                                onSubmitted: (value) {
                                  int? newQuantity = int.tryParse(value);
                                  if (newQuantity == null || newQuantity < 1) {
                                    newQuantity = 1;
                                  } else if (newQuantity > _product.stock) {
                                    newQuantity = _product.stock;
                                  }
                                  setState(() {
                                    _quantity = newQuantity!;
                                    _quantityController.text = '$_quantity';
                                  });
                                },
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(16)),
                                onTap: _quantity < _product.stock
                                    ? () => setState(() {
                                          _quantity++;
                                          _quantityController.text =
                                              '$_quantity';
                                        })
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Icon(
                                    Icons.add,
                                    size: 20,
                                    color: _quantity < _product.stock
                                        ? (isDark
                                            ? Colors.white
                                            : Colors.black87)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Add to Cart Button
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _product.stock > 0 ? _addToCart : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            child: _product.stock > 0
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Add to Cart',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          Formatters.formatCurrency(
                                              (_product.hasDiscount
                                                      ? _product.finalPrice
                                                      : _product.price) *
                                                  _quantity),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, _) {
                      if (cartProvider.itemCount > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => context.go(RouteNames.cart),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'View Cart (${cartProvider.itemCount} items)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatProductType(String? productType) {
    if (productType == null || productType.trim().isEmpty) {
      return 'REGULAR';
    }

    // Convert to lowercase for comparison
    final type = productType.toLowerCase();

    // Handle specific cases
    if (type == 'pre_order' || type == 'preorder') {
      return 'PRE-ORDER';
    } else if (type == 'regular') {
      return 'REGULAR';
    } else if (type == 'business_use' || type == 'business') {
      return 'BUSINESS';
    }

    // For other types, replace underscores with hyphens and convert to uppercase
    return productType.replaceAll('_', '-').toUpperCase();
  }
}
