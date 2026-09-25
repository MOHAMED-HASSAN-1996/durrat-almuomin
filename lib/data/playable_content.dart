/// أدوات تحويل روابط يوتيوب إلى أهداف قابلة للتضمين داخل التطبيق (فريم).
///
/// يوتيوب يسمح بتضمين الفيديوهات والبلاي ليستات المحددة فقط داخل إطار؛
/// أما القنوات والبحث فلا تُضمَّن، فتُفتح خارجيًا كاحتياط. القنوات العامة
/// تُضمَّن عبر قائمة «آخر الرفع» (UU + معرّف القناة).
class YoutubeTarget {
  final String? videoId;
  final String? playlistId;
  final String? channelId;

  const YoutubeTarget({this.videoId, this.playlistId, this.channelId});

  bool get isEmbeddable =>
      (videoId != null && videoId!.isNotEmpty) ||
      (playlistId != null && playlistId!.isNotEmpty) ||
      (channelId != null && channelId!.isNotEmpty);
}

/// يبني رابط التضمين (embed) الخاص بالهدف، أو null إن لم يكن قابلاً للتضمين.
String? embedUrlFor(YoutubeTarget target) {
  const origin = 'https://www.youtube.com';

  if (target.videoId != null && target.videoId!.isNotEmpty) {
    final listParam =
        (target.playlistId != null && target.playlistId!.isNotEmpty)
            ? '&list=${target.playlistId}'
            : '';
    return 'https://www.youtube-nocookie.com/embed/${target.videoId}'
        '?autoplay=1&rel=0&playsinline=1&enablejsapi=1$listParam'
        '&origin=$origin&widget_referrer=$origin';
  }

  if (target.playlistId != null && target.playlistId!.isNotEmpty) {
    return 'https://www.youtube-nocookie.com/embed/videoseries'
        '?list=${target.playlistId}&autoplay=1&rel=0&playsinline=1&enablejsapi=1'
        '&origin=$origin&widget_referrer=$origin';
  }

  if (target.channelId != null && target.channelId!.isNotEmpty) {
    final uploads = uploadsPlaylistIdFor(target.channelId!);
    return 'https://www.youtube-nocookie.com/embed/videoseries'
        '?list=$uploads&autoplay=1&rel=0&playsinline=1&enablejsapi=1'
        '&origin=$origin&widget_referrer=$origin';
  }

  return null;
}

/// رابط تضمين مختصر للتحميل المباشر داخل WebView كصفحة كاملة.
///
/// الفرق عن [embedUrlFor]: بدون معاملَي `origin` و`widget_referrer`،
/// لأنهما مخصصان لتضمين iframe داخل صفحة ويب أخرى فقط. عند تحميل
/// رابط التضمين كصفحة علوية داخل WebView يسبب `origin` غير المطابق
/// خطأ 153 الكاذب («Video player configuration error») حتى مع فيديوهات
/// تسمح بالتضمين رسمياً. هذا الرابط المختصر هو المسار الرسمي المباشر.
String? embedDirectUrlFor(YoutubeTarget target) {
  if (target.videoId != null && target.videoId!.isNotEmpty) {
    final listParam =
        (target.playlistId != null && target.playlistId!.isNotEmpty)
            ? '&list=${target.playlistId}'
            : '';
    return 'https://www.youtube.com/embed/${target.videoId}'
        '?autoplay=1&rel=0&playsinline=1&controls=1$listParam';
  }

  if (target.playlistId != null && target.playlistId!.isNotEmpty) {
    return 'https://www.youtube.com/embed/videoseries'
        '?list=${target.playlistId}&autoplay=1&rel=0&playsinline=1&controls=1';
  }

  if (target.channelId != null && target.channelId!.isNotEmpty) {
    final uploads = uploadsPlaylistIdFor(target.channelId!);
    return 'https://www.youtube.com/embed/videoseries'
        '?list=$uploads&autoplay=1&rel=0&playsinline=1&controls=1';
  }

  return null;
}
///
/// يحوّل معرّف القناة (UC…) إلى معرّف قائمة «آخر الرفع» (UU…).
///
/// القاعدة الرسمية: تُستبدل البادئة `UC` بـ `UU` فقط، لا تُضاف `UU`
/// أمام المعرف كاملاً. الخطأ الشائع `UU + UC…` ينتج معرّفاً غير موجود
/// فيتقاطع المشغّل المدمج مع شاشة فارغة.
String uploadsPlaylistIdFor(String channelId) {
  final cid = channelId.trim();
  if (cid.length >= 2 && (cid.startsWith('UC') || cid.startsWith('UU'))) {
    return 'UU${cid.substring(2)}';
  }
  return cid;
}

/// يسحب الهدف القابل للتضمين من رابط يوتيوب؛ null للروابط غير المضمِّنة
/// (بحث، قناة بمعرّف @، روابط غير يوتيوب…).
YoutubeTarget? parseYoutubeTarget(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  final isYoutube = host == 'youtube.com' ||
      host == 'www.youtube.com' ||
      host == 'm.youtube.com' ||
      host == 'music.youtube.com' ||
      host == 'youtu.be' ||
      host == 'www.youtu.be';
  if (!isYoutube) return null;

  final path = uri.path;
  final query = uri.queryParameters;

  // https://youtu.be/ID
  if (host == 'youtu.be' || host == 'www.youtu.be') {
    if (uri.pathSegments.isEmpty) return null;
    final id = uri.pathSegments.first;
    if (id.isNotEmpty && !id.contains('.')) {
      return YoutubeTarget(videoId: id);
    }
    return null;
  }

  // /watch?v=ID أو /watch?v=ID&list=PL…
  if (path == '/watch' || path.endsWith('/watch')) {
    final v = query['v'];
    if (v != null && v.isNotEmpty) {
      return YoutubeTarget(videoId: v, playlistId: query['list']);
    }
    return null;
  }

  // /playlist?list=PL…
  if (path.startsWith('/playlist')) {
    final list = query['list'];
    if (list != null && list.isNotEmpty) {
      return YoutubeTarget(playlistId: list);
    }
    return null;
  }

  // /embed/ID أو /shorts/ID أو /live/ID
  if (path.startsWith('/embed/') ||
      path.startsWith('/shorts/') ||
      path.startsWith('/live/')) {
    final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    if (last != null && last.isNotEmpty && !last.contains('.')) {
      return YoutubeTarget(videoId: last);
    }
    return null;
  }

  // /channel/UC…
  if (path.startsWith('/channel/')) {
    if (uri.pathSegments.length >= 2) {
      final cid = uri.pathSegments[1];
      if (cid.isNotEmpty) return YoutubeTarget(channelId: cid);
    }
    return null;
  }

  return null;
}