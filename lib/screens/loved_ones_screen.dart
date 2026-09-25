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
import '../widgets/user_avatar.dart';
import 'add_loved_one_screen.dart';
import 'loved_one_detail_screen.dart';
import '../widgets/app_toast.dart';

class LovedOnesScreen extends StatefulWidget {
  const LovedOnesScreen({super.key});

  @override
  State<LovedOnesScreen> createState() => _LovedOnesScreenState();
}

class _LovedOnesScreenState extends State<LovedOnesScreen> {
  List<LovedOneItem> _items = [];
  List<String> _myCreatedIds = [];
  Map<String, int> _userStats = {'ameen': 0, 'fatiha': 0, 'myPosts': 0};
  bool _loading = true;
  bool _showOnlyMine = false; // false = دعوات المسلمين (الكل), true = أحبتي ودعواتي

  final Set<String> _ameenInteractedIds = {};
  final Set<String> _fatihaInteractedIds = {};
  final Map<String, TextEditingController> _quickCommentCtrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _quickCommentCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final list = await LovedOnesService.instance.loadLovedOnes();
    final myIds = await LovedOnesService.instance.getMyCreatedIds();
    final stats = await LovedOnesService.instance.getUserSpiritualStats();
    if (mounted) {
      setState(() {
        _items = list;
        _myCreatedIds = myIds;
        _userStats = stats;
        _loading = false;
      });
    }
  }

  String _formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes <= 1 ? "لحظات" : "${diff.inMinutes} دقيقة"}';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} يوم';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;

    var filtered = _items;
    if (_showOnlyMine) {
      filtered = filtered.where((e) => _myCreatedIds.contains(e.id)).toList();
    }

    final totalFatiha = _items.fold<int>(0, (sum, e) => sum + e.fatihaCount);
    final totalLove = _items.fold<int>(0, (sum, e) => sum + e.loveCount);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0),
        appBar: AppBar(
          title: const Text(
            'دعاء بظهر الغيب',
            style: TextStyle(
              fontFamily: DhikrTheme.titleFont,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          actions: [
            _buildUserAccountActivityButton(context, dark),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            HapticFeedback.lightImpact();
            final res = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AddLovedOneScreen()),
            );
            if (res == true) _load();
          },
          backgroundColor: const Color(0xFF0F3B2C),
          foregroundColor: Colors.white,
          tooltip: 'إضافة دعاء جديد',
          child: const Icon(LucideIcons.plus, size: 28),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F3B2C)))
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                  children: [
                    // Feed Tab Segment: [ دعوات المسلمين (الكل) | دعواتي الخاصة ]
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF14221C) : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _showOnlyMine = false);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_showOnlyMine
                                      ? (dark ? const Color(0xFF1E3A2E) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: !_showOnlyMine
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.globe,
                                      size: 16,
                                      color: !_showOnlyMine
                                          ? const Color(0xFF0F3B2C)
                                          : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'دعوات المسلمين (الكل)',
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 13,
                                        fontWeight: !_showOnlyMine ? FontWeight.w900 : FontWeight.w600,
                                        color: !_showOnlyMine
                                            ? (dark ? Colors.white : DhikrColors.charcoal)
                                            : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _showOnlyMine = true);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _showOnlyMine
                                      ? (dark ? const Color(0xFF1E3A2E) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _showOnlyMine
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.heart,
                                      size: 16,
                                      color: _showOnlyMine
                                          ? const Color(0xFF0F3B2C)
                                          : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'دعواتي الخاصة (${_myCreatedIds.length})',
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 13,
                                        fontWeight: _showOnlyMine ? FontWeight.w900 : FontWeight.w600,
                                        color: _showOnlyMine
                                            ? (dark ? Colors.white : DhikrColors.charcoal)
                                            : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Header Stats Banner (KPI)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: dark
                              ? [const Color(0xFF14241D), const Color(0xFF0C1612)]
                              : [Colors.white, const Color(0xFFF9F8F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF0F3B2C).withValues(alpha: 0.18),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '«مَنْ دَعَا لِأَخِيهِ بِظَهْرِ الْغَيْبِ، قَالَ الْمَلَكُ الْمُوَكَّلُ بِهِ: آمِينَ وَلَكَ بِمِثْلٍ»',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: dark ? const Color(0xFFC5A059) : const Color(0xFF0F3B2C),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryStat(
                                label: 'دعوات المسلمين',
                                count: '${_items.length}',
                                icon: LucideIcons.users,
                                color: const Color(0xFF0F766E),
                                dark: dark,
                              ),
                              _buildSummaryStat(
                                label: 'قراءات الفاتحة',
                                count: '$totalFatiha',
                                icon: LucideIcons.bookOpen,
                                color: const Color(0xFFD97706),
                                dark: dark,
                              ),
                              _buildSummaryStat(
                                label: 'تأمين ودعوات',
                                count: '$totalLove',
                                icon: LucideIcons.heart,
                                color: const Color(0xFFE11D48),
                                dark: dark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Empty State
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0F3B2C).withValues(alpha: 0.12),
                              ),
                              child: const Icon(LucideIcons.heartHandshake, color: Color(0xFF0F3B2C), size: 40),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showOnlyMine
                                  ? 'لم تقم بإضافة أسماء في قائمتك بعد'
                                  : 'لا توجد دعوات في هذا التصنيف حالياً',
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'اضغط على زر الإضافة بالأسفل لكتابة طلب دعاء لمن تحب بظهر الغيب',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 13,
                                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          final isMine = _myCreatedIds.contains(item.id);
                          return _buildCommunityPrayerCard(ctx, item, dark, isMine);
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUserAccountActivityButton(BuildContext context, bool dark) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final profile = state.userProfile;
        final name = profile?['name'] ?? '';
        final photoUrl = profile?['photo'] ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showUserSpiritualActivitySheet(context, profile, dark);
            },
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1A3328) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F3B2C).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: dark ? 0.2 : 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: UserAvatar(photo: photoUrl, name: name, size: 30),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryStat({
    required String label,
    required String count,
    required IconData icon,
    required Color color,
    required bool dark,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              count,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w900,
                fontSize: 17,
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
            fontSize: 11,
            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
          ),
        ),
      ],
    );
  }

  String _getPostPhoto(LovedOneItem item) {
    final path = item.imagePath;
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http')) return path;
      if (File(path).existsSync()) return path;
    }
    const photos = [
      'assets/images/hero_fajr.webp',
      'assets/images/onboarding_athan.webp',
      'assets/images/hero_maghrib.webp',
      'assets/images/onboarding_quran.webp',
      'assets/images/hero_card_bg.webp',
      'assets/images/hero_isha.webp',
      'assets/images/onboarding_adhkar.webp',
      'assets/images/hero_asr.webp',
      'assets/images/hero_dhuhr.webp',
    ];
    final hash = item.id.hashCode.abs();
    return photos[hash % photos.length];
  }

  Widget _buildCommunityPrayerCard(BuildContext context, LovedOneItem item, bool dark, bool isMine) {
    final duaText = item.customDua?.isNotEmpty == true
        ? item.customDua!
        : item.category.defaultDuaAr;
    final postPhoto = _getPostPhoto(item);
    final hasCustomImage = item.imagePath != null &&
        item.imagePath!.isNotEmpty &&
        (item.imagePath!.startsWith('http') ||
            File(item.imagePath!).existsSync());
    final isNetworkImage = postPhoto.startsWith('http');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.selectionClick();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LovedOneDetailScreen(item: item)),
          );
          _load();
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF14221C) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isMine
                  ? const Color(0xFF0F3B2C).withValues(alpha: 0.45)
                  : (dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
              width: isMine ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Post Header: Author Avatar + Name (above time) + actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                // Author avatar
                UserAvatar(
                  photo: item.authorPhoto,
                  name: item.authorName,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author name above post time
                      Text(
                        item.authorName.trim().isEmpty
                            ? 'مستخدم درة المؤمن'
                            : item.authorName.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : DhikrColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            _formatRelativeDate(item.createdAt),
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: (item.daysRemaining <= 5 ? Colors.orange : const Color(0xFF10B981)).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 10,
                                  color: item.daysRemaining <= 5 ? Colors.orange : const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  item.isExpired ? 'انتهت الـ ٣٠ يوماً' : 'باقٍ ${item.daysRemaining} يوم',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: item.daysRemaining <= 5 ? Colors.orange : const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F3B2C).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'دعوتي',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: dark ? const Color(0xFFC5A059) : const Color(0xFF0F3B2C),
                                ),
                              ),
                            ),
                            if (item.isExpired) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () async {
                                  await LovedOnesService.instance.renewLovedOne(item.id);
                                  _load();
                                  if (context.mounted) {
                                    AppToast.show(context,
                                      const SnackBar(
                                        content: Text('تم تجديد ظهور طلب الدعاء في المجتمع لـ ٣٠ يوماً إضافية 🤲'),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber, width: 0.8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.rotateCcw, size: 9, color: Colors.amber),
                                      SizedBox(width: 2),
                                      Text(
                                        'تجديد الطلب',
                                        style: TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                          const Spacer(),
                          // Share button
                          IconButton(
                            icon: const Icon(LucideIcons.share2, size: 15),
                            tooltip: 'مشاركة الدعاء',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            color: dark ? Colors.white54 : Colors.black45,
                            onPressed: () => _shareDuaFromCard(context, item),
                          ),
                          // Edit button (only for my posts)
                          if (isMine)
                            IconButton(
                              icon: const Icon(LucideIcons.edit, size: 15),
                              tooltip: 'تعديل الدعاء',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              color: dark ? const Color(0xFFC5A059) : const Color(0xFF0F3B2C),
                              onPressed: () async {
                                final res = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddLovedOneScreen(itemToEdit: item),
                                  ),
                                );
                                if (res == true) _load();
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(LucideIcons.flag, size: 14),
                              tooltip: 'إبلاغ عن محتوى',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              color: dark ? Colors.white38 : Colors.black38,
                              onPressed: () => _showReportDialog(context, item),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Photo Banner (Height 245, Clean without duplicate title tag) ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            height: 245,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasCustomImage
                      ? (isNetworkImage
                          ? Image.network(
                              postPhoto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFF0F3B2C),
                                child: const Center(
                                  child: Icon(LucideIcons.heartHandshake,
                                      color: Colors.white, size: 40),
                                ),
                              ),
                            )
                          : Image.file(
                              File(postPhoto),
                              fit: BoxFit.cover,
                            ))
                      : Image.asset(
                          postPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFF0F3B2C),
                            child: const Center(
                              child: Icon(LucideIcons.heartHandshake, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                  // Subtle gradient overlay for photography depth
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.40),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  // شيب التصنيف عائم فوق الصورة
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.category.icon, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            item.category.badgeLabelAr,
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // عنوان الكارت (الاسم) تحت الصورة وفوق الدعاء
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: dark ? Colors.white : DhikrColors.charcoal,
              ),
            ),
          ),
          const SizedBox(height: 8),


          // Dua Content Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF0D1713) : const Color(0xFFF8F7F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF0F3B2C).withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                duaText,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 13.5,
                  height: 1.55,
                  color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Community Action Bar: [ آمين (دعوت له) | قراءة الفاتحة | تعليقات وتفاصيل ]
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Builder(
              builder: (ctx) {
                final isAmeenActive = _ameenInteractedIds.contains(item.id);
                final isFatihaActive = _fatihaInteractedIds.contains(item.id);

                return Row(
                  children: [
                    // Ameen Button (toggle: تراجع ينقص العداد)
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final wasActive = isAmeenActive;
                          int newCount;
                          if (wasActive) {
                            setState(() {
                              _ameenInteractedIds.remove(item.id);
                              _userStats['ameen'] =
                                  ((_userStats['ameen'] ?? 1) - 1).clamp(0, 1 << 30);
                            });
                            newCount = await LovedOnesService.instance
                                .retractAmeen(item.id);
                          } else {
                            setState(() {
                              _ameenInteractedIds.add(item.id);
                              _userStats['ameen'] = (_userStats['ameen'] ?? 0) + 1;
                            });
                            newCount = await LovedOnesService.instance
                                .toggleHeart(item.id);
                          }
                          setState(() {
                            item.loveCount = newCount;
                          });
                          if (context.mounted && !wasActive) {
                            AppToast.show(context, 
                              const SnackBar(
                                content: Text('آمين.. استجاب الله دعاءك بظهر الغيب ولك بمثل 🤲'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isAmeenActive
                                ? const Color(0xFFE11D48)
                                : const Color(0xFFE11D48).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE11D48).withValues(alpha: isAmeenActive ? 1.0 : 0.25),
                              width: 1,
                            ),
                            boxShadow: isAmeenActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAmeenActive ? LucideIcons.heartHandshake : LucideIcons.heart,
                                size: 15,
                                color: isAmeenActive ? Colors.white : const Color(0xFFE11D48),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'آمين (${item.loveCount})',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isAmeenActive ? Colors.white : const Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Fatiha Button (toggle: تراجع ينقص العداد)
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final wasActive = isFatihaActive;
                          int newCount;
                          if (wasActive) {
                            setState(() {
                              _fatihaInteractedIds.remove(item.id);
                              _userStats['fatiha'] =
                                  ((_userStats['fatiha'] ?? 1) - 1).clamp(0, 1 << 30);
                            });
                            newCount = await LovedOnesService.instance
                                .retractFatiha(item.id);
                          } else {
                            setState(() {
                              _fatihaInteractedIds.add(item.id);
                              _userStats['fatiha'] = (_userStats['fatiha'] ?? 0) + 1;
                            });
                            newCount = await LovedOnesService.instance
                                .incrementFatiha(item.id);
                          }
                          setState(() {
                            item.fatihaCount = newCount;
                          });
                          if (context.mounted && !wasActive) {
                            AppToast.show(context, 
                              const SnackBar(
                                content: Text('تقبل الله قراءتك للفاتحة ونور بها قبره ومقامه 📖'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isFatihaActive
                                ? const Color(0xFFD97706)
                                : const Color(0xFFD97706).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD97706).withValues(alpha: isFatihaActive ? 1.0 : 0.3),
                              width: 1,
                            ),
                            boxShadow: isFatihaActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFD97706).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isFatihaActive ? LucideIcons.bookOpenCheck : LucideIcons.bookOpen,
                                size: 15,
                                color: isFatihaActive ? Colors.white : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'الفاتحة (${item.fatihaCount})',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isFatihaActive ? Colors.white : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Facebook-Style Comment Preview (If any comments exist) ──
          if (item.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LovedOneDetailScreen(item: item)),
                  );
                  _load();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF0D1713) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F3B2C).withValues(alpha: 0.1),
                        ),
                        child: const Icon(LucideIcons.messageSquareQuote, size: 12, color: Color(0xFF0F3B2C)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 12,
                              color: dark ? Colors.white70 : DhikrColors.charcoal,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: 'أحدث دعاء: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F3B2C),
                                ),
                              ),
                              TextSpan(text: item.comments.first),
                            ],
                          ),
                        ),
                      ),
                      if (item.comments.length > 1) ...[
                        const SizedBox(width: 4),
                        Text(
                          '+${item.comments.length - 1}',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: dark ? DhikrColors.sage : const Color(0xFF0F3B2C),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // ── Inline Quick Comment Field (Facebook-style add comment) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Builder(
              builder: (ctx) {
                final commentCtrl = _quickCommentCtrls.putIfAbsent(item.id, () => TextEditingController());
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF0D1713) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: dark ? Colors.white : DhikrColors.charcoal,
                          ),
                          decoration: InputDecoration(
                            hintText: 'اكتب دعاءً أو تعليقاً طيباً بظهر الغيب...',
                            hintStyle: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w300,
                              color: dark ? Colors.white30 : const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: (text) async {
                            if (text.trim().isEmpty) return;
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
                            HapticFeedback.lightImpact();
                            await LovedOnesService.instance.addComment(item.id, text.trim());
                            commentCtrl.clear();
                            _load();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.sendHorizontal, size: 16, color: Color(0xFF0F3B2C)),
                        tooltip: 'إرسال الدعاء',
                        onPressed: () async {
                          final text = commentCtrl.text.trim();
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
                          HapticFeedback.lightImpact();
                          await LovedOnesService.instance.addComment(item.id, text);
                          commentCtrl.clear();
                          _load();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  void _showUserSpiritualActivitySheet(BuildContext context, Map<String, String>? profile, bool dark) {
    final name = profile?['name'] ?? 'فاعل خير';
    final email = profile?['email'] ?? '';
    final photoUrl = profile?['photo'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final ameenCount = _userStats['ameen'] ?? 0;
    final fatihaCount = _userStats['fatiha'] ?? 0;
    final myPostsCount = _myCreatedIds.length;
    final isAr = Provider.of<AppState>(context, listen: false).language == AppLanguage.arabic;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF10241E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: dark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFF0F3B2C).withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // User Avatar
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F3B2C), Color(0xFF1E5B45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F3B2C).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: photoUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: Image.network(
                              photoUrl,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Text(
                                initial,
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            initial,
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  name,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    color: dark ? Colors.white : DhikrColors.charcoal,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 12.5,
                      color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                    ),
                  ),
                const SizedBox(height: 10),

                // Spiritual Rank Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3B2C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F3B2C).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sparkles, size: 15, color: Color(0xFF0F3B2C)),
                      const SizedBox(width: 6),
                      Text(
                        ameenCount + fatihaCount >= 10
                            ? 'سفير الوفاء وغارس الخيرات 💎'
                            : 'غارس الخيرات بظهر الغيب 🌱',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: dark ? const Color(0xFFC5A059) : const Color(0xFF0F3B2C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF162C23) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActivityStatItem(
                        icon: LucideIcons.heart,
                        title: 'تأمين بظهر الغيب',
                        count: '$ameenCount',
                        color: const Color(0xFFE11D48),
                        dark: dark,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
                      _buildActivityStatItem(
                        icon: LucideIcons.bookOpen,
                        title: 'قراءات الفاتحة',
                        count: '$fatihaCount',
                        color: const Color(0xFFD97706),
                        dark: dark,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
                      _buildActivityStatItem(
                        icon: LucideIcons.users,
                        title: 'أحبتي المضافون',
                        count: '$myPostsCount',
                        color: const Color(0xFF0F766E),
                        dark: dark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => _showOnlyMine = true);
                        },
                        icon: const Icon(LucideIcons.listFilter, size: 18),
                        label: const Text(
                          'عرض منشوراتي فقط',
                          style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final res = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const AddLovedOneScreen()),
                          );
                          if (res == true) _load();
                        },
                        icon: const Icon(LucideIcons.userPlus, size: 18),
                        label: const Text(
                          'إضافة حبيب',
                          style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F3B2C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityStatItem({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
    required bool dark,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: dark ? Colors.white : DhikrColors.charcoal,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 11,
            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
          ),
        ),
      ],
    );
  }

  void _shareDuaFromCard(BuildContext context, LovedOneItem item) {
    HapticFeedback.lightImpact();
    final text = '''
دعاء بظهر الغيب إلى: ${item.name} (${item.category.badgeLabelAr})
«${item.customDua ?? item.category.defaultDuaAr}»

نسألكم قراءة الفاتحة والدعاء له بظهر الغيب 🤲
(تم الإرسال من تطبيق درة المؤمن)
''';
    Clipboard.setData(ClipboardData(text: text));
    AppToast.show(
      context,
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

  void _showReportDialog(BuildContext context, LovedOneItem item) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Provider.of<AppState>(context, listen: false).language == AppLanguage.arabic;
    String selectedReason = 'محتوى غير لائق أو مسيء';
    final reasons = [
      'محتوى غير لائق أو مسيء',
      'طلب تبرعات مالية أو أرقام هواتف',
      'إعلان أو روابط ترويجية',
      'انتهاك خصوصية أو صورة غير مناسبة',
      'أخرى',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            backgroundColor: dark ? const Color(0xFF14241E) : Colors.white,
            title: const Row(
              children: [
                Icon(LucideIcons.flag, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'إبلاغ عن هذا المحتوى',
                  style: TextStyle(
                    fontFamily: DhikrTheme.titleFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ساعدنا في الحفاظ على نقاء وقدسية مجتمع الدعاء، يرجى تحديد سبب الإبلاغ:',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...reasons.map(
                  (r) {
                    final isSel = selectedReason == r;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedReason = r),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFF10B981)
                                : (dark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              size: 18,
                              color: isSel ? const Color(0xFF10B981) : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 13,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                  color: isSel
                                      ? const Color(0xFF10B981)
                                      : (dark ? Colors.white : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(fontFamily: DhikrTheme.arabicFont)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await LovedOnesService.instance.reportLovedOne(
                    id: item.id,
                    reason: selectedReason,
                  );
                  _load();
                  if (context.mounted) {
                    AppToast.show(context, 
                      const SnackBar(
                        content: Text('تم استلام بلاغك وإخفاء المحتوى فوراً. جزاكم الله خيراً 🤲'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text(
                  'إرسال وإخفاء',
                  style: TextStyle(fontFamily: DhikrTheme.arabicFont, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
