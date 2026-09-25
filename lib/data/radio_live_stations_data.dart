typedef BuiltInLiveStation = ({
  String id,
  String name,
  String url,
  String category,
});

/// محطات البث المباشر المدمجة في التطبيق.
///
/// هذه الملف الخاص بصلات (links) المحطات الحية الثابتة في التطبيق، وهي مطابقة
/// لمجموعة `radio` في لوحة التحكم (Firestore) بحيث يحمل كل صف نفس المعرّف:
///   - radio_cairo  →  إذاعة القرآن الكريم من القاهرة
///   - radio_madina →  إذاعة القرآن الكريم من المدينة المنورة (بث SBA الرسمي)
///   - radio_sunnah →  السنة النبوية من المدينة المنورة (بث SBA الرسمي)
///
/// أي تعديل في لوحة التحكم على نفس المعرّف يعيد ضبط الرابط في التطبيق تلقائيًا،
/// ويمكن إضافة محطات جديدة من اللوحة فتُعرض وتشتغل في التطبيق دون تعديل الكود.
const List<BuiltInLiveStation> builtInLiveStations = [
  (
    id: 'radio_cairo',
    name: 'إذاعة القرآن الكريم — القاهرة',
    url: 'https://n07.radiojar.com/8s5u5tpdtwzuv',
    category: 'live',
  ),
  (
    id: 'radio_madina',
    name: 'إذاعة القرآن الكريم — المدينة المنورة',
    url: 'https://cdn-globecast.akamaized.net/live/eds/saudi_quran/hls_roku/index.m3u8',
    category: 'live',
  ),
  (
    id: 'radio_sunnah',
    name: 'السنة النبوية — المدينة المنورة',
    url: 'https://cdn-globecast.akamaized.net/live/eds/saudi_sunnah/hls_roku/index.m3u8',
    category: 'live',
  ),
];