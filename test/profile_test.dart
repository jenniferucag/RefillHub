import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

TestApp profileApp() {
  final app = TestApp(role: 'customer', initialLocation: '/profile');
  app.backend.profiles['user'] = {
    'role': 'customer',
    'isActive': true,
    'name': 'Alex Customer',
    'phone': '09171234567',
    'address': '1 Sample Street',
    'email': 'alex@example.com',
  };
  return app;
}

void main() {
  testWidgets('shows, validates, and saves the customer profile', (
    tester,
  ) async {
    final app = profileApp();
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.text('Alex Customer'), findsOneWidget);
    expect(find.text('09171234567'), findsOneWidget);
    expect(find.text('1 Sample Street'), findsOneWidget);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), ' ');
    await tester.enterText(fields.at(1), 'invalid');
    await tester.enterText(fields.at(2), '');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNWidgets(2));
    expect(
      find.textContaining('Enter a valid PH mobile number'),
      findsOneWidget,
    );
    expect(app.backend.profiles['user']?['name'], 'Alex Customer');

    await tester.enterText(fields.at(0), '  Alex Updated  ');
    await tester.enterText(fields.at(1), '+639171234567');
    await tester.enterText(fields.at(2), '  2 New Street  ');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Alex Updated'), findsOneWidget);
    expect(find.text('+639171234567'), findsOneWidget);
    expect(find.text('2 New Street'), findsOneWidget);
    expect(find.text('Profile updated.'), findsOneWidget);
    expect(app.backend.profiles['user'], {
      'role': 'customer',
      'isActive': true,
      'fullName': 'Alex Updated',
      'name': 'Alex Updated',
      'phone': '+639171234567',
      'address': '2 New Street',
      'email': 'alex@example.com',
    });
  });

  testWidgets('cancel and failed saves preserve the existing profile', (
    tester,
  ) async {
    final app = profileApp();
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Edited Name');
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Customer'), findsOneWidget);
    expect(app.backend.profiles['user']?['name'], 'Alex Customer');

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Edited Name');
    app.backend.updateError = StateError('Firestore unavailable');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save your profile. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Edited Name'), findsOneWidget);
    expect(app.backend.profiles['user']?['name'], 'Alex Customer');

    app.backend.updateError = null;
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(app.backend.profiles['user']?['name'], 'Edited Name');
  });

  testWidgets('logout asks for confirmation', (tester) async {
    final app = profileApp();
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Log out'));
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    expect(app.backend.signOutCount, 0);
    expect(find.text('Your profile'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Log out'),
      ),
    );
    await tester.pumpAndSettle();
    expect(app.backend.signOutCount, 1);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('toolbar logout also requires confirmation', (tester) async {
    final app = profileApp();
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
    expect(app.backend.signOutCount, 0);
  });

  testWidgets('profile editing works on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(412, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = profileApp();
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Updated Name');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(app.backend.profiles['user']?['name'], 'Updated Name');
    expect(app.backend.profiles['user']?['fullName'], 'Updated Name');
  });
}
