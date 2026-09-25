import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../data/playable_content.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';
import 'youtube_iframe_factory.dart'
    if (dart.library.js_interop) 'youtube_iframe_factory_web.dart';

const _ytRed = Color(0xFFFF0000);
const _ytRedDark = Color(0xFFCC0000);
const _gold = Color(0xFFD97706);

/// معرف التطبيق — يُستخدم كهوية رسمية أمام يوتيوب في هيدر Referer/Origin
/// أثناء تحميل صفحة التضمين (اشتراط YouTube Required Minimum Functionality).
const String YOUTUBE_APP_ID = 'com.dhikr.adhkar';

enum PlayerViewMode { cinema, theater, audio }

/// عنصر واحد في قائمة تشغيل المشغل (حلقات السلسلة داخل التطبيق فقط)
class PlayerQueueItem {
  final String url;
  final String title;

  const PlayerQueueItem({required this.url, required this.title});
}

/// يفتح محتوى يوتيوب داخل مشغّل سينمائي فخم متكامل داخل التطبيق
Future<void> playYoutubeInFrame(
  BuildContext context, {
  required String url,
  required String title,
  String? description,
  String? channelName,
  String? channelUrl,
  List<PlayerQueueItem>? playlist,
  int? initialIndex,
}) async {
  final isAr = context.read<AppState>().language == AppLanguage.arabic;

  final target = parseYoutubeTarget(url);
  final embed = target == null ? null : embedUrlFor(target);

  if (embed != null && target != null) {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InAppPlayerScreen(
          target: target,
          title: title,
          sourceUrl: url,
          description: description,
          channelName: channelName,
          channelUrl: channelUrl,
          playlist: playlist,
          initialIndex: initialIndex ?? 0,
        ),
      ),
    );
    return;
  }

  final trimmed = url.trim();
  if (trimmed.isNotEmpty) {
    final ok = await launchUrl(
      Uri.parse(trimmed),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      AppToast.show(
        context,
        SnackBar(
          content: Text(isAr ? 'تعذر فتح الرابط' : 'Could not open the link'),
        ),
      );
    }
    return;
  }

  if (context.mounted) {
    AppToast.show(
      context,
      SnackBar(
        content: Text(
          isAr
              ? 'لم يُضف رابط هذا المحتوى بعد'
              : 'No link for this content yet',
        ),
      ),
    );
  }
}

/// شاشة مشغّل العرض والتحكم السينمائي المتطور:
/// - تحكم كامل بالفيديو (تشغيل، إيقاف، تقديم، ترجيع، كتم صوت، تحكم بالسرعة).
/// - أوضاع عرض متعددة: الوضع السينمائي، وضع المسرح الموسع، ووضع الاستماع الصوتي.
/// - مؤقت النوم التلقائي الذكي للدروس والقصص قبل النوم.
/// - إضاءة محيطية سينمائية (Ambient Glow) وبطاقة توثيق القناة الرسمية.
class InAppPlayerScreen extends StatefulWidget {
  final YoutubeTarget target;
  final String title;
  final String sourceUrl;
  final String? description;
  final String? channelName;
  final String? channelUrl;
  final List<PlayerQueueItem>? playlist;
  final int initialIndex;

  const InAppPlayerScreen({
    super.key,
    required this.target,
    required this.title,
    required this.sourceUrl,
    this.description,
    this.channelName,
    this.channelUrl,
    this.playlist,
    this.initialIndex = 0,
  });

  @override
  State<InAppPlayerScreen> createState() => _InAppPlayerScreenState();
}

