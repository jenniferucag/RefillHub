import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/auth/auth_controller.dart';
import 'package:refillhub/features/orders/data/order_providers.dart';
import 'package:refillhub/features/orders/presentation/admin_order_details_screen.dart';

import 'support/auth_test_support.dart';
import 'support/fake_order_repository.dart';

void main() {
  testWidgets('refill rejection requires a reason and records admin history', (
    tester,
  ) async {
    final backend = FakeAuthBackend(role: 'admin');
    final auth = AuthController(backend);
    final repository = FakeOrderRepository();
    final now = DateTime.now();
    final order = await repository.placeRefillOrder(
      productId: 'refill-product',
      waterType: 'Purified',
      sizeLabel: 'Large',
      quantity: 2,
      address: '1 Main Street',
      phone: '09123456789',
      notes: 'Call on arrival',
      pickupRequestedAt: now.add(const Duration(days: 1)),
      deliveryRequestedAt: now.add(const Duration(days: 2)),
    );
    addTearDown(() async {
      auth.dispose();
      await backend.dispose();
      repository.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [orderRepositoryProvider.overrideWithValue(repository)],
        child: AuthScope(
          controller: auth,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AdminOrderDetailsScreen(order: order),
                        ),
                      );
                    },
                    child: const Text('Open order'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open order'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Mark Picked Up'), findsNothing);
    expect(find.text('Start Preparing'), findsNothing);
    expect(find.text('Unit price: Price to be confirmed'), findsOneWidget);
    expect(find.text('Cash on Delivery'), findsOneWidget);

    await tester.ensureVisible(find.text('Reject'));
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    final rejectDialogButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(ElevatedButton, 'Reject'),
    );
    await tester.tap(rejectDialogButton);
    await tester.pump();
    expect(find.text('Enter a reason before rejecting.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      'Address not serviceable',
    );
    await tester.tap(rejectDialogButton);
    await tester.pumpAndSettle();

    final rejected = await repository.getOrder(order.id);
    expect(rejected?.status, 'Cancelled');
    expect(rejected?.cancellationReason, 'Address not serviceable');
    expect(rejected?.statusHistory.last.changedBy, 'user');
    expect(rejected?.updatedAt.isAfter(order.updatedAt), isTrue);
  });
}
