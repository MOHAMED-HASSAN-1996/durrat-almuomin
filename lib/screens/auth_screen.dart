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

/// كود الدولة → علم إيموجي (من الـ ISO2: أحرف تدل إقليميًا).
String _flagEmoji(String iso2) {
  final upper = iso2.toUpperCase();
  if (upper.length != 2 || upper[0].codeUnitAt(0) < 65 || upper[0].codeUnitAt(0) > 90) {
    return '🌍';
  }
  return String.fromCharCodes(
    upper.codeUnits.map((c) => 0x1F1E6 - 0x41 + c),
  );
}

/// كل دول العالم المتاحة للاختيار (العلم + كود الاتصال + الاسم بالعربي والإنجليزي).
const List<({String iso2, String dial, String nameAr, String nameEn})>
    _countryCodes = [
  (iso2: 'EG', dial: '+20', nameAr: 'مصر', nameEn: 'Egypt'),
  (iso2: 'SA', dial: '+966', nameAr: 'السعودية', nameEn: 'Saudi Arabia'),
  (iso2: 'AE', dial: '+971', nameAr: 'الإمارات', nameEn: 'United Arab Emirates'),
  (iso2: 'KW', dial: '+965', nameAr: 'الكويت', nameEn: 'Kuwait'),
  (iso2: 'QA', dial: '+974', nameAr: 'قطر', nameEn: 'Qatar'),
  (iso2: 'BH', dial: '+973', nameAr: 'البحرين', nameEn: 'Bahrain'),
  (iso2: 'OM', dial: '+968', nameAr: 'عُمان', nameEn: 'Oman'),
  (iso2: 'JO', dial: '+962', nameAr: 'الأردن', nameEn: 'Jordan'),
  (iso2: 'IQ', dial: '+964', nameAr: 'العراق', nameEn: 'Iraq'),
  (iso2: 'SY', dial: '+963', nameAr: 'سوريا', nameEn: 'Syria'),
  (iso2: 'LB', dial: '+961', nameAr: 'لبنان', nameEn: 'Lebanon'),
  (iso2: 'PS', dial: '+970', nameAr: 'فلسطين', nameEn: 'Palestine'),
  (iso2: 'YE', dial: '+967', nameAr: 'اليمن', nameEn: 'Yemen'),
  (iso2: 'LY', dial: '+218', nameAr: 'ليبيا', nameEn: 'Libya'),
  (iso2: 'SD', dial: '+249', nameAr: 'السودان', nameEn: 'Sudan'),
  (iso2: 'MR', dial: '+222', nameAr: 'موريتانيا', nameEn: 'Mauritania'),
  (iso2: 'MA', dial: '+212', nameAr: 'المغرب', nameEn: 'Morocco'),
  (iso2: 'DZ', dial: '+213', nameAr: 'الجزائر', nameEn: 'Algeria'),
  (iso2: 'TN', dial: '+216', nameAr: 'تونس', nameEn: 'Tunisia'),
  (iso2: 'SO', dial: '+252', nameAr: 'الصومال', nameEn: 'Somalia'),
  (iso2: 'DJ', dial: '+253', nameAr: 'جيبوتي', nameEn: 'Djibouti'),
  (iso2: 'KM', dial: '+269', nameAr: 'جزر القمر', nameEn: 'Comoros'),
  (iso2: 'TR', dial: '+90', nameAr: 'تركيا', nameEn: 'Turkey'),
  (iso2: 'IR', dial: '+98', nameAr: 'إيران', nameEn: 'Iran'),
  (iso2: 'PK', dial: '+92', nameAr: 'باكستان', nameEn: 'Pakistan'),
  (iso2: 'IN', dial: '+91', nameAr: 'الهند', nameEn: 'India'),
  (iso2: 'BD', dial: '+880', nameAr: 'بنغلاديش', nameEn: 'Bangladesh'),
  (iso2: 'ID', dial: '+62', nameAr: 'إندونيسيا', nameEn: 'Indonesia'),
  (iso2: 'MY', dial: '+60', nameAr: 'ماليزيا', nameEn: 'Malaysia'),
  (iso2: 'SG', dial: '+65', nameAr: 'سنغافورة', nameEn: 'Singapore'),
  (iso2: 'AF', dial: '+93', nameAr: 'أفغانستان', nameEn: 'Afghanistan'),
  (iso2: 'AZ', dial: '+994', nameAr: 'أذربيجان', nameEn: 'Azerbaijan'),
  (iso2: 'KZ', dial: '+7', nameAr: 'كازاخستان', nameEn: 'Kazakhstan'),
  (iso2: 'UZ', dial: '+998', nameAr: 'أوزبكستان', nameEn: 'Uzbekistan'),
  (iso2: 'TM', dial: '+993', nameAr: 'تركمانستان', nameEn: 'Turkmenistan'),
  (iso2: 'CN', dial: '+86', nameAr: 'الصين', nameEn: 'China'),
  (iso2: 'JP', dial: '+81', nameAr: 'اليابان', nameEn: 'Japan'),
  (iso2: 'KR', dial: '+82', nameAr: 'كوريا الجنوبية', nameEn: 'South Korea'),
  (iso2: 'TH', dial: '+66', nameAr: 'تايلاند', nameEn: 'Thailand'),
  (iso2: 'VN', dial: '+84', nameAr: 'فيتنام', nameEn: 'Vietnam'),
  (iso2: 'PH', dial: '+63', nameAr: 'الفلبين', nameEn: 'Philippines'),
  (iso2: 'GB', dial: '+44', nameAr: 'المملكة المتحدة', nameEn: 'United Kingdom'),
  (iso2: 'US', dial: '+1', nameAr: 'الولايات المتحدة', nameEn: 'United States'),
  (iso2: 'CA', dial: '+1', nameAr: 'كندا', nameEn: 'Canada'),
  (iso2: 'AU', dial: '+61', nameAr: 'أستراليا', nameEn: 'Australia'),
  (iso2: 'NZ', dial: '+64', nameAr: 'نيوزيلندا', nameEn: 'New Zealand'),
  (iso2: 'NL', dial: '+31', nameAr: 'هولندا', nameEn: 'Netherlands'),
  (iso2: 'BE', dial: '+32', nameAr: 'بلجيكا', nameEn: 'Belgium'),
  (iso2: 'LU', dial: '+352', nameAr: 'لوكسمبورغ', nameEn: 'Luxembourg'),
  (iso2: 'FR', dial: '+33', nameAr: 'فرنسا', nameEn: 'France'),
  (iso2: 'ES', dial: '+34', nameAr: 'إسبانيا', nameEn: 'Spain'),
  (iso2: 'PT', dial: '+351', nameAr: 'البرتغال', nameEn: 'Portugal'),
  (iso2: 'DE', dial: '+49', nameAr: 'ألمانيا', nameEn: 'Germany'),
  (iso2: 'CH', dial: '+41', nameAr: 'سويسرا', nameEn: 'Switzerland'),
  (iso2: 'AT', dial: '+43', nameAr: 'النمسا', nameEn: 'Austria'),
  (iso2: 'IT', dial: '+39', nameAr: 'إيطاليا', nameEn: 'Italy'),
  (iso2: 'GR', dial: '+30', nameAr: 'اليونان', nameEn: 'Greece'),
  (iso2: 'SE', dial: '+46', nameAr: 'السويد', nameEn: 'Sweden'),
  (iso2: 'NO', dial: '+47', nameAr: 'النرويج', nameEn: 'Norway'),
  (iso2: 'DK', dial: '+45', nameAr: 'الدنمارك', nameEn: 'Denmark'),
  (iso2: 'FI', dial: '+358', nameAr: 'فنلندا', nameEn: 'Finland'),
  (iso2: 'IE', dial: '+353', nameAr: 'أيرلندا', nameEn: 'Ireland'),
  (iso2: 'PL', dial: '+48', nameAr: 'بولندا', nameEn: 'Poland'),
  (iso2: 'UA', dial: '+380', nameAr: 'أوكرانيا', nameEn: 'Ukraine'),
  (iso2: 'RU', dial: '+7', nameAr: 'روسيا', nameEn: 'Russia'),
  (iso2: 'ZA', dial: '+27', nameAr: 'جنوب أفريقيا', nameEn: 'South Africa'),
  (iso2: 'NG', dial: '+234', nameAr: 'نيجيريا', nameEn: 'Nigeria'),
  (iso2: 'ET', dial: '+251', nameAr: 'إثيوبيا', nameEn: 'Ethiopia'),
  (iso2: 'KE', dial: '+254', nameAr: 'كينيا', nameEn: 'Kenya'),
  (iso2: 'BR', dial: '+55', nameAr: 'البرازيل', nameEn: 'Brazil'),
  (iso2: 'AR', dial: '+54', nameAr: 'الأرجنتين', nameEn: 'Argentina'),
  (iso2: 'MX', dial: '+52', nameAr: 'المكسيك', nameEn: 'Mexico'),
];

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

  ({String iso2, String dial, String nameAr, String nameEn})
      get _selectedCountry {
    for (final c in _countryCodes) {
      if (c.dial == _countryCode) return c;
    }
    return _countryCodes.first;
  }

  Future<void> _openCountryCodePicker() async {
    HapticFeedback.selectionClick();
    final isAr =
        context.read<AppState>().language == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryCodeSheet(
        initialDial: _countryCode,
        dark: dark,
        isArabic: isAr,
      ),
    );
    if (selected != null && selected != _countryCode && mounted) {
      setState(() => _countryCode = selected);
    }
  }

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  const SizedBox(height: 14),

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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
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
                  const SizedBox(height: 12),

                  // Phone Number Field (with Country Code)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(width: 8),
                      // Country Code Picker (بحث في كل الدول)
                      Material(
                        color: dark ? DhikrColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _openCountryCodePicker,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _flagEmoji(_selectedCountry.iso2),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedCountry.dial,
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: dark
                                        ? DhikrColors.darkText
                                        : DhikrColors.charcoal,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: dark
                                      ? DhikrColors.darkMuted
                                      : DhikrColors.charcoalSoft,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 16),

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

                  const SizedBox(height: 12),

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

                  const SizedBox(height: 12),

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

                  const SizedBox(height: 12),

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

