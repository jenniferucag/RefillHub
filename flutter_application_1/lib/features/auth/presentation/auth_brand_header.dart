import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markSize = compact ? 48.0 : 88.0;
    return Column(
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.water_drop_rounded,
            size: compact ? 28 : 48,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: compact ? 10 : 16),
        Text('RefillHub', style: theme.textTheme.titleLarge),
        if (!compact) ...[
          const SizedBox(height: 6),
          Text(
            'Water, well delivered.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
