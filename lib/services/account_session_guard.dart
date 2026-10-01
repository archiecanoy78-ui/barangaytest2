import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../main.dart';

class AccountSessionGuard with WidgetsBindingObserver {
  static final AccountSessionGuard _instance = AccountSessionGuard._internal();
  factory AccountSessionGuard() => _instance;
  AccountSessionGuard._internal();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;
  StreamSubscription<fb_auth.User?>? _idTokenSubscription;
  StreamSubscription<fb_auth.User?>? _authStateSubscription;

  BuildContext? _currentContext;
  bool _isHandlingForceLogout = false;
  String? _activeUid;

  void initialize(BuildContext context, String uid) {
    if (_activeUid == uid && _userDocSubscription != null) return;

    _currentContext = context;
    _activeUid = uid;
    _isHandlingForceLogout = false;

    WidgetsBinding.instance.addObserver(this);
    _startUserDocumentListener(uid);
    _startIdTokenListener();
    _startAuthStateListener();
  }

  void _startUserDocumentListener(String uid) {
    _userDocSubscription?.cancel();

    try {
      _userDocSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) {
          _triggerForceLogout('Your account has been deleted.');
          return;
        }

        final data = snapshot.data();
        if (data != null) {
          final status = (data['status'] as String?)?.toLowerCase() ?? '';
          final isArchived = (data['isArchived'] as bool?) ?? false;

          if (status == 'archived' ||
              status == 'deleted' ||
              status == 'disabled' ||
              isArchived) {
            _triggerForceLogout(
                'Your account has been deactivated. Please contact the administrator.');
          }
        }
      }, onError: (error) {
        debugPrint('Session Guard listener error: $error');
      });
    } catch (e) {
      debugPrint('Error attaching Session Guard listener: $e');
    }
  }

  void _startIdTokenListener() {
    _idTokenSubscription?.cancel();
    _idTokenSubscription =
        fb_auth.FirebaseAuth.instance.idTokenChanges().listen((user) async {
      if (user == null) {
        _triggerForceLogout('Session expired or signed out.');
        return;
      }

      try {
        await user.getIdToken(true);
      } on fb_auth.FirebaseAuthException catch (e) {
        if (e.code == 'user-disabled' ||
            e.code == 'user-not-found' ||
            e.code == 'user-token-expired') {
          _triggerForceLogout(
              'Your account status has changed. Please log in again.');
        }
      } catch (_) {}
    });
  }

  void _startAuthStateListener() {
    _authStateSubscription?.cancel();
    _authStateSubscription =
        fb_auth.FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _triggerForceLogout('Session terminated.');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _activeUid != null) {
      _checkSessionHealthOnResume();
    }
  }

  Future<void> _checkSessionHealthOnResume() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
        await user.getIdToken(true);
      } on fb_auth.FirebaseAuthException catch (e) {
        if (e.code == 'user-disabled' ||
            e.code == 'user-not-found' ||
            e.code == 'user-token-expired') {
          _triggerForceLogout(
              'Your account is no longer active. Please contact administrator.');
        }
      } catch (_) {}
    }
  }

  Future<void> _triggerForceLogout(String message) async {
    if (_isHandlingForceLogout) return;
    _isHandlingForceLogout = true;

    stopGuarding();

    try {
      await fb_auth.FirebaseAuth.instance.signOut();
    } catch (_) {}

    final ctx = _currentContext;
    if (ctx != null && ctx.mounted) {
      final appState = Provider.of<AppState>(ctx, listen: false);
      appState.logout();

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  void stopGuarding() {
    WidgetsBinding.instance.removeObserver(this);
    _userDocSubscription?.cancel();
    _idTokenSubscription?.cancel();
    _authStateSubscription?.cancel();
    _userDocSubscription = null;
    _idTokenSubscription = null;
    _authStateSubscription = null;
    _activeUid = null;
  }
}
