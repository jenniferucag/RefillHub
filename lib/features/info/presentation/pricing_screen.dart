import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../products/data/product_providers.dart';
import '../../cart/presentation/cart_button.dart';

class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(activeProductsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing'),
        actions: const [CartButton()],
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: products.when(
          loading: () => const LoadingView(message: 'Loading products...'),
          error: (error, stack) => ErrorView(
            message: 'Could not load products: $error',
            onRetry: () => ref.invalidate(activeProductsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'No prices available yet',
                message: 'Please check back later.',
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Size')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Availability')),
                  ],
                  rows: [
                    for (final product in items)
                      if (product.sizes.isEmpty)
                        DataRow(
                          cells: [
                            DataCell(Text(product.name)),
                            const DataCell(Text('No sizes available')),
                            const DataCell(Text('-')),
                            const DataCell(Text('-')),
                          ],
                        )
                      else
                        for (final size in product.sizes)
                          DataRow(
                            cells: [
                              DataCell(Text(product.name)),
                              DataCell(Text(size.label)),
                              DataCell(Text('${size.price}')),
                              DataCell(
                                Text(
                                  size.isAvailable
                                      ? 'Available'
                                      : 'Unavailable',
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
