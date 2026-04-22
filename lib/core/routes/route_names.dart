class RouteNames {
  // Auth Routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main Routes
  static const String home = '/home';

  // Product Routes
  static const String products = '/products';
  static const String productList = '/products';
  static const String productDetail = '/products/:id';
  static const String hiddenProducts = '/products/hidden';
  static const String favorites = '/favorites';
  static const String categories = '/categories';

  // Cart Routes
  static const String cart = '/cart';

  // Checkout Routes
  static const String checkout = '/checkout';
  static const String paymentMethod = '/checkout/payment-method';
  static const String bankTransfer = '/checkout/bank-transfer';
  static const String receiptUpload = '/checkout/receipt-upload';

  // Order Routes
  static const String orders = '/orders';
  static const String orderList = '/orders';
  static const String orderDetail = '/orders/:id';

  // Profile Routes
  static const String profile = '/profile';
  static const String settings = '/profile/settings';
  static const String addresses = '/profile/addresses';
  static const String paymentMethods = '/profile/payment-methods';
}
