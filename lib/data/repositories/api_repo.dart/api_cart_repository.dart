import 'dart:convert';

import 'package:daishin_order_app/core/constants/api_constants.dart';
import 'package:daishin_order_app/core/utils/api_helper.dart';
import 'package:daishin_order_app/data/dto/cart_response_dto.dart';
import 'package:daishin_order_app/data/dto/sale_order_detail_dto.dart';
import 'package:daishin_order_app/data/models/cart_item_model.dart';
import 'package:daishin_order_app/data/models/cart_model.dart';
import 'package:daishin_order_app/data/models/product_model.dart';
import 'package:daishin_order_app/data/repositories/abstract/cart_repository.dart';
import 'package:daishin_order_app/presentation/providers/auth_provider.dart';

class ApiCartRepository implements CartRepository {
  final ApiHelper _apiHelper = ApiHelper.instance;
  final AuthProvider _authProvider;

  ApiCartRepository(this._authProvider);

  String get _customerId {
    final user = _authProvider.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.id;
  }

  /// Helper method to parse response data
  Map<String, dynamic>? _parseResponse(dynamic responseData) {
    try {
      if (responseData is String) {
        if (responseData.trim().startsWith('<')) {
          print('⚠️ Received HTML response (likely empty cart or error)');
          return null;
        }
        final decoded = json.decode(responseData);
        if (decoded is List) {
          print('⚠️ Received List response when Map was expected: $decoded');
          return null;
        }
        return decoded as Map<String, dynamic>;
      }
      if (responseData is List) {
        print('⚠️ Received List response when Map was expected: $responseData');
        return null;
      }
      return responseData as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error parsing response: $e');
      return null;
    }
  }

  CartModel _mapDtoToCartModel(CartResponseDto cartResponse) {
    if (cartResponse.data == null) return const CartModel();

    final items = cartResponse.data!.items
        .where((dto) =>
            dto.quantity > 0) // Filter out items with 0 or negative quantity
        .map((dto) {
      // Map DTO to Domain Model
      return CartItemModel(
        id: dto.id,
        // We create a ProductModel from the limited data in the cart DTO
        product: ProductModel(
          id: dto.id,
          name: dto.name,
          description: '', // Not available in cart DTO
          price: dto.originalPrice, // Use original price as base price
          stock: 99, // Assumption
          categoryId: '0',
          images: dto.image.isNotEmpty ? [dto.image] : [],
          createdAt: DateTime.now(),
        ),
        quantity: dto.quantity,
        unitPrice: dto.price, // This is the potentially discounted price
      );
    }).toList();

    print('✅ Mapped ${items.length} cart items and totals from response');

    return CartModel(
      items: items,
      subtotal: cartResponse.data!.total,
      totalVat: cartResponse.data!.totalVat,
      totalPlt: cartResponse.data!.totalPlt,
      grandTotal: cartResponse.data!.grandTotal,
    );
  }

  CartModel _mapSaleOrderDetailToCartModel(
      SaleOrderDetailResponseDto response) {
    if (response.data == null) return const CartModel();

    final data = response.data!;
    final items = data.items.map((dto) {
      // Map DTO to Domain Model
      return CartItemModel(
        id: dto.id,
        product: ProductModel(
          id: dto.id,
          name: dto.name,
          description: '',
          price: (dto.originalPrice is num)
              ? (dto.originalPrice as num).toDouble()
              : double.tryParse(dto.originalPrice.toString()) ?? 0.0,
          stock: 99,
          categoryId: '0',
          images:
              dto.image != null && dto.image!.isNotEmpty ? [dto.image!] : [],
          createdAt: DateTime.now(),
        ),
        quantity: (dto.quantity is int)
            ? dto.quantity as int
            : int.tryParse(dto.quantity.toString()) ?? 0,
        unitPrice: (dto.price is num)
            ? (dto.price as num).toDouble()
            : double.tryParse(dto.price.toString()) ?? 0.0,
      );
    }).toList();

    return CartModel(
      items: items,
      subtotal: (data.total is num)
          ? (data.total as num).toDouble()
          : double.tryParse(data.total.toString()) ?? 0.0,
      totalVat: (data.totalVat is num)
          ? (data.totalVat as num).toDouble()
          : double.tryParse(data.totalVat.toString()) ?? 0.0,
      totalPlt: (data.totalPlt is num)
          ? (data.totalPlt as num).toDouble()
          : double.tryParse(data.totalPlt.toString()) ?? 0.0,
      grandTotal: (data.grandTotal is num)
          ? (data.grandTotal as num).toDouble()
          : double.tryParse(data.grandTotal.toString()) ?? 0.0,
      deliveryDate: data.deliveryDate,
    );
  }

