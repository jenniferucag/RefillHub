import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/router/app_router.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/app_text_field.dart';
import 'package:flutter_application_1/core/widgets/status_chip.dart';

void main() {
  testWidgets('Home remains available and preview is routed', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RefillHubApp()));
    appRouter.go('/home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Hello there'), findsOneWidget);
    expect(find.text('Quick Order'), findsOneWidget);

    appRouter.go('/design-preview');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Shared UI, clear by design.'), findsOneWidget);
    expect(find.text('Color palette'), findsOneWidget);
    expect(find.text('Primary blue'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pump();
    expect(find.text('Typography scale'), findsOneWidget);
    expect(find.text('Water, well designed.'), findsOneWidget);

    appRouter.go('/');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
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
