/// بيانات قسم «قصص الأنبياء والتاريخ الإسلامي بالأنمي» — فيديوهات وسلاسل
/// كرتونية إسلامية حقيقية مأخوذة مباشرة من القناة الرسمية (بتاع أنمي).
library;

/// معرّف القناة الرسمية لقصص الرسوم المتحركة الإسلامية
const String animeChannelId = 'UCFQiJGV7ExuFdGn6pGfgYtw';

/// رابط القناة للعرض الخارجي
const String animeChannelUrl = 'https://www.youtube.com/channel/UCFQiJGV7ExuFdGn6pGfgYtw';

/// تصنيفات قصص الأنمي والرسوم المتحركة
enum AnimeCategory {
  all,
  khalid,
  quranSeries,
}

extension AnimeCategoryExtension on AnimeCategory {
  String get titleAr {
    switch (this) {
      case AnimeCategory.all:
        return 'الكل';
      case AnimeCategory.khalid:
        return 'ملحمة سيف الله المسلول';
      case AnimeCategory.quranSeries:
        return 'قصص القرآن والأمم السابقة';
    }
  }

  String get titleEn {
    switch (this) {
      case AnimeCategory.all:
        return 'All';
      case AnimeCategory.khalid:
        return 'Khalid Ibn Al-Walid Saga';
      case AnimeCategory.quranSeries:
        return 'Quran & Ancient Nations';
    }
  }
}

/// نموذج قصة أو حلقة أنمي لقصص الأنبياء والقرآن
class AnimeProphetStory {
  final String id;
  final String titleAr;
  final String titleEn;
  final String prophetNameAr;
  final String prophetNameEn;
  final String descriptionAr;
  final String descriptionEn;
  final AnimeCategory category;
  final String videoUrl;
  final String durationOrEpisodes;
  final String? customThumbnail;
  final bool isFeatured;
  final String? tag;
  final bool isActive;

  // هيكلة السلاسل والحلقات
  final String? seriesId;
  final String? seriesTitleAr;
  final String? seriesTitleEn;
  final int? episodeNumber;
  final String? episodeTitleAr;
  final int? displayOrder;
  final int? seriesOrder;

  const AnimeProphetStory({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.prophetNameAr,
    required this.prophetNameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.category,
    required this.videoUrl,
    required this.durationOrEpisodes,
    this.customThumbnail,
    this.isFeatured = false,
    this.tag,
    this.isActive = true,
    this.seriesId,
    this.seriesTitleAr,
    this.seriesTitleEn,
    this.episodeNumber,
    this.episodeTitleAr,
    this.displayOrder,
    this.seriesOrder,
  });

  /// استخراج الصورة المصغرة (دقة متوسطة mqdefault: أخف وأسرع بكثير من
  /// hqdefault مع جودة كافية للبطاقات — يحسّن التمرير والبدء بشكل ملحوظ).
  String get thumbnailUrl {
    if (customThumbnail != null && customThumbnail!.isNotEmpty) {
      return customThumbnail!;
    }
    final uri = Uri.tryParse(videoUrl);
    if (uri != null) {
      if (uri.pathSegments.contains('watch')) {
        final v = uri.queryParameters['v'];
        if (v != null && v.isNotEmpty) {
          return 'https://i.ytimg.com/vi/$v/mqdefault.jpg';
        }
      } else if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        return 'https://i.ytimg.com/vi/${uri.pathSegments.first}/mqdefault.jpg';
      }
    }
    return 'https://i.ytimg.com/vi/placeholder/mqdefault.jpg';
  }
}

/// مجموعة سلسلة كرتونية تضم حلقات أو أجزاء متتابعة
class AnimeSeriesGroup {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String badge;
  final AnimeCategory category;
  final List<AnimeProphetStory> episodes;

  const AnimeSeriesGroup({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.badge,
    required this.category,
    required this.episodes,
  });

  int get totalEpisodes => episodes.length;
}

