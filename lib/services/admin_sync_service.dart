import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for synchronizing User registrations, Ratings, and Suggestions
/// with the standalone Admin Dashboard.
class AdminSyncService {
  AdminSyncService._();
  static final AdminSyncService instance = AdminSyncService._();

  // Local storage keys
  static const _ratingsStorageKey = 'adhkar.admin.ratings';
  static const _feedbackStorageKey = 'adhkar.admin.feedback';
  static const _userAccountKey = 'adhkar.user.account';

  // Configurable backend URL (defaults to local admin dashboard server)
  // Can be pointed to localhost:4000 or any hosted URL
  static String adminServerUrl = 'http://127.0.0.1:4000/api';

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

    // Try posting to admin server
    try {
      await http.post(
        Uri.parse('$adminServerUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Gracefully offline
    }

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
      'stars': stars,
      'tags': tags,
      'comment': comment,
      'user': userName ?? 'مستخدم مجهول',
      'platform': defaultTargetPlatform.name,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Save locally
    final existing = prefs.getStringList(_ratingsStorageKey) ?? [];
    existing.insert(0, jsonEncode(ratingData));
    await prefs.setStringList(_ratingsStorageKey, existing);

    // Send to admin dashboard backend
    try {
      final res = await http.post(
        Uri.parse('$adminServerUrl/ratings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ratingData),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      // Offline fallback success (stored locally)
      return true;
    }
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
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Save locally
    final existing = prefs.getStringList(_feedbackStorageKey) ?? [];
    existing.insert(0, jsonEncode(feedbackData));
    await prefs.setStringList(_feedbackStorageKey, existing);

    // Send to admin dashboard backend
    try {
      final res = await http.post(
        Uri.parse('$adminServerUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(feedbackData),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      // Offline fallback
      return true;
    }
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
