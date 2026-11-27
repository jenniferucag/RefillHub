import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';
import '../data/cart_provider.dart';

class CartButton extends ConsumerWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = AuthScope.of(context);
    final uid = auth.status == AuthStatus.customer
        ? auth.backend.currentUserId
        : null;
    if (uid == null) return const SizedBox.shrink();
    final cart = ref.watch(cartProvider(uid));
    final count =
        cart.asData?.value.fold<int>(0, (sum, item) => sum + item.quantity) ??
        0;
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => context.push('/cart'),
      icon: Badge(
        isLabelVisible: count > 0 || cart.hasError,
        label: Text(
          cart.hasError
              ? '!'
              : count > 99
              ? '99+'
              : '$count',
        ),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
