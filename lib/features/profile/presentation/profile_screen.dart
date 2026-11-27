import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/auth_controller.dart';
import '../../auth/presentation/auth_validators.dart';
import '../../auth/presentation/sign_out_confirmation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _edit(Map<String, dynamic> data) {
    _name.text = data['fullName'] as String? ?? data['name'] as String? ?? '';
    _phone.text = data['phone'] as String? ?? '';
    _address.text = data['address'] as String? ?? '';
    setState(() {
      _error = null;
      _editing = true;
    });
  }

  Future<void> _save(AuthController auth) async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await auth.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (error, stack) {
      debugPrint('Profile update failed: $error\n$stack');
      if (!mounted) return;
      setState(() => _error = 'Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final data = auth.profile?.data;
    if (data == null) {
      return const SafeArea(child: LoadingView(message: 'Loading profile...'));
    }
    if ([
      'name',
      'phone',
      'address',
    ].any((field) => data[field] != null && data[field] is! String)) {
      return const SafeArea(
        child: ErrorView(
          message:
              'Your profile contains invalid data. Please contact RefillHub.',
        ),
      );
    }

    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Your profile', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              AppCard(
                child: _editing
                    ? Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'Full name',
                              controller: _name,
                              enabled: !_saving,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.required,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Phone number',
                              controller: _phone,
                              enabled: !_saving,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.philippinePhone,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Delivery address',
                              controller: _address,
                              enabled: !_saving,
                              keyboardType: TextInputType.streetAddress,
                              textInputAction: TextInputAction.done,
                              validator: AuthValidators.required,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            AppButton(
                              label: 'Save changes',
                              isLoading: _saving,
                              onPressed: () => _save(auth),
                            ),
                            const SizedBox(height: 8),
                            AppButton(
                              label: 'Cancel',
                              variant: AppButtonVariant.text,
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _editing = false),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileDetail(
                            label: 'Full name',
                            value:
                                data['fullName'] as String? ??
                                data['name'] as String?,
                          ),
                          const SizedBox(height: 16),
                          _ProfileDetail(
                            label: 'Phone number',
                            value: data['phone'] as String?,
                          ),
                          const SizedBox(height: 16),
                          _ProfileDetail(
                            label: 'Delivery address',
                            value: data['address'] as String?,
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            label: 'Edit profile',
                            onPressed: () => _edit(data),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Log out',
                variant: AppButtonVariant.secondary,
                onPressed: _saving ? null : () => confirmSignOut(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          value == null || value!.trim().isEmpty ? 'Not provided' : value!,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
