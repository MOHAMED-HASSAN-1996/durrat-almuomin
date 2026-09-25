import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/loved_one.dart';
import '../services/loved_ones_service.dart';
import '../services/profanity_filter_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import 'add_loved_one_screen.dart';
import '../widgets/app_toast.dart';
import '../widgets/report_dialog.dart';

class LovedOneDetailScreen extends StatefulWidget {
  const LovedOneDetailScreen({super.key, required this.item});

  final LovedOneItem item;

  @override
  State<LovedOneDetailScreen> createState() => _LovedOneDetailScreenState();
}

class _LovedOneDetailScreenState extends State<LovedOneDetailScreen> {
  late LovedOneItem _item;
  final _commentController = TextEditingController();
  bool _showFatihaText = true;
  bool _isMine = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadCloudComments();
    _checkMine();
  }

  Future<void> _checkMine() async {
    final ids = await LovedOnesService.instance.getMyCreatedIds();
    if (mounted && ids.contains(_item.id)) {
      setState(() => _isMine = true);
    }
  }

  Future<void> _loadCloudComments() async {
    final comments = await LovedOnesService.instance.loadComments(_item.id);
    if (!mounted || comments.isEmpty) return;
    setState(() {
      _item.comments
        ..clear()
        ..addAll(comments);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _incrementFatiha() async {
    HapticFeedback.lightImpact();
    setState(() => _item.fatihaCount += 1);
    final newCount = await LovedOnesService.instance.incrementFatiha(_item.id);
    if (mounted) setState(() => _item.fatihaCount = newCount);
  }

  Future<void> _toggleHeart() async {
    HapticFeedback.mediumImpact();
    setState(() => _item.loveCount += 1);
    final newCount = await LovedOnesService.instance.toggleHeart(_item.id);
    if (mounted) setState(() => _item.loveCount = newCount);
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (LovedOnesService.instance.isCommentInCooldown) {
      AppToast.show(context, 
        const SnackBar(
          content: Text('يرجى الانتظار بضع ثوانٍ قبل إرسال دعاء آخر ⏱️'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final err = ProfanityFilterService.validateText(text, fieldName: 'التعليق');
    if (err != null) {
      AppToast.show(context, 
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    await LovedOnesService.instance.addComment(_item.id, text);
    _commentController.clear();
    setState(() {});
  }

  void _shareDuaCard() {
    HapticFeedback.lightImpact();
    final text = '''
دعاء مهدي إلى: ${_item.name} (${_item.category.badgeLabelAr})
«${_item.customDua ?? _item.category.defaultDuaAr}»

نسألكم قراءة الفاتحة والدعاء له بظهر الغيب 🤲
(تم الإرسال من تطبيق درة المؤمن)
''';
    Clipboard.setData(ClipboardData(text: text));
    AppToast.show(context, 
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('تم نسخ بطاقة الدعاء لنشرها أو مشاركتها 🌿', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف من قائمة الدعاء', style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800)),
        content: Text('هل أنت متأكد من رغبتك في حذف ${_item.name}؟', style: const TextStyle(fontFamily: DhikrTheme.arabicFont)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
          ),
          TextButton(
            onPressed: () async {
              await LovedOnesService.instance.deleteLovedOne(_item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('حذف', style: TextStyle(fontFamily: DhikrTheme.arabicFont, color: Colors.redAccent)),
          ),
        ],
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
            _item.name,
            style: const TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.share2, size: 20),
              tooltip: 'مشاركة بطاقة الدعاء',
              onPressed: _shareDuaCard,
            ),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical, size: 20),
              onSelected: (val) async {
                if (val == 'edit') {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddLovedOneScreen(itemToEdit: _item),
                    ),
                  );
                  if (updated == true) {
                    final items = await LovedOnesService.instance.loadLovedOnes();
                    final found = items.firstWhere((e) => e.id == _item.id, orElse: () => _item);
                    setState(() => _item = found);
                  }
                } else if (val == 'delete') {
                  _confirmDelete();
                } else if (val == 'renew') {
                  await LovedOnesService.instance.renewLovedOne(_item.id);
                  final items = await LovedOnesService.instance.loadLovedOnes();
                  final found =
                      items.firstWhere((e) => e.id == _item.id, orElse: () => _item);
                  if (mounted) setState(() => _item = found);
                  if (context.mounted) {
                    AppToast.show(context,
                      const SnackBar(
                        content: Text('تم تجديد ظهور طلب الدعاء في المجتمع لـ ٣٠ يوماً إضافية 🤲'),
                      ),
                    );
                  }
                } else if (val == 'report') {
                  showLovedOneReportDialog(context, _item, onReported: () {
                    if (mounted) Navigator.pop(context, true);
                  });
                }
              },
              itemBuilder: (_) => [
                if (_isMine && _item.isExpired)
                  const PopupMenuItem(
                    value: 'renew',
                    child: Row(
                      children: [
                        Icon(LucideIcons.rotateCcw, size: 16, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('تجديد الطلب', style: TextStyle(fontFamily: DhikrTheme.arabicFont, color: Colors.amber)),
                      ],
                    ),
                  ),
                if (!_isMine)
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(LucideIcons.flag, size: 16, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('إبلاغ عن محتوى', style: TextStyle(fontFamily: DhikrTheme.arabicFont, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(LucideIcons.edit, size: 16, color: Color(0xFFC5A059)),
                      SizedBox(width: 8),
                      Text('تعديل البيانات', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(fontFamily: DhikrTheme.arabicFont, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              children: [
                // Top Header Card (Photo + Name + Relation + Category)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: dark
                          ? [const Color(0xFF14241D), const Color(0xFF0C1612)]
                          : [Colors.white, const Color(0xFFF9FAF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF0F3B2C).withValues(alpha: 0.12),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Photo (Square Rounded Card instead of Circle)
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _item.category.color.withValues(alpha: 0.5),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19.5),
                          child: _item.imagePath != null &&
                                  _item.imagePath!.isNotEmpty
                              ? (_item.imagePath!.startsWith('http')
                                  ? Image.network(
                                      _item.imagePath!,
                                      fit: BoxFit.cover,
                                      width: 160,
                                      height: 160,
                                      errorBuilder: (_, _, _) => Container(
                                        color: _item.category.color
                                            .withValues(alpha: 0.12),
                                        child: Center(
                                          child: Icon(
                                            _item.category.icon,
                                            size: 56,
                                            color: _item.category.color,
                                          ),
                                        ),
                                      ),
                                    )
                                  : (File(_item.imagePath!).existsSync()
                                      ? Image.file(
                                          File(_item.imagePath!),
                                          fit: BoxFit.cover,
                                          width: 160,
                                          height: 160,
                                        )
                                      : Container(
                                          color: _item.category.color
                                              .withValues(alpha: 0.12),
                                          child: Center(
                                            child: Icon(
                                              _item.category.icon,
                                              size: 56,
                                              color: _item.category.color,
                                            ),
                                          ),
                                        )))
                              : Container(
                                  color: _item.category.color.withValues(alpha: 0.12),
                                  child: Center(
                                    child: Icon(
                                      _item.category.icon,
                                      size: 56,
                                      color: _item.category.color,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        _item.name,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: dark ? Colors.white : const Color(0xFF0F3E33),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _item.category.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _item.category.color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _item.category.badgeLabelAr,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: _item.category.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Interactive Counter Row (Fatiha & Heart)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Fatiha Count Badge
                          _buildStatCounter(
                            icon: LucideIcons.bookOpen,
                            label: 'قراءات الفاتحة',
                            count: _item.fatihaCount,
                            color: const Color(0xFF0F3B2C),
                            dark: dark,
                          ),
                          Container(width: 1, height: 36, color: Colors.grey.withValues(alpha: 0.2)),
                          // Heart Count Badge
                          GestureDetector(
                            onTap: _toggleHeart,
                            child: _buildStatCounter(
                              icon: LucideIcons.heart,
                              label: 'دعوات وتفاعل',
                              count: _item.loveCount,
                              color: const Color(0xFFE11D48),
                              dark: dark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Surah Al-Fatihah Recitation Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF14221C) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF0F3B2C).withValues(alpha: 0.12),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.sparkles, color: dark ? DhikrColors.sage : const Color(0xFF0F3B2C), size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'سورة الفاتحة مهداة إليه',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              _showFatihaText ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _showFatihaText = !_showFatihaText),
                          ),
                        ],
                      ),
                      if (_showFatihaText) ...[
                        const Divider(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: dark ? const Color(0xFF0F1B16) : const Color(0xFFF9FAF8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: dark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFF0F3B2C).withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ﴿١﴾ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ﴿٢﴾ الرَّحْمَٰنِ الرَّحِيمِ ﴿٣﴾ مَالِكِ يَوْمِ الدِّينِ ﴿٤﴾ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ﴿٥﴾ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ﴿٦﴾ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ ﴿٧﴾',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 18,
                              height: 1.9,
                              color: dark ? Colors.white : const Color(0xFF0F3B2C),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Large Tap Button to Increment Fatiha
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _incrementFatiha,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F3B2C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(LucideIcons.checkCheck, size: 18),
                          label: Text(
                            'قرأت الفاتحة له الآن (${_item.fatihaCount})',
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dedicated Dua Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF14221C) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF0F3B2C).withValues(alpha: 0.12),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.heartHandshake, color: dark ? DhikrColors.sage : const Color(0xFF0F3B2C), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'الدعاء المأثور له',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF0F1B16) : const Color(0xFFF9FAF8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: dark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFF0F3B2C).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          _item.customDua ?? _item.category.defaultDuaAr,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 14.5,
                            height: 1.7,
                            fontWeight: FontWeight.w600,
                            color: dark ? Colors.white : const Color(0xFF0F3B2C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Comments & Prayers Log Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF14221C) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF0F3B2C).withValues(alpha: 0.12),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.messageSquare, color: dark ? DhikrColors.sage : const Color(0xFF0F3B2C), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'سجل الأدعية والخواطر له',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Input field to add new prayer note
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(fontFamily: DhikrTheme.bodyFont, fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: 'اكتب دعاءً أو خاطرة طيبة له...',
                                hintStyle: TextStyle(
                                  fontFamily: DhikrTheme.bodyFont,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: dark ? Colors.white38 : const Color(0xFF8C959F),
                                ),
                                filled: true,
                                fillColor: dark ? const Color(0xFF0F1B16) : const Color(0xFFF9FAF8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF0F3B2C).withValues(alpha: 0.1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF0F3B2C).withValues(alpha: 0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: dark ? DhikrColors.sage : const Color(0xFF0F3B2C),
                                    width: 1.4,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addComment,
                            icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF0F3B2C),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // List of comments
                      if (_item.comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'لا توجد أدعية مسجلة بعد، اكتب أول دعاء له 🌿',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12.5,
                                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _item.comments.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: dark ? const Color(0xFF0F1B16) : const Color(0xFFF9FAF8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF0F3B2C).withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(LucideIcons.heart, size: 14, color: dark ? DhikrColors.sage : const Color(0xFF0F3B2C)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _item.comments[i],
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 13,
                                        height: 1.4,
                                        color: dark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCounter({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool dark,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: dark ? Colors.white : const Color(0xFF0F2D24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 11.5,
            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
          ),
        ),
      ],
    );
  }
}
