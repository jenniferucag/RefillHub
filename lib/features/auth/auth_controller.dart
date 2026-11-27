import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Current authentication and authorization state exposed by [AuthController].
enum AuthStatus { loading, signedOut, customer, admin }

const inactiveAccountMessage =
    'Your account is not active. Please contact RefillHub.';

/// Profile data and Firestore cache metadata for an authenticated user.
class UserProfile {
  /// Creates a profile snapshot.
  const UserProfile(
    this.data, {
    this.fromCache = false,
    this.pendingWrites = false,
  });

  /// User document fields, or `null` when the profile document is missing.
  final Map<String, dynamic>? data;

  /// Whether this snapshot came from the local Firestore cache.
  final bool fromCache;

  /// Whether the snapshot contains uncommitted local writes.
  final bool pendingWrites;
}

abstract class AuthBackend {
  String? get currentUserId;
  Stream<String?> get authChanges;
  Stream<UserProfile> watchProfile(String uid);
  Future<UserProfile> getProfile(String uid);
  Future<void> updateProfile(
    String uid, {
    required String name,
    required String phone,
    required String address,
  });
  Future<String> signIn(String email, String password);
  Future<String> registerCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  });
  Future<void> signOut();
}

class FirebaseAuthBackend implements AuthBackend {
  FirebaseAuthBackend(this.auth, this.firestore);

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  @override
  String? get currentUserId => auth.currentUser?.uid;

  @override
  Stream<String?> get authChanges =>
      auth.authStateChanges().map((user) => user?.uid);

  @override
  Stream<UserProfile> watchProfile(String uid) => firestore
      .collection('users')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => UserProfile(
          snapshot.data(),
          fromCache: snapshot.metadata.isFromCache,
          pendingWrites: snapshot.metadata.hasPendingWrites,
        ),
      );

  @override
  Future<UserProfile> getProfile(String uid) async {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    return UserProfile(
      snapshot.data(),
      fromCache: snapshot.metadata.isFromCache,
      pendingWrites: snapshot.metadata.hasPendingWrites,
    );
  }

  @override
  Future<void> updateProfile(
    String uid, {
    required String name,
    required String phone,
    required String address,
  }) async {
    final document = firestore.collection('users').doc(uid);
    await firestore.runTransaction((transaction) async {
      if (auth.currentUser?.uid != uid) {
        throw StateError('The signed-in account has changed.');
      }
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        throw StateError('The user profile does not exist.');
      }
      transaction.update(document, {
        'fullName': name,
        'name': name,
        'phone': phone,
        'address': address,
      });
    });
  }

  @override
  Future<String> signIn(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Sign-in did not return a user.');
    return user.uid;
  }

  @override
  Future<String> registerCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Registration did not return a user.');
    await firestore.collection('users').doc(user.uid).set({
      'role': 'customer',
      'isActive': true,
      'fullName': name,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
    });
    return user.uid;
  }

  @override
  Future<void> signOut() => auth.signOut();
}

class AuthController extends ChangeNotifier {
  AuthController(this.backend) {
    _authSubscription = backend.authChanges.listen(
      _onAuthChanged,
      onError: (Object error, StackTrace stack) {
        _verificationFailed(error, stack);
      },
    );
  }

  final AuthBackend backend;
  late final StreamSubscription<String?> _authSubscription;
  StreamSubscription<UserProfile>? _profileSubscription;
  UserProfile? profile;
  AuthStatus status = AuthStatus.loading;
  String? message;
  bool busy = false;
  int _generation = 0;
  bool _disposed = false;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _onAuthChanged(String? uid) {
    if (_disposed || busy || uid != backend.currentUserId) return;
    if (uid == null) {
      _generation++;
      unawaited(_profileSubscription?.cancel());
      _profileSubscription = null;
      profile = null;
      status = AuthStatus.signedOut;
      _emit();
    } else {
      _watch(uid);
    }
  }

