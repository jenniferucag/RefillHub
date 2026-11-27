import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_view.dart';
import '../data/business_info_providers.dart';

class HowToOrderScreen extends ConsumerWidget {
  const HowToOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessInfoAsync = ref.watch(businessInfoStreamProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('How to Order')),
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
                    Text(
                      businessInfo.about.isEmpty
                          ? 'Not yet provided'
                          : businessInfo.about,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (businessInfo.orderingGuideSteps.isNotEmpty) ...[
                      Text(
                        'Steps to Order',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _OrderingStepsList(
                        steps: businessInfo.orderingGuideSteps,
                      ),
                      const SizedBox(height: 28),
                    ] else ...[
                      Text(
                        'Not yet provided',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/products'),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Start Ordering'),
                      ),
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
}

class _OrderingStepsList extends StatelessWidget {
  const _OrderingStepsList({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final stepNumber = index + 1;
        final step = steps[index];
        return _OrderingStepCard(stepNumber: stepNumber, step: step);
      },
    );
  }
}

class _OrderingStepCard extends StatelessWidget {
  const _OrderingStepCard({required this.stepNumber, required this.step});

  final int stepNumber;
  final String step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  stepNumber.toString(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step $stepNumber',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(step, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
