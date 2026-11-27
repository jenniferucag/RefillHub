import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _sampleProducts = [
    'Sample product A',
    'Sample product B',
    'Sample product C',
  ];

  static const _informationLinks = [
    _InformationLink('Pricing', '/info/pricing', Icons.payments_outlined),
    _InformationLink(
      'How to Order',
      '/info/how-to-order',
      Icons.shopping_bag_outlined,
    ),
    _InformationLink(
      'Delivery Information',
      '/info/delivery-information',
      Icons.local_shipping_outlined,
    ),
    _InformationLink(
      'About/Contact',
      '/info/about-contact',
      Icons.info_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              const _WelcomeBanner(),
              const SizedBox(height: 24),
              _QuickOrderCard(onTap: () => context.go('/products')),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Featured product samples',
                subtitle: 'Sample-only · product details not yet provided',
                action: TextButton(
                  onPressed: () => context.go('/products'),
                  child: const Text('Preview'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 164,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sampleProducts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: 204,
                    child: _SampleProductCard(name: _sampleProducts[index]),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Helpful information',
                subtitle:
                    'Pricing, ordering, delivery and contact details are not yet provided.',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  final columns = (constraints.maxWidth / 220).floor().clamp(
                    1,
                    _informationLinks.length,
                  );
                  final cardWidth =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final link in _informationLinks)
                        SizedBox(
                          width: cardWidth,
                          child: _InformationCard(link: link),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: scheme.secondaryContainer,
        child: Stack(
          children: [
            Positioned(
              right: -32,
              top: -58,
              child: ExcludeSemantics(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: -62,
              child: ExcludeSemantics(
                child: Container(
                  width: 122,
                  height: 122,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.secondary.withValues(alpha: 0.24),
                      width: 16,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello there',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome to RefillHub',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.water_drop_outlined,
                    size: 52,
                    color: scheme.primary.withValues(alpha: 0.72),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickOrderCard extends StatelessWidget {
  const _QuickOrderCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Order',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The sample catalogue and product details are not yet provided.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'Open Products preview',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: scheme.onPrimary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.water_drop_outlined,
                size: 42,
                color: scheme.onPrimary.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SampleProductCard extends StatelessWidget {
  const _SampleProductCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.water_drop_outlined,
            color: theme.colorScheme.primary,
            size: 26,
          ),
          const Spacer(),
          Text(name, style: theme.textTheme.titleSmall),
          const SizedBox(height: 3),
          Text(
            'Sample only · details not yet provided',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.link});

  final _InformationLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => context.push(link.route),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(link.icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(link.title, style: theme.textTheme.titleSmall)),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _InformationLink {
  const _InformationLink(this.title, this.route, this.icon);

  final String title;
  final String route;
  final IconData icon;
}
