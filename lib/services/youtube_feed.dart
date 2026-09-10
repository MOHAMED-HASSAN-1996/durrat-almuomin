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

/// يجلب أحدث مقاطع القناة من خلاصة يوتيوب العامة (بدون API key).
///
/// على أندرويد/آيفون يعمل الطلب المباشر. على الويب يمنع المتصفح الطلب
/// المباشر بـ CORS، لذلك نقع محاولةً أخيرة إلى بروكسي عام. إذا فشل كلاهما
/// تُرمى استثناء ويعرض الواجهة مشغّل القناة المدمج كبديل.
Future<ChannelFeed> fetchChannelFeed(String channelId) async {
  final direct = Uri.parse('$_feedUrlTemplate$channelId');

  String body;
  try {
    body = (await http.get(direct).timeout(const Duration(seconds: 12))).body;
  } catch (_) {
    final proxied = Uri.parse(
      '$_proxyUrlTemplate${Uri.encodeComponent(direct.toString())}',
    );
    final res = await http.get(proxied).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('feed proxy http ${res.statusCode}');
    }
    body = res.body;
  }

  final doc = XmlDocument.parse(body);
  final root = doc.rootElement;

  final channelTitle = _childText(root, 'title') ?? '';

  final videos = <YoutubeVideoInfo>[];
  for (final entry in root.findElements('entry')) {
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

  return ChannelFeed(channelTitle: channelTitle, videos: videos);
}

String? _childText(XmlElement parent, String name) {
  for (final child in parent.findElements(name)) {
    final text = child.innerText.trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}