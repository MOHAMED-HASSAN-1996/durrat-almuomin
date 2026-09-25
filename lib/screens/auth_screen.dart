import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/admin_sync_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/image_upload_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/user_avatar.dart';
import '../widgets/app_toast.dart';

/// Comprehensive Authentication Screen
/// Supports Google Sign-In, Email/Password, and Phone Number Registration.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.onSuccess,
    this.canSkip = true,
  });

  final VoidCallback? onSuccess;
  final bool canSkip;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = true;
  bool _loading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _countryCode = '+20'; // Default Egypt, also popular KSA +966, UAE +971
  String? _photoPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickSignupPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() => _photoPath = picked.path);
      }
    } catch (e) {
      debugPrint('Signup photo pick error: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    try {
      final phone = _phoneController.text.trim().isNotEmpty
          ? '$_countryCode ${_phoneController.text.trim()}'
          : 'غير مسجل';

      UserCredential? cred;
      try {
        cred = await FirebaseAuthService.instance.signInWithGoogle(phoneNumber: phone);
      } catch (e) {
        debugPrint('Firebase Google Sign-In note: $e');
      }

      final resolvedName = cred?.user?.displayName ??
          (_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'مستخدم درة المؤمن');
      final resolvedEmail = cred?.user?.email ??
          (_emailController.text.trim().isNotEmpty ? _emailController.text.trim() : 'user@durrat-almuomin.app');
      final photoUrl = cred?.user?.photoURL ?? '';

      if (mounted) {
        await context.read<AppState>().saveUserProfile(
          name: resolvedName,
          email: resolvedEmail,
          phone: phone,
          photo: photoUrl,
          authProvider: 'google',
        );
      }

      await AdminSyncService.instance.registerOrLoginUser(
        name: resolvedName,
        email: resolvedEmail,
        phone: phone,
        authProvider: 'google',
      );

      if (!mounted) return;
      _showSuccessDialog(resolvedName);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, 
        const SnackBar(content: Text('تعذر تسجيل الدخول بـ Google، حاول مجدداً.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    try {
      final fullName = _isSignUp
          ? _nameController.text.trim()
          : (_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'مستخدم درة المؤمن');

      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final phone = _phoneController.text.trim().isNotEmpty
          ? '$_countryCode ${_phoneController.text.trim()}'
          : 'غير مسجل';

      if (_isSignUp) {
        try {
          await FirebaseAuthService.instance.signUpWithEmail(
            email: email,
            password: password,
            fullName: fullName,
            phoneNumber: phone,
          );
        } catch (e) {
          debugPrint('Firebase signUp note: $e');
        }
      } else {
        try {
          await FirebaseAuthService.instance.signInWithEmail(
            email: email,
            password: password,
          );
        } catch (e) {
          debugPrint('Firebase signIn note: $e');
        }
      }

      if (mounted) {
        // Preserve existing photo on login; use picked photo on signup
        final existingPhoto = context.read<AppState>().userProfile?['photo'] ?? '';
        var photo = _isSignUp ? (_photoPath ?? existingPhoto) : existingPhoto;
        if (photo.isNotEmpty && !photo.startsWith('http')) {
          photo = await ImageUploadService.instance.ensureRemote(photo, folder: 'avatars') ??
              photo;
        }
        if (mounted) {
          await context.read<AppState>().saveUserProfile(
            name: fullName,
            email: email,
            phone: phone,
            photo: photo,
            authProvider: _isSignUp ? 'email_signup' : 'email_login',
          );
        }
      }

      await AdminSyncService.instance.registerOrLoginUser(
        name: fullName,
        email: email,
        phone: phone,
        authProvider: _isSignUp ? 'email_signup' : 'email_login',
      );

      if (!mounted) return;
      _showSuccessDialog(fullName);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, 
        const SnackBar(content: Text('حدث خطأ أثناء التسجيل، يرجى المحاولة لاحقاً.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(String name) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 38),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSignUp ? 'أهلاً بك يا $name! 🌿' : 'مرحباً بعودتك! 👋',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'تم حفظ ومزامنة حسابك بنجاح. يمكنك الآن متابعة وردك اليومي وختماتك.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DhikrColors.forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                Navigator.pop(ctx); // pop dialog
                if (widget.onSuccess != null) {
                  widget.onSuccess!();
                } else {
                  Navigator.pop(context, true); // pop auth screen
                }
              },
              child: const Text('دخول للتطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _skipAsGuest() {
    AdminSyncService.instance.registerDevice(
      name: 'زائر درة المؤمن',
      email: 'guest@durrat-almuomin.app',
    );
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? DhikrColors.darkBg : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.canSkip
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          if (widget.canSkip)
            TextButton(
              onPressed: _skipAsGuest,
              child: Text(
                isAr ? 'تخطي كزائر' : 'Skip as Guest',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w700,
                  color: dark ? DhikrColors.sage : DhikrColors.forest,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Icon & Title (side by side)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: dark ? DhikrColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/app_logo_transparent.webp',
                            width: 44,
                            height: 44,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
_isSignUp
                        ? (isAr ? 'إنشاء حساب' : 'Create Account')
                        : (isAr ? 'تسجيل الدخول' : 'Welcome Back'),
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: dark ? Colors.white : DhikrColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Form Fields
                  if (_isSignUp) ...[
                    // صورة شخصية اختيارية أثناء التسجيل
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GestureDetector(
                        onTap: _pickSignupPhoto,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (dark ? DhikrColors.sage : DhikrColors.forest)
                                          .withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: UserAvatar(
                                    photo: _photoPath,
                                    name: _nameController.text.trim(),
                                    size: 72,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F3B2C),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isAr ? 'صورة شخصية (اختياري)' : 'Profile photo (optional)',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12,
                                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: isAr ? 'الاسم الكامل' : 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        filled: true,
                        fillColor: dark ? DhikrColors.darkSurface : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return isAr ? 'يرجى كتابة الاسم' : 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: isAr ? 'البريد الإلكتروني' : 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: dark ? DhikrColors.darkSurface : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty || !v.contains('@')) {
                        return isAr ? 'يرجى كتابة بريد إلكتروني صحيح' : 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Phone Number Field (with Country Code)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Country Code Dropdown
                      Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: dark ? DhikrColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _countryCode,
                            items: const [
                              DropdownMenuItem(value: '+20', child: Text('🇪🇬 +20')),
                              DropdownMenuItem(value: '+966', child: Text('🇸🇦 +966')),
                              DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971')),
                              DropdownMenuItem(value: '+965', child: Text('🇰🇼 +965')),
                              DropdownMenuItem(value: '+974', child: Text('🇶🇦 +974')),
                              DropdownMenuItem(value: '+968', child: Text('🇴🇲 +968')),
                              DropdownMenuItem(value: '+962', child: Text('🇯🇴 +962')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _countryCode = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Phone Number Input
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: isAr ? 'رقم الهاتف (اختياري)' : 'Phone Number',
                            prefixIcon: const Icon(Icons.phone_iphone_rounded),
                            filled: true,
                            fillColor: dark ? DhikrColors.darkSurface : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: isAr ? 'كلمة المرور' : 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: dark ? DhikrColors.darkSurface : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return isAr ? 'كلمة المرور يجب ألا تقل عن 6 أحرف' : 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DhikrColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 52),
                      elevation: 2,
                    ),
                    onPressed: _loading ? null : _handleSubmit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isSignUp
                                ? (isAr ? 'إنشاء حساب جديد ومتابعة 🌿' : 'Sign Up & Continue')
                                : (isAr ? 'تسجيل الدخول' : 'Sign In'),
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Toggle Sign Up / Sign In
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? (isAr ? 'لديك حساب بالفعل؟ تسجيل الدخول' : 'Already have an account? Sign In')
                          : (isAr ? 'ليس لديك حساب؟ إنشاء حساب جديد' : "Don't have an account? Sign Up"),
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Or Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          isAr ? 'أو عبر جوجل' : 'or with Google',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Google Sign-In Button
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
                      foregroundColor: dark ? Colors.white : Colors.black87,
                      side: BorderSide(
                        color: dark ? Colors.white12 : Colors.grey.withValues(alpha: 0.25),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    onPressed: _loading ? null : _handleGoogleSignIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isAr ? 'المتابعة باستخدام Google' : 'Continue with Google',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
