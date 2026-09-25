import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// رفع الصور إلى Supabase Storage (بديل مجاني عن Firebase Storage).
/// الـ bucket قراءة عامة ويُسمح بالرفع من التطبيق بعد تسجيل الدخول محلياً.
class ImageUploadService {
  ImageUploadService._();
  static final ImageUploadService instance = ImageUploadService._();

  static const String bucket = 'posts';

  bool _bucketEnsured = false;

  bool get _ready {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureBucket() async {
    if (_bucketEnsured || !_ready) return;
    try {
      final storage = Supabase.instance.client.storage;
      final existing = await storage.listBuckets();
      final exists = existing.any((b) => b.name == bucket);
      if (!exists) {
        await storage.createBucket(bucket, const BucketOptions(public: true));
      }
      _bucketEnsured = true;
    } catch (e) {
      debugPrint('Supabase bucket ensure note: $e');
      _bucketEnsured = true;
    }
  }

  /// يرفع صورة محلية ويعيد الرابط العام، أو null عند الفشل.
  Future<String?> uploadLocalImage(
    String localPath, {
    String folder = 'posts',
  }) async {
    if (kIsWeb) return null;
    if (localPath.isEmpty || localPath.startsWith('http')) return localPath;
    if (!_ready) return null;

    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      await _ensureBucket();

      final lower = localPath.toLowerCase();
      final contentType = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      final ext = contentType == 'image/png'
          ? 'png'
          : contentType == 'image/webp'
              ? 'webp'
              : 'jpg';
      final name =
          '${DateTime.now().millisecondsSinceEpoch}_${_rand()}.$ext';
      final path = folder.isEmpty ? name : '$folder/$name';

      await Supabase.instance.client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      return Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Image upload failed: $e');
      return null;
    }
  }

  /// يعيد الرابط كما هو إن كان شبكة، ويرفعه إن كان ملفاً محلياً.
  Future<String?> ensureRemote(String? path, {String folder = 'posts'}) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return uploadLocalImage(path, folder: folder);
  }

  String _rand() {
    final r = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      8,
      (_) => chars[r.nextInt(chars.length)],
    ).join();
  }
}
