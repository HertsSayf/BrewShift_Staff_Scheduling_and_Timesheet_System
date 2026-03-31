import 'package:brew_shift/models/app_models.dart';
import 'package:brew_shift/services/firestore_store.dart';
import 'package:brew_shift/services/local_store.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

/// App-wide session state used to track the current signed-in user.

class AppSession extends ChangeNotifier {
  AppSession({
    FirestoreStoreService? store,
    LocalStoreService? localStore,
  })  : _store = store ?? FirestoreStoreService.instance,
        _localStore = localStore ?? LocalStoreService.instance;

  final FirestoreStoreService _store;
  final LocalStoreService _localStore;

  AppUser? _currentUser;
  bool _isReady = false;

  AppUser? get currentUser => _currentUser;
  bool get isReady => _isReady;
  bool get isLoggedIn => _currentUser != null;

  Future<void> initialize() async {
    _currentUser = await _store.getCurrentUserProfile();
    await _syncCurrentUserLocally();
    _isReady = true;
    notifyListeners();
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    final success = await _store.login(
      identifier: identifier,
      password: password,
    );

    if (!success) {
      return false;
    }

    _currentUser = await _store.getCurrentUserProfile();
    await _syncCurrentUserLocally();
    notifyListeners();
    return _currentUser != null;
  }

  Future<void> logout() async {
    await _store.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> registerUser({
    required String fullName,
    required String staffId,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _store.registerUser(
        fullName: fullName,
        staffId: staffId,
        email: email,
        password: password,
        role: role,
      );

      _currentUser = await _store.getCurrentUserProfile();
      await _syncCurrentUserLocally();
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (error) {
      return _mapRegistrationError(error);
    } catch (_) {
      return 'Something went wrong while creating the account.';
    }
  }


  Future<void> _syncCurrentUserLocally() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    await _localStore.upsertUser(
      user.copyWith(password: ''),
    );
  }

  String _mapRegistrationError(fb.FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'That email is already in use.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return error.message ?? 'Could not create the account.';
    }
  }
}
