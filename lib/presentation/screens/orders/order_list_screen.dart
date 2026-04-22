import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/order/order_receipt_dialog.dart';
import '../../../utils/formatters.dart';
import '../../../core/routes/route_names.dart';

enum OrderSortOption {
  newestFirst,
  oldestFirst,
  deliveryDateAsc,
  deliveryDateDesc,
  priceHighToLow,
  priceLowToHigh,
  deliveryStatus
}

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sub-filter states
  int _deliveryFilterIndex = 0; // 0: Pending, 1: Completed
  int _paymentFilterIndex = 0; // 0: Due/Pending, 1: Paid

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load orders when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderModel> _sortOrdersByTab(
      List<OrderModel> orders, bool isDeliveryTab) {
    if (orders.isEmpty) return [];
    List<OrderModel> sortedList = List.from(orders);

    // Apply basic sort first (Newest first as base)
    sortedList.sort((a, b) {
      final idA = int.tryParse(a.id);
      final idB = int.tryParse(b.id);
      if (idA != null && idB != null) {
        return idB.compareTo(idA);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    // Note: Main sorting logic is handled by filters now, but we keep this for fallback
    return sortedList;
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders, bool isDeliveryTab) {
    if (isDeliveryTab) {
      if (_deliveryFilterIndex == 0) {
        // Delivery: Pending (Active)
        return orders.where((order) {
          String status = order.status.toLowerCase();
          return [
            'pending',
            'preparing',
            'processing',
            'delivering',
            'delivery',
            'shipping',
            'in_transit',
            'out_for_delivery'
          ].contains(status);
        }).toList();
      } else {
        // Delivery: Completed
        return orders.where((order) {
          String status = order.status.toLowerCase();
          return ['completed', 'delivered', 'cancelled'].contains(status);
        }).toList();
      }
    } else {
      if (_paymentFilterIndex == 0) {
        // Payment: Due/Pending
        return orders.where((order) {
          String status = order.paymentStatus.toLowerCase();
          return ['pending', 'unpaid', 'due', 'credit', 'failed']
              .contains(status);
        }).toList();
      } else {
        // Payment: Paid
        return orders.where((order) {
          String status = order.paymentStatus.toLowerCase();
          return ['paid', 'completed'].contains(status);
        }).toList();
      }
    }
  }

  Widget _buildFilterTabs(bool isDeliveryTab) {
    final filters =
        isDeliveryTab ? ['Pending', 'Completed'] : ['Due / Pending', 'Paid'];
    final selectedIndex =
        isDeliveryTab ? _deliveryFilterIndex : _paymentFilterIndex;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isDeliveryTab) {
                    _deliveryFilterIndex = index;
                  } else {
                    _paymentFilterIndex = index;
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index],
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            AppBarLogo(),
            SizedBox(width: 8),
            Text('My Orders'),
          ],
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Delivery'),
            Tab(text: 'Payment'),
          ],
        ),
        actions: [
          // Notification Bell
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
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
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          // Profile Icon
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push(RouteNames.profile),
          ),
        ],
      ),
      body: orderProvider.ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
        success: (orders) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Delivery Tab - Sort by Delivery Status Priority
              _buildOrderList(
                context,
                orders, // Pass all orders, will sort inside
                'No orders found',
                'Start shopping to create orders',
                isDeliveryTab: true,
              ),
              // Payment Tab - Sort by Payment Status Priority
              _buildOrderList(
                context,
                orders, // Pass all orders, will sort inside
                'No orders found',
                'Start shopping to create orders',
                isDeliveryTab: false,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(
    BuildContext context,
    List<OrderModel> orders,
    String emptyTitle,
    String emptyMessage, {
    required bool isDeliveryTab,
  }) {
    // 1. Filter orders based on sub-tabs
    final filteredOrders = _filterOrders(orders, isDeliveryTab);

    // 2. Sort filtered orders
    final sortedOrders = _sortOrdersByTab(filteredOrders, isDeliveryTab);

    return Column(
      children: [
        // Sub-filter Tabs
        _buildFilterTabs(isDeliveryTab),

        // List Content
        Expanded(
          child: sortedOrders.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => context.read<OrderProvider>().loadOrders(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  emptyTitle,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  emptyMessage,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: () => context.go(RouteNames.home),
                                  icon: const Icon(Icons.shopping_bag),
                                  label: const Text('Browse Products'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await context.read<OrderProvider>().loadOrders();
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedOrders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final order = sortedOrders[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context
                                .push('${RouteNames.orders}/${order.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header with Order ID and Share Button
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8), // Reduced vertical padding
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor, // Use app's primary red color
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Centered Title
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Order #${order.id}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Share Button
                                      IconButton(
                                        constraints:
                                            const BoxConstraints(), // Remove minimum size constraints
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.share,
                                            color: Colors.white70, size: 22),
                                        tooltip: 'Share Order',
                                        onPressed: () => _shareOrder(order),
                                      ),
                                    ],
                                  ),
                                ),

                                // Order Tracking Timeline - Only show in Delivery Tab
                                if (isDeliveryTab)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 0),
                                    child: _buildCompactTimeline(order.status),
                                  ),

                                // Order Details
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      // ... (Existing Reference/Customer/Date rows are fine, keeping them common) ...
                                      // Reference Number (if available)
                                      if (order.referenceNo != null) ...[
                                        _buildOrderRow(
                                          'Reference No',
                                          order.referenceNo!,
                                          Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color ??
                                              Colors.black87,
                                          isBold: true,
                                        ),
                                        const Divider(height: 24),
                                      ],

                                      // Customer Name (if available)
                                      if (order.customerName != null) ...[
                                        _buildOrderRow(
                                          'Customer',
                                          order.customerName!,
                                          Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color ??
                                              Colors.black87,
                                          isBold: true,
                                        ),
                                        const Divider(height: 24),
                                      ],

                                      // Order Date
                                      _buildOrderRow(
                                        'Order Date',
                                        Formatters.formatDateTime(
                                            order.createdAt),
                                        Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color ??
                                            Colors.black87,
                                      ),
                                      const Divider(height: 24),

                                      // Dynamic Status Ordering based on Tab
                                      if (isDeliveryTab) ...[
                                        // Delivery Tab: Sale Status First
                                        _buildOrderRow(
                                          'Delivery Date',
                                          Formatters.formatDate(
                                              order.estimatedDeliveryDate),
                                          Theme.of(context).primaryColor,
                                          isBold: true,
                                        ),
                                        const Divider(height: 24),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Sale Status',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color ??
                                                    Colors.black87,
                                              ),
                                            ),
                                            _buildStatusChip(order.status,
                                                isDelivery: true),
                                          ],
                                        ),
                                        const Divider(height: 24),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Payment Status',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color ??
                                                    Colors.black87,
                                              ),
                                            ),
                                            _buildStatusChip(
                                                order.paymentStatus,
                                                isPayment: true),
                                          ],
                                        ),
                                        const Divider(height: 24),
                                      ] else ...[
                                        // Payment Tab: Payment Status First
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Payment Status',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color ??
                                                    Colors.black87,
                                              ),
                                            ),
                                            _buildStatusChip(
                                                order.paymentStatus,
                                                isPayment: true),
                                          ],
                                        ),
                                        const Divider(height: 24),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Sale Status',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color ??
                                                    Colors.black87,
                                              ),
                                            ),
                                            _buildStatusChip(order.status,
                                                isDelivery: true),
                                          ],
                                        ),
                                        const Divider(height: 24),

                                        _buildOrderRow(
                                          'Delivery Date',
                                          Formatters.formatDate(
                                              order.estimatedDeliveryDate),
                                          Theme.of(context).disabledColor,
                                          isBold: false,
                                        ),
                                        const Divider(height: 24),
                                      ],

                                      // Total Items (from API)
                                      _buildOrderRow(
                                        'Total Items',
                                        '${order.totalItems ?? order.items.length} quantity',
                                        Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color ??
                                            Colors.black87,
                                      ),
                                      const Divider(height: 24),

                                      // Total
                                      _buildOrderRow(
                                        'Total Amount',
                                        Formatters.formatCurrency(order.total),
                                        Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color ??
                                            Colors.black87,
                                        isBold: true,
                                      ),

                                      // Repeat Order Button
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _repeatOrder(order),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(Icons.refresh,
                                              size: 20),
                                          label: const Text(
                                            'Repeat Order',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderRow(String label, String value, Color valueColor,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color:
                Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status,
      {bool isDelivery = false, bool isPayment = false}) {
    Color color = Colors.grey.withOpacity(0.15);
    Color textColor = Colors.black87;
    String label = status;

    // Helper to format string (first char uppercase)
    label = status
        .replaceAll('_', ' ')
        .split(' ')
        .map((str) =>
            str.isEmpty ? '' : '${str[0].toUpperCase()}${str.substring(1)}')
        .join(' ');

    if (isDelivery) {
      switch (status.toLowerCase()) {
        case 'pending':
          color = Colors.orange.withOpacity(0.15);
          textColor = Colors.orange[800]!;
          break;
        case 'preparing':
        case 'processing':
          color = Colors.purple.withOpacity(0.15);
          textColor = Colors.purple[800]!;
          break;
        case 'delivery':
        case 'in_transit':
        case 'shipping':
        case 'out_for_delivery':
          color = Colors.blue.withOpacity(0.15);
          textColor = Colors.blue[800]!;
          break;
        case 'completed':
        case 'delivered':
          color = Colors.green.withOpacity(0.15);
          textColor = Colors.green[800]!;
          break;
      }
    } else if (isPayment) {
      switch (status.toLowerCase()) {
        case 'pending':
        case 'unpaid':
          color = Colors.red.withOpacity(0.15);
          textColor = Colors.red[800]!;
          break;
        case 'paid':
          color = Colors.green.withOpacity(0.15);
          textColor = Colors.green[800]!;
          break;
        case 'failed':
          color = Colors.red.withOpacity(0.2);
          textColor = Colors.red[900]!;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCompactTimeline(String deliveryStatus) {
    // Determine current step based on sale status
    int currentStep = 0;
    String status = deliveryStatus.toLowerCase();

    if (status == 'pending') {
      currentStep = 0;
    } else if (['preparing', 'processing'].contains(status)) {
      currentStep = 1;
    } else if ([
      'delivering',
      'delivery',
      'shipping',
      'in_transit',
      'out_for_delivery'
    ].contains(status)) {
      currentStep = 2;
    } else if (['completed', 'delivered'].contains(status)) {
      currentStep = 3;
    }

    final steps = [
      {'title': 'Pending', 'icon': Icons.shopping_cart_checkout},
      {'title': 'Preparing', 'icon': Icons.inventory_2_outlined},
      {'title': 'Delivery', 'icon': Icons.local_shipping_outlined},
      {'title': 'Completed', 'icon': Icons.check_circle_outline},
    ];

    Color primaryColor = Theme.of(context).primaryColor;
    Color inactiveColor = Colors.grey[300]!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        bool isCompleted = index <= currentStep;
        bool isLineCompleted = index < currentStep;

        return Expanded(
          flex: index == steps.length - 1 ? 0 : 1,
          child: Row(
            children: [
              // Icon Badge
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted ? primaryColor : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? primaryColor : inactiveColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      steps[index]['icon'] as IconData,
                      size: 16,
                      color: isCompleted ? Colors.white : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[index]['title'] as String,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? primaryColor : Colors.grey[500],
                    ),
                  ),
                ],
              ),

              // Line to next step
              if (index != steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isLineCompleted ? primaryColor : inactiveColor,
                    margin:
                        const EdgeInsets.only(left: 4, right: 4, bottom: 18),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _shareOrder(OrderModel order) {
    OrderReceiptDialog.show(context, order);
  }

  void _repeatOrder(OrderModel order) async {
    // Add all items from the order to cart (keeping existing items)
    final cartProvider = context.read<CartProvider>();

    try {
      // Add all order items to the cart
      for (var item in order.items) {
        await cartProvider.addToCart(item.product, item.quantity);
      }

      if (mounted) {
        // Calculate smart delivery date based on 5 PM cutoff
        final now = DateTime.now();
        final cutoffTime =
            DateTime(now.year, now.month, now.day, 17, 0); // 5:00 PM

        DateTime suggestedDate;
        String deliveryMessage;

        if (now.isBefore(cutoffTime)) {
          // Before 5 PM: Suggest today
          suggestedDate = now;
          deliveryMessage =
              '${order.items.length} items added. Delivery: Today (before 5 PM cutoff)';
        } else {
          // After 5 PM: Suggest tomorrow
          suggestedDate = now.add(const Duration(days: 1));
          deliveryMessage =
              '${order.items.length} items added. Delivery: Tomorrow (after 5 PM)';
        }

        // Navigate to checkout with suggested delivery date
        context.push(
          RouteNames.checkout,
          extra: {'suggestedDeliveryDate': suggestedDate},
        );

        // Show informative message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deliveryMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding items to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
