import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/loved_one.dart';
import '../services/image_upload_service.dart';
import '../services/loved_ones_service.dart';
import '../services/profanity_filter_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import 'auth_screen.dart';
import '../widgets/app_toast.dart';

class AddLovedOneScreen extends StatefulWidget {
  const AddLovedOneScreen({super.key, this.itemToEdit});

  final LovedOneItem? itemToEdit;

  @override
  State<AddLovedOneScreen> createState() => _AddLovedOneScreenState();
}

class _AddLovedOneScreenState extends State<AddLovedOneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _duaController = TextEditingController();

  LovedOneCategory _selectedCategory = LovedOneCategory.deceased;
  String? _imagePath;
  bool _isSaving = false;
  final ScrollController _scrollCtrl = ScrollController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final it = widget.itemToEdit!;
      _nameController.text = it.name;
      _selectedCategory = it.category;
      _imagePath = it.imagePath;
      _duaController.text = it.customDua ?? it.category.defaultDuaAr;
    } else {
      _duaController.text = _selectedCategory.defaultDuaAr;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _duaController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() => _imagePath = picked.path);
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
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
                'اختيار صورة للشخص المراد الدعاء له',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.image, color: Color(0xFFC5A059)),
                title: const Text('اختيار من المعرض', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.camera, color: Color(0xFFC5A059)),
                title: const Text('التقاط صورة بالكاميرا', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_imagePath != null)
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                  title: const Text('حذف الصورة الحالية', style: TextStyle(fontFamily: DhikrTheme.arabicFont, color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _imagePath = null);
                  },
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1B2E26) : const Color(0xFFF1F5F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 16, color: Color(0xFFC5A059)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يرجى مراعاة الخصوصية وعدم نشر صور حساسة للمرضى احتراماً لكرامة المؤمن.',
                        style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _ensureLoggedIn() async {
    final appState = context.read<AppState>();
    if (appState.isLoggedIn) return true;

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          canSkip: false,
          onSuccess: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );
    if (!mounted) return false;
    if (ok == true) {
      await context.read<AppState>().load();
      return mounted && context.read<AppState>().isLoggedIn;
    }
    return false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final loggedIn = await _ensureLoggedIn();
    if (!loggedIn || !mounted) return;

    final profile = context.read<AppState>().userProfile;
    setState(() => _isSaving = true);

    // Rate limiting: max 2 prayers per day
    if (widget.itemToEdit == null) {
      final canAdd = await LovedOnesService.instance.canAddPrayerToday();
      if (!canAdd) {
        if (mounted) {
          setState(() => _isSaving = false);
          await _showRateLimitDialog(context);
        }
        return;
      }
    }

    var remoteImage = _imagePath;
    if (remoteImage != null && remoteImage.isNotEmpty) {
      final uploaded =
          await ImageUploadService.instance.ensureRemote(remoteImage, folder: 'posts');
      if (uploaded == null) {
        if (mounted) {
          setState(() => _isSaving = false);
          AppToast.show(context, 
            const SnackBar(
              content: Text('تعذر رفع الصورة، تحقق من الاتصال وحاول مجدداً.'),
            ),
          );
        }
        return;
      }
      remoteImage = uploaded;
    }

    var authorPhoto = widget.itemToEdit?.authorPhoto ?? (profile?['photo'] ?? '');
    if (authorPhoto.isNotEmpty && !authorPhoto.startsWith('http')) {
      authorPhoto =
          await ImageUploadService.instance.ensureRemote(authorPhoto, folder: 'avatars') ??
              authorPhoto;
    }

    final id = widget.itemToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final item = LovedOneItem(
      id: id,
      name: _nameController.text.trim(),
      relation: '',
      category: _selectedCategory,
      imagePath: remoteImage,
      customDua: _duaController.text.trim(),
      fatihaCount: widget.itemToEdit?.fatihaCount ?? 0,
      loveCount: widget.itemToEdit?.loveCount ?? 0,
      comments: widget.itemToEdit?.comments,
      createdAt: widget.itemToEdit?.createdAt,
      authorName: widget.itemToEdit?.authorName ?? (profile?['name'] ?? ''),
      authorPhoto: authorPhoto,
    );

    if (widget.itemToEdit != null) {
      await LovedOnesService.instance.updateLovedOne(item);
    } else {
      await LovedOnesService.instance.addLovedOne(item);
      await LovedOnesService.instance.recordPrayerAddedToday();
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (widget.itemToEdit != null) {
        await _showThankYouDialog(context, isEdit: true);
        if (mounted) {
          Navigator.pop(context, true);
        }
        return;
      }
      // وضع الإضافة: حفظ صامت + مسح الحقول والبقاء في الشاشة (بدون أي نتيجة)
      _resetForm();
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedCategory = LovedOneCategory.deceased;
      _nameController.clear();
      _duaController.text = _selectedCategory.defaultDuaAr;
      _imagePath = null;
    });
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _showThankYouDialog(BuildContext context, {required bool isEdit}) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: dark ? const Color(0xFF14241E) : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.heartHandshake, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'جزاكم الله خيراً 🤲',
                  style: TextStyle(
                    fontFamily: DhikrTheme.titleFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit
                    ? 'تم تحديث بيانات طلب الدعاء بنجاح.'
                    : 'تقبل الله طاعتكم، تم نشر طلب الدعاء بظهر الغيب بنجاح.',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: dark ? Colors.white : const Color(0xFF0F3B2C),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF0D1713) : const Color(0xFFF4F9F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.calendarClock, size: 18, color: Color(0xFFC5A059)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيظل الطلب نشطاً في المجتمع لمدة ٣٠ يوماً ليتسابق إخوانك في التأمين وقراءة الفاتحة، وبإمكانك تجديده دائماً.',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 12,
                          height: 1.45,
                          color: dark ? Colors.white70 : const Color(0xFF2E5E4E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF163E32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'آمين.. تقبل الله منا ومنكم ✨',
                  style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRateLimitDialog(BuildContext context) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;
    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          backgroundColor: dark ? const Color(0xFF14241E) : Colors.white,
          title: const Row(
            children: [
              Icon(LucideIcons.alertCircle, color: Colors.orange, size: 24),
              SizedBox(width: 10),
              Text(
                'الحد اليومي للإضافة',
                style: TextStyle(fontFamily: DhikrTheme.titleFont, fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ],
          ),
          content: const Text(
            'عذراً، لقد بلغت الحد الأقصى المسموح به اليوم (طلبين دعاء يومياً)، وذلك لإتاحة الفرصة لجميع المسلمين وحفظ نظام المجتمع المبارك. جزاكم الله خيراً.',
            style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 13.5, height: 1.5),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF163E32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً، جزاكم الله خيراً', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0D1612) : const Color(0xFFF7FBF9),
        appBar: AppBar(
          title: Text(
            widget.itemToEdit != null ? 'تعديل بيانات الدعاء' : 'دعوة بظهر الغيب',
            style: const TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Picker Area (Large Modern Square/Rectangle Field)
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      width: double.infinity,
                      height: 175,
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF14241E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _imagePath != null
                              ? const Color(0xFF0F3B2C)
                              : (dark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF0F3B2C).withValues(alpha: 0.2)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _imagePath != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  _imagePath!.startsWith('http')
                                      ? Image.network(
                                          _imagePath!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Center(
                                            child: Icon(LucideIcons.image,
                                                size: 40,
                                                color: Color(0xFF0F3B2C)),
                                          ),
                                        )
                                      : Image.file(
                                          File(_imagePath!),
                                          fit: BoxFit.cover,
                                        ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.1),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.55),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    left: 12,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.camera, size: 14, color: Colors.white),
                                              SizedBox(width: 6),
                                              Text(
                                                'تغيير الصورة',
                                                style: TextStyle(
                                                  fontFamily: DhikrTheme.arabicFont,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(() => _imagePath = null),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent.withValues(alpha: 0.85),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(LucideIcons.trash2, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F3B2C).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.imagePlus,
                                        size: 26,
                                        color: Color(0xFF0F3B2C),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'إضافة صورة للشخص العزيز (اختياري)',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: dark ? Colors.white : const Color(0xFF0F3B2C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'انقر هنا للاختيار من المعرض أو التقاط صورة بالكاميرا',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 11.5,
                                      color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Selector
                  const Text(
                    'الحالة والنية للدعاء:',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LovedOneCategory.values.map((cat) {
                      final selected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(
                          cat.badgeLabelAr,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12.5,
                            color: selected
                                ? Colors.white
                                : (dark
                                      ? DhikrColors.darkText
                                      : DhikrColors.charcoal),
                          ),
                        ),
                        selected: selected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedCategory = cat;
                              if (widget.itemToEdit == null || _duaController.text.isEmpty) {
                                _duaController.text = cat.defaultDuaAr;
                              }
                            });
                          }
                        },
                        selectedColor: DhikrColors.forest,
                        backgroundColor:
                            dark ? DhikrColors.darkSurface : Colors.white,
                        elevation: 0,
                        pressElevation: 0,
                        side: BorderSide(
                          color: selected
                              ? DhikrColors.forest
                              : (dark
                                    ? DhikrColors.sageSoft
                                        .withValues(alpha: 0.2)
                                    : const Color(0xFFE5E7EB)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Name field
                  Text(
                    'اسم الشخص المراد الدعاء له:',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: dark ? Colors.white70 : DhikrColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'يرجى إدخال اسم الشخص';
                      return ProfanityFilterService.validateText(v, fieldName: 'الاسم');
                    },
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: dark ? Colors.white : DhikrColors.charcoal,
                    ),
                    decoration: InputDecoration(
                      hintText: 'مثال: والدي العزيز محمد، والدتي الغالية، أخي أحمد...',
                      hintStyle: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w300,
                        color: dark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: dark ? const Color(0xFF15221C) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF0F3B2C), width: 1.4),
                      ),
                      prefixIcon: const Icon(LucideIcons.user, size: 18, color: Color(0xFF0F3B2C)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dedicated Dua
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الدعاء المخصص له:',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: dark ? Colors.white70 : DhikrColors.charcoal,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _duaController.text = _selectedCategory.defaultDuaAr;
                          });
                        },
                        icon: const Icon(LucideIcons.rotateCcw, size: 14, color: Color(0xFF0F3B2C)),
                        label: const Text(
                          'استعادة الدعاء المقترح',
                          style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 12, color: Color(0xFF0F3B2C)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _duaController,
                    maxLines: 4,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'يرجى كتابة نص الدعاء';
                      return ProfanityFilterService.validateText(v, fieldName: 'نص الدعاء');
                    },
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: dark ? Colors.white : DhikrColors.charcoal,
                    ),
                    decoration: InputDecoration(
                      hintText: 'اكتب الدعاء الذي تحب أن تدعو له به دائماً...',
                      hintStyle: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w300,
                        color: dark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: dark ? const Color(0xFF15221C) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 30-Day Retention Notice Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF132B22) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 20,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مدة بقاء الطلب في المجتمع (٣٠ يوماً)',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: dark ? Colors.white : const Color(0xFF0F3B2C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'يبقى طلب الدعاء معروضاً لعموم المصلين لمدة ٣٠ يوماً ليتسابق الجميع في التأمين وقراءة الفاتحة، ثم يختفي تلقائياً من المجتمع لإتاحة الفرصة لإخوانك مع بقائه في سجلك وإمكانية تجديده في أي وقت 🤲',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11.5,
                                  height: 1.45,
                                  color: dark ? Colors.white70 : const Color(0xFF2E5E4E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF163E32),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : Text(
                              widget.itemToEdit != null ? 'حفظ التعديلات' : 'إضافة إلى قائمة الدعاء 🤲',
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
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
    );
  }
}
