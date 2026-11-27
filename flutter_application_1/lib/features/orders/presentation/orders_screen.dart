import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => const SafeArea(
    child: EmptyState(
      title: 'No orders to show',
      message: 'Order history is not yet provided.',
      icon: Icons.receipt_long_outlined,
    ),
  );
}
