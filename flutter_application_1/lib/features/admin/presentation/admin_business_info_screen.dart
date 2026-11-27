import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../info/data/business_info.dart';
import '../../info/data/business_info_providers.dart';

class AdminBusinessInfoScreen extends ConsumerStatefulWidget {
  const AdminBusinessInfoScreen({super.key});

  @override
  ConsumerState<AdminBusinessInfoScreen> createState() =>
      _AdminBusinessInfoScreenState();
}

class _AdminBusinessInfoScreenState
    extends ConsumerState<AdminBusinessInfoScreen> {
  late TextEditingController _businessNameController;
  late TextEditingController _aboutController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _contactEmailController;
  late TextEditingController _addressController;
  late TextEditingController _operatingHoursController;
  late TextEditingController _deliveryCoverageController;
  late TextEditingController _deliveryPolicyController;
  late TextEditingController _stepsController;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _aboutController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _contactEmailController = TextEditingController();
    _addressController = TextEditingController();
    _operatingHoursController = TextEditingController();
    _deliveryCoverageController = TextEditingController();
    _deliveryPolicyController = TextEditingController();
    _stepsController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _aboutController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _addressController.dispose();
    _operatingHoursController.dispose();
    _deliveryCoverageController.dispose();
    _deliveryPolicyController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  void _loadBusinessInfo(BusinessInfo info) {
    _businessNameController.text = info.businessName;
    _aboutController.text = info.about;
    _contactPhoneController.text = info.contactPhone;
    _contactEmailController.text = info.contactEmail;
    _addressController.text = info.address;
    _operatingHoursController.text = info.operatingHours;
    _deliveryCoverageController.text = info.deliveryCoverage;
    _deliveryPolicyController.text = info.deliveryPolicy;
    _stepsController.text = info.orderingGuideSteps.join('\n');
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final steps = _stepsController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final updatedInfo = BusinessInfo(
        businessName: _businessNameController.text.trim(),
        about: _aboutController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        address: _addressController.text.trim(),
        operatingHours: _operatingHoursController.text.trim(),
        deliveryCoverage: _deliveryCoverageController.text.trim(),
        deliveryPolicy: _deliveryPolicyController.text.trim(),
        orderingGuideSteps: steps,
      );

      final repository = ref.read(businessInfoRepositoryProvider);
      await repository.updateBusinessInfo(updatedInfo);

      setState(() {
        _successMessage = 'Business information updated successfully';
        _isLoading = false;
      });

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving changes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessInfoAsync = ref.watch(businessInfoStreamProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: businessInfoAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Business Information')),
          body: ErrorView(
            message: 'Error loading business info: $error',
            onRetry: () => ref.invalidate(businessInfoStreamProvider),
          ),
        ),
        data: (businessInfo) {
          if (_businessNameController.text.isEmpty &&
              businessInfo.businessName.isNotEmpty) {
            _loadBusinessInfo(businessInfo);
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Business Information')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: scheme.error),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: scheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: scheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_successMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: scheme.tertiary),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: scheme.tertiary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(
                                  color: scheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage != null || _successMessage != null)
                      const SizedBox(height: 20),
                    Text(
                      'Business Information',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update RefillHub business details. Leave fields empty to show "Not yet provided".',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Basic Information',
                      children: [
                        _buildTextField(
                          label: 'Business Name',
                          controller: _businessNameController,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'About RefillHub',
                          controller: _aboutController,
                          maxLines: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Contact Information',
                      children: [
                        _buildTextField(
                          label: 'Contact Phone',
                          controller: _contactPhoneController,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Contact Email',
                          controller: _contactEmailController,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Address',
                          controller: _addressController,
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Operations',
                      children: [
                        _buildTextField(
                          label: 'Operating Hours',
                          controller: _operatingHoursController,
                          maxLines: 2,
                          hint: 'e.g., Monday-Friday: 9am-6pm',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Delivery Coverage',
                          controller: _deliveryCoverageController,
                          maxLines: 2,
                          hint: 'e.g., Delivery available within 5km radius',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Policies',
                      children: [
                        _buildTextField(
                          label: 'Delivery Policy',
                          controller: _deliveryPolicyController,
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Ordering Guide Steps',
                      children: [
                        _buildTextField(
                          label: 'Ordering Guide Steps',
                          controller: _stepsController,
                          maxLines: 5,
                          hint:
                              'Enter one step per line\n1. First step\n2. Second step\n3. Third step',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter each step on a new line. Steps will be displayed as an ordered list.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveChanges,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  scheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
