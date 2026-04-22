import 'package:daishin_order_app/core/utils/async_value.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/abstract/cart_repository.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final CartRepository _cartRepository;

  CartProvider(this._cartRepository);

  AsyncValue<CartModel> _cartState = const AsyncValue.loading();

  // Cache these for UI usage (optimistic or confirmed)
  int _itemCount = 0;
  double _total = 0.0; // Subtotal
  double _vat = 0.0;
  double _grandTotal = 0.0;

  AsyncValue<CartModel> get cartState => _cartState;
  int get itemCount => _itemCount;
  double get total => _total; // Subtotal
  double get vat => _vat;
  double get grandTotal => _grandTotal;
  String? get deliveryDate => _cartState.when(
        loading: () => null,
        error: (_) => null,
        success: (cart) => cart.deliveryDate,
      );

  /// Load cart items
  Future<void> loadCart({bool showLoading = true}) async {
    if (showLoading) {
      _cartState = const AsyncValue.loading();
      notifyListeners();
    }

    try {
      final cart = await _cartRepository.getCartItems();
      _updateLocalState(cart);
    } catch (e) {
      _cartState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Add product to cart
  Future<void> addToCart(ProductModel product, int quantity) async {
    final previousState = _cartState;
    // We need a base model, if loading or error, use empty
    final previousCart = previousState.when(
      loading: () => const CartModel(),
      error: (_) => const CartModel(),
      success: (cart) => cart,
    );

    try {
      // Optimistic update
      final previousItems = List<CartItemModel>.from(previousCart.items);
      final existingIndex =
          previousItems.indexWhere((i) => i.product.id == product.id);
      final List<CartItemModel> newItems = List.from(previousItems);

      if (existingIndex != -1) {
        final existing = newItems[existingIndex];
        newItems[existingIndex] = existing.copyWith(
          quantity: existing.quantity + quantity,
        );
      } else {
        newItems.add(CartItemModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          product: product,
          quantity: quantity,
          unitPrice: product.finalPrice,
        ));
      }

      // Optimistic calculation (approximate until server response)
      final tempSubtotal =
          newItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      // We keep previous VAT/GrandTotal logic roughly or just set subtotal = grandTotal temporarily
      final tempCart = previousCart.copyWith(
        items: newItems,
        subtotal: tempSubtotal,
        // Don't guess VAT, just keep old or set 0?
        // Better to wait for server for accurate tax.
      );

      _updateLocalState(tempCart);
      notifyListeners();

      // Update with server source of truth directly from response
      final serverCart = await _cartRepository.addToCart(product, quantity);

      _updateLocalState(serverCart);
      notifyListeners();
    } catch (e) {
      // Revert on error
      _cartState = previousState;
      _syncFieldsFromState();
      notifyListeners();
      rethrow;
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String itemId, int quantity) async {
    // If quantity is 0 or less, this is a removal
    if (quantity <= 0) {
      return removeItem(itemId);
    }

    final previousState = _cartState;
    final previousCart = previousState.when(
      loading: () => const CartModel(),
      error: (_) => const CartModel(),
      success: (cart) => cart,
    );

    try {
      // Optimistic update
      final List<CartItemModel> newItems = List.from(previousCart.items);

      final index = newItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        newItems[index] = newItems[index].copyWith(quantity: quantity);
      }

      final tempSubtotal =
          newItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      _updateLocalState(previousCart.copyWith(
        items: newItems,
        subtotal: tempSubtotal,
      ));
      notifyListeners();

      final serverCart = await _cartRepository.updateQuantity(itemId, quantity);
      _updateLocalState(serverCart);
      notifyListeners();
    } catch (e) {
      // Revert on error
      _cartState = previousState;
      _syncFieldsFromState();
      notifyListeners();
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    final previousState = _cartState;
    final previousCart = previousState.when(
      loading: () => const CartModel(),
      error: (_) => const CartModel(),
      success: (cart) => cart,
    );

    try {
      // Optimistic update
      final List<CartItemModel> newItems = List.from(previousCart.items);
      newItems.removeWhere((item) => item.id == itemId);

      final tempSubtotal =
          newItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      _updateLocalState(previousCart.copyWith(
        items: newItems,
        subtotal: tempSubtotal,
      ));
      notifyListeners();

      final serverCart = await _cartRepository.removeFromCart(itemId);
      _updateLocalState(serverCart);
      notifyListeners();
    } catch (e) {
      // Revert
      _cartState = previousState;
      _syncFieldsFromState();
      notifyListeners();
      rethrow;
    }
  }

  /// Clear cart
  Future<void> clearCart() async {
    final previousState = _cartState;

    try {
      // Optimistic update
      _updateLocalState(const CartModel()); // Empty cart
      notifyListeners();

      final serverCart = await _cartRepository.clearCart();
      _updateLocalState(serverCart);
      notifyListeners();
    } catch (e) {
      // Revert
      _cartState = previousState;
      _syncFieldsFromState();
      notifyListeners();
      rethrow;
    }
  }

  void _updateLocalState(CartModel newCart) {
    _cartState = AsyncValue.success(newCart);
    _syncFieldsFromState();
  }

  void _syncFieldsFromState() {
    _cartState.when(loading: () {
      // Keep previous values or reset? Typically keep to avoid flicker
    }, error: (_) {
      // Keep previous values
    }, success: (cart) {
      _itemCount = cart.items.fold(0, (sum, item) => sum + item.quantity);
      // Use API totals if available (checking > 0 or similar is safer but assuming API sends correct 0 if empty)
      _total = cart.subtotal;
      _vat = cart.totalVat;
      _grandTotal = cart.grandTotal > 0
          ? cart.grandTotal
          : cart.subtotal; // Fallback if grandTotal 0
    });
  }

  /// Get cart items list
  List<CartItemModel> get items {
    return _cartState.when(
      loading: () => [],
      error: (e) => [],
      success: (cart) => cart.items,
    );
  }
}
