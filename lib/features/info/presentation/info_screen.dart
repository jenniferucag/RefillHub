import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../cart/presentation/cart_button.dart';
import '../data/business_info.dart';
import '../data/business_info_providers.dart';

enum InfoScreenType { howToOrder, deliveryInformation, aboutContact }

class InfoScreen extends ConsumerWidget {
  const InfoScreen({required this.type, super.key});

  final InfoScreenType type;

  static const _defaultOrderingSteps = [
    'Choose "Refill my container" or "Buy water".',
    'Pick the water type, container size and quantity.',
    'Choose your requested pickup and delivery date and time (the station will confirm your schedule).',
    'Check your address and place the order, payment is Cash on Delivery.',
    'Track your order status under My Orders.',
  ];

  String get _title => switch (type) {
    InfoScreenType.howToOrder => 'How to Order',
    InfoScreenType.deliveryInformation => 'Delivery Information',
    InfoScreenType.aboutContact => 'About/Contact',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessInfo = ref.watch(businessInfoProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: const [CartButton()],
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: businessInfo.when(
          loading: () =>
              const LoadingView(message: 'Loading business information...'),
          error: (error, stack) => ErrorView(
            message:
                'Could not load business information: '
                '${businessInfoErrorMessage(error)}',
            retryLabel: 'Retry',
            onRetry: () => ref.invalidate(businessInfoProvider),
          ),
          data: (info) => _buildContent(context, info),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BusinessInfo info) {
    final theme = Theme.of(context);
    final content = switch (type) {
      InfoScreenType.howToOrder => _howToOrder(context, info, theme),
      InfoScreenType.deliveryInformation => _deliveryInformation(
        context,
        info,
        theme,
      ),
      InfoScreenType.aboutContact => _aboutContact(context, info, theme),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(padding: const EdgeInsets.all(20), children: content),
      ),
    );
  }

  List<Widget> _howToOrder(
    BuildContext context,
    BusinessInfo info,
    ThemeData theme,
  ) {
    final steps = info.orderingGuideSteps.isEmpty
        ? _defaultOrderingSteps
        : info.orderingGuideSteps;
    return [
      for (var index = 0; index < steps.length; index++) ...[
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: Text('${index + 1}'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(steps[index], style: theme.textTheme.bodyLarge),
                ),
              ),
            ],
          ),
        ),
        if (index != steps.length - 1) const SizedBox(height: 10),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => context.go('/home'),
        icon: const Icon(Icons.shopping_bag_outlined),
        label: const Text('Start ordering'),
      ),
    ];
  }

  List<Widget> _deliveryInformation(
    BuildContext context,
    BusinessInfo info,
    ThemeData theme,
  ) => [
    _InfoSection(
      title: 'Delivery Coverage',
      value: info.deliveryCoverage,
      theme: theme,
    ),
    const SizedBox(height: 12),
    _InfoSection(
      title: 'Delivery Policy',
      value: info.deliveryPolicy,
      theme: theme,
    ),
    const SizedBox(height: 12),
    _InfoSection(
      title: 'Operating Hours',
      value: info.operatingHours,
      theme: theme,
    ),
    const SizedBox(height: 12),
    _InfoSection(
      title: 'Schedule Notes',
      value: info.scheduleNotes,
      theme: theme,
    ),
  ];

  List<Widget> _aboutContact(
    BuildContext context,
    BusinessInfo info,
    ThemeData theme,
  ) => [
    _InfoSection(
      title: 'Business Name',
      value: info.businessName,
      theme: theme,
    ),
    const SizedBox(height: 12),
    _InfoSection(title: 'About', value: info.about, theme: theme),
    const SizedBox(height: 12),
    _InfoSection(title: 'Address', value: info.address, theme: theme),
    const SizedBox(height: 12),
    _InfoSection(
      title: 'Operating Hours',
      value: info.operatingHours,
      theme: theme,
    ),
    const SizedBox(height: 12),
    _ContactSection(
      title: 'Contact Phone',
      value: info.contactPhone,
      icon: Icons.call_outlined,
      buttonLabel: 'Call',
      uri: Uri(scheme: 'tel', path: info.contactPhone.trim()),
    ),
    const SizedBox(height: 12),
    _ContactSection(
      title: 'Contact Email',
      value: info.contactEmail,
      icon: Icons.email_outlined,
      buttonLabel: 'Email',
      uri: Uri(scheme: 'mailto', path: info.contactEmail.trim()),
    ),
  ];
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.value,
    required this.theme,
  });

  final String title;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          value.trim().isEmpty ? 'Not yet provided by RefillHub' : value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: value.trim().isEmpty
                ? theme.colorScheme.onSurfaceVariant
                : null,
          ),
        ),
      ],
    ),
  );
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({
    required this.title,
    required this.value,
    required this.icon,
    required this.buttonLabel,
    required this.uri,
  });

  final String title;
  final String value;
  final IconData icon;
  final String buttonLabel;
  final Uri uri;

  Future<void> _launch(BuildContext context) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app is available for this action.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Could not launch $uri: $error\n$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the contact app.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          value.trim().isEmpty ? 'Not yet provided by RefillHub' : value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (value.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _launch(context),
            icon: Icon(icon),
            label: Text(buttonLabel),
          ),
        ],
      ],
    ),
  );
}
