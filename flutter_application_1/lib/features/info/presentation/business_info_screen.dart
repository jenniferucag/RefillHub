import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/error_view.dart';
import '../data/business_info_providers.dart';

const String _notProvided = 'Not yet provided';

class BusinessInfoScreen extends ConsumerWidget {
  const BusinessInfoScreen({super.key});

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $uri';
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $uri';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessInfoAsync = ref.watch(businessInfoStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('RefillHub Information')),
      body: businessInfoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(
          message: 'Error loading information: $error',
          onRetry: () => ref.invalidate(businessInfoStreamProvider),
        ),
        data: (businessInfo) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Business Name
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  businessInfo.businessName.isEmpty
                      ? _notProvided
                      : businessInfo.businessName,
                  style: theme.textTheme.headlineSmall,
                ),
              ),

              // About
              _buildSection(
                context: context,
                title: 'About Us',
                content: businessInfo.about.isEmpty
                    ? _notProvided
                    : businessInfo.about,
                isEmpty: businessInfo.about.isEmpty,
              ),

              // Contact Information
              _buildSection(
                context: context,
                title: 'Contact Information',
                content: '',
                children: [
                  _buildContactRow(
                    context: context,
                    label: 'Phone',
                    value: businessInfo.contactPhone.isEmpty
                        ? _notProvided
                        : businessInfo.contactPhone,
                    isEmpty: businessInfo.contactPhone.isEmpty,
                    icon: Icons.phone_outlined,
                    onTap: businessInfo.contactPhone.isNotEmpty
                        ? () => _launchPhone(businessInfo.contactPhone)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildContactRow(
                    context: context,
                    label: 'Email',
                    value: businessInfo.contactEmail.isEmpty
                        ? _notProvided
                        : businessInfo.contactEmail,
                    isEmpty: businessInfo.contactEmail.isEmpty,
                    icon: Icons.email_outlined,
                    onTap: businessInfo.contactEmail.isNotEmpty
                        ? () => _launchEmail(businessInfo.contactEmail)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context: context,
                    label: 'Address',
                    value: businessInfo.address.isEmpty
                        ? _notProvided
                        : businessInfo.address,
                    isEmpty: businessInfo.address.isEmpty,
                  ),
                ],
              ),

              // Operating Hours
              _buildSection(
                context: context,
                title: 'Operating Hours',
                content: businessInfo.operatingHours.isEmpty
                    ? _notProvided
                    : businessInfo.operatingHours,
                isEmpty: businessInfo.operatingHours.isEmpty,
              ),

              // Delivery Coverage
              _buildSection(
                context: context,
                title: 'Delivery Coverage',
                content: businessInfo.deliveryCoverage.isEmpty
                    ? _notProvided
                    : businessInfo.deliveryCoverage,
                isEmpty: businessInfo.deliveryCoverage.isEmpty,
              ),

              // Delivery Policy
              _buildSection(
                context: context,
                title: 'Delivery Policy',
                content: businessInfo.deliveryPolicy.isEmpty
                    ? _notProvided
                    : businessInfo.deliveryPolicy,
                isEmpty: businessInfo.deliveryPolicy.isEmpty,
              ),

              // Ordering Guide
              if (businessInfo.orderingGuideSteps.isNotEmpty)
                _buildSection(
                  context: context,
                  title: 'How to Order',
                  content: '',
                  children: [
                    for (
                      int i = 0;
                      i < businessInfo.orderingGuideSteps.length;
                      i++
                    )
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  businessInfo.orderingGuideSteps[i],
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              else
                _buildSection(
                  context: context,
                  title: 'How to Order',
                  content: _notProvided,
                  isEmpty: true,
                ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String content,
    bool isEmpty = false,
    List<Widget>? children,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (children != null)
            Column(children: children)
          else
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback? onTap,
    bool isEmpty = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: isEmpty ? Colors.transparent : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isEmpty ? scheme.onSurfaceVariant : scheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isEmpty
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.arrow_outward, size: 16, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isEmpty = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
