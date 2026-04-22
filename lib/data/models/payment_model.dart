class PaymentModel {
  final String id;
  final String orderId;
  final String method;
  final double amount;
  final String status;
  final String? receiptUrl;
  final BankDetails? bankDetails;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.status,
    this.receiptUrl,
    this.bankDetails,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      method: json['method'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      receiptUrl: json['receipt_url'] as String?,
      bankDetails: json['bank_details'] != null
          ? BankDetails.fromJson(json['bank_details'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'method': method,
      'amount': amount,
      'status': status,
      'receipt_url': receiptUrl,
      'bank_details': bankDetails?.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class BankDetails {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String? qrCodeUrl;

  BankDetails({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    this.qrCodeUrl,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bank_name'] as String,
      accountName: json['account_name'] as String,
      accountNumber: json['account_number'] as String,
      qrCodeUrl: json['qr_code_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bank_name': bankName,
      'account_name': accountName,
      'account_number': accountNumber,
      'qr_code_url': qrCodeUrl,
    };
  }
}
