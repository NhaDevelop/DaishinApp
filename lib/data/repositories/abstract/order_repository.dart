import '../../models/order_model.dart';
import '../../models/cart_item_model.dart';
import '../../models/address_model.dart';
import '../../models/payment_method_model.dart';

abstract class OrderRepository {
  /// Get payment methods
  Future<List<PaymentMethodModel>> getPaymentMethods();

  /// Create a new order
  Future<OrderModel> createOrder({
    required List<CartItemModel> items,
    required String paymentMethod,
    required AddressModel deliveryAddress,
    String? notes,
  });

  /// Get all orders for current user
  Future<List<OrderModel>> getOrders();

  /// Get order by ID
  Future<OrderModel> getOrderById(String id);

  /// Upload payment receipt
  Future<bool> uploadReceipt(String orderId, String filePath);

  /// Update order status (for testing)
  Future<void> updateOrderStatus(String orderId, String status);

  /// Update payment method for current cart/session
  Future<void> updatePaymentMethod(String paymentMethod);

  /// Update order note for current cart/session
  Future<void> updateOrderNote(String note);

  /// Update delivery date for current cart/session
  Future<void> updateDeliveryDate(String deliveryDate);

  /// Submit the current order
  Future<Map<String, dynamic>> submitOrder({String? deliveryDate});
}
