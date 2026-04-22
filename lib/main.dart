import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

import 'data/repositories/abstract/order_repository.dart';
import 'data/repositories/api_repo.dart/api_order_repository.dart';
import 'data/repositories/api_repo.dart/api_auth_repository.dart';
import 'data/repositories/api_repo.dart/api_product_repository.dart';
import 'data/repositories/api_repo.dart/api_cart_repository.dart';

// Providers
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/order_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/navigation_provider.dart';
import 'presentation/providers/favorites_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const DaishinOrderApp());
}

class DaishinOrderApp extends StatelessWidget {
  const DaishinOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme Provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Repositories
        Provider(create: (_) => ApiAuthRepository()),

        // Providers
        ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(context.read<ApiAuthRepository>())..initialize(),
        ),

        // Product Repository needs AuthProvider
        ProxyProvider<AuthProvider, ApiProductRepository>(
          update: (_, auth, __) => ApiProductRepository(auth),
        ),

        // Use ApiOrderRepository
        ProxyProvider<AuthProvider, OrderRepository>(
          update: (context, authProvider, _) =>
              ApiOrderRepository(authProvider),
        ),

        // ApiCartRepository needs AuthProvider
        ProxyProvider<AuthProvider, ApiCartRepository>(
          update: (context, authProvider, _) => ApiCartRepository(authProvider),
        ),

        ChangeNotifierProvider(
          create: (context) =>
              ProductProvider(context.read<ApiProductRepository>())
                ..loadProducts()
                ..loadCategories(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CartProvider(context.read<ApiCartRepository>())..loadCart(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              // Cast to OrderRepository to be safe or ensure it finds the Provider<OrderRepository>
              OrderProvider(context.read<OrderRepository>())..loadOrders(),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
            create: (context) =>
                FavoritesProvider(context.read<ApiProductRepository>())),
      ],
      child: const DaishinAppView(),
    );
  }
}

class DaishinAppView extends StatefulWidget {
  const DaishinAppView({super.key});

  @override
  State<DaishinAppView> createState() => _DaishinAppViewState();
}

class _DaishinAppViewState extends State<DaishinAppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Initialize Router with AuthProvider to handle redirects
    final authProvider = context.read<AuthProvider>();
    _router = AppRouter(authProvider).router;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          key: const ValueKey('main_app'),
          title: 'DAISHIN Order System',
          debugShowCheckedModeBanner: false,
          // Theme Configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          themeAnimationDuration: Duration.zero,

          // Router Configuration
          routerConfig: _router,
        );
      },
    );
  }
}
