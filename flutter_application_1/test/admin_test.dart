import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/core/router/app_router.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

const _prototypeNotice =
    'Prototype only · No authentication or authorization is connected. '
    'Admin routes are not access-protected.';

void main() {
  testWidgets('/admin redirects to the demo login', (tester) async {
    final router = createAppRouter(initialLocation: '/admin');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.text('Admin demo'), findsOneWidget);
    expect(
      find.textContaining('No backend authentication is connected.'),
      findsOneWidget,
    );
    expect(find.text('Continue to demo'), findsOneWidget);
  });

  testWidgets('admin login validates fields and opens dashboard locally', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: '/admin/login');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    await tester.tap(find.text('Continue to demo'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNWidgets(2));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'not-an-email');
    await tester.enterText(fields.at(1), 'short');
    await tester.tap(find.text('Continue to demo'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );

    await tester.enterText(fields.at(0), 'demo@example.com');
    await tester.enterText(fields.at(1), 'demo-password');
    await tester.tap(find.text('Continue to demo'));
    await tester.pumpAndSettle();
    expect(find.text('Operations overview'), findsOneWidget);
  });

  testWidgets('dashboard includes exact summaries and sample disclaimer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(initialLocation: '/admin/dashboard');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    for (final label in [
      'Total Orders',
      'Pending',
      'In Progress',
      'Delivered',
      "Today's Orders",
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('Sample data · not live'), findsNWidgets(6));
    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('narrow admin navigation uses a drawer with all menu routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(initialLocation: '/admin/customers');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
    expect(find.text(_prototypeNotice), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    for (final label in [
      'Dashboard',
      'Products',
      'Customers',
      'Orders',
      'Delivery',
    ]) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(label)),
        findsOneWidget,
      );
    }

    await tester.tap(find.text('Delivery'));
    await tester.pumpAndSettle();
    expect(find.text('Delivery details not yet provided'), findsOneWidget);
    expect(find.text(_prototypeNotice), findsOneWidget);
  });

  testWidgets('wide admin navigation switches placeholder routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(initialLocation: '/admin/orders');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text(_prototypeNotice), findsOneWidget);
    for (final label in [
      'Dashboard',
      'Products',
      'Customers',
      'Orders',
      'Delivery',
    ]) {
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

    for (final section in [
      'Dashboard',
      'Products',
      'Customers',
      'Orders',
      'Delivery',
    ]) {
      await tester.tap(find.text(section).first);
      await tester.pumpAndSettle();
      if (section == 'Dashboard') {
        expect(find.text('Operations overview'), findsOneWidget);
      } else {
        expect(find.text('$section details not yet provided'), findsOneWidget);
      }
      expect(find.text(_prototypeNotice), findsOneWidget);
    }
  });
}

Widget _app(GoRouter router) =>
    MaterialApp.router(theme: appTheme, routerConfig: router);
