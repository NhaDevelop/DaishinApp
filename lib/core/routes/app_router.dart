import 'package:daishin_order_app/presentation/screens/home/home_screen.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/splash_screen.dart';
import 'route_names.dart';
import '../../presentation/screens/favorites/favorite_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/widgets/common/main_navigation.dart';

import '../../presentation/screens/products/product_list_screen.dart';
import '../../presentation/screens/categories/categories_screen.dart';
import '../../presentation/screens/products/product_detail_screen.dart';
import '../../presentation/screens/products/hidden_products_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/checkout/checkout_screen.dart';
import '../../presentation/screens/checkout/payment_method_screen.dart';
import '../../presentation/screens/checkout/bank_transfer_screen.dart';
import '../../presentation/screens/checkout/receipt_upload_screen.dart';
import '../../presentation/screens/orders/order_list_screen.dart';
import '../../presentation/screens/orders/order_detail_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/settings_screen.dart';
import '../../presentation/screens/profile/addresses_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: authProvider,
    initialLocation: RouteNames.splash,
    routes: [
      // Splash Route
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main Routes with Bottom Navigation (ShellRoute)
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'browse',
                builder: (context, state) => const ProductListScreen(),
              ),
              GoRoute(
                path: 'categories',
                builder: (context, state) => const CategoriesScreen(),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.favorites,
            builder: (context, state) => const FavoriteScreen(),
          ),
          GoRoute(
            path: RouteNames.products,
            builder: (context, state) => const ProductListScreen(),
          ),
          GoRoute(
            path: RouteNames.orders,
            builder: (context, state) => const OrderListScreen(),
          ),
          GoRoute(
            path: RouteNames.cart,
            builder: (context, state) => const CartScreen(),
          ),
        ],
      ),

      // Routes OUTSIDE ShellRoute (Full Screen)
      // Profile
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Product Detail
      GoRoute(
        path: RouteNames.productDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: RouteNames.hiddenProducts,
        builder: (context, state) => const HiddenProductsScreen(),
      ),

      // Checkout Routes
      GoRoute(
        path: RouteNames.checkout,
        builder: (context, state) {
          // Extract suggested delivery date from extra if provided
          DateTime? suggestedDate;
          if (state.extra is Map<String, dynamic>) {
            final extraMap = state.extra as Map<String, dynamic>;
            suggestedDate = extraMap['suggestedDeliveryDate'] as DateTime?;
          }
          return CheckoutScreen(suggestedDeliveryDate: suggestedDate);
        },
      ),
      GoRoute(
        path: RouteNames.paymentMethod,
        builder: (context, state) => const PaymentMethodScreen(),
      ),
      GoRoute(
        path: RouteNames.bankTransfer,
        builder: (context, state) => const BankTransferScreen(),
      ),
      GoRoute(
        path: RouteNames.receiptUpload,
        builder: (context, state) => const ReceiptUploadScreen(),
      ),

      // Order Detail
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
      ),

      // Profile Sub-screens
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.addresses,
        builder: (context, state) => const AddressesScreen(),
      ),
    ],
    redirect: (context, state) {
      // 1. Check if AuthProvider is initialized
      if (!authProvider.isInitialized) {
        return null; // Stay on Splash (initial location)
      }

      final isLoggedIn = authProvider.isAuthenticated;
      final location = state.uri.path;

      final isSplash = location == RouteNames.splash;
      final isLoggingIn = location == RouteNames.login;
      final isRegistering = location == RouteNames.register;
      final isRecoveringPassword = location == RouteNames.forgotPassword;

      // 2. If just initialized and still on Splash, render decision
      if (isSplash) {
        return isLoggedIn ? RouteNames.home : RouteNames.login;
      }

      // 3. Auth Guard
      if (!isLoggedIn) {
        // If not logged in and not on a public page, go to login
        if (!isLoggingIn && !isRegistering && !isRecoveringPassword) {
          return RouteNames.login;
        }
      } else {
        // If logged in and trying to access public pages, go to home
        if (isLoggingIn || isRegistering || isRecoveringPassword) {
          return RouteNames.home;
        }
      }

      return null;
    },
  );
}
