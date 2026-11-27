import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/presentation/auth_validators.dart';
import '../../auth/auth_controller.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn(AuthController auth) {
    if (_formKey.currentState?.validate() ?? false) {
      auth.signIn(_email.text.trim(), _password.text, admin: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        color: scheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Text('RefillHub', style: theme.textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text('Admin login', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access the operations dashboard.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            label: 'Email',
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.email_outlined,
                            validator: AuthValidators.email,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Password',
                            controller: _password,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_outline,
                            validator: AuthValidators.password,
                          ),
                          const SizedBox(height: 24),
                          if (auth.message != null &&
                              auth.message!.isNotEmpty) ...[
                            Text(
                              auth.message!,
                              style: TextStyle(color: scheme.error),
                            ),
                            const SizedBox(height: 12),
                          ],
                          AppButton(
                            label: 'Log in',
                            icon: Icons.arrow_forward,
                            isLoading: auth.busy,
                            onPressed: () => _signIn(auth),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Back to RefillHub'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
