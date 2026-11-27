import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_business_info_screen.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/admin/presentation/admin_products_screen.dart';
import '../../features/admin/presentation/admin_delivery_management_screen.dart';
import '../../features/orders/presentation/admin_orders_list_screen.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/customers/presentation/admin_customer_management_screen.dart';
import '../../features/design_preview/presentation/design_preview_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/navigation/presentation/customer_shell.dart';
import '../../features/orders/data/order.dart';
import '../../features/orders/presentation/order_confirmation_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/refill_order_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/products/presentation/product_details_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/info/presentation/info_screen.dart';
import '../../features/info/presentation/pricing_screen.dart';

String? authRedirect(AuthStatus status, Uri location) {
  final path = location.path;
  if (status == AuthStatus.loading) {
    return path == '/auth-loading'
        ? null
        : Uri(
            path: '/auth-loading',
            queryParameters: {'from': location.toString()},
          ).toString();
  }
  if (path == '/auth-loading') {
    final from = location.queryParameters['from'];
    final uri = from == null ? null : Uri.tryParse(from);
    if (uri != null &&
        !uri.hasScheme &&
        !uri.hasAuthority &&
        uri.path.startsWith('/') &&
        uri.path != '/auth-loading') {
      return uri.toString();
    }
    return '/login';
  }
  if (status == AuthStatus.signedOut) {
    return path == '/' ||
            path == '/login' ||
            path == '/register' ||
            path == '/admin/login'
        ? null
        : '/login';
  }
  final isAdminPath = path == '/admin' || path.startsWith('/admin/');
  if (status == AuthStatus.admin) {
    return isAdminPath && path != '/admin/login' ? null : '/admin/dashboard';
  }
  const customerPaths = {
    '/home',
    '/products',
    '/orders',
    '/order-confirmation',
    '/profile',
    '/cart',
    '/checkout',
    '/refill',
    '/info/pricing',
    '/info/how-to-order',
    '/info/delivery-information',
    '/info/about-contact',
  };
  final segments = location.pathSegments;
  final isProductDetails =
      segments.length == 2 &&
      segments[0] == 'products' &&
      segments[1].isNotEmpty &&
      !segments[1].contains('/');
  return customerPaths.contains(path) || isProductDetails ? null : '/home';
}

GoRouter createAppRouter({
  required AuthController auth,
  String initialLocation = '/',
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: auth,
  redirect: (context, state) => authRedirect(auth.status, state.uri),
  routes: [
    GoRoute(
      path: '/auth-loading',
      builder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(auth.message ?? 'Checking your account...'),
            ],
          ),
        ),
      ),
    ),
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/admin', redirect: (context, state) => '/admin/dashboard'),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/products',
          builder: (context, state) => const AdminProductsScreen(),
        ),
        GoRoute(
          path: '/admin/customers',
          builder: (context, state) => const AdminCustomerManagementScreen(),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const AdminOrdersListScreen(),
        ),
        GoRoute(
          path: '/admin/delivery',
          builder: (context, state) => const AdminDeliveryManagementScreen(),
        ),
        GoRoute(
          path: '/admin/business-info',
          builder: (context, state) => const AdminBusinessInfoScreen(),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          CustomerShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/products',
              builder: (context, state) => const ProductsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/refill',
      builder: (context, state) => const RefillOrderScreen(),
    ),
    GoRoute(
      path: '/order-confirmation',
      builder: (context, state) {
        final order = state.extra as CustomerOrder?;
        if (order == null) {
          return const Scaffold(
            body: Center(child: Text('Order information not found')),
          );
        }
        return OrderConfirmationScreen(order: order);
      },
    ),
    GoRoute(
      path: '/products/:productId',
      builder: (context, state) =>
          ProductDetailsScreen(productId: state.pathParameters['productId']!),
    ),
    GoRoute(
      path: '/info/pricing',
      builder: (context, state) => const PricingScreen(),
    ),
    GoRoute(
      path: '/info/how-to-order',
      builder: (context, state) =>
          const InfoScreen(type: InfoScreenType.howToOrder),
    ),
    GoRoute(
      path: '/info/delivery-information',
      builder: (context, state) =>
          const InfoScreen(type: InfoScreenType.deliveryInformation),
    ),
    GoRoute(
      path: '/info/about-contact',
      builder: (context, state) =>
          const InfoScreen(type: InfoScreenType.aboutContact),
    ),
    GoRoute(
      path: '/design-preview',
      builder: (context, state) => const DesignPreviewScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        state.error?.toString() ?? 'The requested page could not be found.',
      ),
    ),
  ),
);
