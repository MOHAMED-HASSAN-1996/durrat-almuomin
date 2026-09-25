import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../services/image_upload_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _photoPath;
  bool _saving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().userProfile;
    _nameController = TextEditingController(text: profile?['name'] ?? '');
    _emailController = TextEditingController(text: profile?['email'] ?? '');
    final phone = profile?['phone'] ?? '';
    _phoneController = TextEditingController(text: phone == 'غير مسجل' ? '' : phone);
    _photoPath = profile?['photo'];
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final appState = context.read<AppState>();
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        if (!mounted) return;
        setState(() => _photoPath = picked.path);
        var photo = await ImageUploadService.instance.ensureRemote(
              picked.path,
              folder: 'avatars',
            ) ??
            picked.path;
        final currentProfile = appState.userProfile;
        await appState.saveUserProfile(
          name: _nameController.text.trim().isEmpty ? (currentProfile?['name'] ?? 'مستخدم') : _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? 'غير مسجل' : _phoneController.text.trim(),
          photo: photo,
          authProvider: currentProfile?['authProvider'] ?? 'email',
        );
        if (mounted) {
          setState(() => _photoPath = photo);
          AppToast.show(context, 
            const SnackBar(
              content: Text('تم تحديث صورتك الشخصية بنجاح ✨', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
              backgroundColor: Color(0xFF0F3B2C),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  void _showPhotoOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final isAr = Provider.of<AppState>(ctx, listen: false).language == AppLanguage.arabic;
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF14221C) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'تعديل الصورة الشخصية 📷',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(LucideIcons.image, color: Color(0xFF0F3B2C)),
                  title: const Text('اختيار من المعرض', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.camera, color: Color(0xFF0F3B2C)),
                  title: const Text('التقاط صورة بالكاميرا', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                if (_photoPath != null && _photoPath!.isNotEmpty)
                  ListTile(
                    leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                    title: const Text('حذف الصورة الحالية', style: TextStyle(fontFamily: DhikrTheme.arabicFont, color: Colors.redAccent)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() => _photoPath = '');
                      final appState = context.read<AppState>();
                      final currentProfile = appState.userProfile;
                      await appState.saveUserProfile(
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        phone: _phoneController.text.trim(),
                        photo: '',
                        authProvider: currentProfile?['authProvider'] ?? 'email',
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _saving = true);

    final appState = context.read<AppState>();
    final currentProfile = appState.userProfile;
    final photo = currentProfile?['photo'] ?? '';
    final authProvider = currentProfile?['authProvider'] ?? 'email';

    await appState.saveUserProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? 'غير مسجل' : _phoneController.text.trim(),
      photo: photo,
      authProvider: authProvider,
    );

    if (mounted) {
      setState(() => _saving = false);
      AppToast.show(context, 
        const SnackBar(
          content: Text(
            'تم حفظ وتحديث بيانات حسابك بنجاح ✨',
            style: TextStyle(fontFamily: DhikrTheme.arabicFont),
          ),
          backgroundColor: Color(0xFF0F3B2C),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isAr = appState.language == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final profile = appState.userProfile;
    final name = profile?['name'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0),
        appBar: AppBar(
          title: Text(
            isAr ? 'الملف الشخصي والحساب' : 'Profile & Account',
            style: const TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. Greeting & Avatar (Clean Header Without Background) ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                        child: Column(
                          children: [
                            // Avatar with Edit Button
                            GestureDetector(
                              onTap: _showPhotoOptionsSheet,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0F3B2C), Color(0xFF1E5B45)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFF0F3B2C).withValues(alpha: 0.3),
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
                                          blurRadius: 14,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _photoPath != null && _photoPath!.isNotEmpty
                                          ? (_photoPath!.startsWith('http')
                                              ? Image.network(
                                                  _photoPath!,
                                                  width: 92,
                                                  height: 92,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => Center(
                                                    child: Text(
                                                      initial,
                                                      style: const TextStyle(
                                                        fontFamily: DhikrTheme.arabicFont,
                                                        fontSize: 34,
                                                        fontWeight: FontWeight.w900,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : (File(_photoPath!).existsSync()
                                                  ? Image.file(
                                                      File(_photoPath!),
                                                      width: 92,
                                                      height: 92,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        initial,
                                                        style: const TextStyle(
                                                          fontFamily: DhikrTheme.arabicFont,
                                                          fontSize: 34,
                                                          fontWeight: FontWeight.w900,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    )))
                                          : Center(
                                              child: Text(
                                                initial,
                                                style: const TextStyle(
                                                  fontFamily: DhikrTheme.arabicFont,
                                                  fontSize: 34,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F3B2C),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: dark ? const Color(0xFF0A1612) : Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(LucideIcons.camera, color: Colors.white, size: 15),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              isAr
                                  ? (name.isNotEmpty ? 'أهلاً بك، $name 🌿' : 'أهلاً بك يا مؤمن 🌿')
                                  : (name.isNotEmpty ? 'Welcome, $name' : 'Welcome'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w900,
                                fontSize: 21,
                                color: dark ? Colors.white : DhikrColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr
                                  ? 'اضغط على الصورة لتغييرها، أو عدل بياناتك أدناه'
                                  : 'Tap photo to edit, or update your information below',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── 2. Data Completion & Edit Form ──
                      Text(
                        isAr ? 'البيانات الشخصية' : 'Personal Details',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: dark ? DhikrColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: dark
                                ? Colors.white.withValues(alpha: 0.08)
                                : DhikrColors.charcoal.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Full Name Field
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: dark ? Colors.white : DhikrColors.charcoal,
                              ),
                              decoration: InputDecoration(
                                labelText: isAr ? 'الاسم بالكامل' : 'Full Name',
                                labelStyle: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: dark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF94A3B8),
                                ),
                                hintText: isAr ? 'أدخل اسمك الكريم' : 'Enter your name',
                                hintStyle: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12.5,
                                  color: dark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(LucideIcons.user, size: 18, color: Color(0xFF0F3B2C)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: dark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0F3B2C),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return isAr ? 'يرجى إدخال الاسم' : 'Please enter your name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: dark ? Colors.white : DhikrColors.charcoal,
                              ),
                              decoration: InputDecoration(
                                labelText: isAr ? 'البريد الإلكتروني' : 'Email Address',
                                labelStyle: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: dark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF94A3B8),
                                ),
                                hintText: 'example@gmail.com',
                                hintStyle: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12.5,
                                  color: dark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(LucideIcons.mail, size: 18, color: Color(0xFF0F3B2C)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: dark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0F3B2C),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Phone Field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: dark ? Colors.white : DhikrColors.charcoal,
                              ),
                              decoration: InputDecoration(
                                labelText: isAr ? 'رقم الهاتف' : 'Phone Number',
                                labelStyle: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: dark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF94A3B8),
                                ),
                                hintText: isAr ? 'مثال: 01012345678' : 'e.g. +1234567890',
                                hintStyle: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12.5,
                                  color: dark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(LucideIcons.phone, size: 18, color: Color(0xFF0F3B2C)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: dark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0F3B2C),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── 3. Save Button ──
                      FilledButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F3B2C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.checkCheck, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAr ? 'حفظ وتحديث البيانات' : 'Save & Update',
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 16),

                      // ── 4. Log out option ──
                      OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(isAr ? 'تسجيل الخروج' : 'Log out'),
                              content: Text(
                                isAr
                                    ? 'هل أنت متأكد من رغبتك في تسجيل الخروج من هذا الحساب؟'
                                    : 'Are you sure you want to log out?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE55353),
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(isAr ? 'خروج' : 'Log out'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            await context.read<AppState>().logoutUser();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        icon: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFE55353)),
                        label: Text(
                          isAr ? 'تسجيل الخروج من الحساب' : 'Log Out',
                          style: const TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE55353),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: const Color(0xFFE55353).withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── 5. Permanently Delete Account (Google Play Policy) ──
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            HapticFeedback.heavyImpact();
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Row(
                                  children: [
                                    const Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAr ? 'حذف الحساب نهائياً' : 'Delete Account',
                                      style: const TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  isAr
                                      ? 'تنبيه: سيتم حذف حسابك وبياناتك المسجلة نهائياً، ولن تتمكن من استرجاعها. هل تريد المتابعة بالتأكيد؟'
                                      : 'Warning: Your account and associated data will be permanently deleted. This action cannot be undone. Are you sure you want to proceed?',
                                  style: const TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 13.5),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(isAr ? 'إلغاء' : 'Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(isAr ? 'نعم، حذف الحساب' : 'Delete Permanently'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              try {
                                await context.read<AppState>().deleteAccount();
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  AppToast.show(context, 
                                    SnackBar(
                                      content: Text(
                                        isAr ? 'تم حذف حسابك وبياناتك بنجاح' : 'Your account has been deleted successfully',
                                        style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF0F3B2C),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppToast.show(context, 
                                    SnackBar(
                                      content: Text(
                                        isAr
                                            ? 'لدواعي الأمان، يرجى تسجيل الدخول مجدداً ثم المحاولة ثانية لحذف الحساب'
                                            : 'For security reasons, please re-authenticate before deleting your account',
                                        style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.red.shade800,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFDC2626)),
                          label: Text(
                            isAr ? 'حذف الحساب والبيانات نهائياً' : 'Permanently Delete Account',
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
