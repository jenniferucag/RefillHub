import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/auth_controller.dart';
import '../../products/data/product.dart';
import '../../products/data/product_providers.dart';
import '../../products/presentation/product_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
    final profile = AuthScope.of(context).profile?.data;
    final storedFullName = profile?['fullName'];
    final fullName = storedFullName is String && storedFullName.isNotEmpty
        ? storedFullName
        : null;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _WelcomeBanner(fullName: fullName),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 490,
                    child: _QuickOrderCard(
                      title: 'Refill my container',
                      subtitle: 'Have your container collected and refilled.',
                      icon: Icons.recycling_outlined,
                      onTap: () => context.push('/refill'),
                    ),
                  ),
                  SizedBox(
                    width: 490,
                    child: _QuickOrderCard(
                      title: 'Buy water',
                      subtitle: 'Choose water products and delivery details.',
                      icon: Icons.shopping_bag_outlined,
                      onTap: () => context.go('/products'),
                    ),
                  ),
                ],
              ),
              const _AvailableWaterSection(),
              const SectionHeader(
                title: 'Helpful information',
                subtitle: 'View pricing and other information.',
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
  const _WelcomeBanner({required this.fullName});

  final String? fullName;

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
                          fullName == null ? 'Hello' : 'Hello, $fullName',
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
  const _QuickOrderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          title,
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
                icon,
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

class _AvailableWaterSection extends ConsumerWidget {
  const _AvailableWaterSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(activeProductsProvider);
    return products.when(
      loading: () => const _AvailableWaterLoading(),
      error: (error, stack) {
        debugPrint('Home available products stream failed: $error');
        return _AvailableWaterError(
          message: 'Could not load available water: $error',
          onRetry: () => ref.invalidate(activeProductsProvider),
        );
      },
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return _AvailableWaterProducts(products: items.take(4).toList());
      },
    );
  }
}

class _AvailableWaterLoading extends StatelessWidget {
  const _AvailableWaterLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Available water'),
        SizedBox(height: 12),
        SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
        SizedBox(height: 28),
      ],
    );
  }
}

class _AvailableWaterError extends StatelessWidget {
  const _AvailableWaterError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Available water'),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ErrorView(message: message, onRetry: onRetry),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _AvailableWaterProducts extends StatelessWidget {
  const _AvailableWaterProducts({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Available water'),
        const SizedBox(height: 12),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              final lowestPrice = _lowestAvailablePrice(product);
              return SizedBox(
                width: 204,
                child: AppCard(
                  onTap: () => context.push(
                    '/products/${Uri.encodeComponent(product.id)}',
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductImage(
                        imageUrl: product.imageUrl,
                        imageBytes: product.imageBytes,
                        size: 54,
                      ),
                      const Spacer(),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Water type: ${product.waterType}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lowestPrice == null
                            ? 'No available sizes'
                            : 'Lowest size: ₱$lowestPrice',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

num? _lowestAvailablePrice(Product product) {
  num? lowest;
  for (final size in product.sizes) {
    if (!size.isAvailable) continue;
    if (lowest == null || size.price < lowest) lowest = size.price;
  }
  return lowest;
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