/// قائمة سلاسل وقصص حقيقية ومؤكدة من قناة «بتاع أنمي» الرسمية
const List<AnimeProphetStory> animatedProphetStories = [
  // --- 1. سلسلة ملحمة خالد بن الوليد (سيف الله المسلول) ---
  AnimeProphetStory(
    id: 'khalid-ep1',
    seriesId: 'series-khalid',
    seriesTitleAr: 'سلسلة ملحمة سيف الله المسلول خالد بن الوليد (أنمي)',
    seriesTitleEn: 'Khalid Ibn Al-Walid Anime Epic',
    episodeNumber: 1,
    displayOrder: 1,
    seriesOrder: 1,
    episodeTitleAr: 'الفصل الأول',
    titleAr: 'خالد بن الوليد | الفصل الأول : ميلادُ بطلٍ لا يُهزم (أنمي)',
    titleEn: 'Khalid Ibn Al-Walid | Chapter 1: Birth of an Undefeated Hero',
    prophetNameAr: 'سيف الله المسلول',
    prophetNameEn: 'Sword of Allah',
    descriptionAr: 'نشأة خالد بن الوليد وعبقريته العسكرية قبل الإسلام وإسلامه المبارك بين يدي النبي ﷺ.',
    descriptionEn: 'The early life and military genius of Khalid Ibn Al-Walid.',
    category: AnimeCategory.khalid,
    videoUrl: 'https://www.youtube.com/watch?v=1a1ntXVfRx8',
    durationOrEpisodes: 'حلقة كاملة',
    isFeatured: true,
    tag: 'سيف الله',
  ),
  AnimeProphetStory(
    id: 'khalid-ep2',
    seriesId: 'series-khalid',
    seriesTitleAr: 'سلسلة ملحمة سيف الله المسلول خالد بن الوليد (أنمي)',
    seriesTitleEn: 'Khalid Ibn Al-Walid Anime Epic',
    episodeNumber: 2,
    displayOrder: 2,
    seriesOrder: 1,
    episodeTitleAr: 'الفصل الثاني',
    titleAr: 'خالد بن الوليد | الفصل الثاني : سيف الله المسلول وغزوة مؤتة (أنمي)',
    titleEn: 'Khalid Ibn Al-Walid | Chapter 2: The Battle of Mu\'tah',
    prophetNameAr: 'سيف الله المسلول',
    prophetNameEn: 'Sword of Allah',
    descriptionAr: 'ملحمة غزوة مؤتة وتكسر السيوف التسعة وانسحاب جيش المسلمين العبقري بحنكة خالد.',
    descriptionEn: 'The historic Battle of Mu\'tah and the tactical brilliance of Khalid.',
    category: AnimeCategory.khalid,
    videoUrl: 'https://www.youtube.com/watch?v=zoYJ6_vEmjo',
    durationOrEpisodes: 'حلقة ملحمية',
    tag: 'غزوة مؤتة',
  ),
  AnimeProphetStory(
    id: 'khalid-ep3',
    seriesId: 'series-khalid',
    seriesTitleAr: 'سلسلة ملحمة سيف الله المسلول خالد بن الوليد (أنمي)',
    seriesTitleEn: 'Khalid Ibn Al-Walid Anime Epic',
    episodeNumber: 3,
    displayOrder: 3,
    seriesOrder: 1,
    episodeTitleAr: 'الفصل الثالث',
    titleAr: 'خالد بن الوليد | الفصل الثالث : بين الموت والمجد وكمين حنين (أنمي)',
    titleEn: 'Khalid Ibn Al-Walid | Chapter 3: Ambush of Hunayn',
    prophetNameAr: 'سيف الله المسلول',
    prophetNameEn: 'Sword of Allah',
    descriptionAr: 'وقائع كمين حنين وسقوط الأبطال، وثبات خالد والنبي ﷺ حتى تحقق النصر المؤزر.',
    descriptionEn: 'The ambush of Hunayn and the triumph of the believers.',
    category: AnimeCategory.khalid,
    videoUrl: 'https://www.youtube.com/watch?v=3EWY51NBgvI',
    durationOrEpisodes: 'حلقة مميزة',
    tag: 'غزوة حنين',
  ),
  AnimeProphetStory(
    id: 'khalid-ep4',
    seriesId: 'series-khalid',
    seriesTitleAr: 'سلسلة ملحمة سيف الله المسلول خالد بن الوليد (أنمي)',
    seriesTitleEn: 'Khalid Ibn Al-Walid Anime Epic',
    episodeNumber: 4,
    displayOrder: 4,
    seriesOrder: 1,
    episodeTitleAr: 'الفصل الرابع',
    titleAr: 'خالد بن الوليد | الفصل الرابع : حروب الردة ومعركة اليمامة (أنمي)',
    titleEn: 'Khalid Ibn Al-Walid | Chapter 4: Ridda Wars & Battle of Yamama',
    prophetNameAr: 'سيف الله المسلول',
    prophetNameEn: 'Sword of Allah',
    descriptionAr: 'معركة بزاخة، حادثة مالك بن نويرة، ومعركة اليمامة الكبرى مع مسيلمة الكذاب وحديقة الموت.',
    descriptionEn: 'The Ridda Wars and the decisive Battle of Yamama.',
    category: AnimeCategory.khalid,
    videoUrl: 'https://www.youtube.com/watch?v=HcKyCh7nEzo',
    durationOrEpisodes: 'خاتمة ملحمية',
    isFeatured: true,
    tag: 'حروب الردة',
  ),

  // --- 2. سلسلة قصص القرآن وعِبر الأنبياء والأمم السابقة ---
  AnimeProphetStory(
    id: 'quran-story-aad',
    seriesId: 'series-quran-lessons',
    seriesTitleAr: 'سلسلة قصص القرآن وعِبر الأنبياء والأمم السابقة (أنمي)',
    seriesTitleEn: 'Quran Stories & Ancient Nations Series',
    episodeNumber: 1,
    displayOrder: 1,
    seriesOrder: 2,
    episodeTitleAr: 'الحلقة ١',
    titleAr: 'عمالقة الأرض ومصانع الخلود | قصة قوم عاد ونبي الله هود كاملة (أنمي)',
    titleEn: 'Giants of the Earth: Story of the People of \'Ad & Prophet Hud',
    prophetNameAr: 'سيدنا هود عليه السلام',
    prophetNameEn: 'Prophet Hud (AS)',
    descriptionAr: 'قصة قوم عاد وإرم ذات العماد التي لم يُخلق مثلها في البلاد، وعتوهم وتكذيبهم لنبي الله هود والريح الصرصر.',
    descriptionEn: 'The epic story of Iram of the Pillars and Prophet Hud.',
    category: AnimeCategory.quranSeries,
    videoUrl: 'https://www.youtube.com/watch?v=ls3DBA4kt7Y',
    durationOrEpisodes: 'حلقة كاملة',
    isFeatured: true,
    tag: 'قوم عاد',
  ),
  AnimeProphetStory(
    id: 'quran-story-ukhrood',
    seriesId: 'series-quran-lessons',
    seriesTitleAr: 'سلسلة قصص القرآن وعِبر الأنبياء والأمم السابقة (أنمي)',
    seriesTitleEn: 'Quran Stories & Ancient Nations Series',
    episodeNumber: 2,
    displayOrder: 2,
    seriesOrder: 2,
    episodeTitleAr: 'الحلقة ٢',
    titleAr: 'طفل ضعيف هزم ملكاً جباراً يدّعي الألوهية | قصة أصحاب الأخدود (أنمي)',
    titleEn: 'Story of the Boy & The Trench (Ashab Al-Ukhdood)',
    prophetNameAr: 'الغلام والراهب الصالح',
    prophetNameEn: 'The Believing Boy',
    descriptionAr: 'قصة الغلام المؤمن، والساحر، والراهب، وثبات المؤمنين على دينهم داخل الأخدود المشهود.',
    descriptionEn: 'The miraculous endurance of the boy and believers in the trench.',
    category: AnimeCategory.quranSeries,
    videoUrl: 'https://www.youtube.com/watch?v=4QPczxhd_M8',
    durationOrEpisodes: 'حلقة مؤثرة',
    isFeatured: true,
    tag: 'أصحاب الأخدود',
  ),
  AnimeProphetStory(
    id: 'quran-story-nimrud',
    seriesId: 'series-quran-lessons',
    seriesTitleAr: 'سلسلة قصص القرآن وعِبر الأنبياء والأمم السابقة (أنمي)',
    seriesTitleEn: 'Quran Stories & Ancient Nations Series',
    episodeNumber: 3,
    displayOrder: 3,
    seriesOrder: 2,
    episodeTitleAr: 'الحلقة ٣',
    titleAr: 'أول من ادّعى الألوهية في التاريخ | قصة النمرود كاملة (أنمي)',
    titleEn: 'The First to Claim Divinity: Full Story of Nimrod (Anime)',
    prophetNameAr: 'سيدنا إبراهيم والنمرود',
    prophetNameEn: 'Prophet Ibrahim & Nimrod',
    descriptionAr: 'قصة النمرود الجبار الذي ادّعى الألوهية ومنازلته لنبي الله إبراهيم عليه السلام، والنار التي قيل لها: كوني برداً وسلاماً.',
    descriptionEn: 'The tyrant Nimrod who claimed divinity and his confrontation with Prophet Ibrahim (AS).',
    category: AnimeCategory.quranSeries,
    videoUrl: 'https://www.youtube.com/watch?v=eXgCGopLwGs',
    durationOrEpisodes: 'حلقة كاملة',
    tag: 'قصة النمرود',
  ),
  AnimeProphetStory(
    id: 'battle-fights',
    seriesId: 'series-quran-lessons',
    seriesTitleAr: 'سلسلة قصص القرآن وعِبر الأنبياء والأمم السابقة (أنمي)',
    seriesTitleEn: 'Quran Stories & Ancient Nations Series',
    episodeNumber: 4,
    displayOrder: 4,
    seriesOrder: 2,
    episodeTitleAr: 'الحلقة ٤',
    titleAr: 'أقوى القتالات في التاريخ الإسلامي 🔥 نزالات فردية أرعبت جيوشاً كاملة',
    titleEn: 'Greatest Duels in Islamic History: Lone Warriors Who Struck Fear',
    prophetNameAr: 'فرسان الإسلام',
    prophetNameEn: 'Warriors of Islam',
    descriptionAr: 'استعراض سينمائي بالأنمي لأقوى المبارزات الحقيقية لفرسان المسلمين في القادسية، اليرموك، والفتوحات.',
    descriptionEn: 'Cinematic anime display of the most courageous single duels in Islamic battles.',
    category: AnimeCategory.quranSeries,
    videoUrl: 'https://www.youtube.com/watch?v=znhlt5gzCJQ',
    durationOrEpisodes: 'حلقة ملحمية',
    tag: 'فرسان الإسلام',
  ),

  // --- 3. (محذوفة) سلسلة بطولات وفرسان التاريخ الإسلامي — أُزيلت بالكامل
  // وبقيت منها حلقة «أقوى القتالات» ضمن سلسلة قصص القرآن (رقم ٤)
];

