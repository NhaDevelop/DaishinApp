import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:marquee/marquee.dart';

import '../../../data/models/product_model.dart';
import '../../../utils/formatters.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../common/top_snackbar.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final bool showHideButton;

  const ProductCard({
    super.key,
    required this.product,
    this.showHideButton = true,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final int _quantity = 1;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '$_quantity');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CartProvider is accessed via Consumer below
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/products/${widget.product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Tooltip(
          message: widget.product.name,
          waitDuration: const Duration(milliseconds: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section with Badges
              Stack(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        color: isDark ? Colors.grey[900] : Colors.grey[50],
                        child: widget.product.images.isNotEmpty
                            ? (widget.product.images.first.startsWith('http')
                                ? Image.network(
                                    widget.product.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    widget.product.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ))
                            : Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                      ),
                    ),
                  ),

                  // Discount Badge with Icon
                  if (widget.product.discountPercentage != null &&
                      widget.product.discountPercentage! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_offer,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '-${widget.product.discountPercentage!.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Action Buttons (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        // Favorite Button
                        Consumer<FavoritesProvider>(
                          builder: (context, favoritesProvider, _) {
                            final isFavorite =
                                favoritesProvider.isFavorite(widget.product.id);
                            return GestureDetector(
                              onTap: () => favoritesProvider
                                  .toggleFavorite(widget.product),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color: isFavorite
                                      ? const Color(0xFFFF3B30)
                                      : Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                        if (widget.showHideButton) ...[
                          const SizedBox(width: 6),
                          // Hide Button
                          GestureDetector(
                            onTap: () {
                              context
                                  .read<ProductProvider>()
                                  .toggleProductVisibility(widget.product.id);
                              TopSnackBar.show(
                                  context, '${widget.product.name} hidden');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.visibility_off_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Product Type Badge (Bottom of Image)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (widget.product.productType != null &&
                                widget.product.productType!.trim().isNotEmpty &&
                                widget.product.productType!.toLowerCase() !=
                                    'regular')
                            ? Colors.orange
                            : Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatProductType(widget.product.productType),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name (Single Line)
                      SizedBox(
                        height: 20,
                        child: Marquee(
                          text: widget.product.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A1A),
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
                      const SizedBox(height: 6),

                      // Promotion Days Left (if available)
                      if (widget.product.promotionDayLeft != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.product.promotionDayLeft!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Price Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Final Price
                          Text(
                            widget.product.hasDiscount
                                ? Formatters.formatCurrency(
                                    widget.product.finalPrice)
                                : widget.product.displayPrice,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.product.hasDiscount
                                  ? const Color(0xFFF44336)
                                  : (isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Original Price (if discounted)
                          if (widget.product.hasDiscount)
                            Text(
                              Formatters.formatCurrency(widget.product.price),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),

                      const Spacer(),

                      // Add to Cart Button or Quantity Controls
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: Consumer<CartProvider>(
                          builder: (context, cartProvider, _) {
                            // Check if product is in cart
                            final cartItem =
                                cartProvider.items.cast<dynamic>().firstWhere(
                                      (item) =>
                                          item?.product.id == widget.product.id,
                                      orElse: () => null,
                                    );
                            final isInCart = cartItem != null;
                            final currentQuantity =
                                isInCart ? cartItem.quantity as int : 0;

                            return Row(
                              children: [
                                // Add to Cart Icon Button (always visible)
                                Expanded(
                                  flex: isInCart ? 1 : 3,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 36,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          await cartProvider.addToCart(
                                              widget.product, 1);
                                          if (context.mounted) {
                                            TopSnackBar.show(
                                                context, 'Added to cart');
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            TopSnackBar.show(
                                                context, 'Error: $e',
                                                isError: true);
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: isInCart
                                          ? const Icon(
                                              Icons.add_shopping_cart_rounded,
                                              size: 16)
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                    Icons
                                                        .add_shopping_cart_rounded,
                                                    size: 16),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Add',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                // Quantity Controls (show when in cart)
                                if (isInCart) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: isDark
                                            ? null
                                            : Border.all(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                width: 1,
                                              ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Decrease Button
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                if (currentQuantity > 1) {
                                                  await cartProvider
                                                      .updateQuantity(
                                                    widget.product.id,
                                                    currentQuantity - 1,
                                                  );
                                                } else {
                                                  await cartProvider.removeItem(
                                                      widget.product.id);
                                                }
                                              },
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                left: Radius.circular(7),
                                              ),
                                              child: Container(
                                                width: 28,
                                                height: 36,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  currentQuantity > 1
                                                      ? Icons.remove
                                                      : Icons.delete_outline,
                                                  size: 16,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Theme.of(context)
                                                          .primaryColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Quantity Display
                                          Expanded(
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                '$currentQuantity',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Theme.of(context)
                                                          .primaryColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Increase Button
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                await cartProvider
                                                    .updateQuantity(
                                                  widget.product.id,
                                                  currentQuantity + 1,
                                                );
                                              },
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                right: Radius.circular(7),
                                              ),
                                              child: Container(
                                                width: 28,
                                                height: 36,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.add,
                                                  size: 16,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Theme.of(context)
                                                          .primaryColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
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
