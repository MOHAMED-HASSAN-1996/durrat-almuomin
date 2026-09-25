import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../services/location_label.dart';
import '../services/loved_ones_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';
import 'loved_ones_screen.dart';
import 'location_map_picker_screen.dart';

enum NotifFilter { all, lovedOnes, system }

enum NotifType {
  lovedOnesFatiha,
  lovedOnesAmeen,
  lovedOnesComment,
  systemLocation,
}

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

/// Notifications Screen — real Loved Ones interactions + location status.
/// Prayer alerts are excluded (they have their own system).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotifFilter _selectedFilter = NotifFilter.all;
  final List<NotificationItem> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRealNotifications();
  }

  String _agoAr(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'الآن';
    if (d.inMinutes < 60) return 'منذ ${d.inMinutes} دقائق';
    if (d.inHours < 24) return 'منذ ${d.inHours} ساعات';
    if (d.inDays < 30) return 'منذ ${d.inDays} أيام';
    return 'منذ ${d.inDays ~/ 30} أشهر';
  }

  String _agoEn(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    return '${d.inDays ~/ 30}mo ago';
  }

  Future<void> _loadRealNotifications() async {
    final items = <NotificationItem>[];
    try {
      final appState = context.read<AppState>();
      final savedLoc = appState.storage.getSavedLocation();
      if (savedLoc != null) {
        final cityAr =
            ((savedLoc['cityAr'] as String?) ??
                    (savedLoc['city'] as String?) ??
                    '')
                .trim();
        final cityEn = ((savedLoc['cityEn'] as String?) ?? cityAr).trim();
        final provinceAr = ((savedLoc['provinceAr'] as String?) ?? '').trim();
        final provinceEn = ((savedLoc['provinceEn'] as String?) ?? '').trim();
        final countryAr = ((savedLoc['countryAr'] as String?) ?? '').trim();
        final countryEn = ((savedLoc['countryEn'] as String?) ?? '').trim();
        final labelAr = locationLabel(
          city: cityAr,
          province: provinceAr,
          country: countryAr,
        );
        final labelEn = locationLabel(
          city: cityEn,
          province: provinceEn,
          country: countryEn,
        );
        items.add(
          NotificationItem(
            id: 'loc',
            type: NotifType.systemLocation,
            titleAr: 'تم ضبط الموقع والقبلة',
            titleEn: 'Location & Qibla ready',
            subtitleAr: labelAr.isNotEmpty
                ? 'الموقع الحالي: $labelAr — مواقيت الصلاة والقبلة تعمل الآن'
                : 'تم حفظ إحداثيات موقعك لمواقيت الصلاة والقبلة',
            subtitleEn: labelEn.isNotEmpty
                ? 'Current location: $labelEn — prayer times & qibla active'
                : 'Your coordinates are saved for prayer times & qibla',
            timeAr: 'عند الإعداد',
            timeEn: 'At setup',
            icon: LucideIcons.mapPin,
            color: const Color(0xFF10B981),
            isRead: true,
          ),
        );
      }

      final service = LovedOnesService.instance;
      final myIds = await service.getMyCreatedIds();
      final lovedOnes = await service.loadLovedOnes();
      final mine = lovedOnes
          .where((i) => myIds.contains(i.id))
          .toList(growable: false);

      for (final item in mine) {
        if (item.fatihaCount > 0) {
          items.add(
            NotificationItem(
              id: '${item.id}_fatiha',
              type: NotifType.lovedOnesFatiha,
              titleAr: 'قراءة الفاتحة لأحبائك',
              titleEn: 'Al-Fatihah for your loved one',
              subtitleAr:
                  'قرأ ${item.fatihaCount} مصلٍّ سورة الفاتحة وأهداها لـ${item.name}',
              subtitleEn:
                  '${item.fatihaCount} believer(s) recited Al-Fatihah for ${item.name}',
              timeAr: _agoAr(item.createdAt),
              timeEn: _agoEn(item.createdAt),
              icon: LucideIcons.bookOpen,
              color: const Color(0xFF0F766E),
              isRead: false,
            ),
          );
        }
        if (item.loveCount > 0) {
          items.add(
            NotificationItem(
              id: '${item.id}_ameen',
              type: NotifType.lovedOnesAmeen,
              titleAr: 'دعا بظهر الغيب',
              titleEn: 'Dua interactions (Ameen)',
              subtitleAr:
                  '${item.loveCount} شخص دعا لـ${item.name} — تقبّل الله من الجميع',
              subtitleEn:
                  '${item.loveCount} believer(s) made dua for ${item.name}',
              timeAr: _agoAr(item.createdAt),
              timeEn: _agoEn(item.createdAt),
              icon: LucideIcons.heartHandshake,
              color: const Color(0xFFE11D48),
              isRead: false,
            ),
          );
        }

        final comments = await service.loadComments(item.id);
        final otherComments = comments.length;
        if (otherComments > 0) {
          items.add(
            NotificationItem(
              id: '${item.id}_comments',
              type: NotifType.lovedOnesComment,
              titleAr: 'خواطر ودعوات على منشورك',
              titleEn: 'Prayer comments on your post',
              subtitleAr:
                  '$otherComments تعليق دعائي على طلبك من أجل ${item.name}',
              subtitleEn:
                  '$otherComments prayer comment(s) on your request for ${item.name}',
              timeAr: _agoAr(item.createdAt),
              timeEn: _agoEn(item.createdAt),
              icon: LucideIcons.messageSquare,
              color: const Color(0xFF0F3B2C),
              isRead: false,
            ),
          );
        }
      }
    } catch (_) {
      // Keep whatever was collected; empty list → empty state below.
    }

    if (!mounted) return;
    setState(() {
      _notifications
        ..clear()
        ..addAll(items);
      _loading = false;
    });
  }

  void _markAllAsRead() {
    HapticFeedback.selectionClick();
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    AppToast.show(
      context,
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
            n.type == NotifType.lovedOnesComment;
      }
      if (_selectedFilter == NotifFilter.system) {
        return n.type == NotifType.systemLocation;
      }
      return true;
    }).toList();

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            dark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle:
                dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                  color:
                      dark ? DhikrColors.sage : const Color(0xFF0F3B2C),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: isAr
                              ? 'الكل (${_notifications.length})'
                              : 'All',
                          filter: NotifFilter.all,
                          dark: dark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label:
                              isAr ? 'دعاء بظهر الغيب 🤲' : 'Loved Ones',
                          filter: NotifFilter.lovedOnes,
                          dark: dark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: isAr ? 'النظام ⚙️' : 'System',
                          filter: NotifFilter.system,
                          dark: dark,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          )
                        : filteredList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.bellOff,
                                      size: 48,
                                      color: dark
                                          ? Colors.white
                                              .withValues(alpha: 0.15)
                                          : Colors.black
                                              .withValues(alpha: 0.15),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isAr
                                          ? 'لا توجد إشعارات بعد'
                                          : 'No notifications yet',
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: dark
                                            ? DhikrColors.darkMuted
                                            : DhikrColors.charcoalSoft,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isAr
                                          ? 'سيظهر هنا ما يخص منشوراتك عند تفاعل الآخرين'
                                          : 'Activity on your posts will appear here',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 12.5,
                                        color: dark
                                            ? DhikrColors.darkMuted
                                                .withValues(alpha: 0.7)
                                            : DhikrColors.charcoalSoft
                                                .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 6, 16, 90),
                                itemCount: filteredList.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
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
                : (dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
            width: 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F3B2C)
                        .withValues(alpha: dark ? 0.3 : 0.12),
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
                ? (item.isRead
                    ? const Color(0xFF111E18)
                    : const Color(0xFF142B22))
                : (item.isRead ? Colors.white : const Color(0xFFF6FBF8)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead
                  ? (dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05))
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
                              fontWeight: item.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                              fontSize: 14,
                              color:
                                  dark ? Colors.white : DhikrColors.charcoal,
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
                        color: dark
                            ? Colors.white70
                            : const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color:
                                item.color.withValues(alpha: dark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                                  dark ? DhikrColors.sage : item.color,
                            ),
                          ),
                        ),
                        if (item.type != NotifType.systemLocation)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isAr ? 'عرض المنشور' : 'View Post',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: dark
                                      ? DhikrColors.sage
                                      : const Color(0xFF0F766E),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                isAr
                                    ? LucideIcons.chevronLeft
                                    : LucideIcons.chevronRight,
                                size: 13,
                                color: dark
                                    ? DhikrColors.sage
                                    : const Color(0xFF0F766E),
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
