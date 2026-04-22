import 'dart:convert';
import '../../../core/utils/api_helper.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/order_model.dart';
import '../abstract/order_repository.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../models/payment_method_model.dart';

class ApiOrderRepository implements OrderRepository {
  final AuthProvider authProvider;

  ApiOrderRepository(this.authProvider);

  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      // Get current user ID from AuthProvider
      final userId = authProvider.currentUser?.id ??
          '50'; // Fallback to '50' if not logged in

      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.ordersList(userId)}';
      print('🔗 Fetching orders for user $userId from: $url');

      final response = await ApiHelper.instance.dio.get(url);
      print('📥 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final dynamic data;
        if (response.data is String) {
          print('⚠️ Response is String, parsing JSON...');
          data = json.decode(response.data);
        } else {
          data = response.data;
        }

        print('📊 Parsed data type: ${data.runtimeType}');

        if (data is Map<String, dynamic> && data['status'] == 1) {
          final List<dynamic> orderList = data['data'] ?? [];
          print('✅ Found ${orderList.length} orders');

          final List<OrderModel> parsedOrders = [];
          for (int i = 0; i < orderList.length; i++) {
            try {
              final order =
                  OrderModel.fromJson(orderList[i] as Map<String, dynamic>);
              parsedOrders.add(order);
            } catch (e) {
              print('❌ Error parsing order at index $i: $e');
              print('Order data: ${orderList[i]}');
            }
          }

          print(
              '✅ Successfully parsed ${parsedOrders.length} orders out of ${orderList.length}');

          // Sort orders by creation date, newest first
          parsedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return parsedOrders;
        } else {
          print(
              '⚠️ API status not 1 or data not Map. Status: ${data is Map ? data['status'] : 'N/A'}');
        }
      }

      print('⚠️ No orders found or API error, returning empty list');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error fetching orders: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  @override
  Future<OrderModel> getOrderById(String id) async {
    try {
      // Get current user ID from AuthProvider
      final userId = authProvider.currentUser?.id ??
          '50'; // Fallback to '50' if not logged in

      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.ordersList(userId)}';
      print('🔗 Fetching order detail for ID $id from: $url');

      final response = await ApiHelper.instance.dio.get(url);
      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data;
        if (response.data is String) {
          data = json.decode(response.data);
        } else {
          data = response.data;
        }

        if (data is Map<String, dynamic> && data['status'] == 1) {
          final List<dynamic> orderList = data['data'];

          // Find the order with matching ID
          final orderJson = orderList.firstWhere(
            (order) => order['id'].toString() == id,
            orElse: () => null,
          );

          if (orderJson != null) {
            print('✅ Found order with ID $id');
            return OrderModel.fromJson(orderJson as Map<String, dynamic>);
          } else {
            print('⚠️ Order with ID $id not found in the list');
            throw Exception('Order not found');
          }
        }

        throw Exception('Order not found or invalid response');
      } else {
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching order by ID $id: $e');
      rethrow;
    }
  }

// ... (existing helper methods if needed)

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      const url = '${ApiConstants.orderBaseUrl}${ApiConstants.paymentMethods}';
      print('🔗 Fetching payment methods from: $url');

      final response = await ApiHelper.instance.dio.get(url);

      if (response.statusCode == 200) {
        final dynamic data;
        if (response.data is String) {
          data = json.decode(response.data);
        } else {
          data = response.data;
        }

        if (data is Map<String, dynamic> && data['status'] == 1) {
          final List<dynamic> list = data['data'] ?? [];
          return list
              .map(
                  (e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching payment methods: $e');
      return [];
    }
  }

  @override
  Future<void> updatePaymentMethod(String paymentMethod) async {
    try {
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.updatePaymentMethod(paymentMethod)}';
      print('🔗 Updating payment method to $paymentMethod at: $url');

      final response = await ApiHelper.instance.dio.get(url);
      print(
          '📥 Update Payment Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        final dynamic data;
        if (response.data is String) {
          data = json.decode(response.data);
        } else {
          data = response.data;
        }

        if (data is Map<String, dynamic> && data['status'] == 1) {
          print('✅ Payment method updated successfully');
          return;
        }
      }
      print('⚠️ Failed to update payment method');
    } catch (e) {
      print('❌ Error updating payment method: $e');
      // Don't rethrow to avoid blocking the UI, but log it
    }
  }

  @override
  Future<void> updateOrderNote(String note) async {
    try {
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.updateOrderNote(note)}';
      print('🔗 Updating order note to "$note" at: $url');

      final response = await ApiHelper.instance.dio.get(url);
      print(
          '📥 Update Note Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        final dynamic data;
        if (response.data is String) {
          data = json.decode(response.data);
        } else {
          data = response.data;
        }

        if (data is Map<String, dynamic> && data['status'] == 1) {
          print('✅ Order note updated successfully');
          return;
        }
      }
      print('⚠️ Failed to update order note');
    } catch (e) {
      print('❌ Error updating order note: $e');
      // Don't rethrow to avoid blocking the user flow
    }
  }

  @override
  Future<void> updateDeliveryDate(String deliveryDate) async {
    try {
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.updateDeliveryDate(deliveryDate)}';
      print('🔗 Updating delivery date: $url');

      final response = await ApiHelper.instance.dio.get(url);
      print(
          '📥 Update Delivery Date Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update delivery date: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating delivery date: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> submitOrder({String? deliveryDate}) async {
    try {
      const url = '${ApiConstants.orderBaseUrl}${ApiConstants.submitOrder}';
      print('🔗 Submitting order at: $url');

      final response = await ApiHelper.instance.dio.get(url);
      print(
          '📥 Submit Order Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        final dynamic data;
        if (response.data is String) {
          data = json.decode(response.data);
        } else {
          data = response.data;
        }

        if (data is Map<String, dynamic>) {
          if (data['status'] == 1) {
            print('✅ Order submitted successfully');
          } else {
            print('⚠️ Order submission returned status: ${data['status']}');
          }
          return data;
        }
      }
      throw Exception('Failed to submit order: ${response.statusCode}');
    } catch (e) {
      print('❌ Error submitting order: $e');
      rethrow;
    }
  }

  @override
  Future<OrderModel> createOrder({
    required List items,
    required String paymentMethod,
    required deliveryAddress,
    String? notes,
  }) async {
    // This method is not used in the current API flow
    // The API uses submitOrder instead
    throw UnimplementedError(
        'createOrder is not implemented for API repository');
  }

  @override
  Future<bool> uploadReceipt(String orderId, String filePath) async {
    // TODO: Implement receipt upload when API endpoint is available
    throw UnimplementedError('uploadReceipt is not implemented yet');
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    // TODO: Implement order status update when API endpoint is available
    throw UnimplementedError('updateOrderStatus is not implemented yet');
  }
}