  void _watch(String uid, {AuthStatus? verifiedStatus}) {
    final generation = ++_generation;
    unawaited(_profileSubscription?.cancel());
    profile = null;
    status = verifiedStatus ?? AuthStatus.loading;
    _emit();
    _profileSubscription = backend
        .watchProfile(uid)
        .listen(
          (profile) {
            if (generation != _generation || uid != backend.currentUserId) {
              return;
            }
            if (profile.fromCache) {
              status = AuthStatus.loading;
              message = 'Waiting for the server to verify your account.';
              _emit();
              return;
            }
            final next = _profileStatus(profile);
            if (profile.pendingWrites) {
              if (next != status ||
                  (status != AuthStatus.customer &&
                      status != AuthStatus.admin)) {
                status = AuthStatus.loading;
                message = 'Waiting for the server to verify your account.';
                _emit();
              }
              return;
            }
            if (next == null) {
              unawaited(_reject(_profileError(profile)));
              return;
            }
            this.profile = profile;
            message = null;
            status = next;
            _emit();
          },
          onError: (Object error, StackTrace stack) {
            if (generation == _generation) _verificationFailed(error, stack);
          },
        );
  }

  AuthStatus? _profileStatus(UserProfile profile) {
    final data = profile.data;
    if (data == null || data['isActive'] != true) return null;
    return switch (data['role']) {
      'customer' => AuthStatus.customer,
      'admin' => AuthStatus.admin,
      _ => null,
    };
  }

  String _profileError(UserProfile profile) =>
      profile.data == null || profile.data!['isActive'] != true
      ? inactiveAccountMessage
      : 'Your account role is invalid. Please contact RefillHub.';

  void _verificationFailed(Object error, StackTrace stack) {
    debugPrint('Account verification failed: $error\n$stack');
    unawaited(_reject('Unable to verify your account. Please try again.'));
  }

  Future<void> _reject(String? reason) async {
    ++_generation;
    unawaited(_profileSubscription?.cancel());
    _profileSubscription = null;
    profile = null;
    status = AuthStatus.signedOut;
    busy = true;
    message = reason;
    _emit();
    try {
      await backend.signOut();
    } catch (error, stack) {
      debugPrint('Sign-out failed: $error\n$stack');
      message = [
        if (reason != null && reason.isNotEmpty) reason,
        'Sign-out failed; please try again.',
      ].join(' ');
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> signIn(String email, String password, {bool admin = false}) =>
      _authenticate(() => backend.signIn(email, password), admin: admin);

  Future<void> registerCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) => _authenticate(
    () => backend.registerCustomer(
      email: email,
      password: password,
      name: name,
      phone: phone,
      address: address,
    ),
    registration: true,
  );

  Future<void> _authenticate(
    Future<String> Function() operation, {
    bool admin = false,
    bool registration = false,
  }) async {
    if (busy) return;
    busy = true;
    message = null;
    _emit();
    try {
      final uid = await operation();
      if (_disposed) return;
      final profile = await backend.getProfile(uid);
      if (_disposed) return;
      if (profile.fromCache || profile.pendingWrites) {
        throw StateError('The account profile is not confirmed by the server.');
      }
      if (backend.currentUserId != uid) {
        throw StateError('The signed-in account changed during verification.');
      }
      final next = _profileStatus(profile);
      if (next == null) {
        await _reject(_profileError(profile));
      } else if (admin && next != AuthStatus.admin) {
        await _reject('This account does not have admin access.');
      } else {
        _watch(uid, verifiedStatus: next);
      }
    } catch (error, stack) {
      debugPrint('Authentication failed: $error\n$stack');
      final reason = error is FirebaseAuthException
          ? error.message ?? 'Authentication failed. Please try again.'
          : registration && backend.currentUserId != null
          ? 'Your account was created, but its profile could not be verified. Please contact RefillHub.'
          : 'Unable to verify your account. Please try again.';
      if (backend.currentUserId != null) {
        await _reject(reason);
      } else {
        status = AuthStatus.signedOut;
        message = reason;
      }
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> signOut() => _reject(null);

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) {
    final uid = backend.currentUserId;
    if (uid == null || status != AuthStatus.customer) {
      throw StateError('An active customer account is required.');
    }
    return backend.updateProfile(
      uid,
      name: name,
      phone: phone,
      address: address,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_authSubscription.cancel());
    unawaited(_profileSubscription?.cancel());
    super.dispose();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    required AuthController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope is missing.');
    return scope!.notifier!;
  }
}
