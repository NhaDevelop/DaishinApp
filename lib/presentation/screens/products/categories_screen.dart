import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../../data/models/category_model.dart';
import '../../../core/routes/route_names.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final Set<String> _expandedCategories = {};

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppBarLogo(),
            SizedBox(width: 8),
            Text('Categories'),
          ],
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: productProvider.categoriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text('Error: $error',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => productProvider.loadCategories(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        success: (categories) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isExpanded = _expandedCategories.contains(category.id);

            return _buildCategoryCard(
              context,
              category,
              productProvider,
              isExpanded,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryModel category,
    ProductProvider productProvider,
    bool isExpanded,
  ) {
    final hasSubCategories = category.subCategories.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Category
          InkWell(
            onTap: () {
              if (hasSubCategories) {
                setState(() {
                  if (isExpanded) {
                    _expandedCategories.remove(category.id);
                  } else {
                    _expandedCategories.add(category.id);
                  }
                });
              } else {
                // Navigate to products for this category
                productProvider.filterByCategory(category.id);
                context.push(RouteNames.productList);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Circle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category.name).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(category.name),
                      color: _getCategoryColor(category.name),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Category Name and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (hasSubCategories) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${category.subCategories.length} subcategories',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Trailing Icon
                  if (hasSubCategories)
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                    ),
                ],
              ),
            ),
          ),
          // Subcategories
          if (hasSubCategories && isExpanded) ...[
            ...category.subCategories.map((subCategory) {
              return Column(
                children: [
                  const Divider(height: 1),
                  InkWell(
                    onTap: () {
                      productProvider.filterByCategory(subCategory.id);
                      context.push(RouteNames.productList);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 20,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.7),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              subCategory.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.8),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white30
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            // All [Category] Option
            Column(
              children: [
                const Divider(height: 1),
                InkWell(
                  onTap: () {
                    productProvider.filterByCategory(category.id);
                    context.push(RouteNames.productList);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 20,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'All ${category.name}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white30
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    // Use primary color for all categories
    return Theme.of(context).primaryColor;
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase().trim();

    if (name.contains('rice') || name.contains('noodle')) {
      return Icons.rice_bowl_rounded;
    } else if (name.contains('seaweed') || name.contains('pickle')) {
      return Icons.eco_rounded;
    } else if (name.contains('other') && name.contains('food')) {
      return Icons.fastfood_rounded;
    } else if (name.contains('confection') || name.contains('cake')) {
      return Icons.cake_rounded;
    } else if (name.contains('non-food')) {
      return Icons.shopping_basket_rounded;
    } else if (name.contains('meat')) {
      return Icons.set_meal_rounded;
    } else if (name.contains('chill')) {
      return Icons.ac_unit_rounded;
    } else if (name.contains('frozen')) {
      return Icons.ac_unit;
    } else if (name.contains('beverage') ||
        name.contains('drink') ||
        name.contains('alcohol') ||
        name.contains('sake') ||
        name.contains('shochu')) {
      return Icons.local_drink_rounded;
    } else if (name.contains('season')) {
      return Icons.local_dining_rounded;
    } else if (name.contains('pet')) {
      return Icons.pets_rounded;
    } else if (name.contains('bread')) {
      return Icons.bakery_dining_rounded;
    } else if (name.contains('gyomu')) {
      return Icons.business_rounded;
    } else {
      return Icons.category_rounded;
    }
  }
}
