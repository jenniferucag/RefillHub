import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({required this.child, super.key});

  final Widget child;

  static const narrowBreakpoint = 840.0;

  static const _destinations = [
    _AdminDestination(
      'Dashboard',
      '/admin/dashboard',
      Icons.dashboard_outlined,
    ),
    _AdminDestination('Products', '/admin/products', Icons.water_drop_outlined),
    _AdminDestination('Customers', '/admin/customers', Icons.people_outline),
    _AdminDestination('Orders', '/admin/orders', Icons.receipt_long_outlined),
    _AdminDestination(
      'Delivery',
      '/admin/delivery',
      Icons.local_shipping_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < narrowBreakpoint;
        final currentPath = GoRouterState.of(context).uri.path;
        final selectedIndex = _destinations.indexWhere(
          (destination) => destination.path == currentPath,
        );
        final title = selectedIndex < 0
            ? 'Dashboard'
            : _destinations[selectedIndex].label;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text('Admin · $title'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.water_drop_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          drawer: isNarrow
              ? Drawer(
                  child: SafeArea(
                    child: _AdminDrawer(
                      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!isNarrow) ...[
                NavigationRail(
                  selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (index) {
                    context.go(_destinations[index].path);
                  },
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              ],
              Expanded(
                child: Column(
                  children: [
                    const _PrototypeNotice(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrototypeNotice extends StatelessWidget {
  const _PrototypeNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: scheme.onSecondaryContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Prototype only · No authentication or authorization is connected. Admin routes are not access-protected.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.water_drop_outlined, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('RefillHub', style: theme.textTheme.titleLarge),
              Text(
                'Admin demo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        for (var index = 0; index < AdminShell._destinations.length; index++)
          _DrawerDestinationTile(
            destination: AdminShell._destinations[index],
            selected: index == selectedIndex,
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Prototype only · navigation does not secure access',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerDestinationTile extends StatelessWidget {
  const _DrawerDestinationTile({
    required this.destination,
    required this.selected,
  });

  final _AdminDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(destination.icon),
      title: Text(destination.label),
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        context.go(destination.path);
      },
    );
  }
}

class _AdminDestination {
  const _AdminDestination(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;
}
