import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../auth_controller.dart';
import 'auth_form_layout.dart';
import 'auth_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit(AuthController auth) {
    if (_formKey.currentState!.validate()) {
      auth.registerCustomer(
        email: _email.text.trim(),
        password: _passwordController.text,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return AuthFormLayout(
      title: 'Create your account',
      subtitle: "A few details, then you're ready to refill.",
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Full name',
              controller: _name,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline,
              validator: AuthValidators.required,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Phone number',
              controller: _phone,
              hint: '09xxxxxxxxx or +639xxxxxxxxx',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.phone_outlined,
              validator: AuthValidators.philippinePhone,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Delivery address',
              controller: _address,
              hint: 'Street, barangay, city',
              keyboardType: TextInputType.streetAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.location_on_outlined,
              validator: AuthValidators.required,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Email',
              controller: _email,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.email_outlined,
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Password',
              controller: _passwordController,
              isPassword: true,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.lock_outline,
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Confirm password',
              isPassword: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              validator: (value) => AuthValidators.matchingPassword(
                value,
                _passwordController.text,
              ),
            ),
            const SizedBox(height: 24),
            if (auth.message != null && auth.message!.isNotEmpty) ...[
              Text(
                auth.message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Create account',
                isLoading: auth.busy,
                onPressed: () => _submit(auth),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                AppButton(
                  label: 'Log in',
                  variant: AppButtonVariant.text,
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
