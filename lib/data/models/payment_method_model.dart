class PaymentMethodModel {
  final int id;
  final String name;
  final String image;

  const PaymentMethodModel({
    required this.id,
    required this.name,
    required this.image,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );
  }

  String get displayName {
    if (name.toLowerCase() == 'cod') {
      return 'Cash on Delivery';
    } else if (name.toLowerCase() == 'account_receivable') {
      return 'Account Receivable'; // With Bank Transfer subtitle maybe?
    }
    // Capitalize words
    return name
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
