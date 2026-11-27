import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../data/business_info_providers.dart';

class DeliveryInformationScreen extends ConsumerWidget {
  const DeliveryInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessInfoAsync = ref.watch(businessInfoStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Information')),
      body: businessInfoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(
          message: 'Error loading information: $error',
          onRetry: () => ref.invalidate(businessInfoStreamProvider),
        ),
        data: (businessInfo) {
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  children: [
                    _buildSection(
                      context,
                      icon: Icons.schedule_outlined,
                      title: 'Operating Hours',
                      content: businessInfo.operatingHours,
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      icon: Icons.map_outlined,
                      title: 'Delivery Coverage',
                      content: businessInfo.deliveryCoverage,
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      icon: Icons.local_shipping_outlined,
                      title: 'Delivery Policy',
                      content: businessInfo.deliveryPolicy,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isEmpty = content.isEmpty;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isEmpty ? 'Not yet provided' : content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
