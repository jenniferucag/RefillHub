import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/core/router/app_router.dart';
import 'package:refillhub/features/auth/auth_controller.dart';

import 'support/auth_test_support.dart';

void main() {
  test('redirects restrict customer and admin route access', () {
    String? redirect(AuthStatus status, String location) =>
        authRedirect(status, Uri.parse(location));
    expect(redirect(AuthStatus.signedOut, '/orders'), '/login');
    expect(redirect(AuthStatus.signedOut, '/register'), isNull);
    expect(redirect(AuthStatus.signedOut, '/admin/login'), isNull);
    expect(redirect(AuthStatus.customer, '/admin/dashboard'), '/home');
    expect(redirect(AuthStatus.customer, '/design-preview'), '/home');
    expect(redirect(AuthStatus.customer, '/info/pricing'), isNull);
    expect(redirect(AuthStatus.admin, '/products'), '/admin/dashboard');
    expect(redirect(AuthStatus.admin, '/admin/orders'), isNull);
    expect(redirect(AuthStatus.admin, '/admin/login'), '/admin/dashboard');
  });

  test('loading preserves safe deep links without redirecting externally', () {
    final loading = authRedirect(
      AuthStatus.loading,
      Uri.parse('/admin/orders'),
    );
    expect(
      authRedirect(AuthStatus.admin, Uri.parse(loading!)),
      '/admin/orders',
    );
    expect(
      authRedirect(
        AuthStatus.signedOut,
        Uri(path: '/auth-loading', queryParameters: {'from': '//example.com'}),
      ),
      '/login',
    );
  });

  late FakeAuthBackend backend;
  late AuthController auth;

  setUp(() {
    backend = FakeAuthBackend();
    auth = AuthController(backend);
  });

  tearDown(() async {
    auth.dispose();
    await backend.dispose();
  });

  test('admin login signs out a customer before granting access', () async {
    await auth.signIn('customer@example.com', 'password', admin: true);
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.message, 'This account does not have admin access.');
    expect(backend.currentUserId, isNull);
  });

  test('admin login accepts an active admin', () async {
    backend.profiles['user'] = {'role': 'admin', 'isActive': true};
    await auth.signIn('admin@example.com', 'password', admin: true);
    expect(auth.status, AuthStatus.admin);
    expect(backend.currentUserId, 'user');
  });

  for (final profile in <Map<String, dynamic>?>[
    null,
    {'role': 'customer'},
    {'role': 'customer', 'isActive': null},
    {'role': 'customer', 'isActive': false},
  ]) {
    test('invalid active status signs out: $profile', () async {
      backend.profiles['user'] = profile;
      await auth.signIn('customer@example.com', 'password');
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.message, inactiveAccountMessage);
      expect(backend.currentUserId, isNull);
    });
  }

  test('unknown role fails closed', () async {
    backend.profiles['user'] = {'role': 'owner', 'isActive': true};
    await auth.signIn('customer@example.com', 'password');
    expect(auth.status, AuthStatus.signedOut);
    expect(backend.currentUserId, isNull);
    expect(auth.message, contains('role is invalid'));
  });

  test('registration creates an active customer', () async {
    await auth.registerCustomer(
      email: 'customer@example.com',
      password: 'password',
      name: 'Customer',
      phone: '09171234567',
      address: 'Address',
    );
    expect(auth.status, AuthStatus.customer);
    expect(backend.profiles['user']?['role'], 'customer');
    expect(backend.profiles['user']?['isActive'], true);
  });

  test('live deactivation revokes access and signs out', () async {
    await auth.signIn('customer@example.com', 'password');
    await Future<void>.delayed(Duration.zero);
    backend.setProfile({'role': 'customer', 'isActive': false});
    await Future<void>.delayed(Duration.zero);
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.message, inactiveAccountMessage);
    expect(backend.currentUserId, isNull);
  });

  test('unconfirmed local profile changes do not grant admin access', () async {
    await auth.signIn('customer@example.com', 'password');
    await Future<void>.delayed(Duration.zero);
    backend.emitProfile(
      const UserProfile({
        'role': 'admin',
        'isActive': true,
      }, pendingWrites: true),
    );
    await Future<void>.delayed(Duration.zero);
    expect(auth.status, AuthStatus.loading);
    backend.emitProfile(
      const UserProfile({'role': 'customer', 'isActive': true}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(auth.status, AuthStatus.customer);
  });

  test('pending profile edits do not interrupt a verified session', () async {
    await auth.signIn('customer@example.com', 'password');
    await Future<void>.delayed(Duration.zero);
    backend.emitProfile(
      const UserProfile({
        'role': 'customer',
        'isActive': true,
        'name': 'Pending',
      }, pendingWrites: true),
    );
    await Future<void>.delayed(Duration.zero);
    expect(auth.status, AuthStatus.customer);
    expect(auth.profile?.data?['name'], isNull);
  });
}
