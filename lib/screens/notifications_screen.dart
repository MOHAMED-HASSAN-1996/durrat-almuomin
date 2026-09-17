import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../types/adhkar.dart';
import '../theme/app_theme.dart';
import 'loved_ones_screen.dart';
import 'location_map_picker_screen.dart';

enum NotifFilter { all, lovedOnes, system }

enum NotifType { lovedOnesFatiha, lovedOnesAmeen, lovedOnesComment, lovedOnesNewPost, systemLocation, systemZakat, systemQuran, systemRadio }

class NotificationItem {
  final String id;
  final NotifType type;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String timeAr;
  final String timeEn;
  final IconData icon;
  final Color color;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.timeAr,
    required this.timeEn,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

/// Notifications Screen — Displays Loved Ones (دعاء بظهر الغيب) community interactions
/// and App/System notifications (excluding prayer times which have their own alerts).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotifFilter _selectedFilter = NotifFilter.all;

  late final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'n1',
      type: NotifType.lovedOnesFatiha,
      titleAr: 'قراءة الفاتحة مهداة لأحبائك',
      titleEn: 'Al-Fatihah recitation for your loved one',
      subtitleAr: 'أحد المصلين قرأ سورة الفاتحة وأهداها لوالدتك الغالية 🤲',
      subtitleEn: 'A fellow believer recited Al-Fatihah for your loved one',
      timeAr: 'منذ ١٠ دقائق',
      timeEn: '10m ago',
      icon: LucideIcons.bookOpen,
      color: const Color(0xFF0F766E),
      isRead: false,
    ),
    NotificationItem(
      id: 'n2',
      type: NotifType.lovedOnesAmeen,
      titleAr: 'تفاعل دعاء بظهر الغيب (آمين)',
      titleEn: 'Dua Interaction (Ameen)',
      subtitleAr: 'تفاعل ٥ مصلين بـ "آمين" على طلب الدعاء لوالدك الحبيب 🌿',
      subtitleEn: '5 believers interacted with "Ameen" on your prayer request',
      timeAr: 'منذ نصف ساعة',
      timeEn: '30m ago',
      icon: LucideIcons.heartHandshake,
      color: const Color(0xFFE11D48),
      isRead: false,
    ),
    NotificationItem(
      id: 'n3',
      type: NotifType.lovedOnesComment,
      titleAr: 'خاطرة ودعاء طيب جديد',
      titleEn: 'New heartfelt prayer comment',
      subtitleAr: 'كتب أحدهم: "اللهم اشفها شفاءً تاماً واجعل ما أصابها رفعة لدرجاتها" 💬',
      subtitleEn: 'Someone commented: "May Allah grant full healing and patience"',
      timeAr: 'منذ ساعتين',
      timeEn: '2h ago',
      icon: LucideIcons.messageSquare,
      color: const Color(0xFF0F3B2C),
      isRead: false,
    ),
    NotificationItem(
      id: 'n4',
      type: NotifType.systemLocation,
      titleAr: 'مزامنة الموقع الجغرافي والقبلة',
      titleEn: 'Location & Qibla Synchronized',
      subtitleAr: 'تم تثبيت وتوحيد موقعك الجغرافي عبر كافة شاشات التطبيق بنجاح 📍',
      subtitleEn: 'Your location has been unified and synchronized across all screens',
      timeAr: 'اليوم',
      timeEn: 'Today',
      icon: LucideIcons.mapPin,
      color: const Color(0xFF10B981),
      isRead: true,
    ),
    NotificationItem(
      id: 'n5',
      type: NotifType.lovedOnesNewPost,
      titleAr: 'طلب دعاء بظهر الغيب في المجتمع',
      titleEn: 'New prayer request in community',
      subtitleAr: 'أخ لك في الله يسأل الدعاء لأخيه المريض بالشفاء العاجل 🕊️',
      subtitleEn: 'A brother requests prayers for his ailing brother',
      timeAr: 'منذ ٤ ساعات',
      timeEn: '4h ago',
      icon: LucideIcons.heart,
      color: const Color(0xFFD97706),
      isRead: true,
    ),
    NotificationItem(
      id: 'n6',
      type: NotifType.systemZakat,
      titleAr: 'حاسبة الزكاة والنصاب',
      titleEn: 'Zakat Calculation Log',
      subtitleAr: 'تم حفظ وتوثيق عمليات احتساب زكاة المال وعروض التجارة بنجاح 💾',
      subtitleEn: 'Your Zakat calculation record has been saved successfully',
      timeAr: 'أمس',
      timeEn: 'Yesterday',
      icon: LucideIcons.badgePercent,
      color: const Color(0xFF0F766E),
      isRead: true,
    ),
    NotificationItem(
      id: 'n7',
      type: NotifType.systemQuran,
      titleAr: 'تحديث المصحف الشريف 📖',
      titleEn: 'Holy Quran Landscape View',
      subtitleAr: 'أصبح بإمكانك الآن تدوير الشاشة وتلاوة المصحف بالعرض الكامل بانسيابية تامة ✨',
      subtitleEn: 'You can now rotate your device for full-width Quran reading',
      timeAr: 'منذ يومين',
      timeEn: '2d ago',
      icon: LucideIcons.sparkles,
      color: const Color(0xFF7C3AED),
      isRead: true,
    ),
    NotificationItem(
      id: 'n8',
      type: NotifType.systemRadio,
      titleAr: 'إذاعة القرآن الكريم 📻',
      titleEn: 'Quran Radio Update',
      subtitleAr: 'تم إضافة أزرار التبديل للمحطة السابقة والتالية مع بث سلس هادئ 🌿',
      subtitleEn: 'Previous and Next station controls are now active in notifications',
      timeAr: 'منذ ٣ أيام',
      timeEn: '3d ago',
      icon: LucideIcons.radio,
      color: const Color(0xFF0F3B2C),
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    HapticFeedback.selectionClick();
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم تعيين جميع الإشعارات كمقروءة ✓',
          style: TextStyle(fontFamily: DhikrTheme.arabicFont),
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onTapNotification(NotificationItem item) {
    HapticFeedback.lightImpact();
    setState(() => item.isRead = true);

    switch (item.type) {
      case NotifType.lovedOnesFatiha:
      case NotifType.lovedOnesAmeen:
      case NotifType.lovedOnesComment:
      case NotifType.lovedOnesNewPost:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LovedOnesScreen()),
        );
        break;
      case NotifType.systemLocation:
        final savedLoc = context.read<AppState>().storage.getSavedLocation();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LocationMapPickerScreen(
              initialLat: (savedLoc?['lat'] as num?)?.toDouble(),
              initialLng: (savedLoc?['lng'] as num?)?.toDouble(),
              initialCityAr: savedLoc?['cityAr'] as String?,
              initialCountryAr: savedLoc?['countryAr'] as String?,
            ),
          ),
        );
        break;
      case NotifType.systemZakat:
      case NotifType.systemQuran:
      case NotifType.systemRadio:
        // Already read
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isAr = appState.language == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final unreadCount = _notifications.where((n) => !n.isRead).length;

    final filteredList = _notifications.where((n) {
      if (_selectedFilter == NotifFilter.lovedOnes) {
        return n.type == NotifType.lovedOnesFatiha ||
            n.type == NotifType.lovedOnesAmeen ||
            n.type == NotifType.lovedOnesComment ||
            n.type == NotifType.lovedOnesNewPost;
      }
      if (_selectedFilter == NotifFilter.system) {
        return n.type == NotifType.systemLocation ||
            n.type == NotifType.systemZakat ||
            n.type == NotifType.systemQuran ||
            n.type == NotifType.systemRadio;
      }
      return true;
    }).toList();

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            leading: IconButton(
              icon: Icon(
                LucideIcons.arrowRight,
                color: dark ? Colors.white : DhikrColors.charcoal,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isAr ? 'مركز الإشعارات والتفاعلات' : 'Notifications & Activity',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                color: dark ? Colors.white : DhikrColors.charcoal,
              ),
            ),
            centerTitle: true,
            actions: [
              if (unreadCount > 0)
                IconButton(
                  icon: const Icon(LucideIcons.checkCheck, size: 20),
                  tooltip: isAr ? 'تعيين الكل كمقروء' : 'Mark all as read',
                  color: dark ? DhikrColors.sage : const Color(0xFF0F3B2C),
                  onPressed: _markAllAsRead,
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                children: [
                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: isAr ? 'الكل (${_notifications.length})' : 'All',
                          filter: NotifFilter.all,
                          dark: dark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: isAr ? 'دعاء بظهر الغيب 🤲' : 'Loved Ones',
                          filter: NotifFilter.lovedOnes,
                          dark: dark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: isAr ? 'تنبيهات النظام ⚙️' : 'System',
                          filter: NotifFilter.system,
                          dark: dark,
                        ),
                      ],
                    ),
                  ),

                  // Feed list
                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.bellOff,
                                  size: 48,
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.15),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isAr ? 'لا توجد إشعارات في هذا القسم' : 'No notifications in this section',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 14,
                                    color: dark
                                        ? DhikrColors.darkMuted
                                        : DhikrColors.charcoalSoft,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                            itemCount: filteredList.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final item = filteredList[i];
                              return _buildNotifCard(
                                item: item,
                                isAr: isAr,
                                dark: dark,
                                onTap: () => _onTapNotification(item),
                              );
                            },
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

  Widget _buildFilterChip({
    required String label,
    required NotifFilter filter,
    required bool dark,
  }) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (dark ? const Color(0xFF144533) : const Color(0xFF0F3B2C))
              : (dark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (dark ? DhikrColors.sage : const Color(0xFF0F3B2C))
                : (dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
            width: 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F3B2C).withValues(alpha: dark ? 0.3 : 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
            color: isSelected
                ? Colors.white
                : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
          ),
        ),
      ),
    );
  }

  Widget _buildNotifCard({
    required NotificationItem item,
    required bool isAr,
    required bool dark,
    required VoidCallback onTap,
  }) {
    final title = isAr ? item.titleAr : item.titleEn;
    final subtitle = isAr ? item.subtitleAr : item.subtitleEn;
    final time = isAr ? item.timeAr : item.timeEn;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: dark
                ? (item.isRead ? const Color(0xFF111E18) : const Color(0xFF142B22))
                : (item.isRead ? Colors.white : const Color(0xFFF6FBF8)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead
                  ? (dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05))
                  : item.color.withValues(alpha: dark ? 0.35 : 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: dark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w900,
                              fontSize: 14,
                              color: dark ? Colors.white : DhikrColors.charcoal,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12.5,
                        height: 1.45,
                        color: dark ? Colors.white70 : const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: dark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: dark ? DhikrColors.sage : item.color,
                            ),
                          ),
                        ),
                        if (item.type == NotifType.lovedOnesFatiha ||
                            item.type == NotifType.lovedOnesAmeen ||
                            item.type == NotifType.lovedOnesComment ||
                            item.type == NotifType.lovedOnesNewPost)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isAr ? 'عرض المنشور' : 'View Post',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: dark ? DhikrColors.sage : const Color(0xFF0F766E),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                isAr ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                                size: 13,
                                color: dark ? DhikrColors.sage : const Color(0xFF0F766E),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