  @override
  Future<CartModel> addToCart(ProductModel product, int quantity) async {
    try {
      // Step 1: Add product to cart
      // If quantity is 1 (from grid card), just add and return
      // If quantity > 1 (from detail screen), add then update to desired quantity
      final addUrl =
          '${ApiConstants.orderBaseUrl}${ApiConstants.addToCart(product.id, 1, _customerId)}';
      print('🛒 Adding to cart (step 1): $addUrl');

      final addResponse = await _apiHelper.dio.get(addUrl);

      if (addResponse.statusCode != 200) {
        throw Exception('Failed to add to cart: ${addResponse.statusCode}');
      }

      // Parse the response to see current state
      final responseData = _parseResponse(addResponse.data);
      if (responseData != null) {
        final cartDto = CartResponseDto.fromJson(responseData);
        if (cartDto.status == 1) {
          // If user requested quantity of 1 (grid card), we're done
          if (quantity == 1) {
            return _mapDtoToCartModel(cartDto);
          }

          // If user requested more than 1 (detail screen with manual input),
          // we need to update to the desired quantity
          // The add_product already added 1, so we update to the total desired
          return updateQuantity(product.id, quantity);
        } else {
          throw Exception(cartDto.message);
        }
      }

      throw Exception('Invalid response from server');
    } catch (e) {
      print('❌ Error adding to cart: $e');
      rethrow;
    }
  }

  @override
  Future<CartModel> getCartItems() async {
    try {
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.getCartDetail(_customerId)}';
      print('🛒 Fetching cart details: $url');

      final response = await _apiHelper.dio.get(url);

      if (response.statusCode == 200) {
        final responseData = _parseResponse(response.data);
        if (responseData == null) return const CartModel();

        final dto = SaleOrderDetailResponseDto.fromJson(responseData);
        if (dto.status == 1) {
          return _mapSaleOrderDetailToCartModel(dto);
        } else {
          if (dto.message.toLowerCase().contains('empty') || dto.data == null) {
            return const CartModel();
          }
          print('⚠️ API returned status ${dto.status}: ${dto.message}');
          return const CartModel();
        }
      } else {
        throw Exception('Failed to fetch cart: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching cart: $e');
      return const CartModel();
    }
  }

  @override
  Future<CartModel> updateQuantity(String itemId, int quantity) async {
    try {
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.updateCartItem(itemId, quantity, _customerId)}';
      print('🛒 Updating cart item: $url');

      final response = await _apiHelper.dio.get(url);
      print('📥 UpdateCartItem response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = _parseResponse(response.data);
        if (responseData == null) {
          return const CartModel();
        }

        final cartDto = CartResponseDto.fromJson(responseData);
        if (cartDto.status == 1) {
          return _mapDtoToCartModel(cartDto);
        } else {
          throw Exception(cartDto.message);
        }
      } else {
        throw Exception('Failed to update cart item');
      }
    } catch (e) {
      print('❌ Error updating cart item: $e');
      rethrow;
    }
  }

  @override
  Future<CartModel> removeFromCart(String itemId) async {
    try {
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.removeFromCart(itemId, _customerId)}';
      print('🛒 Removing from cart: $url');

      final response = await _apiHelper.dio.get(url);

      if (response.statusCode == 200) {
        final responseData = _parseResponse(response.data);
        if (responseData == null) {
          return const CartModel();
        }
        final cartDto = CartResponseDto.fromJson(responseData);
        if (cartDto.status == 1) {
          return _mapDtoToCartModel(cartDto);
        } else {
          throw Exception(cartDto.message);
        }
      } else {
        throw Exception('Failed to remove from cart');
      }
    } catch (e) {
      print('❌ Error removing from cart: $e');
      rethrow;
    }
  }

  @override
  Future<CartModel> clearCart() async {
    try {
      final url =
          '${ApiConstants.orderBaseUrl}${ApiConstants.clearCart(_customerId)}';
      print('🛒 Clearing cart: $url');

      final response = await _apiHelper.dio.get(url);

      if (response.statusCode == 200) {
        final responseData = _parseResponse(response.data);
        if (responseData == null) {
          return const CartModel();
        }
        final cartDto = CartResponseDto.fromJson(responseData);
        if (cartDto.status == 1) {
          return _mapDtoToCartModel(cartDto);
        } else {
          return const CartModel();
        }
      } else {
        throw Exception('Failed to clear cart');
      }
    } catch (e) {
      print('❌ Error clearing cart: $e');
      rethrow;
    }
  }

  @override
  Future<int> getCartItemCount() async {
    try {
      final cart = await getCartItems();
      return cart.items.fold<int>(0, (sum, item) => sum + item.quantity);
    } catch (e) {
      print('❌ Error getting cart item count: $e');
      return 0;
    }
  }

  @override
  Future<double> getCartTotal() async {
    try {
      final cart = await getCartItems();
      return cart.grandTotal > 0
          ? cart.grandTotal
          : cart.items.fold<double>(
              0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
    } catch (e) {
      print('❌ Error getting cart total: $e');
      return 0.0;
    }
  }
}
