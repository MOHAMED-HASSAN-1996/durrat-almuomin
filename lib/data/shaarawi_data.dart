/// بيانات دروس الشيخ محمد متولي الشعراوي منظمة ومبوبة ومأخوذة مباشرة من القناة الرسمية.
library;

/// معرّف القناة الرسمية للشيخ الشعراوي (@alsharawiofficial).
const String shaarawiChannelId = 'UCijSEIUA72pyzSNOf_lx5ng';

/// رابط القناة للعرض/open خارجيًا.
const String shaarawiChannelUrl = 'https://www.youtube.com/@alsharawiofficial';

/// تصنيفات دروس الشيخ الشعراوي
enum ShaarawiCategory {
  all,
  tafsir,
  faith,
  life,
  seerah,
  gems,
}

extension ShaarawiCategoryExtension on ShaarawiCategory {
  String get titleAr {
    switch (this) {
      case ShaarawiCategory.all:
        return 'الكل';
      case ShaarawiCategory.tafsir:
        return 'تفسير القرآن الكريم';
      case ShaarawiCategory.faith:
        return 'العقيدة والإيمان';
      case ShaarawiCategory.life:
        return 'قضايا الحياة والرزق';
      case ShaarawiCategory.seerah:
        return 'السيرة والمناسبات';
      case ShaarawiCategory.gems:
        return 'روائع وخواطر قصيرة';
    }
  }

  String get titleEn {
    switch (this) {
      case ShaarawiCategory.all:
        return 'All';
      case ShaarawiCategory.tafsir:
        return 'Quran Tafsir';
      case ShaarawiCategory.faith:
        return 'Faith & Creed';
      case ShaarawiCategory.life:
        return 'Life & Sustenance';
      case ShaarawiCategory.seerah:
        return 'Seerah & Occasions';
      case ShaarawiCategory.gems:
        return 'Short Gems';
    }
  }
}

/// نموذج درس من دروس الشيخ الشعراوي
class ShaarawiLesson {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final ShaarawiCategory category;
  final String videoUrl;
  final String duration;
  final String? customThumbnail;
  final bool isFeatured;
  final String? badge;

  // هيكلة السلاسل والأجزاء
  final String? seriesId;
  final String? seriesTitleAr;
  final String? seriesTitleEn;
  final int? partNumber;
  final String? partTitleAr;

  const ShaarawiLesson({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.category,
    required this.videoUrl,
    required this.duration,
    this.customThumbnail,
    this.isFeatured = false,
    this.badge,
    this.seriesId,
    this.seriesTitleAr,
    this.seriesTitleEn,
    this.partNumber,
    this.partTitleAr,
  });

  /// استخراج الصورة المصغرة الحقيقية من يوتيوب
  String get thumbnailUrl {
    if (customThumbnail != null && customThumbnail!.isNotEmpty) {
      return customThumbnail!;
    }
    final uri = Uri.tryParse(videoUrl);
    if (uri != null) {
      if (uri.pathSegments.contains('watch')) {
        final v = uri.queryParameters['v'];
        if (v != null && v.isNotEmpty) {
          return 'https://i.ytimg.com/vi/$v/hqdefault.jpg';
        }
      } else if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        return 'https://i.ytimg.com/vi/${uri.pathSegments.first}/hqdefault.jpg';
      }
    }
    return 'https://i.ytimg.com/vi/placeholder/hqdefault.jpg';
  }
}

/// مجموعة سلسلة تحتوي على دروس وأجزاء مرتبطة
class ShaarawiSeriesGroup {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String badge;
  final ShaarawiCategory category;
  final List<ShaarawiLesson> episodes;

  const ShaarawiSeriesGroup({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.badge,
    required this.category,
    required this.episodes,
  });

  int get totalParts => episodes.length;
}

