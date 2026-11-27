import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/auth_controller.dart';
import '../../cart/data/cart_provider.dart';
import '../../cart/presentation/cart_button.dart';
import '../data/product.dart';
import '../data/product_providers.dart';
import 'product_image.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  ProductSize? _selected;
  int? _selectedIndex;
  bool _adding = false;

  Future<void> _add(String uid, Product product, ProductSize size) async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      await ref.read(cartProvider(uid).notifier).add(product, size);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to cart.')));
    } catch (error, stack) {
      debugPrint('Add to cart failed: $error\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is CartException
                ? error.message
                : 'Could not save your cart. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  void didUpdateWidget(ProductDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _selected = null;
      _selectedIndex = null;
    }
  }

  bool _isSelected(int index, ProductSize size) =>
      size.isAvailable &&
      index == _selectedIndex &&
      _selected != null &&
      size.label == _selected!.label &&
      size.price == _selected!.price;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(activeProductsProvider);
    final auth = AuthScope.of(context);
    final uid = auth.status == AuthStatus.customer
        ? auth.backend.currentUserId
        : null;
    final cart = uid == null ? null : ref.watch(cartProvider(uid));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: const [CartButton()],
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/products');
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
            Product? product;
            for (final item in items) {
              if (item.id == widget.productId) {
                product = item;
                break;
              }
            }
            if (product == null) {
              return const Center(
                child: Text('This product is no longer available.'),
              );
            }
            final index = _selectedIndex;
            final hasSelection =
                index != null &&
                index < product.sizes.length &&
                _isSelected(index, product.sizes[index]);
            final ambiguous =
                hasSelection &&
                product.sizes
                        .where((size) => size.label == _selected!.label)
                        .length !=
                    1;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ProductImage(
                        imageUrl: product.imageUrl,
                        imageBytes: product.imageBytes,
                        size: 128,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Water type: ${product.waterType}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(product.description),
                    const SizedBox(height: 24),
                    Text(
                      'Sizes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (product.sizes.isEmpty)
                      const Text('No sizes available.')
                    else
                      for (var index = 0; index < product.sizes.length; index++)
                        ListTile(
                          title: Text(product.sizes[index].label),
                          subtitle: Text(
                            'Price: ${product.sizes[index].price}',
                          ),
                          enabled: product.sizes[index].isAvailable,
                          selected: _isSelected(index, product.sizes[index]),
                          trailing: product.sizes[index].isAvailable
                              ? (_isSelected(index, product.sizes[index])
                                    ? const Icon(Icons.check_circle)
                                    : null)
                              : const Text('Unavailable'),
                          onTap: product.sizes[index].isAvailable
                              ? () => setState(() {
                                  _selectedIndex = index;
                                  _selected = product!.sizes[index];
                                })
                              : null,
                        ),
                    const SizedBox(height: 20),
                    if (ambiguous)
                      const Text(
                        'This size cannot be added because its label is duplicated.',
                      ),
                    if (cart?.hasError == true)
                      const Text(
                        'Could not load your cart. Open it to try again.',
                      ),
                    AppButton(
                      label: 'Add to cart',
                      isLoading: _adding,
                      onPressed:
                          hasSelection &&
                              !ambiguous &&
                              uid != null &&
                              cart?.asData != null
                          ? () => _add(uid, product!, _selected!)
                          : null,
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
