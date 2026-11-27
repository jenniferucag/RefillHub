import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:refillhub/core/theme/app_theme.dart';
import 'package:refillhub/core/widgets/app_text_field.dart';
import 'package:refillhub/core/widgets/status_chip.dart';
import 'support/auth_test_support.dart';

void main() {
  testWidgets('customer accounts cannot open the design preview', (
    tester,
  ) async {
    final app = TestApp(role: 'customer', initialLocation: '/home');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Refill my container'), findsWidgets);
    expect(find.text('Buy water'), findsWidgets);

    app.router.go('/design-preview');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Shared UI, clear by design.'), findsNothing);
    expect(app.router.routeInformationProvider.value.uri.path, '/home');
  });

  testWidgets('Status chips and password visibility are available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: ListView(
            children: [
              for (final status in OrderStatus.values)
                StatusChip(status: status),
              const AppTextField(label: 'Password', isPassword: true),
            ],
          ),
        ),
      ),
    );

    for (final status in [
      'Pending',
      'Confirmed',
      'Preparing',
      'Out for Delivery',
      'Delivered',
      'Cancelled',
    ]) {
      expect(find.text(status), findsOneWidget);
    }

    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });
}
