import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_logo.dart';
import '../../auth/presentation/sign_out_confirmation.dart';
import '../../cart/presentation/cart_button.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _ShellDestination('Home', Icons.home_outlined, Icons.home),
    _ShellDestination('Products', Icons.water_drop_outlined, Icons.water_drop),
    _ShellDestination(
      'My Orders',
      Icons.receipt_long_outlined,
      Icons.receipt_long,
    ),
    _ShellDestination('Profile', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _destinations[navigationShell.currentIndex].label;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (navigationShell.currentIndex == 0)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: AppLogo(size: 36),
            ),
          const CartButton(),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => confirmSignOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: theme.colorScheme.surface,
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
