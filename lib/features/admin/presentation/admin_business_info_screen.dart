import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../info/data/business_info.dart';
import '../../info/data/business_info_providers.dart';

class AdminBusinessInfoScreen extends ConsumerWidget {
  const AdminBusinessInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessInfo = ref.watch(businessInfoProvider);
    return SafeArea(
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
        data: (info) => _BusinessInfoForm(
          key: const ValueKey('admin-business-info-form'),
          info: info,
        ),
      ),
    );
  }
}

class _BusinessInfoForm extends ConsumerStatefulWidget {
  const _BusinessInfoForm({required this.info, super.key});

  final BusinessInfo info;

  @override
  ConsumerState<_BusinessInfoForm> createState() => _BusinessInfoFormState();
}

class _BusinessInfoFormState extends ConsumerState<_BusinessInfoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessName;
  late final TextEditingController _about;
  late final TextEditingController _contactPhone;
  late final TextEditingController _contactEmail;
  late final TextEditingController _address;
  late final TextEditingController _operatingHours;
  late final TextEditingController _deliveryCoverage;
  late final TextEditingController _deliveryPolicy;
  late final TextEditingController _scheduleNotes;
  late final List<TextEditingController> _orderingSteps;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _businessName = TextEditingController(text: widget.info.businessName);
    _about = TextEditingController(text: widget.info.about);
    _contactPhone = TextEditingController(text: widget.info.contactPhone);
    _contactEmail = TextEditingController(text: widget.info.contactEmail);
    _address = TextEditingController(text: widget.info.address);
    _operatingHours = TextEditingController(text: widget.info.operatingHours);
    _deliveryCoverage = TextEditingController(
      text: widget.info.deliveryCoverage,
    );
    _deliveryPolicy = TextEditingController(text: widget.info.deliveryPolicy);
    _scheduleNotes = TextEditingController(text: widget.info.scheduleNotes);
    _orderingSteps = [
      for (final step in widget.info.orderingGuideSteps)
        TextEditingController(text: step),
    ];
  }

  @override
  void dispose() {
    _businessName.dispose();
    _about.dispose();
    _contactPhone.dispose();
    _contactEmail.dispose();
    _address.dispose();
    _operatingHours.dispose();
    _deliveryCoverage.dispose();
    _deliveryPolicy.dispose();
    _scheduleNotes.dispose();
    for (final controller in _orderingSteps) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return null;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\+?[0-9][0-9\s().-]*$').hasMatch(phone) ||
        digits.length < 7 ||
        digits.length > 15) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  void _moveStep(int oldIndex, int newIndex) {
    setState(() {
      final controller = _orderingSteps.removeAt(oldIndex);
      _orderingSteps.insert(newIndex, controller);
    });
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final info = BusinessInfo(
      businessName: _businessName.text.trim(),
      about: _about.text.trim(),
      contactPhone: _contactPhone.text.trim(),
      contactEmail: _contactEmail.text.trim(),
      address: _address.text.trim(),
      operatingHours: _operatingHours.text.trim(),
      deliveryCoverage: _deliveryCoverage.text.trim(),
      deliveryPolicy: _deliveryPolicy.text.trim(),
      scheduleNotes: _scheduleNotes.text.trim(),
      orderingGuideSteps: [
        for (final step in _orderingSteps)
          if (step.text.trim().isNotEmpty) step.text.trim(),
      ],
      exists: true,
    );
    try {
      await ref.read(businessInfoRepositoryProvider).save(info);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business information saved.')),
      );
    } catch (error, stackTrace) {
      if (error is FirebaseException) {
        debugPrint(
          'Saving business information failed: FirebaseException '
          'code=${error.code}, message=${error.message}\n$stackTrace',
        );
      } else {
        debugPrint('Saving business information failed: $error\n$stackTrace');
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = businessInfoErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Business Information',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Manage the information shown to customers.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!widget.info.exists) ...[
                const SizedBox(height: 16),
                const AppCard(
                  child: Text('No business information saved yet.'),
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Could not save business information: $_saveError',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      TextButton(
                        onPressed: _saving ? null : _save,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _field('Business Name', _businessName),
              _field('About', _about, maxLines: 4),
              _field(
                'Contact Phone',
                _contactPhone,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              _field(
                'Contact Email',
                _contactEmail,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              _field('Address', _address, maxLines: 3),
              _field('Operating Hours', _operatingHours, maxLines: 2),
              _field('Delivery Coverage', _deliveryCoverage, maxLines: 3),
              _field('Delivery Policy', _deliveryPolicy, maxLines: 4),
              _field('Schedule Notes', _scheduleNotes, maxLines: 3),
              const SizedBox(height: 16),
              Text('Ordering Guide Steps', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var index = 0; index < _orderingSteps.length; index++)
                Padding(
                  key: ObjectKey(_orderingSteps[index]),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Step ${index + 1}',
                          controller: _orderingSteps[index],
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Move step up',
                        onPressed: index == 0 || _saving
                            ? null
                            : () => _moveStep(index, index - 1),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: 'Move step down',
                        onPressed: index == _orderingSteps.length - 1 || _saving
                            ? null
                            : () => _moveStep(index, index + 1),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      IconButton(
                        tooltip: 'Remove step',
                        onPressed: _saving
                            ? null
                            : () {
                                setState(() {
                                  _orderingSteps.removeAt(index).dispose();
                                });
                              },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () => setState(
                          () => _orderingSteps.add(TextEditingController()),
                        ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add step'),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? 'Saving...' : 'Save business information',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AppTextField(
      label: label,
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    ),
  );
}
