// import '../abstract/cart_repository.dart';
import '../abstract/cart_repository.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../models/cart_model.dart';

class MockCartRepository implements CartRepository {
  final List<CartItemModel> _cartItems = [];
  int _nextId = 1;
  static const double _taxRate = 0.10;

  CartModel _createCartModel() {
    final subtotal = _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final totalVat = subtotal * _taxRate;
    final grandTotal = subtotal + totalVat; // Ignoring PLT for mock

    return CartModel(
      items: List.from(_cartItems),
      subtotal: subtotal,
      totalVat: totalVat,
      totalPlt: 0.0,
      grandTotal: grandTotal,
    );
  }

  @override
  Future<CartModel> getCartItems() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _createCartModel();
  }

  @override
  Future<CartModel> addToCart(ProductModel product, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Check if product already in cart
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex != -1) {
      // Update quantity
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      // Add new item
      _cartItems.add(CartItemModel(
        id: (_nextId++).toString(),
        product: product,
        quantity: quantity,
        unitPrice: product.price,
      ));
    }
    return _createCartModel();
  }

  @override
  Future<CartModel> updateQuantity(String itemId, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (quantity <= 0) {
      return await removeFromCart(itemId);
    }

    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
    }
    return _createCartModel();
  }

  @override
  Future<CartModel> removeFromCart(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _cartItems.removeWhere((item) => item.id == itemId);
    return _createCartModel();
  }

  @override
  Future<CartModel> clearCart() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _cartItems.clear();
    return _createCartModel();
  }

  @override
  Future<int> getCartItemCount() async {
    int total = 0;
    for (var item in _cartItems) {
      total += item.quantity;
    }
    return total;
  }

  @override
  Future<double> getCartTotal() async {
    double total = 0.0;
    for (var item in _cartItems) {
      total += item.totalPrice;
    }
    return total;
  }
}
// }