class _InAppPlayerScreenState extends State<InAppPlayerScreen>
    with SingleTickerProviderStateMixin {
  static int _viewSeq = 0;

  late YoutubeTarget _currentTarget;
  late String _currentTitle;
  late String _currentSourceUrl;
  late List<PlayerQueueItem> _playlist;
  late int _currentIndex;

  String _embedUrl = '';

  /// بعض المواد النادرة يقفل ناشرها التضمين قصداً؛ قراره لا نتدخل فيه
  /// والافتراضي الدائم هو صفحة التضمين الرسمية embed.
  late final bool _useWatchMode = false;

  /// true فقط عند فشل تحميل رابط التضمين نفسه (شبكة) — عندها نعرض
  /// بديل واضح (إعادة المحاولة / فتح في يوتيوب) بدل شاشة معلّقة.
  /// ملاحظة: لا يُستخدم لرصد أخطاء يوتيوب الداخلية؛ المشغّل الرسمي
  /// يعرضها بنفسه بصدق داخل الإطار.
  bool _embedFailed = false;

  /// الطبقة الثانية من حل الفيديو (2026): عند فشل صفحة التضمين نفسها
  /// (player-unavailable)، نحول تلقائيًا إلى صفحة المشاهدة الرسمية
  /// m.youtube.com/watch داخل نفس WebView — بدون مغادرة التطبيق.
  /// هذه هي الطريقة المحفوظة المحدثة (راجع YOUTUBE_153_FIX.md).
  bool _watchFallbackUsed = false;
  bool _desktopWatchFallbackUsed = false;
  int _embedCheckCount = 0;
  String _viewType = '';
  WebViewController? _controller;
  YoutubePlayerController? _ytController;
  bool _useYtFlutter = false;
  bool _isLoading = true;

  // Player Controls State
  bool _isPlaying = true;
  bool _isMuted = false;
  double _playbackSpeed = 1.0;
  PlayerViewMode _viewMode = PlayerViewMode.cinema;
  bool _isBookmarked = false;

  // Sleep Timer State
  int? _sleepTimerMinutes;
  int _sleepSecondsRemaining = 0;
  Timer? _sleepTicker;

  // Screen Orientation State
  bool _isLandscape = false;

  // Audio Mode Equalizer Animation
  late AnimationController _eqController;

  @override
  void initState() {
    super.initState();
    _currentTarget = widget.target;
    _currentTitle = widget.title;
    _currentSourceUrl = widget.sourceUrl;
    _playlist = widget.playlist ?? const [];
    _currentIndex = widget.initialIndex.clamp(
      0,
      _playlist.isEmpty ? 0 : _playlist.length - 1,
    );

    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _setupPlayer();
  }

  void _onYtPlayerUpdate() {
    if (!mounted || _ytController == null) return;
    final val = _ytController!.value;
    if (_isPlaying != val.isPlaying ||
        _isLoading != !val.isReady ||
        _isLandscape != val.isFullScreen) {
      setState(() {
        _isPlaying = val.isPlaying;
        _isLandscape = val.isFullScreen;
        if (val.isReady) {
          _isLoading = false;
        }
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _statePoller?.cancel();
    _ytController?.removeListener(_onYtPlayerUpdate);
    _ytController?.dispose();
    _sleepTicker?.cancel();
    _eqController.dispose();
    super.dispose();
  }

  void _toggleOrientation() {
    if (_useYtFlutter && _ytController != null) {
      _ytController!.toggleFullScreenMode();
    } else {
      setState(() {
        _isLandscape = !_isLandscape;
      });
      if (_isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      // التشغيل التلقائي بعد التدوير: إعادة تخطيط المشهد عند تغيير
      // الاتجاه قد توقف الفيديو — نستأنف التشغيل فورًا بعد استقرار التخطيط.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _sendCommand('playVideo');
      });
    }
  }

  Future<void> _setupPlayer() async {
    setState(() {
      _isLoading = true;
      _isPlaying = true;
      _embedFailed = false;
    });
    _watchFallbackUsed = false;
    _desktopWatchFallbackUsed = false;
    _embedCheckCount = 0;
    _useYtFlutter = false;
    // الويب: iframe عبر embedUrlFor (يحتاج origin). الموبايل: التضمين
    // الرسمي المباشر embedDirectUrlFor + هيدر Referer (الحل الأصلي
    // المحفوظ في YOUTUBE_153_FIX.md). لو رفض التضمين (153/«الفيديو غير
    // متاح») يتولّى مراقب الحالة التحويل التلقائي لصفحة المشاهدة
    // (شبكة أمان داخل نفس WebView — بدون مغادرة التطبيق).
    _embedUrl = (kIsWeb
            ? embedUrlFor(_currentTarget)
            : embedDirectUrlFor(_currentTarget)) ??
        '';
    if (_embedUrl.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (kIsWeb) {
      _viewType = 'yt-cinema-${_viewSeq++}';
      registerYoutubeFrameFactory(_viewType, _embedUrl);
      _controller = null;
      setState(() {
        _isLoading = false;
      });
    } else if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      // التشغيل عبر رابط التضمين الرسمي مباشرة (youtube-nocookie embed).
      // السبب: صفحة YT.Player اليدوية كانت تُنتج أخطاء 150 كاذبة
      // («قيود من الناشر») رغم أن كل الفيديوهات تسمح بالتضمين رسمياً —
      // تم التحقق من الـ 28 فيديو عبر oEmbed. المسار الرسمي المباشر
      // هو ما تستخدمه تطبيقات الإنتاج ولا يُنتج إنذارات كاذبة.
      // التحكم (تشغيل/إيقاف/سرعة/كتم) يعمل عبر postMessage مع enablejsapi=1.
      // تشغيل embed رسمي. منذ يوليو 2025 أصبح يوتيوب يرفض التشغيل داخل
      // WebView بخطأ 153 («form embedder.identity.missing.referrer») إذا لم
      // يصل مع الطلب هيدر Referer صالح. الحل هو ما تطلبه توثيق يوتيوب
      // الرسمي نفسه (Required Minimum Functionality): إرسال
      // `Referer: https://<bundle_id>` مع طلب صفحة التضمين. هذه هي هوية
      // التطبيق الرسمية أمام يوتيوب — بلا إخفاء شعار وبلا كسر قيود.
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        )
        ..setBackgroundColor(const Color(0xFF000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _isPlaying = true;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted && (error.isForMainFrame ?? false)) {
                setState(() => _isLoading = false);
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url.toLowerCase();
              if (url.contains('youtube.com') ||
                  url.contains('youtube-nocookie.com') ||
                  url.contains('youtu.be') ||
                  url.contains('googlevideo.com') ||
                  url.contains('ytimg.com') ||
                  url.contains('google.com') ||
                  url.startsWith('about:blank') ||
                  url.startsWith('data:')) {
                return NavigationDecision.navigate;
              }
              if (!request.isMainFrame) {
                return NavigationDecision.navigate;
              }
              launchUrl(
                Uri.parse(request.url),
                mode: LaunchMode.externalApplication,
              );
              return NavigationDecision.prevent;
            },
          ),
        );

      try {
        await _loadCurrentUrl();
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _embedFailed = true;
          });
        }
        return;
      }

      // السماح بالتشغيل التلقائي وبأوامر التشغيل من أزرار التطبيق
      // (بدونها WebView يرفض التشغيل ويعلق الفيديو على الغلاف)
      final platformController = _controller?.platform;
      if (platformController is AndroidWebViewController) {
        await platformController.setMediaPlaybackRequiresUserGesture(false);
      }

      Timer(const Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
        }
      });
      _startStatePoller();
    } else {
      _controller = null;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// إرسال أمر تحكم للمشغّل الرسمي عبر عنصر <video> مباشرة.
  ///
  /// صفحة التضمين الرسمية (embed) تحتوي عنصر فيديو HTML5 قياسياً،
  /// فالتحكم به مباشرة (play/pause/seek/rate/mute) هو الطريقة المدعومة
  /// للتحميل العلوي داخل WebView — بدل جسر YT.Player الذي كان مصدر
  /// الإنذارات الكاذبة.
  void _sendCommand(String func, [List<dynamic>? args]) {
    if (kIsWeb) {
      sendYoutubeCommand(_viewType, func, args);
      return;
    }
    final c = _controller;
    if (c == null) return;
    final arg0 = (args != null && args.isNotEmpty) ? '${args[0]}' : '0';
    switch (func) {
      case 'playVideo':
        c.runJavaScript(
          "try{var v=document.querySelector('video');if(v){v.play()}}catch(e){}",
        );
        break;
      case 'pauseVideo':
        c.runJavaScript(
          "try{var v=document.querySelector('video');if(v){v.pause()}}catch(e){}",
        );
        break;
      case 'mute':
        c.runJavaScript(
          "try{var v=document.querySelector('video');if(v){v.muted=true}}catch(e){}",
        );
        break;
      case 'unMute':
        c.runJavaScript(
          "try{var v=document.querySelector('video');if(v){v.muted=false}}catch(e){}",
        );
        break;
      case 'setPlaybackRate':
        final rate = double.tryParse(arg0) ?? 1.0;
        c.runJavaScript(
          "try{var v=document.querySelector('video');if(v){v.playbackRate=$rate}}catch(e){}",
        );
        break;
      case 'seekTo':
        final secs = double.tryParse(arg0) ?? 0;
        c.runJavaScript(
          "try{var v=document.querySelector('video');if(v){v.currentTime=$secs}}catch(e){}",
        );
        c.runJavaScript(
          "try{var v=document.querySelector('video');if(v){v.play()}}catch(e){}",
        );
        break;
    }
  }

  /// رابط العرض الحالي: صفحة التضمين الرسمية (embed) دائماً.
  String get _currentLoadUrl {
    return _embedUrl;
  }

  Future<void> _loadCurrentUrl() async {
    final c = _controller;
    if (c == null) throw StateError('no controller');
    final url = _currentLoadUrl;
    if (url.contains('/embed/')) {
      // إرسال هوية التطبيق في Referer — اشتراط يوتيوب الرسمي منذ 2025
      // (Required Minimum Functionality) لمنع خطأ 153 في WebView.
      await c.loadRequest(
        Uri.parse(url),
        headers: const {'Referer': 'https://${YOUTUBE_APP_ID}'},
      );
    } else {
      await c.loadRequest(Uri.parse(url));
    }
  }

  /// مزامنة آمنة لزر التشغيل: تقرأ حالة عنصر <video> فقط (paused أم لا).
  /// لا ترصد أي «أخطاء» — المصدر السابق للإنذارات الكاذبة أُزيل نهائياً.
  Timer? _statePoller;

  void _startStatePoller() {
    _statePoller?.cancel();
    _statePoller = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _useYtFlutter) return;
      final c = _controller;
      if (c == null) return;
      try {
        // 0/1 = فيديو يعمل (متوقف/مشتغل)؛ -2 = صفحة التضمين أعلنت فشلها
        // (علامة ytp-embed-error / ترميز .ytp-error ظاهر، أو player-unavailable)
        //؛ -99 = العنصر لم يُبنَ بعد أو فيديو لم يتأصل بعد.
        final res = await c.runJavaScriptReturningResult(
          "try{var v=document.querySelector('video');"
          "if(v&&v.currentSrc){return v.paused?0:1;}"
          "var pe=document.querySelector('.ytp-error');"
          "if(pe&&getComputedStyle(pe).display!=='none'){return -2;}"
          "var pp=document.querySelector('.html5-video-player');"
          "if(pp&&pp.className.indexOf('ytp-embed-error')>=0){return -2;}"
          "var pa=document.querySelector('.player-unavailable');"
          "if(pa&&getComputedStyle(pa).display!=='none'){return -2;}"
          "return -99;}catch(e){return -99;}",
        );
        final st = int.tryParse('$res');
        if (st == null) return;
        if (st == -99) {
          // بعض إصدارات Android WebView تفتح صفحة m.youtube.com ولكن لا
          // تنشئ عنصر الفيديو فيها بسبب صفحة موافقة أو اختلاف توافق الجهاز.
          // جرّب صفحة المشاهدة الرسمية الكاملة داخل نفس WebView قبل عرض
          // شاشة الخطأ للمستخدم.
          if (_embedUrl.startsWith('https://m.youtube.com/') &&
              !_desktopWatchFallbackUsed) {
            _embedCheckCount++;
            if (_embedCheckCount >= 5) {
              await _activateDesktopWatchFallback();
            }
          }
          return;
        }
        if (st == -2) {
          _embedCheckCount++;
          if (_embedCheckCount >= 3) {
            if (_embedUrl.startsWith('https://m.youtube.com/')) {
              await _activateDesktopWatchFallback();
            } else {
              await _activateWatchFallback();
            }
          }
          return;
        }
        final playing = st == 1;
        if (playing != _isPlaying && mounted) {
          setState(() => _isPlaying = playing);
        }
      } catch (_) {}
    });
  }

  /// صفحة المشاهدة الرسمية (لا تخضع لقيود التضمين داخل WebView).
  String _watchUrlFor(String videoId) {
    final lang = context.read<AppState>().language == AppLanguage.arabic
        ? 'ar'
        : 'en';
    return 'https://m.youtube.com/watch?v=$videoId&autoplay=1&hl=$lang';
  }

  String _desktopWatchUrlFor(String videoId) {
    final lang = context.read<AppState>().language == AppLanguage.arabic
        ? 'ar'
        : 'en';
    return 'https://www.youtube.com/watch?v=$videoId&autoplay=1&hl=$lang';
  }

  Future<void> _activateDesktopWatchFallback() async {
    if (_desktopWatchFallbackUsed || !mounted) return;
    final vid = _currentTarget.videoId;
    if (vid == null || vid.isEmpty) return;

    _desktopWatchFallbackUsed = true;
    _embedCheckCount = 0;
    final c = _controller;
    if (c == null) return;
    setState(() => _isLoading = true);
    try {
      await c.loadRequest(
        Uri.parse(_desktopWatchUrlFor(vid)),
        headers: const {'Referer': 'https://com.dhikr.adhkar'},
      );
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// الطبقة الثانية (الطرق الموفّر لحالتها): فشل صفحة التضمين
  /// (قيد تعذّر التشغيل داخل WebView) → التحويل لصفحة المشاهدة الرسمية
  /// لنفس الفيديو داخل نفس WebView. صفحة المشاهدة لا تخضع لقيود
  /// المُضمِّن، والتحكم (تشغيل/إيقاف/تقدم/سرعة) يعمل عليها لأنها تملك
  /// عنصر <video> قياسيًا، ومراقب الحالة يميز 0/1 (فيديو يعمل) عن -2.
  Future<void> _activateWatchFallback() async {
    if (_watchFallbackUsed || !mounted) return;
    _watchFallbackUsed = true;
    final vid = _currentTarget.videoId;
    if (vid == null || vid.isEmpty) return;
    final watchUrl = _watchUrlFor(vid);
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final c = _controller;
    if (c == null) return;
    try {
      await c.loadRequest(
        Uri.parse(watchUrl),
        headers: const {'Referer': 'https://${YOUTUBE_APP_ID}'},
      );
    } catch (_) {}
  }

  bool get _hasPrev => _currentIndex > 0 && _playlist.isNotEmpty;
  bool get _hasNext =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length - 1;

  /// التنقل بين حلقات السلسلة داخل التطبيق فقط (لا علاقة باقتراحات يوتيوب)
  void _playAt(int index) {
    if (index < 0 || index >= _playlist.length || index == _currentIndex)
      return;
    final item = _playlist[index];
    final target = parseYoutubeTarget(item.url);
    if (target == null) {
      _showFeedback(context, 'تعذر فتح هذه الحلقة');
      return;
    }
    HapticFeedback.selectionClick();
    _ytController?.removeListener(_onYtPlayerUpdate);
    _ytController?.dispose();
    _ytController = null;
    _controller = null;
    setState(() {
      _currentIndex = index;
      _currentTarget = target;
      _currentTitle = item.title;
      _currentSourceUrl = item.url;
      _isMuted = false;
      _playbackSpeed = 1.0;
      _isPlaying = false;
    });
    _setupPlayer();
  }

  void _playPrev() => _playAt(_currentIndex - 1);
  void _playNext() => _playAt(_currentIndex + 1);

  void _togglePlay() {
    if (_useYtFlutter && _ytController != null) {
      if (_ytController!.value.isPlaying) {
        _ytController!.pause();
      } else {
        _ytController!.play();
      }
      setState(() {
        _isPlaying = _ytController!.value.isPlaying;
      });
      return;
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
    _sendCommand(_isPlaying ? 'playVideo' : 'pauseVideo');
  }

  void _forward10() {
    if (_useYtFlutter && _ytController != null) {
      final pos = _ytController!.value.position;
      _ytController!.seekTo(pos + const Duration(seconds: 10));
    } else if (_controller != null) {
      _controller!.runJavaScript(
        "try{var v=document.querySelector('video');if(v){v.currentTime+=10}}catch(e){}",
      );
    }
    _showFeedback(context, '+10 ثوانٍ');
  }

  void _rewind10() {
    if (_useYtFlutter && _ytController != null) {
      final pos = _ytController!.value.position;
      final target = pos - const Duration(seconds: 10);
      _ytController!.seekTo(target < Duration.zero ? Duration.zero : target);
    } else if (_controller != null) {
      _controller!.runJavaScript(
        "try{var v=document.querySelector('video');if(v){v.currentTime=Math.max(0,v.currentTime-10)}}catch(e){}",
      );
    }
    _showFeedback(context, '-10 ثوانٍ');
  }

  void _setSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    if (_useYtFlutter && _ytController != null) {
      _ytController!.setPlaybackRate(speed);
    } else {
      _sendCommand('setPlaybackRate', [speed]);
    }
    _showFeedback(context, 'سرعة التشغيل: ${speed}x');
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_useYtFlutter && _ytController != null) {
      if (_isMuted) {
        _ytController!.mute();
      } else {
        _ytController!.unMute();
      }
    } else {
      _sendCommand(_isMuted ? 'mute' : 'unMute');
    }
    _showFeedback(context, _isMuted ? 'تم كتم الصوت' : 'تم تفعيل الصوت');
  }

  void _restartVideo() {
    setState(() {
      _isPlaying = true;
    });
    if (_useYtFlutter && _ytController != null) {
      _ytController!.seekTo(Duration.zero);
      _ytController!.play();
    } else {
      _sendCommand('seekTo', [0, true]);
      _sendCommand('playVideo');
    }
    _showFeedback(context, 'إعادة التشغيل من البداية');
  }

  void _showFeedback(BuildContext context, String text) {
    AppToast.hide(context);
    AppToast.show(
      context,
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _startSleepTimer(int minutes) {
    _sleepTicker?.cancel();
    setState(() {
      _sleepTimerMinutes = minutes;
      _sleepSecondsRemaining = minutes * 60;
    });

    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_sleepSecondsRemaining <= 1) {
        t.cancel();
        setState(() {
          _sleepTimerMinutes = null;
          _sleepSecondsRemaining = 0;
          _isPlaying = false;
        });
        if (_useYtFlutter && _ytController != null) {
          _ytController!.pause();
        } else {
          _sendCommand('pauseVideo');
        }
        if (mounted) {
          AppToast.show(
            context,
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                'تم إيقاف التشغيل تلقائياً بواسطة مؤقت النوم 🌙',
                style: TextStyle(fontFamily: DhikrTheme.arabicFont),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _sleepSecondsRemaining--;
        });
      }
    });

    Navigator.of(context).pop();
    _showFeedback(context, 'تم ضبط مؤقت النوم: $minutes دقيقة 🌙');
  }

  void _cancelSleepTimer() {
    _sleepTicker?.cancel();
    setState(() {
      _sleepTimerMinutes = null;
      _sleepSecondsRemaining = 0;
    });
    _showFeedback(context, 'تم إلغاء مؤقت النوم');
  }

  void _openSleepTimerSheet(BuildContext context, bool isAr) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF161E28) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: dark ? Colors.white12 : Colors.black12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(LucideIcons.moon, size: 20, color: _gold),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'مؤقت النوم الذكي (إيقاف تلقائي)' : 'Sleep Timer',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'سيتم إيقاف تشغيل الفيديو والدرس تلقائياً بعد انقضاء الوقت المحدد:'
                    : 'Playback will automatically pause after the selected duration:',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 12.5,
                  color: dark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [15, 30, 45, 60, 90].map((mins) {
                  final isSelected = _sleepTimerMinutes == mins;
                  return ChoiceChip(
                    selected: isSelected,
                    onSelected: (_) => _startSleepTimer(mins),
                    selectedColor: _gold,
                    backgroundColor: dark
                        ? const Color(0xFF222C3A)
                        : const Color(0xFFF1F5F9),
                    label: Text(
                      isAr ? '$mins دقيقة' : '$mins min',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (dark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_sleepTimerMinutes != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _cancelSleepTimer();
                  },
                  icon: const Icon(LucideIcons.x, size: 16, color: Colors.red),
                  label: Text(
                    isAr ? 'إلغاء المؤقت النشط' : 'Cancel active timer',
                    style: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _toggleBookmark(bool isAr) {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    _showFeedback(
      context,
      _isBookmarked
          ? (isAr ? 'تم حفظ الدرس في المفضلة' : 'Saved to favorites')
          : (isAr ? 'تمت إزالة الدرس من المفضلة' : 'Removed from favorites'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = dark ? const Color(0xFF090D12) : const Color(0xFFF8FAFC);
    final cardBg = dark ? const Color(0xFF131A24) : Colors.white;
    final borderColor = dark
        ? Colors.white12
        : Colors.black.withValues(alpha: 0.08);

    if (_useYtFlutter && _ytController != null) {
      return YoutubePlayerBuilder(
        onEnterFullScreen: () {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        },
        onExitFullScreen: () {
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        },
        player: YoutubePlayer(
          controller: _ytController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: _ytRed,
          progressColors: const ProgressBarColors(
            playedColor: _ytRed,
            handleColor: _ytRedDark,
            bufferedColor: Colors.white24,
            backgroundColor: Colors.black26,
          ),
          onReady: () {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          bottomActions: [],
        ),
        builder: (context, player) {
          return _buildScaffold(
            context,
            player,
            isAr,
            dark,
            bgColor,
            cardBg,
            borderColor,
          );
        },
      );
    }

    final fallbackPlayer = _buildPlayerContent(context, isAr);
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape =
            orientation == Orientation.landscape || _isLandscape;
        if (isLandscape) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Center(child: SizedBox.expand(child: fallbackPlayer)),
                Positioned(
                  top: 14,
                  right: isAr ? null : 14,
                  left: isAr ? 14 : null,
                  child: SafeArea(
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _toggleOrientation,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.fullscreen_exit_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        return _buildScaffold(
          context,
          fallbackPlayer,
          isAr,
          dark,
          bgColor,
          cardBg,
          borderColor,
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    Widget playerWidget,
    bool isAr,
    bool dark,
    Color bgColor,
    Color cardBg,
    Color borderColor,
  ) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF0D1219) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.channelName ?? (isAr ? 'مشغل الفيديو' : 'Video Player'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: dark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              children: [
                // مؤقت النوم النشط (إن وُجد)
                if (_sleepTimerMinutes != null) ...[
                  _buildActiveSleepTimerPill(isAr, dark),
                  const SizedBox(height: 10),
                ],

                // 1. اسم الفيديو فوق الفيديو (اسم القناة في الهيدر فوق)
                Text(
                  _currentTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.5,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                // 2. منصة عرض الفيديو
                _buildVideoStage(
                  context,
                  playerWidget,
                  isAr,
                  dark,
                  borderColor,
                ),
                const SizedBox(height: 12),

                // 3. أزرار التحكم في الحلقات: السابق/التالي/تدوير — التشغيل
                // والإيقاف من أزرار يوتيوب الأصلية داخل الفيديو نفسه (في
                // صفحة المشاهدة الرسمية) فلا يوجد زر تشغيل خاص بنا يمكن أن
                // يتداخل مع إعدادات المشغّل ويسبب خطأ 153.
                _buildInteractiveControlDeck(isAr, dark, cardBg, borderColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// كبسولة مؤقت النوم النشط
  Widget _buildActiveSleepTimerPill(bool isAr, bool dark) {
    final mins = _sleepSecondsRemaining ~/ 60;
    final secs = (_sleepSecondsRemaining % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: dark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.moon, size: 16, color: _gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAr
                  ? 'مؤقت النوم نشط: إيقاف تلقائي بعد $mins:$secs دقيقة'
                  : 'Sleep timer: pausing in $mins:$secs',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: dark ? const Color(0xFFFBBF24) : _gold,
              ),
            ),
          ),
          InkWell(
            onTap: _cancelSleepTimer,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 16, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// منصة العرض السينمائي (Video Stage with Ambient Glow)
  Widget _buildVideoStage(
    BuildContext context,
    Widget playerWidget,
    bool isAr,
    bool dark,
    Color borderColor,
  ) {
    final isTheater = _viewMode == PlayerViewMode.theater;
    final isAudio = _viewMode == PlayerViewMode.audio;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Ambient Glow (مخفف للأداء: ظل واحد خفيف بدل طبقات ثقيلة)
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isAudio ? _gold : _ytRed).withValues(
                    alpha: dark ? 0.12 : 0.06,
                  ),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ),

        // 2. Video Player Container - دائماً موجود في الشجرة لضمان استمرار الصوت دون انقطاع
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(isTheater ? 14 : 22),
            border: Border.all(
              color: isAudio
                  ? _gold.withValues(alpha: dark ? 0.4 : 0.25)
                  : borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.6 : 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isTheater ? 13 : 21),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  playerWidget,

                  if (_isLoading)
                    Container(
                      color: Colors.black87,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.8,
                          color: _ytRed,
                        ),
                      ),
                    ),

                  // واجهة الاستماع الصوتي المركز: تظهر فوق المشغل بسلاسة مع الحفاظ على تشغيل الصوت
                  if (isAudio)
                    Positioned.fill(
                      child: _buildAudioModeOverlay(isAr, dark, borderColor),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// واجهة وضع الاستماع الصوتي المركز (تظهر فوق الفيديو دون مقاطعة تدفق الصوت)
  Widget _buildAudioModeOverlay(bool isAr, bool dark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF182230), const Color(0xFF0F151E)]
              : [const Color(0xFFF8FAFC), const Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Headphone Glowing Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: dark ? 0.25 : 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(LucideIcons.headphones, size: 24, color: _gold),
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                _currentTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),

              // Channel & Status
              Text(
                widget.channelName ??
                    (isAr ? 'الاستماع الصوتي في الخلفية' : 'Background Audio'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: dark ? _gold : const Color(0xFFB45309),
                ),
              ),
              const SizedBox(height: 10),

              // Animated Soundwave Visualizer (locked in fixed height to eliminate jitter)
              SizedBox(
                height: 28,
                child: AnimatedBuilder(
                  animation: _eqController,
                  builder: (ctx, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(14, (i) {
                        final animVal =
                            (_eqController.value + (i * 0.07)) % 1.0;
                        final height = 6.0 + (animVal * 20.0);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 3.5,
                          height: _isPlaying ? height : 6,
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
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

  /// محول أوضاع العرض (سينمائي / مسرح / استماع)
  // ignore: unused_element
  Widget _buildViewModeSelector(bool isAr, bool dark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF131A24) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          _buildModeTab(
            title: isAr ? 'الوضع السينمائي' : 'Cinema',
            icon: LucideIcons.clapperboard,
            mode: PlayerViewMode.cinema,
            dark: dark,
          ),
          _buildModeTab(
            title: isAr ? 'مسرح موسّع' : 'Theater',
            icon: LucideIcons.monitor,
            mode: PlayerViewMode.theater,
            dark: dark,
          ),
          _buildModeTab(
            title: isAr ? 'استماع فقط' : 'Audio',
            icon: LucideIcons.headphones,
            mode: PlayerViewMode.audio,
            dark: dark,
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required PlayerViewMode mode,
    required bool dark,
  }) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _viewMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (dark ? const Color(0xFF222C3A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? (dark ? Colors.white : Colors.black87)
                    : (dark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (dark ? Colors.white : Colors.black87)
                      : (dark ? Colors.white54 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// لوحة تحكم المشغل الذكية (Interactive Control Deck)
  Widget _buildInteractiveControlDeck(
    bool isAr,
    bool dark,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // الحلقة السابقة من السلسلة داخل التطبيق (باهتة عند عدم وجود سابق)
          _buildNavArrow(
            icon: LucideIcons.skipForward,
            label: isAr ? 'السابق' : 'Prev',
            onTap: _hasPrev ? _playPrev : null,
            dark: dark,
          ),

          // ملاحظة: لا يوجد زر تشغيل/إيقاف خاص بنا عمداً — التشغيل والإيقاف
          // من أزرار يوتيوب الأصلية داخل الفيديو نفسه، حتى لا يتداخل أي
          // أمر خارجي مع إعدادات المشغّل الرسمي (كان سبب خطأ 153).

          // الحلقة التالية من السلسلة داخل التطبيق (باهتة عند عدم وجود تالٍ)
          _buildNavArrow(
            icon: LucideIcons.skipBack,
            label: isAr ? 'التالي' : 'Next',
            onTap: _hasNext ? _playNext : null,
            dark: dark,
          ),

          // تدوير الشاشة
          _buildControlButton(
            icon: _isLandscape
                ? Icons.screen_lock_portrait_rounded
                : Icons.screen_rotation_rounded,
            label: isAr
                ? (_isLandscape ? 'طولي' : 'تدوير')
                : (_isLandscape ? 'Portrait' : 'Rotate'),
            onTap: _toggleOrientation,
            dark: dark,
            highlight: _isLandscape,
          ),
        ],
      ),
    );
  }

  /// زرار تنقل بين الحلقات — باهت وغير فعال عند غياب حلقة في هذا الاتجاه
  Widget _buildNavArrow({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool dark,
  }) {
    final enabled = onTap != null;
    final color = enabled
        ? (dark ? Colors.white70 : Colors.black87)
        : (dark ? Colors.white24 : Colors.black26);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool dark,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: highlight
                  ? Colors.red
                  : (dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: highlight
                    ? Colors.red
                    : (dark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// محدد سرعة الاستماع (0.75x - 2.0x)
  // ignore: unused_element
  Widget _buildSpeedSelector(
    bool isAr,
    bool dark,
    Color cardBg,
    Color borderColor,
  ) {
    final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.gauge,
            size: 16,
            color: dark ? Colors.white60 : Colors.black54,
          ),
          const SizedBox(width: 8),
          Text(
            isAr ? 'السرعة:' : 'Speed:',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: speeds.map((sp) {
                  final isSelected = _playbackSpeed == sp;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (_) => _setSpeed(sp),
                      selectedColor: _ytRed,
                      backgroundColor: dark
                          ? const Color(0xFF1B2330)
                          : const Color(0xFFF1F5F9),
                      visualDensity: VisualDensity.compact,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      label: Text(
                        '${sp}x',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (dark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerContent(BuildContext context, bool isAr) {
    if (_useYtFlutter && _ytController != null) {
      return YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: _ytRed,
        progressColors: const ProgressBarColors(
          playedColor: _ytRed,
          handleColor: _ytRedDark,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.black26,
        ),
        onReady: () {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
        bottomActions: [],
      );
    }
    if (_embedFailed) {
      return _buildEmbedErrorTile(context, isAr);
    }
    if (_embedUrl.isEmpty) {
      return _buildFallbackTile(context, isAr);
    }
    if (kIsWeb && _viewType.isNotEmpty) {
      return HtmlElementView(viewType: _viewType);
    }
    final controller = _controller;
    if (controller != null) {
      return WebViewWidget(controller: controller);
    }
    return _buildFallbackTile(context, isAr);
  }

  /// بديل واضح عند تعذّر تحميل المشغّل (انقطاع شبكة فقط — الإنذارات
  /// الكاذبة السابقة أُزيلت مع صفحة YT.Player اليدوية).
  Widget _buildEmbedErrorTile(BuildContext context, bool isAr) {
    return Container(
      color: const Color(0xFF141922),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.shieldAlert, size: 42, color: _gold),
          const SizedBox(height: 10),
          Text(
            isAr
                ? 'تعذّر تحميل الفيديو\nتحقق من اتصال الإنترنت ثم أعد المحاولة'
                : 'Could not load the video\nCheck your connection and retry',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _setupPlayer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ytRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(LucideIcons.refreshCw, size: 14),
            label: Text(
              isAr ? 'إعادة المحاولة' : 'Retry',
              style: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackTile(BuildContext context, bool isAr) {
    return Container(
      color: const Color(0xFF141922),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.playCircle, size: 44, color: _ytRed),
          const SizedBox(height: 12),
          Text(
            isAr ? 'جاهز للتشغيل بأعلى جودة' : 'Ready for playback',
            style: const TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _setupPlayer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ytRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(LucideIcons.refreshCw, size: 14),
            label: Text(
              isAr ? 'إعادة المحاولة' : 'Retry',
              style: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
