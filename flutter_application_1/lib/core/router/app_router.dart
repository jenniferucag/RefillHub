import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/admin/presentation/admin_placeholder_screen.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/admin_business_info_screen.dart';
import '../../features/design_preview/presentation/design_preview_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/navigation/presentation/customer_shell.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/info/presentation/info_screen.dart';
import '../../features/info/presentation/business_info_screen.dart';
import '../../features/info/presentation/how_to_order_screen.dart';
import '../../features/info/presentation/delivery_information_screen.dart';

GoRouter createAppRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/admin', redirect: (context, state) => '/admin/login'),
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
          builder: (context, state) =>
              const AdminPlaceholderScreen(section: 'Products'),
        ),
        GoRoute(
          path: '/admin/customers',
          builder: (context, state) =>
              const AdminPlaceholderScreen(section: 'Customers'),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) =>
              const AdminPlaceholderScreen(section: 'Orders'),
        ),
        GoRoute(
          path: '/admin/delivery',
          builder: (context, state) =>
              const AdminPlaceholderScreen(section: 'Delivery'),
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
    GoRoute(
      path: '/info/pricing',
      builder: (context, state) => const InfoScreen(title: 'Pricing'),
    ),
    GoRoute(
      path: '/info/how-to-order',
      builder: (context, state) => const HowToOrderScreen(),
    ),
    GoRoute(
      path: '/info/delivery-information',
      builder: (context, state) => const DeliveryInformationScreen(),
    ),
    GoRoute(
      path: '/info/about-contact',
      builder: (context, state) => const BusinessInfoScreen(),
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

final GoRouter appRouter = createAppRouter();
