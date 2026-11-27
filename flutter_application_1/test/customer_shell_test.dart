import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/core/router/app_router.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

void main() {
  testWidgets('customer tabs show their placeholder destinations', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: '/home');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    for (final label in ['Home', 'Products', 'My Orders', 'Profile']) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    expect(find.text('Products preview'), findsOneWidget);
    expect(
      find.text('Product catalogue and details are not yet provided.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Preview only. Search is not functional while catalogue data is unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.text('Search preview (not functional)'), findsOneWidget);

    await tester.tap(find.text('My Orders'));
    await tester.pumpAndSettle();
    expect(find.text('No orders to show'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);
  });

  testWidgets('home displays sample products and info links navigate back', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: '/home');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    expect(find.text('Hello there'), findsOneWidget);
    expect(find.text('Quick Order'), findsOneWidget);
    expect(find.text('Sample product A'), findsOneWidget);
    expect(find.text('Sample product B'), findsOneWidget);
    expect(find.text('Sample product C'), findsOneWidget);
    expect(
      find.text(
        'The sample catalogue and product details are not yet provided.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Sample only · details not yet provided'),
      findsNWidgets(3),
    );

    await tester.tap(find.text('Quick Order'));
    await tester.pumpAndSettle();
    expect(find.text('Products preview'), findsOneWidget);
    expect(
      find.text(
        'Preview only. Search is not functional while catalogue data is unavailable.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Pricing, ordering, delivery and contact details are not yet provided.',
      ),
      findsOneWidget,
    );
    for (final title in [
      'Pricing',
      'How to Order',
      'Delivery Information',
      'About/Contact',
    ]) {
      await tester.ensureVisible(find.text(title));
      expect(find.text(title), findsOneWidget);
    }

    await tester.ensureVisible(find.text('Pricing'));
    await tester.tap(find.text('Pricing'));
    await tester.pumpAndSettle();
    expect(find.text('Not yet provided.'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    await tester.drag(find.byType(ListView).first, const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.text('Quick Order'), findsOneWidget);
  });

  testWidgets('each information route shows its placeholder', (tester) async {
    final router = createAppRouter(initialLocation: '/home');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    const infoRoutes = {
      '/info/pricing': 'Pricing',
      '/info/how-to-order': 'How to Order',
      '/info/delivery-information': 'Delivery Information',
      '/info/about-contact': 'About/Contact',
    };

    for (final entry in infoRoutes.entries) {
      router.push(entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('Not yet provided.'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('products search value survives switching tabs', (tester) async {
    final router = createAppRouter(initialLocation: '/home');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    final searchField = find.byKey(const ValueKey('products-search'));
    await tester.enterText(searchField, 'sample query');

    await tester.tap(find.text('My Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'sample query',
    );
  });
}

Widget _app(GoRouter router) =>
    MaterialApp.router(theme: appTheme, routerConfig: router);