/// قائمة دروس الشيخ الشعراوي الحقيقية من قناته الرسمية (@alsharawiofficial)
const List<ShaarawiLesson> organizedShaarawiLessons = [
  // --- 1. سلسلة قصة سيدنا آدم وبداية الخلق ---
  ShaarawiLesson(
    id: 'shaarawi-adam-1',
    seriesId: 'series-adam-creation',
    seriesTitleAr: 'سلسلة قصة سيدنا آدم وبداية الخلق',
    seriesTitleEn: 'Prophet Adam & The Creation Series',
    partNumber: 1,
    partTitleAr: 'الجزء الأول',
    titleAr: 'قصة سيدنا آدم عليه السلام وبداية الخلق وكيف كانت الأرض قبل نزوله',
    titleEn: 'Story of Prophet Adam (AS) & The Beginning of Creation',
    descriptionAr: 'بيان عميق من فضيلة الشيخ الشعراوي حول بدء خلق أبي البشر، وحال الأرض، وسجود الملائكة وحكمة الاستخلاف.',
    descriptionEn: 'The beginning of human creation and the purpose of existence by Sheikh El-Shaarawi.',
    category: ShaarawiCategory.faith,
    videoUrl: 'https://www.youtube.com/watch?v=i9s53HR2f9U',
    duration: '48 دقيقة',
    isFeatured: true,
    badge: 'بداية الخلق',
  ),
  ShaarawiLesson(
    id: 'shaarawi-adam-2',
    seriesId: 'series-adam-creation',
    seriesTitleAr: 'سلسلة قصة سيدنا آدم وبداية الخلق',
    seriesTitleEn: 'Prophet Adam & The Creation Series',
    partNumber: 2,
    partTitleAr: 'الجزء الثاني',
    titleAr: 'قصة قابيل وهابيل وأول جريمة في تاريخ البشرية ووفاة آدم عليه السلام',
    titleEn: 'Story of Cain & Abel and The First Crime',
    descriptionAr: 'خواطر إيمانية مؤثرة في قصة ابني آدم، دوافع الحسد والعدوان، وكيف علّم الله الإنسان بالغراب ووداع نبي الله آدم.',
    descriptionEn: 'The story of Cain and Abel, lessons on envy and repentance.',
    category: ShaarawiCategory.faith,
    videoUrl: 'https://www.youtube.com/watch?v=nA69tZ6eqYk',
    duration: '42 دقيقة',
    badge: 'أول جريمة',
  ),
  ShaarawiLesson(
    id: 'shaarawi-khalifah',
    seriesId: 'series-adam-creation',
    seriesTitleAr: 'سلسلة قصة سيدنا آدم وبداية الخلق',
    seriesTitleEn: 'Prophet Adam & The Creation Series',
    partNumber: 3,
    partTitleAr: 'الجزء الثالث',
    titleAr: 'تفسير: { وَإِذْ قَالَ رَبُّكَ لِلْمَلَائِكَةِ إِنِّي جَاعِلٌ فِي الْأَرْضِ خَلِيفَةً }',
    titleEn: 'Tafsir: Indeed, I will make upon the earth a successive authority',
    descriptionAr: 'تفسير بلاغي وإيماني بديع لسر استخلاف الإنسان في الأرض وتكريمه بالعلم وعمارة الكون.',
    descriptionEn: 'Profound interpretation of man\'s mission as a steward on earth.',
    category: ShaarawiCategory.tafsir,
    videoUrl: 'https://www.youtube.com/watch?v=z3Ad1ixs6Zk',
    duration: '39 دقيقة',
    badge: 'خلافة الأرض',
  ),

  // --- 2. سلسلة قصة سيدنا نوح عليه السلام والفلك ---
  ShaarawiLesson(
    id: 'shaarawi-nuh-1',
    seriesId: 'series-nuh-story',
    seriesTitleAr: 'سلسلة قصة سيدنا نوح والفلك والطوفان',
    seriesTitleEn: 'Prophet Nuh & The Ark Series',
    partNumber: 1,
    partTitleAr: 'الجزء الأول',
    titleAr: 'قصة نوح عليه السلام وأولاده الثلاثة سام وحام ويافث — الجزء الأول',
    titleEn: 'Story of Prophet Nuh (AS) & His Three Sons — Part 1',
    descriptionAr: 'صبر شيخ المرسلين نوح عليه السلام، بناء السفينة بأمر الله، ونداء الابن العاصي وأسرار ذرية البشرية.',
    descriptionEn: 'The struggle of Prophet Nuh and the divine command to build the Ark.',
    category: ShaarawiCategory.faith,
    videoUrl: 'https://www.youtube.com/watch?v=_uaVY2FBdIA',
    duration: '36 دقيقة',
    isFeatured: true,
    badge: 'شيخ المرسلين',
  ),
  ShaarawiLesson(
    id: 'shaarawi-nuh-2',
    seriesId: 'series-nuh-story',
    seriesTitleAr: 'سلسلة قصة سيدنا نوح والفلك والطوفان',
    seriesTitleEn: 'Prophet Nuh & The Ark Series',
    partNumber: 2,
    partTitleAr: 'الجزء الثاني',
    titleAr: 'قصة نوح عليه السلام وأولاده الثلاثة سام وحام ويافث — الجزء الثاني',
    titleEn: 'Story of Prophet Nuh (AS) & His Three Sons — Part 2',
    descriptionAr: 'استقرار الفلك على الجودي، نجاة المؤمنين، وتوزيع الأمم والشعوب بعد الطوفان العظيم.',
    descriptionEn: 'The Ark settling on Mount Judi and the emergence of nations after the deluge.',
    category: ShaarawiCategory.faith,
    videoUrl: 'https://www.youtube.com/watch?v=uORrgAMG3jM',
    duration: '38 دقيقة',
    badge: 'سفينة النجاة',
  ),

  // --- 3. سلسلة مولد النبي ﷺ من الظلمات إلى النور ---
  ShaarawiLesson(
    id: 'shaarawi-seerah-1',
    seriesId: 'series-prophet-birth',
    seriesTitleAr: 'سلسلة مولد النبي ﷺ: من الظلمات إلى النور',
    seriesTitleEn: 'Birth of Prophet Muhammad ﷺ Series',
    partNumber: 1,
    partTitleAr: 'الجزء الأول',
    titleAr: 'مولد النبي ﷺ | من الظلمات إلى النور، رسائل من حياة خير الأنام (١)',
    titleEn: 'Birth of the Prophet ﷺ: Messages from the Best of Creation (1)',
    descriptionAr: 'خواطر الشيخ الشعراوي في بشائر المولد النبوي الشريف وكيف أشرقت شمس الهداية على العالم بأسره.',
    descriptionEn: 'The radiant dawn of the Prophetic birth and illumination of humanity.',
    category: ShaarawiCategory.seerah,
    videoUrl: 'https://www.youtube.com/watch?v=WF9iq86xFEU',
    duration: '45 دقيقة',
    isFeatured: true,
    badge: 'مولد النور',
  ),
  ShaarawiLesson(
    id: 'shaarawi-seerah-2',
    seriesId: 'series-prophet-birth',
    seriesTitleAr: 'سلسلة مولد النبي ﷺ: من الظلمات إلى النور',
    seriesTitleEn: 'Birth of Prophet Muhammad ﷺ Series',
    partNumber: 2,
    partTitleAr: 'الجزء الثاني',
    titleAr: 'مولد النبي ﷺ | من الظلمات إلى النور، رسائل من حياة خير الأنام (٢)',
    titleEn: 'Birth of the Prophet ﷺ: Messages from the Best of Creation (2)',
    descriptionAr: 'نشأة النبي يتيماً، حفظ الله له من الجاهلية، وشمائله وأخلاقه التي شهد له بها العدو قبل الصديق.',
    descriptionEn: 'Prophetic upbringing, moral purity, and Divine protection.',
    category: ShaarawiCategory.seerah,
    videoUrl: 'https://www.youtube.com/watch?v=1Z8bUJHUZ7k',
    duration: '41 دقيقة',
    badge: 'خُلق عظيم',
  ),
  ShaarawiLesson(
    id: 'shaarawi-seerah-3',
    seriesId: 'series-prophet-birth',
    seriesTitleAr: 'سلسلة مولد النبي ﷺ: من الظلمات إلى النور',
    seriesTitleEn: 'Birth of Prophet Muhammad ﷺ Series',
    partNumber: 3,
    partTitleAr: 'الجزء الثالث',
    titleAr: 'مولد النبي ﷺ | من الظلمات إلى النور، رسائل من حياة خير الأنام (٣)',
    titleEn: 'Birth of the Prophet ﷺ: Messages from the Best of Creation (3)',
    descriptionAr: 'نزول الوحي في غار حراء، بدء الدعوة الإسلامية، والثبات على الحق رغم الشدائد.',
    descriptionEn: 'The revelation in Cave Hira and steadfastness in spreading the message.',
    category: ShaarawiCategory.seerah,
    videoUrl: 'https://www.youtube.com/watch?v=87PxoS-SSik',
    duration: '44 دقيقة',
    badge: 'نزول الوحي',
  ),
  ShaarawiLesson(
    id: 'shaarawi-seerah-4',
    seriesId: 'series-prophet-birth',
    seriesTitleAr: 'سلسلة مولد النبي ﷺ: من الظلمات إلى النور',
    seriesTitleEn: 'Birth of Prophet Muhammad ﷺ Series',
    partNumber: 4,
    partTitleAr: 'الجزء الرابع',
    titleAr: 'مولد النبي ﷺ | من الظلمات إلى النور، رسائل من حياة خير الأنام (٤)',
    titleEn: 'Birth of the Prophet ﷺ: Messages from the Best of Creation (4)',
    descriptionAr: 'معالم الرحمة المهداة في تعامل النبي مع أصحابه وأهله، ووصاياه الخالدة لأمته.',
    descriptionEn: 'The mercy of Prophet Muhammad ﷺ and his everlasting counsel.',
    category: ShaarawiCategory.seerah,
    videoUrl: 'https://www.youtube.com/watch?v=pzM49q8lPyI',
    duration: '39 دقيقة',
    badge: 'رحمة للعالمين',
  ),

  // --- 4. سلسلة روائع التفسير وأسرار الآيات ---
  ShaarawiLesson(
    id: 'shaarawi-kahf',
    seriesId: 'series-quran-secrets',
    seriesTitleAr: 'سلسلة روائع التفسير وأسرار الآيات',
    seriesTitleEn: 'Quranic Secrets & Tafsir Series',
    partNumber: 1,
    partTitleAr: 'الجزء الأول',
    titleAr: 'قصة أصحاب الكهف، وما سبب اختفائهم وموتهم بعد اكتشاف كهفهم',
    titleEn: 'Story of the Companions of the Cave & Secret of Their Passing',
    descriptionAr: 'تحليل دقيق ومؤثر لفتية الكهف، سر نومهم ثلاثمائة سنين، وحكمة وفاتهم بعد بعثهم.',
    descriptionEn: 'Profound explanation of Surah Al-Kahf and the wisdom behind their sleep.',
    category: ShaarawiCategory.tafsir,
    videoUrl: 'https://www.youtube.com/watch?v=Vqp41fkS-Lc',
    duration: '50 دقيقة',
    isFeatured: true,
    badge: 'سورة الكهف',
  ),
  ShaarawiLesson(
    id: 'shaarawi-najm',
    seriesId: 'series-quran-secrets',
    seriesTitleAr: 'سلسلة روائع التفسير وأسرار الآيات',
    seriesTitleEn: 'Quranic Secrets & Tafsir Series',
    partNumber: 2,
    partTitleAr: 'الجزء الثاني',
    titleAr: 'تفسير: { وَالنَّجْمِ إِذَا هَوَىٰ * مَا ضَلَّ صَاحِبُكُمْ وَمَا غَوَىٰ }',
    titleEn: 'Tafsir: By the star when it descends, Your companion has not strayed',
    descriptionAr: 'إعجاز بياني فريد في بلاغة سورة النجم وإثبات صدق نبوة المصطفى ورؤيته لجبريل في الملأ الأعلى.',
    descriptionEn: 'Linguistic and spiritual miracles in Surah An-Najm.',
    category: ShaarawiCategory.tafsir,
    videoUrl: 'https://www.youtube.com/watch?v=obSe0B4QJ6Y',
    duration: '35 دقيقة',
    badge: 'سورة النجم',
  ),
  ShaarawiLesson(
    id: 'shaarawi-nur',
    seriesId: 'series-quran-secrets',
    seriesTitleAr: 'سلسلة روائع التفسير وأسرار الآيات',
    seriesTitleEn: 'Quranic Secrets & Tafsir Series',
    partNumber: 3,
    partTitleAr: 'الجزء الثالث',
    titleAr: 'تفسير سورة النور وأحكام العفة وطهارة المجتمع الإسلامي',
    titleEn: 'Tafsir Surah An-Nur: Social Purity & Chastity',
    descriptionAr: 'تشريعات حفظ الأسرة والمجتمع وحكمة الحدود وتطهير القلوب في ضوء كتاب الله.',
    descriptionEn: 'Islamic social ethics and family protection in Surah An-Nur.',
    category: ShaarawiCategory.tafsir,
    videoUrl: 'https://www.youtube.com/watch?v=WwXH8sx5upg',
    duration: '37 دقيقة',
    badge: 'سورة النور',
  ),

  // --- 5. سلسلة الفرج وطمأنينة القلب والروح ---
  ShaarawiLesson(
    id: 'shaarawi-faraj-1',
    seriesId: 'series-faraj-hope',
    seriesTitleAr: 'سلسلة الفرج وطمأنينة القلب والروح',
    seriesTitleEn: 'Relief & Inner Tranquility Series',
    partNumber: 1,
    partTitleAr: 'الجزء الأول',
    titleAr: 'هكذا تنتقل برحمة الله من لحظات اليأس إلى بداية الفرج الكبير',
    titleEn: 'Moving with Allah\'s Mercy from Despair to Great Relief',
    descriptionAr: 'بلسم شافٍ لكل صاحب همّ أو ابتلاء، وكيف يُحدث الله بعد عسرٍ يسراً فوق ما تتخيل.',
    descriptionEn: 'Uplifting sermon explaining how relief comes right after darkness.',
    category: ShaarawiCategory.life,
    videoUrl: 'https://www.youtube.com/watch?v=PQ55rSUzmGo',
    duration: '31 دقيقة',
    isFeatured: true,
    badge: 'الفرج الكبير',
  ),
  ShaarawiLesson(
    id: 'shaarawi-faraj-2',
    seriesId: 'series-faraj-hope',
    seriesTitleAr: 'سلسلة الفرج وطمأنينة القلب والروح',
    seriesTitleEn: 'Relief & Inner Tranquility Series',
    partNumber: 2,
    partTitleAr: 'الجزء الثاني',
    titleAr: 'حسن الظن بالله ولذة الرضا بقضاء الله وقدره',
    titleEn: 'Good Expectation of Allah & Contentment',
    descriptionAr: 'أسرار السكينة النفسية والتسليم لحكمة الخالق مهما بدت الظروف قاسية.',
    descriptionEn: 'The secret of true peace and contentment with Allah\'s divine plan.',
    category: ShaarawiCategory.life,
    videoUrl: 'https://www.youtube.com/watch?v=OmqkX9fpzfs',
    duration: '33 دقيقة',
    badge: 'سكينة النفس',
  ),
  ShaarawiLesson(
    id: 'shaarawi-gem-relief',
    seriesId: 'series-faraj-hope',
    seriesTitleAr: 'سلسلة الفرج وطمأنينة القلب والروح',
    seriesTitleEn: 'Relief & Inner Tranquility Series',
    partNumber: 3,
    partTitleAr: 'الجزء الثالث',
    titleAr: 'خاطرة نادرة: مفتاح انشراح الصدر وزوال الهموم',
    titleEn: 'Rare Gem: Key to Peace of Mind',
    descriptionAr: 'درّة موجزة تريح القلب وتبعث الطمأنينة في ثوانٍ معدودة.',
    descriptionEn: 'Brief comforting reflection bringing immediate peace.',
    category: ShaarawiCategory.gems,
    videoUrl: 'https://www.youtube.com/watch?v=PQ55rSUzmGo',
    duration: '12 دقيقة',
    badge: 'خاطرة نادرة',
  ),
];

