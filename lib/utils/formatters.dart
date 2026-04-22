import 'package:intl/intl.dart';

class Formatters {
  /// Format currency (USD)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format date (e.g., "Jan 9, 2026")
  static String formatDate(DateTime date) {
    final formatter = DateFormat('MMM d, y');
    return formatter.format(date);
  }

  /// Format date with time (e.g., "Jan 9, 2026 3:30 PM")
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('MMM d, y h:mm a');
    return formatter.format(date);
  }

  /// Format number with commas
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  /// Format phone number
  static String formatPhone(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    return phone; // Return as-is if not 10 digits
  }

  /// Format order status for display
  static String formatOrderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'WAITING_PAYMENT':
        return 'Waiting Payment';
      case 'PENDING_VERIFICATION':
        return 'Pending Verification';
      case 'PAID':
        return 'Paid';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}
