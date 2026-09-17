import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';
import 'storage.dart';

/// Comprehensive Firebase Auth & Firestore Service
class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  User? get currentUser => _auth?.currentUser;
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  /// Initialize Firebase safely
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
      debugPrint('Firebase initialized successfully.');
      return true;
    } catch (e) {
      debugPrint('Firebase initialization note: $e');
      _initialized = false;
      return false;
    }
  }

  /// Sign Up with Email and Password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    await initialize();
    if (_auth == null) {
      throw Exception('خدمة Firebase غير مفعلة حالياً');
    }

    final cred = await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (cred.user != null) {
      await cred.user!.updateDisplayName(fullName);
      await _syncUserToFirestore(
        user: cred.user!,
        fullName: fullName,
        phone: phoneNumber,
        provider: 'password',
      );
    }

    return cred;
  }

  /// Sign In with Email and Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await initialize();
    if (_auth == null) {
      throw Exception('خدمة Firebase غير مفعلة حالياً');
    }

    final cred = await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (cred.user != null) {
      await _syncUserToFirestore(
        user: cred.user!,
        provider: 'password',
      );
    }

    return cred;
  }

  /// Sign In with Google
  Future<UserCredential?> signInWithGoogle({String? phoneNumber}) async {
    await initialize();
    if (_auth == null) {
      throw Exception('خدمة Firebase غير مفعلة حالياً');
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: '273977925686-95kek3141s432gsuqhj47gug8dql80id.apps.googleusercontent.com',
      );

      // Sign out from any stale session first to allow account selection
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in flow
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth!.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _syncUserToFirestore(
          user: userCredential.user!,
          fullName: userCredential.user!.displayName ?? googleUser.displayName,
          phone: phoneNumber,
          provider: 'google',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error during Google Sign-In: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Synchronize User Profile to Cloud Firestore
  Future<void> _syncUserToFirestore({
    required User user,
    String? fullName,
    String? phone,
    required String provider,
  }) async {
    final storage = DhikrStorage();
    final streakInfo = storage.getStreakInfo();
    final resolvedName = fullName ?? user.displayName ?? 'مستخدم درة المؤمن';
    final resolvedEmail = user.email ?? '';
    final resolvedPhone = phone ?? user.phoneNumber ?? '';

    // Always persist to local app profile immediately
    try {
      await storage.saveUserProfile(
        name: resolvedName,
        email: resolvedEmail,
        phone: resolvedPhone,
        authProvider: provider,
      );
    } catch (e) {
      debugPrint('Local storage user profile error: $e');
    }

    if (_firestore == null) return;

    try {
      final docRef = _firestore!.collection('users').doc(user.uid);
      final data = <String, dynamic>{
        'uid': user.uid,
        'email': resolvedEmail,
        'displayName': resolvedName,
        'phoneNumber': resolvedPhone,
        'photoURL': user.photoURL ?? '',
        'provider': provider,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'streak': streakInfo.streak,
      };

      await docRef.set(data, SetOptions(merge: true)).timeout(
        const Duration(seconds: 4),
        onTimeout: () => debugPrint('Firestore user sync timed out gracefully'),
      );
    } catch (e) {
      debugPrint('Firestore sync error: $e');
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    if (_auth != null) {
      await _auth!.signOut();
    }
  }

  /// Delete Account permanently (Google Play Requirement)
  /// Deletes user document from Cloud Firestore and deletes the Auth user account.
  Future<void> deleteAccount() async {
    await initialize();
    final user = _auth?.currentUser;
    if (user == null) {
      throw Exception('لا يوجد مستخدم مسجل حالياً');
    }

    // 1. Delete Firestore user document if present
    if (_firestore != null) {
      try {
        await _firestore!.collection('users').doc(user.uid).delete().timeout(
          const Duration(seconds: 5),
          onTimeout: () => debugPrint('Firestore user doc delete timed out'),
        );
      } catch (e) {
        debugPrint('Firestore delete error: $e');
      }
    }

    // 2. Clear local storage profile
    try {
      final storage = DhikrStorage();
      await storage.clearUserProfile();
    } catch (e) {
      debugPrint('Local storage clear error: $e');
    }

    // 3. Disconnect Google Sign In if applicable
    try {
      await GoogleSignIn().disconnect();
    } catch (_) {}

    // 4. Delete user account from Firebase Authentication
    await user.delete();
  }
}
