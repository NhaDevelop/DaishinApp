class ApiConstants {
  // Base URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-project.camboinfo.com',
  );

  // Order API Base URL (different server)
  static const String orderBaseUrl = String.fromEnvironment(
    'ORDER_API_BASE_URL',
    defaultValue: 'http://157.230.247.204/api-project',
  );

  // Timeout
  static const int timeoutDuration = 60000; // 60 seconds

  // API Endpoints
  // AuthR
  static const String login =
      '/?page=request&method=authorization&request_page=authorization&request_method=login_order&short_title=demo-order';
  static const String register = '/api/auth/register';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/refresh';

  // Products
  static const String products = '/api/products';
  static String productsByCategory(String categoryId) =>
      '/?page=get&method=product_by_category&short_title=demo-admin-order&id=$categoryId';
  static const String productPromotion =
      '/?page=get&method=product_promotion&short_title=demo-admin-order';
  static const String productFeatured =
      '/?page=get&method=product_featured&short_title=demo-admin-order';
  static const String productBusiness =
      '/?page=get&method=product_business_use&short_title=demo-admin-order';
  static const String productRetailUse =
      '/?page=get&method=product_retail_use&short_title=demo-admin-order';
  static const String categories =
      '/?page=request&method=default_api&request_page=get&request_method=get_product_category&short_title=demo-admin-order';
  static const String productDetail =
      '/?page=request&method=default_api&request_page=get&request_method=product_detail&short_title=demo-admin-order';
  static String toggleFavorite(String productId, String customerId) =>
      '/?page=update&method=update_favorite&short_title=demo-admin-order&product_id=$productId';
  static String getFavorites(String customerId) =>
      '/?page=get&method=get_favorite_products&short_title=demo-admin-order&customer_id=$customerId';

  // Cart
  static String addToCart(String productId, int quantity, String customerId) =>
      '/?page=update&method=add_product&product_id=$productId&quantity=$quantity&customer_id=$customerId&short_title=demo-admin-order';
  static String getCart(String customerId) =>
      '/?page=get&method=get_cart&customer_id=$customerId&short_title=demo-admin-order';
  static String updateCartItem(
          String productId, int quantity, String customerId) =>
      '/?page=update&method=update_product_quantity&product_id=$productId&quantity=$quantity&short_title=demo-admin-order';
  static String removeFromCart(String productId, String customerId) =>
      '/?page=delete&method=delete_product&product_id=$productId&customer_id=$customerId&short_title=demo-admin-order';
  static String clearCart(String customerId) =>
      '/?page=delete&method=delete_all_product&customer_id=$customerId&short_title=demo-admin-order';

  static String getCartDetail(String customerId) =>
      '/?page=get&method=get_sale_order_detail&short_title=demo-admin-order&customer_id=$customerId';

  static String updatePaymentMethod(String value) =>
      '/?page=update&method=update_payment_method&value=$value&short_title=demo-admin-order';

  static String updateOrderNote(String value) =>
      '/?page=update&method=update_note&value=$value&short_title=demo-order';

  static const String submitOrder =
      '/?page=update&method=submit_order&short_title=demo-order';

  // Orders
  static const String orders = '/api/orders';
  static const String paymentMethods =
      '/?page=get&method=get_payment_method&short_title=demo-admin-order';
  static String ordersList(String userId) =>
      '/?page=get&method=get_order_detail&short_title=demo-admin-order&user_id=$userId';
  static String orderDetail(String id) =>
      '/?page=get&method=get_order_detail&short_title=demo-admin-order&sale_id=$id';
  static String updateDeliveryDate(String deliveryDate) =>
      '/?page=update&method=update_delivery_date&value=$deliveryDate&short_title=demo-order';

  // Payment
  static const String uploadReceipt = '/api/payments/upload-receipt';
  static const String bankDetails = '/api/payments/bank-details';

  // Profile
  static const String profile = '/api/profile';
  static const String addresses = '/api/profile/addresses';
}
