import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/core/router/app_router.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/auth/presentation/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('checks required fields, email, and password length', () {
      expect(AuthValidators.required('  '), isNotNull);
      expect(AuthValidators.required('Full name'), isNull);
      expect(AuthValidators.email('not-an-email'), isNotNull);
      expect(AuthValidators.email('person@example.com'), isNull);
      expect(AuthValidators.password('short7'), isNotNull);
      expect(AuthValidators.password('long-enough'), isNull);
    });

    test('checks password confirmation', () {
      expect(
        AuthValidators.matchingPassword('', 'correct-password'),
        isNotNull,
      );
      expect(
        AuthValidators.matchingPassword('other-password', 'correct-password'),
        isNotNull,
      );
      expect(
        AuthValidators.matchingPassword('correct-password', 'correct-password'),
        isNull,
      );
    });

    test('accepts only the two supported Philippine phone formats', () {
      expect(AuthValidators.philippinePhone('09171234567'), isNull);
      expect(AuthValidators.philippinePhone('+639171234567'), isNull);
      for (final phone in [
        '9171234567',
        '0917123456',
        '08171234567',
        '+63281234567',
        '+63917123456',
        '+6391712345678',
        '09 171234567',
      ]) {
        expect(AuthValidators.philippinePhone(phone), isNotNull, reason: phone);
      }
    });
  });

  testWidgets('splash navigates to login after two seconds', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    expect(find.text('RefillHub'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.text('Welcome back'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('splash timer is cancelled when leaving the splash screen', (
    tester,
  ) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    router.go('/login');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('auth links navigate between login and register', (tester) async {
    final router = createAppRouter(initialLocation: '/login');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    await tester.tap(find.text('Create account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Create your account'), findsOneWidget);

    final loginLink = find.text('Log in').last;
    await tester.ensureVisible(loginLink);
    await tester.tap(loginLink);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('login requires valid details before navigating home', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: '/login');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'person@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'safe-password');
    await tester.tap(find.text('Log in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hello there'), findsOneWidget);
  });

  testWidgets('registration validates fields and submits valid details', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: '/register');
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(router));

    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNWidgets(6));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Alex Customer');
    await tester.enterText(fields.at(1), '09171234567');
    await tester.enterText(fields.at(2), '1 Sample Street');
    await tester.enterText(fields.at(3), 'alex@example.com');
    await tester.enterText(fields.at(4), 'a-secure-password');
    await tester.enterText(fields.at(5), 'a-different-password');
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);

    await tester.enterText(fields.at(5), 'a-secure-password');
    await tester.tap(find.text('Create account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hello there'), findsOneWidget);
  });
}

Widget _app(GoRouter router) =>
    MaterialApp.router(theme: appTheme, routerConfig: router);
