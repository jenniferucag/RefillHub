import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/auth/presentation/auth_validators.dart';
import 'package:refillhub/features/checkout/data/checkout.dart';
import 'package:refillhub/features/cart/data/cart_item.dart';

void main() {
  group('AuthValidators', () {
    test('required validator rejects empty/whitespace', () {
      expect(AuthValidators.required(''), isNotNull);
      expect(AuthValidators.required('   '), isNotNull);
      expect(AuthValidators.required('\t\n'), isNotNull);
      expect(AuthValidators.required('Valid Name'), isNull);
    });

    test('email validator checks format', () {
      expect(AuthValidators.email('invalid'), isNotNull);
      expect(AuthValidators.email('user@'), isNotNull);
      expect(AuthValidators.email('@example.com'), isNotNull);
      expect(AuthValidators.email('user@example.com'), isNull);
      expect(AuthValidators.email('user+tag@example.co.uk'), isNull);
    });

    test('password validator requires minimum length', () {
      expect(AuthValidators.password('short'), isNotNull);
      expect(AuthValidators.password('short1'), isNotNull);
      expect(AuthValidators.password('short12'), isNotNull);
      expect(AuthValidators.password('longenough'), isNull);
      expect(AuthValidators.password('longenoughpassword'), isNull);
    });

    test('matchingPassword validator compares passwords', () {
      expect(
        AuthValidators.matchingPassword('password123', 'password123'),
        isNull,
      );
      expect(
        AuthValidators.matchingPassword('password123', 'password124'),
        isNotNull,
      );
      expect(AuthValidators.matchingPassword('', 'password'), isNotNull);
    });

    test('philippinePhone accepts two supported formats', () {
      // Format 1: 09171234567
      expect(AuthValidators.philippinePhone('09171234567'), isNull);
      expect(AuthValidators.philippinePhone('09087654321'), isNull);

      // Format 2: +639171234567
      expect(AuthValidators.philippinePhone('+639171234567'), isNull);
      expect(AuthValidators.philippinePhone('+639087654321'), isNull);
    });

    test('philippinePhone rejects invalid formats', () {
      // Missing country code digit
      expect(AuthValidators.philippinePhone('9171234567'), isNotNull);

      // Wrong initial digit (08)
      expect(AuthValidators.philippinePhone('08171234567'), isNotNull);

      // Wrong country code (+63 without 0)
      expect(AuthValidators.philippinePhone('+63281234567'), isNotNull);

      // Wrong length
      expect(AuthValidators.philippinePhone('0917123456'), isNotNull);
      expect(AuthValidators.philippinePhone('091712345678'), isNotNull);

      // Spaces
      expect(AuthValidators.philippinePhone('0917 123 4567'), isNotNull);
    });
  });

  group('CheckoutRequest validation', () {
    final validItems = [
      CartItem(
        productId: 'p1',
        productName: 'Product A',
        sizeLabel: 'Medium',
        unitPrice: 100,
        quantity: 2,
      ),
    ];

    test('creates valid checkout request', () {
      final request = CheckoutRequest(
        items: validItems,
        address: '123 Main Street',
        phone: '09171234567',
        notes: 'Please ring the bell',
        deliveryFee: null,
      );

      expect(request.items.length, 1);
      expect(request.address, '123 Main Street');
      expect(request.phone, '09171234567');
      expect(request.paymentMethod, 'Cash on Delivery');
    });

    test('preserves all checkout data', () {
      const address = '456 Oak Avenue';
      const phone = '+639171234567';
      const notes = 'Handle carefully';
      const deliveryFee = '50.00';

      final request = CheckoutRequest(
        items: validItems,
        address: address,
        phone: phone,
        notes: notes,
        deliveryFee: deliveryFee,
      );

      expect(request.address, address);
      expect(request.phone, phone);
      expect(request.notes, notes);
      expect(request.deliveryFee, deliveryFee);
    });

    test('requires items to be provided', () {
      final request = CheckoutRequest(
        items: const [],
        address: '123 Main Street',
        phone: '09171234567',
        notes: '',
        deliveryFee: null,
      );

      expect(request.items.isEmpty, true);
    });
  });

  group('Delivery fee parsing', () {
    test('parseDeliveryFee accepts valid positive decimals', () {
      expect(parseDeliveryFee('50'), '50');
      expect(parseDeliveryFee('50.00'), '50.00');
      expect(parseDeliveryFee('50.50'), '50.50');
      expect(parseDeliveryFee('0.99'), '0.99');
    });

    test('parseDeliveryFee rejects zero or null', () {
      expect(parseDeliveryFee(null), isNull);
      expect(parseDeliveryFee(''), isNull);
      expect(parseDeliveryFee('0'), isNull);
      expect(parseDeliveryFee('0.0'), isNull);
      expect(parseDeliveryFee('0.00'), isNull);
    });

    test('parseDeliveryFee rejects invalid formats', () {
      expect(parseDeliveryFee('abc'), isNull);
      expect(parseDeliveryFee('-50'), isNull);
      expect(parseDeliveryFee('50.00.00'), isNull);
      expect(parseDeliveryFee('\$50'), isNull);
    });

    test('parseDeliveryFee trims whitespace', () {
      expect(parseDeliveryFee('  50  '), '50');
      expect(parseDeliveryFee('  50.50  '), '50.50');
    });

    test('parseDeliveryFee returns null for empty after trim', () {
      expect(parseDeliveryFee('   '), isNull);
      expect(parseDeliveryFee('\t\n'), isNull);
    });
  });

  group('addDecimals calculation', () {
    test('adds whole numbers', () {
      expect(addDecimals('100', '50'), '150');
    });

    test('adds decimals with same scale', () {
      expect(addDecimals('100.50', '50.25'), '150.75');
    });

    test('adds decimals with different scales', () {
      expect(addDecimals('100.5', '50.25'), '150.75');
      expect(addDecimals('100', '50.5'), '150.5');
    });

    test('removes trailing zeros', () {
      expect(addDecimals('100.50', '50.50'), '151');
      expect(addDecimals('100.1', '50.9'), '151');
    });

    test('handles zero additions', () {
      expect(addDecimals('100.50', '0'), '100.5');
      expect(addDecimals('0', '50.25'), '50.25');
      expect(addDecimals('0', '0'), '0');
    });

    test('handles small decimals', () {
      expect(addDecimals('0.1', '0.2'), '0.3');
      expect(addDecimals('0.01', '0.02'), '0.03');
    });

    test('handles large numbers', () {
      expect(addDecimals('9999.99', '0.01'), '10000');
      expect(addDecimals('1000000.50', '500000.50'), '1500001');
    });
  });
}
