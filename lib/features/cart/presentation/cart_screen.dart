import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/auth_controller.dart';
import '../../products/data/product.dart';
import '../../products/data/product_providers.dart';
import '../data/cart_item.dart';
import '../data/cart_provider.dart';

String? cartItemWarning(CartItem item, List<Product> products) {
  final matchingProducts = products.where(
    (product) => product.id == item.productId,
  );
  if (matchingProducts.length != 1 || !matchingProducts.single.isActive) {
    return 'Product is no longer available.';
  }
  final sizes = matchingProducts.single.sizes.where(
    (size) => size.label == item.sizeLabel,
  );
  if (sizes.isEmpty) return 'Size is no longer available.';
  if (sizes.length != 1) {
    return 'Size cannot be verified because its label is duplicated.';
  }
  final size = sizes.single;
  final warnings = <String>[
    if (!size.isAvailable) 'Size is no longer available.',
    if (!size.price.isFinite || size.price <= 0)
      'Size has an invalid price.'
    else if (size.price != item.unitPrice)
      'Price changed from ${item.unitPrice} to ${size.price}. Remove and add this item again to use the current price.',
  ];
  return warnings.isEmpty ? null : warnings.join('\n');
}

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    ref.invalidate(cartProductCheckProvider);
  }

  Future<void> _perform(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error, stack) {
      debugPrint('Cart operation failed: $error\n$stack');
      if (!mounted) return;
      final message = error is CartException
          ? error.message
          : 'Could not save your cart. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<bool> _confirmClear() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear cart?'),
          content: const Text('Remove all items from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear cart'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final uid = auth.status == AuthStatus.customer
        ? auth.backend.currentUserId
        : null;
    if (uid == null) {
      return const Scaffold(body: LoadingView(message: 'Loading cart...'));
    }
    final cart = ref.watch(cartProvider(uid));
    final items = cart.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/products'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (items != null && items.isNotEmpty)
            TextButton(
              onPressed: () async {
                if (await _confirmClear() && mounted) {
                  await _perform(
                    () => ref.read(cartProvider(uid).notifier).clear(),
                  );
                }
              },
              child: const Text('Clear cart'),
            ),
        ],
      ),
      body: SafeArea(
        child: cart.when(
          loading: () => const LoadingView(message: 'Loading cart...'),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not load your saved cart. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Try again',
                    onPressed: () => ref.invalidate(cartProvider(uid)),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (await _confirmClear() && mounted) {
                        await _perform(() async {
                          await ref.read(cartStorageProvider).save(uid, []);
                          ref.invalidate(cartProvider(uid));
                        });
                      }
                    },
                    child: const Text('Clear saved cart'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'Your cart is empty',
                message: 'Add a product to get started.',
                icon: Icons.shopping_cart_outlined,
              );
            }
            final check = ref.watch(cartProductCheckProvider);
            final currentProducts = !check.isLoading && !check.hasError
                ? check.asData?.value
                : null;
            final subtotal = cartTotal(items);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (check.isLoading)
                      const Text(
                        'Checking current product availability and prices...',
                      )
                    else if (check.hasError)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Could not verify current product details: '
                            '${check.error}. Your cart may be out of date.',
                          ),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(cartProductCheckProvider),
                            child: const Text('Retry product check'),
                          ),
                        ],
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              ref.invalidate(cartProductCheckProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh product details'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    for (final item in items) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(item.sizeLabel),
                            Text(
                              'Unit: ${item.unitPrice}   Item subtotal: ${cartTotal([item])}',
                            ),
                            if (currentProducts != null &&
                                cartItemWarning(item, currentProducts) !=
                                    null) ...[
                              const SizedBox(height: 8),
                              Text(
                                cartItemWarning(item, currentProducts)!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Decrease quantity',
                                  onPressed: item.quantity <= 1
                                      ? null
                                      : () => _perform(
                                          () => ref
                                              .read(cartProvider(uid).notifier)
                                              .changeQuantity(
                                                item.productId,
                                                item.sizeLabel,
                                                -1,
                                              ),
                                        ),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  tooltip: 'Increase quantity',
                                  onPressed:
                                      item.quantity >= CartItem.maxQuantity
                                      ? null
                                      : () => _perform(
                                          () => ref
                                              .read(cartProvider(uid).notifier)
                                              .changeQuantity(
                                                item.productId,
                                                item.sizeLabel,
                                                1,
                                              ),
                                        ),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Remove item',
                                  onPressed: () => _perform(
                                    () => ref
                                        .read(cartProvider(uid).notifier)
                                        .remove(item.productId, item.sizeLabel),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Subtotal: $subtotal',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text('Subtotal uses the prices saved in your cart.'),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Checkout',
                      onPressed: () => context.push('/checkout'),
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
