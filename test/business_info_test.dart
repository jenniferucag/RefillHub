import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/info/data/business_info.dart';
import 'package:refillhub/features/info/data/business_info_providers.dart';
import 'package:refillhub/features/info/data/business_info_repository.dart';

import 'support/auth_test_support.dart';

class _Repository extends Fake implements BusinessInfoRepository {
  BusinessInfo? saved;
  Object? failure;

  @override
  Future<void> save(BusinessInfo info) async {
    if (failure case final error?) throw error;
    saved = info;
  }
}

Future<void> _pumpAdmin(
  WidgetTester tester, {
  required BusinessInfo info,
  required _Repository repository,
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final app = TestApp(
    role: 'admin',
    initialLocation: '/admin/business-info',
    businessInfoStream: () => Stream.value(info),
    extraOverrides: [
      businessInfoRepositoryProvider.overrideWithValue(repository),
    ],
  );
  await tester.pumpWidget(app.widget);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

void main() {
  test('shows the FirebaseException message to the customer', () {
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'TEST read denied',
    );

    expect(businessInfoErrorMessage(error), 'TEST read denied');
  });

  testWidgets(
    'admin validates and saves business information with editable steps',
    (tester) async {
      final repository = _Repository();
      await _pumpAdmin(
        tester,
        repository: repository,
        info: const BusinessInfo(
          orderingGuideSteps: ['First step', 'Second step'],
          exists: true,
        ),
      );

      expect(find.text('Business Information'), findsOneWidget);
      await tester.ensureVisible(find.text('Add step'));
      await tester.tap(find.text('Add step'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove step').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Move step down').first);
      await tester.pumpAndSettle();

      await _enter(tester, 'Business Name', 'TEST Hub');
      await _enter(tester, 'About', 'TEST about');
      await _enter(tester, 'Contact Phone', 'not a phone');
      await _enter(tester, 'Contact Email', 'invalid');
      await tester.ensureVisible(find.text('Save business information'));
      await tester.tap(find.text('Save business information'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid phone number.'), findsOneWidget);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(repository.saved, isNull);

      await _enter(tester, 'Contact Phone', '+1 (415) 555-0132');
      await _enter(tester, 'Contact Email', 'info@example.com');
      await _enter(tester, 'Address', 'TEST address');
      await _enter(tester, 'Operating Hours', 'TEST hours');
      await _enter(tester, 'Delivery Coverage', 'TEST coverage');
      await _enter(tester, 'Delivery Policy', 'TEST policy');
      await _enter(tester, 'Schedule Notes', 'TEST notes');
      await _enter(tester, 'Step 2', 'Updated first step');
      await tester.ensureVisible(find.text('Save business information'));
      await tester.tap(find.text('Save business information'));
      await tester.pumpAndSettle();

      expect(repository.saved, isNotNull);
      expect(repository.saved!.businessName, 'TEST Hub');
      expect(repository.saved!.about, 'TEST about');
      expect(repository.saved!.contactPhone, '+1 (415) 555-0132');
      expect(repository.saved!.contactEmail, 'info@example.com');
      expect(repository.saved!.address, 'TEST address');
      expect(repository.saved!.operatingHours, 'TEST hours');
      expect(repository.saved!.deliveryCoverage, 'TEST coverage');
      expect(repository.saved!.deliveryPolicy, 'TEST policy');
      expect(repository.saved!.scheduleNotes, 'TEST notes');
      expect(repository.saved!.orderingGuideSteps, [
        'Second step',
        'Updated first step',
      ]);
      expect(find.text('Business information saved.'), findsOneWidget);
    },
  );

  testWidgets('admin shows missing-document form and save errors with retry', (
    tester,
  ) async {
    final repository = _Repository()..failure = StateError('write unavailable');
    await _pumpAdmin(
      tester,
      repository: repository,
      info: const BusinessInfo(),
    );

    expect(find.text('No business information saved yet.'), findsOneWidget);
    await tester.ensureVisible(find.text('Save business information'));
    await tester.tap(find.text('Save business information'));
    await tester.pumpAndSettle();
    expect(find.textContaining('write unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(repository.saved, isNull);
  });
}