/// تجميع الدروس حسب السلاسل المترابطة
List<ShaarawiSeriesGroup> get shaarawiSeriesGroups {
  return [
    ShaarawiSeriesGroup(
      id: 'series-adam-creation',
      titleAr: 'سلسلة قصة سيدنا آدم وبداية الخلق',
      titleEn: 'Prophet Adam & The Creation Series',
      descriptionAr: 'من بدء خلق آدم، وسجود الملائكة، إلى قابيل وهابيل وحكمة استخلاف الإنسان في الأرض.',
      descriptionEn: 'Creation of Adam, story of Cain and Abel, and the divine purpose of mankind.',
      badge: '٣ أجزاء',
      category: ShaarawiCategory.faith,
      episodes: organizedShaarawiLessons
          .where((l) => l.seriesId == 'series-adam-creation')
          .toList(),
    ),
    ShaarawiSeriesGroup(
      id: 'series-nuh-story',
      titleAr: 'سلسلة قصة سيدنا نوح والفلك والطوفان',
      titleEn: 'Prophet Nuh & The Ark Series',
      descriptionAr: 'صبر نوح عليه السلام، بناء الفلك، نداء الابن، ونجاة ذرية المؤمنين بعد الطوفان.',
      descriptionEn: 'Prophet Nuh, building the Ark, survival of believers, and his three sons.',
      badge: 'جزآن كاملان',
      category: ShaarawiCategory.faith,
      episodes: organizedShaarawiLessons
          .where((l) => l.seriesId == 'series-nuh-story')
          .toList(),
    ),
    ShaarawiSeriesGroup(
      id: 'series-prophet-birth',
      titleAr: 'سلسلة مولد النبي ﷺ: من الظلمات إلى النور',
      titleEn: 'Birth of Prophet Muhammad ﷺ Series',
      descriptionAr: 'الموسوعة الكبرى في شمائل ومولد خاتم الأنبياء ﷺ من المولد الشريف إلى نزول الوحي.',
      descriptionEn: 'Comprehensive series on the life, birth, and message of Prophet Muhammad ﷺ.',
      badge: '٤ أجزاء',
      category: ShaarawiCategory.seerah,
      episodes: organizedShaarawiLessons
          .where((l) => l.seriesId == 'series-prophet-birth')
          .toList(),
    ),
    ShaarawiSeriesGroup(
      id: 'series-quran-secrets',
      titleAr: 'سلسلة روائع التفسير وأسرار الآيات',
      titleEn: 'Quranic Secrets & Tafsir Series',
      descriptionAr: 'خواطر الشيخ في قصة أصحاب الكهف، وتفسير سورة النجم، وسورة النور.',
      descriptionEn: 'Reflections on Surah Al-Kahf, Surah An-Najm, and Surah An-Nur.',
      badge: '٣ أجزاء',
      category: ShaarawiCategory.tafsir,
      episodes: organizedShaarawiLessons
          .where((l) => l.seriesId == 'series-quran-secrets')
          .toList(),
    ),
    ShaarawiSeriesGroup(
      id: 'series-faraj-hope',
      titleAr: 'سلسلة الفرج وطمأنينة القلب والروح',
      titleEn: 'Relief & Inner Tranquility Series',
      descriptionAr: 'دروس الأمل والانتقال برحمة الله من اليأس إلى الفرج وسكينة الرضا بقضاء الله.',
      descriptionEn: 'Spiritual lessons on overcoming despair, finding solace, and trusting divine destiny.',
      badge: '٣ أجزاء',
      category: ShaarawiCategory.life,
      episodes: organizedShaarawiLessons
          .where((l) => l.seriesId == 'series-faraj-hope')
          .toList(),
    ),
  ];
}