/// تجميع القصص حسب السلاسل الكرتونية المتتابعة
List<AnimeSeriesGroup> get animeSeriesGroups {
  return [
    AnimeSeriesGroup(
      id: 'series-khalid',
      titleAr: 'سلسلة ملحمة سيف الله المسلول خالد بن الوليد (أنمي)',
      titleEn: 'Khalid Ibn Al-Walid Anime Epic Series',
      descriptionAr: 'الملحمة الكرتونية الأبرز: من نشأة خالد، إلى غزوة مؤتة، كمين حنين، وملاحم حروب الردة.',
      descriptionEn: 'The four chapters of the military genius and sword of Allah Khalid Ibn Al-Walid.',
      badge: '٤ فصول كاملة',
      category: AnimeCategory.khalid,
      episodes: animatedProphetStories
          .where((s) => s.seriesId == 'series-khalid')
          .toList(),
    ),
    AnimeSeriesGroup(
      id: 'series-quran-lessons',
      titleAr: 'سلسلة قصص القرآن وعِبر الأنبياء والأمم السابقة (أنمي)',
      titleEn: 'Quran Stories & Ancient Nations Series',
      descriptionAr: 'حكايات العظات الكبرى: قصة قوم عاد وهود، أصحاب الأخدود، وقصة النمرود في سرد أنميشن شيق.',
      descriptionEn: 'Inspiring accounts of Prophet Hud, the people of \'Ad, the boy of the trench, and the story of Nimrod.',
      badge: '٤ حلقات كبرى',
      category: AnimeCategory.quranSeries,
      episodes: animatedProphetStories
          .where((s) => s.seriesId == 'series-quran-lessons')
          .toList(),
    ),
  ];
}