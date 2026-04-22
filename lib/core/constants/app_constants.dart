class AppConstants {
  // App Info
  static const String appName = 'DAISHIN Order System';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyLanguage = 'language';
  static const String keyThemeMode = 'theme_mode';

  // Languages
  static const String langEnglish = 'en';
  static const String langKhmer = 'km';
  static const String langJapanese = 'ja';
  static const String langChinese = 'zh';

  // User Roles
  static const String roleRetail = 'retail';
  static const String roleBusiness = 'business';

  // Payment Methods
  static const String paymentCOD = 'cod';
  static const String paymentBankTransfer = 'bank_transfer';
  static const String paymentInvoice = 'invoice';

  // Order Status
  static const String orderPending = 'PENDING';
  static const String orderWaitingPayment = 'WAITING_PAYMENT';
  static const String orderPendingVerification = 'PENDING_VERIFICATION';
  static const String orderPaid = 'PAID';
  static const String orderDelivered = 'DELIVERED';
  static const String orderCancelled = 'CANCELLED';

  // Pagination
  static const int defaultPageSize = 20;

  // Image Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'pdf'];
}
