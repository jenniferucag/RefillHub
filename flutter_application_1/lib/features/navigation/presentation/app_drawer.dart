import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const _informationLinks = [
    _NavigationLink(
      'How to Order',
      '/info/how-to-order',
      Icons.shopping_bag_outlined,
    ),
    _NavigationLink(
      'Delivery Information',
      '/info/delivery-information',
      Icons.local_shipping_outlined,
    ),
    _NavigationLink(
      'About & Contact',
      '/info/about-contact',
      Icons.info_outline,
    ),
    _NavigationLink('Pricing', '/info/pricing', Icons.payments_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 32,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'RefillHub',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Information & Support',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Information',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (final link in _informationLinks) _NavigationTile(link: link),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({required this.link});

  final _NavigationLink link;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(link.icon),
      title: Text(link.title),
      onTap: () {
        context.pop();
        context.push(link.route);
      },
    );
  }
}

class _NavigationLink {
  const _NavigationLink(this.title, this.route, this.icon);

  final String title;
  final String route;
  final IconData icon;
}
