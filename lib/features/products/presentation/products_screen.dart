import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/product_providers.dart';
import 'product_image.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _search = TextEditingController();
  String? _selectedWaterType;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(activeProductsProvider);
    final waterTypes =
        (products.asData?.value ?? const [])
            .map((product) => product.waterType)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final query = _search.text.trim().toLowerCase();
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/refill'),
                            icon: const Icon(Icons.recycling_outlined),
                            label: const Text('Refill my container'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.push('/cart'),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Buy water'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('products-search'),
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Search products',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final type in <String?>[null, ...waterTypes])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  type == null
                                      ? 'All'
                                      : type == 'All'
                                      ? 'All (water type)'
                                      : type,
                                ),
                                selected: _selectedWaterType == type,
                                onSelected: (selected) => setState(
                                  () => _selectedWaterType = selected
                                      ? type
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: products.when(
                  loading: () =>
                      const LoadingView(message: 'Loading products...'),
                  error: (error, stack) => ErrorView(
                    message: 'Could not load products: $error',
                    onRetry: () => ref.invalidate(activeProductsProvider),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return EmptyState(
                        title: _selectedWaterType == null
                            ? 'No products available yet'
                            : 'No products available for this type',
                        message: _selectedWaterType == null
                            ? 'Please check back later.'
                            : 'Choose another water type.',
                      );
                    }
                    final typedItems = _selectedWaterType == null
                        ? items
                        : items
                              .where(
                                (product) =>
                                    product.waterType == _selectedWaterType,
                              )
                              .toList();
                    if (typedItems.isEmpty) {
                      return const EmptyState(
                        title: 'No products available for this type',
                        message: 'Choose another water type.',
                      );
                    }
                    final filtered = typedItems
                        .where(
                          (product) =>
                              product.name.toLowerCase().contains(query) ||
                              product.description.toLowerCase().contains(
                                query,
                              ) ||
                              product.waterType.toLowerCase().contains(query),
                        )
                        .toList();
                    if (filtered.isEmpty) {
                      return const EmptyState(
                        title: 'No products match your search.',
                        message: 'Try a different search.',
                        icon: Icons.search_off,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return AppCard(
                          onTap: () => context.push(
                            '/products/${Uri.encodeComponent(product.id)}',
                          ),
                          child: Row(
                            children: [
                              ProductImage(
                                imageUrl: product.imageUrl,
                                imageBytes: product.imageBytes,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
