import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Products preview', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Product catalogue and details are not yet provided.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Preview only. Search is not functional while catalogue data is unavailable.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              const TextField(
                key: ValueKey('products-search'),
                decoration: InputDecoration(
                  labelText: 'Search preview (not functional)',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              const AppCard(
                child: Text('The product catalogue is not yet provided.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
