import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

void main() {
  group('LoginScreen form validation', () {
    testWidgets('displays login form with email and password fields', (
      tester,
    ) async {
      final app = TestApp();
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('you@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('shows validation error for empty email', (tester) async {
      final app = TestApp();
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      // Click login without entering anything
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required.'), findsWidgets);
    });

    testWidgets('shows validation error for empty password', (tester) async {
      final app = TestApp();
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'user@example.com');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required.'), findsWidgets);
    });

    testWidgets('shows validation error for invalid email format', (
      tester,
    ) async {
      final app = TestApp();
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'not-an-email');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
    });

    testWidgets('shows validation error for password too short', (
      tester,
    ) async {
      final app = TestApp();
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'user@example.com');
      await tester.enterText(fields.at(1), 'short');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters.'),
        findsOneWidget,
      );
    });

    testWidgets('accepts valid email and password', (tester) async {
      final app = TestApp();
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'user@example.com');
      await tester.enterText(fields.at(1), 'validpassword123');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      // No error messages should appear for valid input
      expect(find.text('Enter a valid email address.'), findsNothing);
      expect(
        find.text('Password must be at least 8 characters.'),
        findsNothing,
      );
    });

    testWidgets('shows register link', (tester) async {
      final app = TestApp();
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      expect(find.text('New to RefillHub?'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });
  });
}