/// ورقة اختيار الدولة القابلة للبحث: علم + اسم + كود الاتصال لكل دول العالم.
class _CountryCodeSheet extends StatefulWidget {
  const _CountryCodeSheet({
    required this.initialDial,
    required this.dark,
    required this.isArabic,
  });

  final String initialDial;
  final bool dark;
  final bool isArabic;

  @override
  State<_CountryCodeSheet> createState() => _CountryCodeSheetState();
}

class _CountryCodeSheetState extends State<_CountryCodeSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<({String iso2, String dial, String nameAr, String nameEn})>
      get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _countryCodes;
    return _countryCodes
        .where((c) =>
            c.nameAr.contains(q) ||
            c.nameEn.toLowerCase().contains(q) ||
            c.dial.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    final dark = widget.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF14221C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                isAr ? 'اختر الدولة' : 'Select Country',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 15,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
            decoration: InputDecoration(
              hintText:
                  isAr ? 'ابحث باسم الدولة أو كود الاتصال...' : 'Search by country or dial code...',
              hintStyle: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 13,
                color:
                    dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF4F6F5),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      isAr ? 'لا توجد نتائج' : 'No results',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        color: dark
                            ? DhikrColors.darkMuted
                            : DhikrColors.charcoalSoft,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    itemBuilder: (context, i) {
                      final c = _filtered[i];
                      final isSelected = c.dial == widget.initialDial;
                      return ListTile(
                        leading: Text(
                          _flagEmoji(c.iso2),
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          c.nameAr,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 15,
                            color:
                                dark ? DhikrColors.darkText : DhikrColors.charcoal,
                          ),
                        ),
                        subtitle: Text(
                          c.nameEn,
                          style: TextStyle(
                            fontSize: 12,
                            color: dark
                                ? DhikrColors.darkMuted
                                : DhikrColors.charcoalSoft,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c.dial,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: dark
                                    ? DhikrColors.sage
                                    : DhikrColors.forest,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color:
                                    dark ? DhikrColors.sage : DhikrColors.forest,
                              ),
                            ],
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(c.dial),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
