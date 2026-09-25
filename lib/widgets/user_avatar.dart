import 'dart:io';

import 'package:flutter/material.dart';

/// دائرة صورة الحساب الموحدة: تعرض صورة الشبكة أو ملفاً محلياً،
/// وتسقط على الحرف الأول أو أيقونة شخص عند غياب الصورة.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.photo,
    this.name,
    this.size = 32,
    this.background,
    this.foreground = Colors.white,
  });

  final String? photo;
  final String? name;
  final double size;
  final Color? background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final p = (photo ?? '').trim();
    final initial = (name ?? '').trim().isNotEmpty
        ? (name!.trim()[0].toUpperCase())
        : '';

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              background ?? const Color(0xFF0F3B2C),
              (background ?? const Color(0xFF0F3B2C)).withValues(alpha: 0.7),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: initial.isNotEmpty
            ? Text(
                initial,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.42,
                  color: foreground,
                ),
              )
            : Icon(Icons.person_rounded, size: size * 0.55, color: foreground),
      );
    }

    if (p.isEmpty) return fallback();
    if (p.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          p,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        ),
      );
    }
    try {
      if (File(p).existsSync()) {
        return ClipOval(
          child: Image.file(File(p), width: size, height: size, fit: BoxFit.cover),
        );
      }
    } catch (_) {}
    return fallback();
  }
}
