import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

final Map<String, web.HTMLIFrameElement> _activeIframes = {};

/// Registers an HTML iframe view factory for [viewType] that loads
/// [embedUrl]. Used by the in-app YouTube player on web builds.
void registerYoutubeFrameFactory(String viewType, String embedUrl) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int id, {Object? params}) {
      final iframe = web.HTMLIFrameElement()
        ..id = 'yt-iframe-$viewType'
        ..src = embedUrl
        ..allowFullscreen = true
        ..setAttribute(
          'allow',
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen',
        )
        ..setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
      iframe.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%'
        ..borderRadius = '16px';
      _activeIframes[viewType] = iframe;
      return iframe;
    },
  );
}

/// Dispatches YouTube Iframe API command (playVideo, pauseVideo, seekTo, etc.)
void sendYoutubeCommand(String viewType, String func, [List<dynamic>? args]) {
  try {
    final iframe = _activeIframes[viewType] ??
        (web.document.getElementById('yt-iframe-$viewType') as web.HTMLIFrameElement?);
    if (iframe != null && iframe.contentWindow != null) {
      final payload = jsonEncode({
        'event': 'command',
        'func': func,
        'args': args ?? [],
      });
      iframe.contentWindow!.postMessage(payload.toJS, '*'.toJS);
    }
  } catch (_) {}
}