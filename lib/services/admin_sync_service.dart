import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_auth_service.dart';

/// Service for synchronizing User registrations, Ratings, and Suggestions
/// with the admin dashboard via Firestore.
///
/// Everything is offline-first: entries are always stored locally, then a
/// best-effort Firestore write delivers them to the dashboard collections
/// (`ratings` / `feedback`). Failures never surface to the user.
class AdminSyncService {
  AdminSyncService._();
  static final AdminSyncService instance = AdminSyncService._();

  // Local storage keys
  static const _ratingsStorageKey = 'adhkar.admin.ratings';
  static const _feedbackStorageKey = 'adhkar.admin.feedback';
  static const _userAccountKey = 'adhkar.user.account';

  // Legacy backend URL (kept for reference; Firestore is now the channel).
  static String adminServerUrl = 'http://127.0.0.1:4000/api';

  /// Best-effort Firestore writer: initializes Firebase + anonymous identity,
  /// writes the document, and swallows all errors (offline-safe).
  Future<bool> _sendToCloud(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      final ok = await FirebaseAuthService.instance.initialize();
      if (!ok) return false;
      await FirebaseAuthService.instance.signInAnonymously();
      await FirebaseFirestore.instance
          .collection(collection)
          .add({...data, 'sentAt': FieldValue.serverTimestamp()}).timeout(
            const Duration(seconds: 5),
          );
      return true;
    } catch (e) {
      debugPrint('AdminSync cloud note ($collection): $e');
      return false;
    }
  }

  /// Register or Login User with Name, Email, Phone, and Auth Provider
  Future<Map<String, dynamic>> registerOrLoginUser({
    required String name,
    required String email,
    required String phone,
    String authProvider = 'email_password',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = {
      'id': 'usr_${DateTime.now().millisecondsSinceEpoch}',
      'name': name.isEmpty ? 'مستخدم ذِكْر' : name,
      'email': email.isEmpty ? 'غير مسجل' : email,
      'phone': phone.isEmpty ? 'غير مسجل' : phone,
      'platform': defaultTargetPlatform.name,
      'status': 'نشط',
      'role': 'مستخدم',
      'authProvider': authProvider,
      'registeredAt': DateTime.now().toIso8601String(),
      'lastActive': DateTime.now().toIso8601String(),
      'completedDhikrs': 0,
    };

    await prefs.setString(_userAccountKey, jsonEncode(profile));

    // User identity itself lives in Firebase Auth + `users` docs
    // (see FirebaseAuthService); no separate write needed here.

    return profile;
  }

  /// Get current logged in user account
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userAccountKey);
      if (raw != null) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Logout current user
  Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userAccountKey);
    } catch (_) {}
  }

  /// Register or update user device profile
  Future<void> registerDevice({
    required String name,
    required String email,
  }) async {
    await registerOrLoginUser(
      name: name,
      email: email,
      phone: '',
      authProvider: 'guest',
    );
  }

  /// Submit App Rating with tags and comment
  Future<bool> submitRating({
    required int stars,
    required List<String> tags,
    required String comment,
    String? userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ratingData = {
      'id': 'rate_${DateTime.now().millisecondsSinceEpoch}',
      'stars': stars.clamp(1, 5),
      'tags': tags,
      'comment': comment,
      'user': userName ?? 'مستخدم مجهول',
      'platform': defaultTargetPlatform.name,
      'featured': false,
      'isApproved': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Save locally
    final existing = prefs.getStringList(_ratingsStorageKey) ?? [];
    existing.insert(0, jsonEncode(ratingData));
    await prefs.setStringList(_ratingsStorageKey, existing);

    // Deliver to the admin dashboard collection (best-effort).
    await _sendToCloud('ratings', ratingData);
    return true;
  }

  /// Submit Feedback / Suggestion
  Future<bool> submitFeedback({
    required String message,
    required String category,
    String? userContact,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final feedbackData = {
      'id': 'fb_${DateTime.now().millisecondsSinceEpoch}',
      'category': category,
      'message': message,
      'contact': userContact ?? 'غير محدد',
      'platform': defaultTargetPlatform.name,
      'status': 'جديد',
      'adminReply': '',
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Save locally
    final existing = prefs.getStringList(_feedbackStorageKey) ?? [];
    existing.insert(0, jsonEncode(feedbackData));
    await prefs.setStringList(_feedbackStorageKey, existing);

    // Deliver to the admin dashboard collection (best-effort).
    await _sendToCloud('feedback', feedbackData);
    return true;
  }

  /// Retrieve all locally stored ratings
  Future<List<Map<String, dynamic>>> getLocalRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_ratingsStorageKey) ?? [];
    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// Retrieve all locally stored feedback
  Future<List<Map<String, dynamic>>> getLocalFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_feedbackStorageKey) ?? [];
    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
}
