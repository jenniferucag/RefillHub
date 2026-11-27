import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'auth_form_layout.dart';
import 'auth_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      title: 'Welcome back',
      subtitle: 'Log in to continue to your RefillHub account.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.email_outlined,
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              isPassword: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(label: 'Log in', onPressed: _submit),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'New to RefillHub?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                AppButton(
                  label: 'Create account',
                  variant: AppButtonVariant.text,
                  onPressed: () => context.go('/register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
