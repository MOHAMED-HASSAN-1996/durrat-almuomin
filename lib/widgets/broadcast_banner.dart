import 'package:flutter/material.dart';

import '../services/remote_content_service.dart';
import '../theme/app_theme.dart';

/// In-app banner for admin broadcasts (`broadcasts` collection).
///
/// Silent by design: renders nothing until the remote service delivers at
/// least one active broadcast. Offline or empty collection keeps the home
/// screen exactly as before.
class BroadcastBanner extends StatefulWidget {
  const BroadcastBanner({super.key, required this.dark, required this.isAr});

  final bool dark;
  final bool isAr;

  @override
  State<BroadcastBanner> createState() => _BroadcastBannerState();
}

class _BroadcastBannerState extends State<BroadcastBanner> {
  final Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    RemoteContentService.instance.initialize();
    RemoteContentService.instance.addListener(_onRemote);
  }

  @override
  void dispose() {
    RemoteContentService.instance.removeListener(_onRemote);
    super.dispose();
  }

  void _onRemote() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RemoteContentService.instance,
      builder: (context, _) {
        final items = RemoteContentService.instance.activeBroadcasts
            .where((b) => !_dismissed.contains(b['id']?.toString()))
            .take(3)
            .toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              for (final b in items)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.dark
                        ? const Color(0xFF0F3B2C)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.campaign_outlined,
                          size: 18,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (b['title'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: widget.dark
                                    ? Colors.white
                                    : DhikrColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (b['message'] ?? '').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12,
                                height: 1.6,
                                color: widget.dark
                                    ? Colors.white70
                                    : DhikrColors.charcoalSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(
                          () => _dismissed.add(b['id']?.toString() ?? ''),
                        ),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: widget.dark
                              ? Colors.white54
                              : DhikrColors.charcoalSoft,
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
}
