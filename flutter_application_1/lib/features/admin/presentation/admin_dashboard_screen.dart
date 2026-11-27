import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const _summary = [
    _SummaryMetric('Total Orders', '248', Icons.receipt_long_outlined),
    _SummaryMetric('Pending', '18', Icons.schedule_outlined),
    _SummaryMetric('In Progress', '12', Icons.local_shipping_outlined),
    _SummaryMetric('Delivered', '218', Icons.task_alt_outlined),
    _SummaryMetric("Today's Orders", '24', Icons.today_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Operations overview',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'A quick view of order activity for your team.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: scheme.onSecondaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sample data · not live. These demo numbers are illustrative only and are not connected to actual orders.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 14.0;
                  final columns = (constraints.maxWidth / 220).floor().clamp(
                    1,
                    _summary.length,
                  );
                  final cardWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final metric in _summary)
                        SizedBox(
                          width: cardWidth,
                          child: _MetricCard(metric: metric),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prototype workspace',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Admin navigation is a front-end preview and does not enforce authorization. Operational data and connected workflows have not been provided.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _SummaryMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: scheme.primary),
          const SizedBox(height: 18),
          Text(metric.label, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(metric.value, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Sample data · not live',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric {
  const _SummaryMetric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}
