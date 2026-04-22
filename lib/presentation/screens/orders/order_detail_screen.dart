import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers/order_provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../../utils/formatters.dart';
import '../../../data/models/order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderById(widget.orderId);
    });
  }

  Future<void> _shareReceiptImage(OrderModel order) async {
    try {
      // Find the render boundary
      final boundary = _receiptKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Could not find receipt boundary");
      }

      // Capture the image
      final image = await boundary.toImage(pixelRatio: 3.0); // High resolution
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/receipt_${order.id}.png');
      await file.writeAsBytes(pngBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Order Receipt #${order.id}',
        subject: 'Receipt #${order.id}',
      );
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppBarLogo(),
            const SizedBox(width: 8),
            Text('Order #${widget.orderId}'),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (orderProvider.currentOrderState.hasData &&
              orderProvider.currentOrderState.data != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () =>
                  _shareReceiptImage(orderProvider.currentOrderState.data!),
              tooltip: 'Share Receipt',
            ),
        ],
      ),
      body: orderProvider.currentOrderState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error) => Center(child: Text('Error: $error')),
        success: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Receipt Container
                RepaintBoundary(
                  key: _receiptKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.black.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Order Status Header
                        // Order Status Header
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.85),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Receipt Brand Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'OFFICIAL RECEIPT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Main Amount or OrderRef
                              if (order.referenceNo != null) ...[
                                Text(
                                  order.referenceNo!,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                    fontFamily:
                                        'Courier', // Monospace for numbers looks receipt-like
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  Formatters.formatOrderStatus(order.status)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              // Date
                              Text(
                                Formatters.formatDate(order.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Order Tracking Timeline
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          child: OrderTrackingTimeline(order: order),
                        ),

                        Divider(height: 1, color: Colors.grey[300]),

                        // Delivery Address Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'DELIVER TO',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                order.deliveryAddress.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.deliveryAddress.phone,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.deliveryAddress.fullAddress,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey[300]),

                        // Order Items Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ORDER ITEMS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...order.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Product Image (Only show if URL exists)
                                        if (item.product.images.isNotEmpty &&
                                            item.product.images.first
                                                .startsWith('http'))
                                          Container(
                                            width: 48,
                                            height: 48,
                                            margin: const EdgeInsets.only(
                                                right: 12),
                                            decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.grey[200]!)),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                item.product.images.first,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.image,
                                                        size: 20,
                                                        color: Colors.grey),
                                              ),
                                            ),
                                          ),

                                        // Product Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Product Name (Cleaner)
                                              Text(
                                                item.product.name,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),

                                              // Wrapper for ID and Qty Info
                                              Row(
                                                children: [
                                                  // ID Badge
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      'ID: ${item.product.id}',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Qty x Price
                                                  Text(
                                                    '${item.quantity} x ${Formatters.formatCurrency(item.unitPrice)}',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Total Price
                                        Text(
                                          Formatters.formatCurrency(
                                              item.totalPrice),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),

                        // Dashed Divider
                        CustomPaint(
                          size: const Size(double.infinity, 1),
                          painter: DashedLinePainter(),
                        ),

                        // Order Summary Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ORDER SUMMARY',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryRow(
                                  'Grand Total', order.subtotal, false),
                              const SizedBox(height: 12),
                              _buildSummaryRow('Tax (10%)', order.tax, false),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                  'Shipping Fee', order.shippingFee, false),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'TOTAL',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(order.total),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32)
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, [bool isBold = false]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          Formatters.formatCurrency(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class OrderTrackingTimeline extends StatelessWidget {
  final dynamic order; // Using dynamic or OrderModel

  const OrderTrackingTimeline({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Determine the current step (0 to 3):
    // 0. Placed (Pending) -> 1. Preparing -> 2. Delivery (Shipping) -> 3. Completed
    int currentStep = 0;

    // Logic for steps based on sale status
    String deliveryStatus = order.status.toLowerCase();

    // Step 0: Pending (default - order placed)
    if (deliveryStatus == 'pending') {
      currentStep = 0;
    }
    // Step 1: Preparing/Processing
    else if (['preparing', 'processing'].contains(deliveryStatus)) {
      currentStep = 1;
    }
    // Step 2: Delivery (Shipping/In Transit)
    else if ([
      'delivering',
      'delivery',
      'shipping',
      'in_transit',
      'out_for_delivery'
    ].contains(deliveryStatus)) {
      currentStep = 2;
    }
    // Step 3: Completed/Delivered
    else if (['completed', 'delivered'].contains(deliveryStatus)) {
      currentStep = 3;
    }

    // Step Definition
    final steps = [
      {'title': 'Pending', 'icon': Icons.shopping_cart_checkout},
      {'title': 'Preparing', 'icon': Icons.inventory_2_outlined},
      {'title': 'Delivery', 'icon': Icons.local_shipping_outlined},
      {'title': 'Completed', 'icon': Icons.check_circle_outline},
    ];

    Color primaryColor = Theme.of(context).primaryColor;
    Color inactiveColor = Colors.grey[300]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(steps.length, (index) {
                bool isCompleted = index <= currentStep;
                bool isLineCompleted = index < currentStep;

                return Expanded(
                  flex: index == steps.length - 1
                      ? 0
                      : 1, // Last item doesn't need flex for line
                  child: Row(
                    children: [
                      // Icon Badge
                      Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: isCompleted
                                    ? primaryColor
                                    : Colors.grey[100],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCompleted
                                      ? primaryColor
                                      : inactiveColor,
                                  width: 2,
                                )),
                            child: Icon(
                              steps[index]['icon'] as IconData,
                              size: 18,
                              color:
                                  isCompleted ? Colors.white : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            steps[index]['title'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCompleted
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  isCompleted ? primaryColor : Colors.grey[500],
                            ),
                          )
                        ],
                      ),

                      // Line to next step
                      if (index != steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 3,
                            color:
                                isLineCompleted ? primaryColor : inactiveColor,
                            margin: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 20)
                                .copyWith(
                                    top: 0,
                                    bottom:
                                        20), // Align with circle center (approx)
                            // Better alignment:
                            // Circle is 36px. Center is 18px.
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// Dashed Line Painter for receipt divider
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1;

    const dashWidth = 5;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
