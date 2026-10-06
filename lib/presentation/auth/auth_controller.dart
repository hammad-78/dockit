import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/auth/auth_repository.dart';
import '../../domain/models/models.dart';

class AuthController extends ChangeNotifier {
  AuthController() : _repository = AuthRepository() {
    _subscription = _repository!.authStateChanges.listen(_syncUser);
  }

  AuthController.test() : _repository = null;

  final AuthRepository? _repository;
  StreamSubscription<User?>? _subscription;
  User? _user;
  AccountRole? _role;
  bool _roleLoaded = false;
  bool _busy = false;

  User? get user => _user;
  AccountRole? get role => _role;
  bool get isSignedIn => _user != null;
  bool get isRoleLoaded => _roleLoaded;
  bool get isBusy => _busy;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _run(
    () => _repository!.signInWithEmail(email: email, password: password),
  );

  Future<void> createAccount({
    required String email,
    required String password,
  }) =>
      _run(() => _repository!.createAccount(email: email, password: password));

  Future<void> signInWithGoogle() => _run(_repository!.signInWithGoogle);

  Future<void> signOut() => _run(_repository!.signOut);

  Future<void> saveRole(AccountRole role) async {
    final user = _user;
    if (user == null) throw StateError('You must be signed in to choose a role.');

    await _run(
      () => _repository!.saveRole(user: user, role: role),
    );
    _role = role;
    _roleLoaded = true;
    notifyListeners();
  }

  Future<void> _syncUser(User? user) async {
    _user = user;
    _role = null;
    _roleLoaded = user == null;
    notifyListeners();

    if (user != null) {
      await _loadRole(user);
    }
  }

  Future<void> _loadRole(User user) async {
    _user = user;
    _role = await _repository!.getRole(user);
    _roleLoaded = true;
    notifyListeners();
  }

  Future<void> _run(Future<Object?> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      final result = await action();
      if (result is UserCredential) {
        final user = result.user;
        if (user != null) await _loadRole(user);
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
