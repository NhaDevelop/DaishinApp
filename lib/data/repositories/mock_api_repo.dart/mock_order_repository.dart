// import '../abstract/order_repository.dart';
// import '../../models/order_model.dart';
// import '../../models/cart_item_model.dart';
// import '../../models/product_model.dart';
// import '../../models/address_model.dart';
// import '../../models/payment_method_model.dart';

// class MockOrderRepository implements OrderRepository {
//   final List<OrderModel> _orders = [];
//   int _nextId = 1;

//   // Initialize with some sample orders
//   MockOrderRepository() {
//     _initializeSampleOrders();
//   }

//   void _initializeSampleOrders() {
//     // Sample address
//     final sampleAddress = AddressModel(
//       id: '1',
//       userId: '1',
//       fullName: 'Test User',
//       phone: '+855123456789',
//       addressLine1: '123 Main Street',
//       city: 'Phnom Penh',
//       country: 'Cambodia',
//       isDefault: true,
//     );

//     // Sample Product
//     final sampleProduct = ProductModel(
//       id: '101',
//       name: 'Sample Item',
//       description: 'A sample product',
//       price: 15.00,
//       stock: 100,
//       categoryId: '1',
//       createdAt: DateTime(2026, 1, 1),
//       images: [],
//     );

//     // Sample orders
//     _orders.addAll([
//       OrderModel(
//         id: '1',
//         userId: '1',
//         items: [
//           CartItemModel(
//               id: '1', product: sampleProduct, quantity: 2, unitPrice: 15.00),
//           CartItemModel(
//               id: '2', product: sampleProduct, quantity: 1, unitPrice: 15.00),
//         ],
//         subtotal: 149.98,
//         tax: 15.00,
//         shippingFee: 5.00,
//         total: 169.98,
//         paymentMethod: 'bank_transfer',
//         status: 'DELIVERED',
//         deliveryStatus: 'delivered',
//         paymentStatus: 'paid',
//         deliveryAddress: sampleAddress,
//         paymentReceiptUrl: 'https://example.com/receipt1.jpg',
//         createdAt: DateTime(2026, 1, 5, 14, 30),
//         updatedAt: DateTime(2026, 1, 6, 10, 0),
//       ),
//       OrderModel(
//         id: '2',
//         userId: '1',
//         items: [
//           CartItemModel(
//               id: '3', product: sampleProduct, quantity: 5, unitPrice: 15.00),
//         ],
//         subtotal: 79.99,
//         tax: 8.00,
//         shippingFee: 5.00,
//         total: 92.99,
//         paymentMethod: 'cod',
//         status: 'PAID',
//         deliveryStatus: 'shipping',
//         paymentStatus: 'paid',
//         deliveryAddress: sampleAddress,
//         createdAt: DateTime(2026, 1, 20, 9, 15),
//         updatedAt: DateTime(2026, 1, 21, 11, 20),
//       ),
//       OrderModel(
//         id: '3',
//         userId: '1',
//         items: [
//           CartItemModel(
//               id: '4', product: sampleProduct, quantity: 10, unitPrice: 15.00),
//           CartItemModel(
//               id: '5', product: sampleProduct, quantity: 3, unitPrice: 15.00),
//         ],
//         subtotal: 199.97,
//         tax: 20.00,
//         shippingFee: 5.00,
//         total: 224.97,
//         paymentMethod: 'bank_transfer',
//         status: 'PENDING_VERIFICATION',
//         deliveryStatus: 'pending',
//         paymentStatus: 'pending',
//         deliveryAddress: sampleAddress,
//         paymentReceiptUrl: 'https://example.com/receipt3.jpg',
//         createdAt: DateTime(2026, 2, 1, 16, 45),
//       ),
//       OrderModel(
//         id: '4',
//         userId: '1',
//         items: [
//           CartItemModel(
//               id: '6', product: sampleProduct, quantity: 4, unitPrice: 15.00),
//         ],
//         subtotal: 60.00,
//         tax: 6.00,
//         shippingFee: 5.00,
//         total: 71.00,
//         paymentMethod: 'bank_transfer',
//         status: 'PREPARING',
//         deliveryStatus: 'preparing',
//         paymentStatus: 'paid',
//         deliveryAddress: sampleAddress,
//         paymentReceiptUrl: 'https://example.com/receipt4.jpg',
//         createdAt: DateTime(2026, 1, 28, 10, 0),
//         updatedAt: DateTime(2026, 1, 29, 12, 0),
//       ),
//       OrderModel(
//         id: '5',
//         userId: '1',
//         items: [
//           CartItemModel(
//               id: '7', product: sampleProduct, quantity: 7, unitPrice: 15.00),
//         ],
//         subtotal: 105.00,
//         tax: 10.50,
//         shippingFee: 5.00,
//         total: 120.50,
//         paymentMethod: 'cod',
//         status: 'COMPLETED',
//         deliveryStatus: 'completed',
//         paymentStatus: 'paid',
//         deliveryAddress: sampleAddress,
//         createdAt: DateTime(2026, 1, 4, 15, 0),
//         updatedAt: DateTime(2026, 1, 9, 15, 0),
//       ),
//     ]);
//   }

