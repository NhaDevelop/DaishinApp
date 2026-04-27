import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER CORE — no external package needed
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps any child with a shimmering highlight sweep animation.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
            final highlight = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF5F5F5);

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON PRIMITIVES
// ─────────────────────────────────────────────────────────────────────────────

/// A plain rectangular skeleton block.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A circle skeleton (for avatars/icons).
class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT CARD SKELETON  (mirrors ProductCard exactly)
// ─────────────────────────────────────────────────────────────────────────────

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder (square)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: SkeletonBox(
                width: double.infinity,
                height: double.infinity,
                radius: 0,
              ),
            ),
          ),
          // Details area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  SkeletonBox(width: double.infinity, height: 14, radius: 6),
                  const SizedBox(height: 8),
                  // Price row
                  Row(
                    children: [
                      SkeletonBox(width: 60, height: 13, radius: 6),
                      const SizedBox(width: 8),
                      SkeletonBox(width: 40, height: 11, radius: 6),
                    ],
                  ),
                  const Spacer(),
                  // Add-to-cart button
                  SkeletonBox(
                    width: double.infinity,
                    height: 36,
                    radius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT GRID SKELETON  (2-column, N rows)
// ─────────────────────────────────────────────────────────────────────────────

class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  const ProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.56,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => const Shimmer(child: ProductCardSkeleton()),
          childCount: itemCount,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY CHIP SKELETON  (horizontal scroll row)
// ─────────────────────────────────────────────────────────────────────────────

class CategoryChipSkeleton extends StatelessWidget {
  const CategoryChipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(5, (i) {
            final widths = [60.0, 90.0, 110.0, 80.0, 70.0];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SkeletonBox(width: widths[i], height: 36, radius: 20),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME CATEGORY ROW SKELETON  (icon + label circles)
// ─────────────────────────────────────────────────────────────────────────────

class HomeCategoryRowSkeleton extends StatelessWidget {
  const HomeCategoryRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(6, (_) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SkeletonCircle(size: 56),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 52, height: 11, radius: 5),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME QUICK FILTER ROW SKELETON  (4 square icon boxes)
// ─────────────────────────────────────────────────────────────────────────────

class HomeQuickFilterSkeleton extends StatelessWidget {
  const HomeQuickFilterSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(4, (_) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    SkeletonBox(width: double.infinity, height: 60, radius: 16),
                    const SizedBox(height: 6),
                    SkeletonBox(width: 48, height: 11, radius: 5),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME PRODUCT GRID SKELETON  (compact, used inside a SliverToBoxAdapter)
// ─────────────────────────────────────────────────────────────────────────────

class HomeProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  const HomeProductGridSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.56,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: itemCount,
          itemBuilder: (_, __) => const ProductCardSkeleton(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BANNER SKELETON  (full-width promotional banner strip)
// ─────────────────────────────────────────────────────────────────────────────

class BannerSkeleton extends StatelessWidget {
  const BannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SkeletonBox(
          width: double.infinity,
          height: 110,
          radius: 16,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CART ITEM SKELETON  (matches _buildModernCartItem layout)
// ─────────────────────────────────────────────────────────────────────────────

class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SkeletonBox(width: 90, height: 90, radius: 16),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SkeletonBox(
                          width: double.infinity, height: 15, radius: 6),
                    ),
                    const SizedBox(width: 12),
                    const SkeletonCircle(size: 24),
                  ],
                ),
                const SizedBox(height: 8),
                SkeletonBox(width: 80, height: 12, radius: 5),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 70, height: 16, radius: 6),
                    SkeletonBox(width: 100, height: 36, radius: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full cart loading skeleton — wraps several CartItemSkeletons in a Shimmer.
class CartLoadingSkeleton extends StatelessWidget {
  final int itemCount;
  const CartLoadingSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const Shimmer(child: CartItemSkeleton()),
          childCount: itemCount,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER SKELETON  (title + "See All" button)
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeaderSkeleton extends StatelessWidget {
  const SectionHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonBox(width: 100, height: 18, radius: 6),
            SkeletonBox(width: 56, height: 14, radius: 6),
          ],
        ),
      ),
    );
  }
}
