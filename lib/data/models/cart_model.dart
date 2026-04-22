import 'cart_item_model.dart';

class CartModel {
  final List<CartItemModel> items;
  final double subtotal;
  final double totalVat;
  final double totalPlt;
  final double grandTotal;
  final String? deliveryDate;

  const CartModel({
    this.items = const [],
    this.subtotal = 0.0,
    this.totalVat = 0.0,
    this.totalPlt = 0.0,
    this.grandTotal = 0.0,
    this.deliveryDate,
  });

  CartModel copyWith({
    List<CartItemModel>? items,
    double? subtotal,
    double? totalVat,
    double? totalPlt,
    double? grandTotal,
    String? deliveryDate,
  }) {
    return CartModel(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalVat: totalVat ?? this.totalVat,
      totalPlt: totalPlt ?? this.totalPlt,
      grandTotal: grandTotal ?? this.grandTotal,
      deliveryDate: deliveryDate ?? this.deliveryDate,
    );
  }
}
