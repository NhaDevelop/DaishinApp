import 'package:flutter/foundation.dart';
import '../../data/repositories/abstract/order_repository.dart';
import '../../data/models/order_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/address_model.dart';
import '../../core/utils/async_value.dart';

import '../../data/models/payment_method_model.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;

  OrderProvider(this._orderRepository);

  AsyncValue<List<OrderModel>> _ordersState = const AsyncValue.loading();
  AsyncValue<OrderModel?> _currentOrderState = const AsyncValue.success(null);
  AsyncValue<List<PaymentMethodModel>> _paymentMethodsState =
      const AsyncValue.loading();

  AsyncValue<List<OrderModel>> get ordersState => _ordersState;
  AsyncValue<OrderModel?> get currentOrderState => _currentOrderState;
  AsyncValue<List<PaymentMethodModel>> get paymentMethodsState =>
      _paymentMethodsState;

  /// Load all orders
  Future<void> loadOrders() async {
    _ordersState = const AsyncValue.loading();
    notifyListeners();

    try {
      final orders = await _orderRepository.getOrders();
      _ordersState = AsyncValue.success(orders);
      notifyListeners();
    } catch (e) {
      _ordersState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Create new order
  Future<OrderModel> createOrder({
    required List<CartItemModel> items,
    required String paymentMethod,
    required AddressModel deliveryAddress,
    String? notes,
  }) async {
    try {
      final order = await _orderRepository.createOrder(
        items: items,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        notes: notes,
      );

      // Reload orders to include new one
      await loadOrders();

      return order;
    } catch (e) {
      rethrow;
    }
  }

  /// Get order by ID
  Future<void> loadOrderById(String id) async {
    _currentOrderState = const AsyncValue.loading();
    notifyListeners();

    try {
      final order = await _orderRepository.getOrderById(id);
      _currentOrderState = AsyncValue.success(order);
      notifyListeners();
    } catch (e) {
      _currentOrderState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Upload payment receipt
  Future<bool> uploadReceipt(String orderId, String filePath) async {
    try {
      final result = await _orderRepository.uploadReceipt(orderId, filePath);

      // Reload orders to reflect changes
      await loadOrders();
      await loadOrderById(orderId);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Update order status (for testing)
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _orderRepository.updateOrderStatus(orderId, status);
      await loadOrders();
      await loadOrderById(orderId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get orders list
  List<OrderModel> get orders {
    return _ordersState.when(
      loading: () => [],
      error: (e) => [],
      success: (orders) => orders,
    );
  }

  /// Load payment methods
  Future<void> loadPaymentMethods() async {
    _paymentMethodsState = const AsyncValue.loading();
    notifyListeners();

    try {
      final methods = await _orderRepository.getPaymentMethods();
      _paymentMethodsState = AsyncValue.success(methods);
      notifyListeners();
    } catch (e) {
      _paymentMethodsState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Get payment methods list
  List<PaymentMethodModel> get paymentMethods {
    return _paymentMethodsState.when(
      loading: () => [],
      error: (e) => [],
      success: (methods) => methods,
    );
  }

  /// Update payment method
  Future<void> updatePaymentMethod(String paymentMethod) async {
    try {
      await _orderRepository.updatePaymentMethod(paymentMethod);
    } catch (e) {
      // Log error but don't propagate to UI as it's a background update
      if (kDebugMode) {
        print('Error updating payment method: $e');
      }
    }
  }

  /// Update order note
  Future<void> updateOrderNote(String note) async {
    try {
      await _orderRepository.updateOrderNote(note);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order note: $e');
      }
    }
  }

  /// Update delivery date
  Future<void> updateDeliveryDate(String deliveryDate) async {
    try {
      await _orderRepository.updateDeliveryDate(deliveryDate);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating delivery date: $e');
      }
      rethrow;
    }
  }

  /// Submit the current order
  Future<Map<String, dynamic>> submitOrder({String? deliveryDate}) async {
    try {
      return await _orderRepository.submitOrder(deliveryDate: deliveryDate);
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting order: $e');
      }
      rethrow;
    }
  }
}