/// سلاسل وقوائم تشغيل كبرى لدروس الشيخ الشعراوي
class ShaarawiPlaylist {
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String playlistUrl;
  final String episodesCount;

  const ShaarawiPlaylist({
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.playlistUrl,
    required this.episodesCount,
  });
}

const List<ShaarawiPlaylist> shaarawiPlaylists = [
  ShaarawiPlaylist(
    titleAr: 'تفسير القرآن الكريم كاملاً — خواطر الشعراوي',
    titleEn: 'Complete Quran Tafsir Series',
    subtitleAr: 'السلسلة الموسوعية الكاملة لتفسير كتاب الله من الفاتحة إلى الناس',
    subtitleEn: 'The encyclopedic series of Quran interpretation from start to finish',
    playlistUrl: 'https://www.youtube.com/playlist?list=PLEKtuRowisPO3Xo2591jbM-VEjwTUq8Ea',
    episodesCount: 'سلسلة شاملة',
  ),
  ShaarawiPlaylist(
    titleAr: 'سلسلة خواطر إيمانية وقضايا العصر',
    titleEn: 'Faith Thoughts & Contemporary Issues',
    subtitleAr: 'دروس ومحاضرات جامعة في الأخلاق، السلوك، والمعاملات الإسلامية',
    subtitleEn: 'Lectures on morals, ethics, and contemporary Islamic matters',
    playlistUrl: 'https://www.youtube.com/playlist?list=PL_t0u9KqG1l3m2B_Vz7zZ8Q0eG9R6_qW7',
    episodesCount: 'أكثر من 50 درسًا',
  ),
  ShaarawiPlaylist(
    titleAr: 'روائع التلاوة والابتهالات في رحاب الشيخ',
    titleEn: 'Quran Recitations & Invocations',
    subtitleAr: 'مقاطع وابتهالات وتأملات قرآنية بصوت الشيخ الشعراوي',
    subtitleEn: 'Supplications and Quranic reflections with the Sheikh',
    playlistUrl: 'https://www.youtube.com/playlist?list=PL_7zB4G1uQ3mP8V0L6yX7wZ9_qK4v2M5',
    episodesCount: 'مختارات نادرة',
  ),
];