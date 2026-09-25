import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// فيديو من قناة يوتيوب (بيانات مأخوذة من خلاصة RSS العامة للقناة).
class YoutubeVideoInfo {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final DateTime? publishedAt;

  const YoutubeVideoInfo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    this.publishedAt,
  });

  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';
}

/// خلاصة قناة: اسمها + أحدث مقاطعها.
class ChannelFeed {
  final String channelTitle;
  final List<YoutubeVideoInfo> videos;

  const ChannelFeed({required this.channelTitle, required this.videos});
}

const _feedUrlTemplate = 'https://www.youtube.com/feeds/videos.xml?channel_id=';
const _proxyUrlTemplate = 'https://api.allorigins.win/raw?url=';

/// كاش خفيف داخل الجلسة: يمنع إعادة جلب نفس القناة مع كل rebuild
/// (سبب رئيسي للبطء والوميض)، ويسمح بعرض آخر بيانات ناجحة عند انقطاع الشبكة.
final Map<String, _CachedFeed> _feedMemoryCache = {};

class _CachedFeed {
  final ChannelFeed feed;
  final DateTime fetchedAt;
  _CachedFeed(this.feed, this.fetchedAt);
}

const _feedCacheTtl = Duration(hours: 6);

/// يجلب أحدث مقاطع القناة من خلاصة يوتيوب العامة (بدون API key).
///
/// على أندرويد/آيفون يعمل الطلب المباشر. على الويب يمنع المتصفح الطلب
/// المباشر بـ CORS، لذلك نقع محاولةً أخيرة إلى بروكسي عام. إذا فشل كلاهما
/// تُرمى استثناء ويعرض الواجهة مشغّل القناة المدمج كبديل.
///
/// ملاحظة حقوق النشر: هذه الخلاصة عامة من يوتيوب، والتشغيل يتم دائماً
/// عبر مشغّل يوتيوب الرسمي المدمج مع ذكر القناة ورابطها — لا تنزيل
/// ولا إعادة رفع ولا إخفاء لشعار يوتيوب.
Future<ChannelFeed> fetchChannelFeed(String channelId) async {
  final now = DateTime.now();
  final cached = _feedMemoryCache[channelId.trim()];
  if (cached != null && now.difference(cached.fetchedAt) < _feedCacheTtl) {
    return cached.feed;
  }

  final direct = Uri.parse('$_feedUrlTemplate${channelId.trim()}');

  String body;
  try {
    final res =
        await http.get(direct).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200 || res.body.isEmpty) {
      throw Exception('feed http ${res.statusCode}');
    }
    body = res.body;
  } catch (_) {
    final proxied = Uri.parse(
      '$_proxyUrlTemplate${Uri.encodeComponent(direct.toString())}',
    );
    final res = await http.get(proxied).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 || res.body.isEmpty) {
      // عند الفشل اعرض آخر كاش معروف بدل شاشة فارغة تماماً.
      if (cached != null) return cached.feed;
      throw Exception('feed proxy http ${res.statusCode}');
    }
    body = res.body;
  }

  // صفحة خطأ HTML (حظر/شبكة) ليست XML صالحاً — اعتبرها فشلاً واضحاً.
  final trimmed = body.trimLeft();
  if (!trimmed.startsWith('<')) {
    if (cached != null) return cached.feed;
    throw Exception('feed invalid body');
  }

  final doc = XmlDocument.parse(body);
  final root = doc.rootElement;

  final channelTitle = _childText(root, 'title') ?? '';

  final videos = <YoutubeVideoInfo>[];
  for (final entry in root.children.whereType<XmlElement>().where(
      (e) => e.name.local == 'entry')) {
    final videoId = _childText(entry, 'videoId');
    if (videoId == null || videoId.isEmpty) continue;

    var title = _childText(entry, 'title') ?? '';
    if (title.isEmpty) title = 'بدون عنوان';

    final publishedStr = _childText(entry, 'published');
    final published =
        publishedStr == null ? null : DateTime.tryParse(publishedStr);

    videos.add(YoutubeVideoInfo(
      videoId: videoId,
      title: title.trim(),
      thumbnailUrl: 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg',
      publishedAt: published,
    ));
  }

  final feed = ChannelFeed(channelTitle: channelTitle, videos: videos);
  _feedMemoryCache[channelId.trim()] = _CachedFeed(feed, now);
  return feed;
}

/// يقرأ نص عنصر فرعي بمطابقة الاسم المحلي (local name) بدل الاسم الكامل،
/// لأن خلاصة يوتيوب تستخدم بادئة النطاق `yt:` (مثال: `<yt:videoId>`)،
/// ومطابقة الاسم الكامل فقط كانت تُرجع قائمة فارغة دائماً — وهو سبب
/// ظهور «تعذّر جلب المقاطع» حتى مع اتصال سليم.
String? _childText(XmlElement parent, String localName) {
  for (final child in parent.children.whereType<XmlElement>()) {
    if (child.name.local == localName) {
      final text = child.innerText.trim();
      if (text.isNotEmpty) return text;
    }
  }
  return null;
}