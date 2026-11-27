import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:refillhub/features/auth/presentation/auth_validators.dart';
import 'package:refillhub/features/auth/auth_controller.dart';

import 'support/auth_test_support.dart';

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

  testWidgets('signed-out users cannot open customer routes', (tester) async {
    final app = TestApp(initialLocation: '/orders');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('deactivation signs the user out and displays the reason', (
    tester,
  ) async {
    final app = TestApp(role: 'customer', initialLocation: '/profile');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    app.backend.setProfile({'role': 'customer', 'isActive': false});
    await tester.pumpAndSettle();
    expect(app.backend.signOutCount, 1);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text(inactiveAccountMessage), findsOneWidget);
  });

  for (final profile in <Map<String, dynamic>?>[
    null,
    {'role': 'customer'},
    {'role': 'customer', 'isActive': null},
    {'role': 'customer', 'isActive': false},
  ]) {
    testWidgets('invalid active status fails closed: $profile', (tester) async {
      final app = TestApp(role: 'customer', initialLocation: '/home');
      app.backend.profiles['user'] = profile;
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();
      expect(app.backend.currentUserId, isNull);
      expect(find.text(inactiveAccountMessage), findsOneWidget);
      expect(find.text('Hello there'), findsNothing);
    });
  }

  testWidgets('customers cannot navigate to admin routes', (tester) async {
    final app = TestApp(role: 'customer', initialLocation: '/home');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    app.router.go('/admin/dashboard');
    await tester.pumpAndSettle();
    expect(app.router.routeInformationProvider.value.uri.path, '/home');
    expect(find.text('Operations overview'), findsNothing);
  });

  testWidgets('admins cannot navigate to customer routes', (tester) async {
    final app = TestApp(role: 'admin', initialLocation: '/admin/dashboard');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    app.router.go('/products');
    await tester.pumpAndSettle();
    expect(
      app.router.routeInformationProvider.value.uri.path,
      '/admin/dashboard',
    );
    expect(find.text('Products preview'), findsNothing);
  });

  testWidgets('auth links navigate between login and register', (tester) async {
    final app = TestApp(initialLocation: '/login');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

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
    final app = TestApp(initialLocation: '/login');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('registration validates fields and submits valid details', (
    tester,
  ) async {
    final app = TestApp(initialLocation: '/register');
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();
    expect(find.text('Hello, Alex Customer'), findsOneWidget);
    expect(app.backend.profiles['user']?['role'], 'customer');
    expect(app.backend.profiles['user']?['isActive'], true);
  });
}
