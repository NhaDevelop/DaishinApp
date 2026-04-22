import '../../models/cart_model.dart';
import '../../models/product_model.dart';

abstract class CartRepository {
  /// Get all cart items
  Future<CartModel> getCartItems();

  /// Add product to cart
  Future<CartModel> addToCart(ProductModel product, int quantity);

  /// Update cart item quantity
  Future<CartModel> updateQuantity(String itemId, int quantity);

  /// Remove item from cart
  Future<CartModel> removeFromCart(String itemId);

  /// Clear all cart items
  Future<CartModel> clearCart();

  /// Get cart item count
  Future<int> getCartItemCount();

  /// Get cart total
  Future<double> getCartTotal();
}
