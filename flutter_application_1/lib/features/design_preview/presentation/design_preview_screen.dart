import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';

class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('RefillHub · Design preview')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              const _BrandBanner(),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Color palette',
                subtitle: 'Shared tokens for water, surface, and feedback.',
              ),
              const SizedBox(height: 12),
              const _PalettePreview(),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Typography scale',
                subtitle: 'Manrope · Google Fonts · Material 3 light',
              ),
              const SizedBox(height: 12),
              const _TypographyPreview(),
              const SizedBox(height: 32),
              const SectionHeader(
                title: 'Buttons',
                subtitle: 'Primary, secondary, text, and loading states.',
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppButton(label: 'Primary action', onPressed: _noop),
                    AppButton(
                      label: 'Secondary',
                      onPressed: _noop,
                      variant: AppButtonVariant.secondary,
                    ),
                    AppButton(
                      label: 'Text action',
                      onPressed: _noop,
                      variant: AppButtonVariant.text,
                    ),
                    AppButton(
                      label: 'Please wait',
                      onPressed: _noop,
                      isLoading: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Text fields',
                subtitle: 'Labels, validation, and password visibility.',
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    const AppTextField(
                      label: 'Email address',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.lock_outline,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter a password'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Order statuses',
                subtitle: 'The six supported status styles.',
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: OrderStatus.values
                      .map((status) => StatusChip(status: status))
                      .toList(),
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Cards and feedback',
                subtitle: 'Reusable surfaces for content and system states.',
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AppCard', style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'A calm, bordered surface that follows the app theme.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const AppCard(
                child: EmptyState(
                  title: 'Nothing here yet',
                  message: 'A helpful explanation can guide the next step.',
                  icon: Icons.water_drop_outlined,
                ),
              ),
              const SizedBox(height: 12),
              const AppCard(
                child: SizedBox(
                  height: 128,
                  child: LoadingView(message: 'Loading your information'),
                ),
              ),
              const SizedBox(height: 12),
              const AppCard(
                child: SizedBox(
                  height: 180,
                  child: ErrorView(
                    message: 'This information could not be loaded.',
                    onRetry: _noop,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _noop() {}
}

class _BrandBanner extends StatelessWidget {
  const _BrandBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: scheme.primary,
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -56,
              child: ExcludeSemantics(
                child: Container(
                  width: 184,
                  height: 184,
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 46,
              bottom: -82,
              child: ExcludeSemantics(
                child: Container(
                  width: 142,
                  height: 142,
                  decoration: BoxDecoration(
                    color: scheme.onPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.water_drop_outlined, color: scheme.onPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'REFILLHUB  /  DESIGN SYSTEM',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimary.withValues(alpha: 0.82),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Shared UI, clear by design.',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Text(
                      'A calm, consistent visual language for every RefillHub screen.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview();

  static const _tokens = [
    _ColorToken('Primary blue', AppColors.primary),
    _ColorToken('Aqua accent', AppColors.aqua),
    _ColorToken('Cool canvas', AppColors.background),
    _ColorToken('Surface', AppColors.surface),
    _ColorToken('Ink', AppColors.onSurface),
    _ColorToken('Muted text', AppColors.onSurfaceVariant),
    _ColorToken('Success', AppColors.success),
    _ColorToken('Error', AppColors.error),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: _tokens
              .map(
                (token) => SizedBox(
                  width: itemWidth,
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: token.color,
                            borderRadius: BorderRadius.circular(10),
                            border: token.color == AppColors.surface
                                ? Border.all(color: AppColors.outline)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          token.name,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          token.hex,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ColorToken {
  const _ColorToken(this.name, this.color);

  final String name;
  final Color color;

  String get hex =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

class _TypographyPreview extends StatelessWidget {
  const _TypographyPreview();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final samples = [
      _TypeSample('Display', textTheme.displaySmall, 'Water, well designed.'),
      _TypeSample('Headline', textTheme.headlineMedium, 'A clear next step'),
      _TypeSample('Title', textTheme.titleLarge, 'Order details'),
      _TypeSample(
        'Body',
        textTheme.bodyLarge,
        'A readable message for every screen.',
      ),
      _TypeSample('Label', textTheme.labelLarge, 'PRIMARY ACTION'),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manrope',
            style: textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          for (var index = 0; index < samples.length; index++) ...[
            if (index > 0) const Divider(height: 24),
            _TypographyRow(sample: samples[index]),
          ],
        ],
      ),
    );
  }
}

class _TypographyRow extends StatelessWidget {
  const _TypographyRow({required this.sample});

  final _TypeSample sample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${sample.name} · ${sample.style?.fontSize?.toInt()} px',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(sample.example, style: sample.style),
      ],
    );
  }
}

class _TypeSample {
  const _TypeSample(this.name, this.style, this.example);

  final String name;
  final TextStyle? style;
  final String example;
}
