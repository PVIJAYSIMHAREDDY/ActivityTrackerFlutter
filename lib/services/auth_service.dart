import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'firestore_service.dart';

enum AuthProvider { google, facebook, guest }

class AuthUser {
  final String name;
  final String email;
  final String? photoUrl;
  final AuthProvider provider;
  const AuthUser({
    required this.name,
    required this.email,
    this.photoUrl,
    required this.provider,
  });
}

class AuthService {
  static final GoogleSignIn _google = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  static Future<AuthUser?> signInWithGoogle() async {
    final auth = fa.FirebaseAuth.instance;
    final guest = auth.currentUser?.isAnonymous == true
        ? auth.currentUser
        : null;
    fa.UserCredential result;
    if (kIsWeb) {
      final provider = fa.GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      result = guest != null
          ? await guest.linkWithPopup(provider)
          : await auth.signInWithPopup(provider);
    } else {
      final account = await _google.signIn();
      if (account == null) return null;
      final tokens = await account.authentication;
      final credential = fa.GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      result = guest != null
          ? await guest.linkWithCredential(credential)
          : await auth.signInWithCredential(credential);
    }
    return _fromFirebase(result.user!);
  }

  static AuthUser _fromFirebase(fa.User user) => AuthUser(
    name: user.displayName ?? (user.isAnonymous ? 'Guest' : 'User'),
    email: user.email ?? '',
    photoUrl: user.photoURL,
    provider: user.isAnonymous ? AuthProvider.guest : AuthProvider.google,
  );

  static Future<AuthUser> continueAsGuest() async {
    final auth = fa.FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
    return _fromFirebase(user);
  }

  static Future<bool> isLoggedIn() async =>
      fa.FirebaseAuth.instance.currentUser != null;
  static Future<AuthUser?> getCurrentUser() async {
    final user = fa.FirebaseAuth.instance.currentUser;
    return user == null ? null : _fromFirebase(user);
  }

  static Future<void> _clearLegacySession() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'is_logged_in',
      'user_name',
      'user_email',
      'user_photo',
      'user_provider',
      'custom_profile_photo',
      'notifications_enabled',
    ]) {
      await prefs.remove(key);
    }
  }

  static Future<void> signOut() async {
    await fa.FirebaseAuth.instance.signOut();
    await _clearLegacySession();
    if (!kIsWeb) {
      try {
        await _google.signOut();
      } catch (_) {}
    }
  }

  static Future<void> deleteAccount() async {
    final user = fa.FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in again.');
    // Reauthenticate before deleting any data, keeping the same account.
    if (!user.isAnonymous) {
      if (kIsWeb) {
        await user.reauthenticateWithPopup(fa.GoogleAuthProvider());
      } else {
        await _google.signOut();
        final account = await _google.signIn();
        if (account == null) throw StateError('Account deletion cancelled.');
        final tokens = await account.authentication;
        await user.reauthenticateWithCredential(
          fa.GoogleAuthProvider.credential(
            idToken: tokens.idToken,
            accessToken: tokens.accessToken,
          ),
        );
      }
    }
    await FirestoreService.deleteUserData(user.uid);
    await user.delete();
    await _clearLegacySession();
  }
}
