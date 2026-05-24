import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;

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
  static const _keyLoggedIn = 'is_logged_in';
  static const _keyName = 'user_name';
  static const _keyEmail = 'user_email';
  static const _keyPhoto = 'user_photo';
  static const _keyProvider = 'user_provider';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ── Google ──────────────────────────────────────────────────────────────────

  static Future<AuthUser?> signInWithGoogle() async {
    // Force a fresh sign-in each time to avoid stale token issues
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null && accessToken == null) {
      throw Exception('Google authentication returned no tokens. Check Firebase SHA-1 configuration.');
    }

    // Sign into Firebase Auth — idToken preferred, accessToken as fallback
    final credential = fa.GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    await fa.FirebaseAuth.instance.signInWithCredential(credential);

    final user = AuthUser(
      name: account.displayName ?? account.email,
      email: account.email,
      photoUrl: account.photoUrl,
      provider: AuthProvider.google,
    );
    await _persist(user);
    return user;
  }

  // ── Facebook ─────────────────────────────────────────────────────────────────

  static Future<AuthUser?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );
    if (result.status != LoginStatus.success) return null;

    // Sign into Firebase Auth so Firestore security rules pass
    final accessToken = result.accessToken?.tokenString;
    if (accessToken != null) {
      try {
        final credential = fa.FacebookAuthProvider.credential(accessToken);
        await fa.FirebaseAuth.instance.signInWithCredential(credential);
      } catch (e) {
        debugPrint('Firebase Auth (Facebook) error: $e');
      }
    }

    final data = await FacebookAuth.instance.getUserData(
      fields: 'name,email,picture.width(200)',
    );
    final user = AuthUser(
      name: data['name'] ?? 'Facebook User',
      email: data['email'] ?? '',
      photoUrl: data['picture']?['data']?['url'],
      provider: AuthProvider.facebook,
    );
    await _persist(user);
    return user;
  }

  // ── Guest ────────────────────────────────────────────────────────────────────

  static Future<AuthUser> continueAsGuest() async {
    try {
      // Anonymous Firebase UID so Firestore operations have a user doc
      if (fa.FirebaseAuth.instance.currentUser == null) {
        await fa.FirebaseAuth.instance.signInAnonymously();
      }
    } catch (_) {}
    const user = AuthUser(
      name: 'Guest',
      email: '',
      provider: AuthProvider.guest,
    );
    await _persist(user);
    return user;
  }

  // ── Session ──────────────────────────────────────────────────────────────────

  static Future<void> _persist(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyName, user.name);
    await prefs.setString(_keyEmail, user.email);
    await prefs.setString(_keyProvider, user.provider.name);
    if (user.photoUrl != null) {
      await prefs.setString(_keyPhoto, user.photoUrl!);
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<AuthUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyLoggedIn) ?? false)) return null;
    final providerStr = prefs.getString(_keyProvider) ?? 'guest';
    final provider = AuthProvider.values.firstWhere(
      (p) => p.name == providerStr,
      orElse: () => AuthProvider.guest,
    );
    return AuthUser(
      name: prefs.getString(_keyName) ?? 'User',
      email: prefs.getString(_keyEmail) ?? '',
      photoUrl: prefs.getString(_keyPhoto),
      provider: provider,
    );
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPhoto);
    await prefs.remove(_keyProvider);
    try { await fa.FirebaseAuth.instance.signOut(); } catch (_) {}
    try { await _googleSignIn.signOut(); } catch (_) {}
    try { await FacebookAuth.instance.logOut(); } catch (_) {}
  }
}