//   @override
//   Future<OrderModel> createOrder({
//     required List<CartItemModel> items,
//     required String paymentMethod,
//     required AddressModel deliveryAddress,
//     String? notes,
//   }) async {
//     await Future.delayed(const Duration(seconds: 1));

//     // Calculate totals
//     final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
//     final tax = subtotal * 0.1; // 10% tax
//     const shippingFee = 5.0;
//     final total = subtotal + tax + shippingFee;

//     // Determine initial status based on payment method
//     String status;
//     if (paymentMethod == 'cod') {
//       status = 'PENDING';
//     } else if (paymentMethod == 'bank_transfer') {
//       status = 'WAITING_PAYMENT';
//     } else {
//       status = 'PENDING'; // invoice
//     }

//     final order = OrderModel(
//       id: (_nextId++).toString(),
//       userId: '1', // Mock user ID
//       items: items,
//       subtotal: subtotal,
//       tax: tax,
//       shippingFee: shippingFee,
//       total: total,
//       paymentMethod: paymentMethod,
//       status: status,
//       deliveryAddress: deliveryAddress,
//       notes: notes,
//       createdAt: DateTime.now(),
//     );

//     _orders.insert(0, order); // Add to beginning for newest first
//     return order;
//   }

//   @override
//   Future<List<OrderModel>> getOrders() async {
//     await Future.delayed(const Duration(milliseconds: 500));
//     return List.from(_orders);
//   }

//   @override
//   Future<OrderModel> getOrderById(String id) async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     return _orders.firstWhere(
//       (order) => order.id == id,
//       orElse: () => throw Exception('Order not found'),
//     );
//   }

//   @override
//   Future<bool> uploadReceipt(String orderId, String filePath) async {
//     await Future.delayed(const Duration(seconds: 1));

//     final index = _orders.indexWhere((order) => order.id == orderId);
//     if (index == -1) {
//       throw Exception('Order not found');
//     }

//     // Update order with receipt URL and status
//     final order = _orders[index];
//     final updatedOrder = OrderModel(
//       id: order.id,
//       userId: order.userId,
//       items: order.items,
//       subtotal: order.subtotal,
//       tax: order.tax,
//       shippingFee: order.shippingFee,
//       total: order.total,
//       paymentMethod: order.paymentMethod,
//       status: 'PENDING_VERIFICATION',
//       deliveryAddress: order.deliveryAddress,
//       paymentReceiptUrl: filePath,
//       notes: order.notes,
//       createdAt: order.createdAt,
//       updatedAt: DateTime.now(),
//     );

//     _orders[index] = updatedOrder;
//     return true;
//   }

//   @override
//   Future<void> updateOrderStatus(String orderId, String status) async {
//     await Future.delayed(const Duration(milliseconds: 300));

//     final index = _orders.indexWhere((order) => order.id == orderId);
//     if (index == -1) {
//       throw Exception('Order not found');
//     }

//     final order = _orders[index];
//     final updatedOrder = OrderModel(
//       id: order.id,
//       userId: order.userId,
//       items: order.items,
//       subtotal: order.subtotal,
//       tax: order.tax,
//       shippingFee: order.shippingFee,
//       total: order.total,
//       paymentMethod: order.paymentMethod,
//       status: status,
//       deliveryAddress: order.deliveryAddress,
//       paymentReceiptUrl: order.paymentReceiptUrl,
//       notes: order.notes,
//       createdAt: order.createdAt,
//       updatedAt: DateTime.now(),
//     );

//     _orders[index] = updatedOrder;
//   }

//   @override
//   Future<List<PaymentMethodModel>> getPaymentMethods() async {
//     return [
//       const PaymentMethodModel(
//           id: 134,
//           name: 'account_receivable',
//           image:
//               'https://order.daishintc.com/assets/api/image/pament_method_account_payable.png'),
//       const PaymentMethodModel(
//           id: 135,
//           name: 'cod',
//           image:
//               'https://order.daishintc.com/assets/api/image/pament_method_account_payable_cod.png'),
//     ];
//   }

//   @override
//   Future<void> updatePaymentMethod(String paymentMethod) async {
//     // Mock implementation - doesn't need to do anything
//     await Future.delayed(const Duration(milliseconds: 300));
//   }

//   @override
//   Future<void> updateOrderNote(String note) async {
//     // Mock implementation
//     await Future.delayed(const Duration(milliseconds: 300));
//   }

//   @override
//   Future<void> updateDeliveryDate(String deliveryDate) async {
//     // Mock implementation - does nothing
//     await Future.delayed(const Duration(milliseconds: 100));
//   }

//   @override
//   Future<Map<String, dynamic>> submitOrder({String? deliveryDate}) async {
//     // Mock implementation
//     await Future.delayed(const Duration(milliseconds: 500));
//     return {'status': 1, 'message': 'Order submitted successfully'};
//   }
// }
