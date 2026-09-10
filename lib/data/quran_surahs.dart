/// Metadata for all 114 Surahs of the Holy Quran.
class QuranSurahMeta {
  const QuranSurahMeta({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
    required this.page,
  });

  final int number;
  final String name;
  final String englishName;
  final String englishTranslation;
  final int numberOfAyahs;
  final String revelationType; // 'Meccan' or 'Medinan'
  final int page;

  bool get isMeccan => revelationType == 'Meccan';
  String get typeAr => isMeccan ? 'مكية' : 'مدنية';
}

/// Given a page number (1..604), returns the primary Surah on that page.
QuranSurahMeta getSurahForPage(int page) {
  for (int i = quranSurahs.length - 1; i >= 0; i--) {
    if (quranSurahs[i].page <= page) {
      return quranSurahs[i];
    }
  }
  return quranSurahs.first;
}

/// Given a page number (1..604), returns the Juz number (1..30).
int getJuzForPage(int page) {
  if (page <= 1) return 1;
  final juz = ((page - 2) ~/ 20) + 1;
  return juz.clamp(1, 30);
}

/// Given a Juz number (1..30), returns its Arabic name.
String getJuzNameAr(int juz) {
  const juzNames = [
    'الجزء الأول',
    'الجزء الثاني',
    'الجزء الثالث',
    'الجزء الرابع',
    'الجزء الخامس',
    'الجزء السادس',
    'الجزء السابع',
    'الجزء الثامن',
    'الجزء التاسع',
    'الجزء العاشر',
    'الجزء الحادي عشر',
    'الجزء الثاني عشر',
    'الجزء الثالث عشر',
    'الجزء الرابع عشر',
    'الجزء الخامس عشر',
    'الجزء السادس عشر',
    'الجزء السابع عشر',
    'الجزء الثامن عشر',
    'الجزء التاسع عشر',
    'الجزء العشرون',
    'الجزء الحادي والعشرون',
    'الجزء الثاني والعشرون',
    'الجزء الثالث والعشرون',
    'الجزء الرابع والعشرون',
    'الجزء الخامس والعشرون',
    'الجزء السادس والعشرون',
    'الجزء السابع والعشرون',
    'الجزء الثامن والعشرون',
    'الجزء التاسع والعشرون',
    'الجزء الثلاثون',
  ];
  if (juz >= 1 && juz <= 30) return juzNames[juz - 1];
  return 'الجزء $juz';
}

/// Constructs the high-definition Medina Mushaf page image URL
/// from the official Quran.com images repository (quran/quran.com-images / files.quran.app)
/// (طبعة مجمع الملك فهد لطباعة المصحف الشريف 1920x3106 المعتمدة في Quran.com)
/// with multi-tier CDN and fallback support.
String getMadaniMushafPageUrl(int page, {int fallbackIndex = 0}) {
  final p = page.clamp(1, 604);
  final padded = p.toString().padLeft(3, '0');

  switch (fallbackIndex) {
    case 1:
      // Secondary: Quran.com Android data gateway
      return 'https://android.quran.com/data/width_1920/page$padded.png';
    case 2:
      // Alternative resolution: Quran.com 1260px width
      return 'https://files.quran.app/hafs/madani/width_1260/page$padded.png';
    case 3:
      // Fallback: King Fahd Quran Complex via jsDelivr CDN
      return 'https://cdn.jsdelivr.net/gh/QuranHub/quran-pages-images@main/kfgqpc/hafs-wasat/$p.jpg';
    case 0:
    default:
      // Primary: Official Quran.com / Quran Android Ultra-HD (1920x3106) transparent Madani Mushaf
      return 'https://files.quran.app/hafs/madani/width_1920/page$padded.png';
  }
}

const List<QuranSurahMeta> quranSurahs = [
  QuranSurahMeta(number: 1, name: 'الفَاتِحَة', englishName: 'Al-Fatihah', englishTranslation: 'The Opening', numberOfAyahs: 7, revelationType: 'Meccan', page: 1),
  QuranSurahMeta(number: 2, name: 'البَقَرَة', englishName: 'Al-Baqarah', englishTranslation: 'The Cow', numberOfAyahs: 286, revelationType: 'Medinan', page: 2),
  QuranSurahMeta(number: 3, name: 'آل عِمرَان', englishName: 'Ali \'Imran', englishTranslation: 'Family of Imran', numberOfAyahs: 200, revelationType: 'Medinan', page: 50),
  QuranSurahMeta(number: 4, name: 'النِّسَاء', englishName: 'An-Nisa', englishTranslation: 'The Women', numberOfAyahs: 176, revelationType: 'Medinan', page: 77),
  QuranSurahMeta(number: 5, name: 'المَائِدَة', englishName: 'Al-Ma\'idah', englishTranslation: 'The Table Spread', numberOfAyahs: 120, revelationType: 'Medinan', page: 106),
  QuranSurahMeta(number: 6, name: 'الأنعَام', englishName: 'Al-An\'am', englishTranslation: 'The Cattle', numberOfAyahs: 165, revelationType: 'Meccan', page: 128),
  QuranSurahMeta(number: 7, name: 'الأعرَاف', englishName: 'Al-A\'raf', englishTranslation: 'The Heights', numberOfAyahs: 206, revelationType: 'Meccan', page: 151),
  QuranSurahMeta(number: 8, name: 'الأَنفَال', englishName: 'Al-Anfal', englishTranslation: 'The Spoils of War', numberOfAyahs: 75, revelationType: 'Medinan', page: 177),
  QuranSurahMeta(number: 9, name: 'التَّوبَة', englishName: 'At-Tawbah', englishTranslation: 'The Repentance', numberOfAyahs: 129, revelationType: 'Medinan', page: 187),
  QuranSurahMeta(number: 10, name: 'يُونُس', englishName: 'Yunus', englishTranslation: 'Jonah', numberOfAyahs: 109, revelationType: 'Meccan', page: 208),
  QuranSurahMeta(number: 11, name: 'هُود', englishName: 'Hud', englishTranslation: 'Hud', numberOfAyahs: 123, revelationType: 'Meccan', page: 221),
  QuranSurahMeta(number: 12, name: 'يُوسُف', englishName: 'Yusuf', englishTranslation: 'Joseph', numberOfAyahs: 111, revelationType: 'Meccan', page: 235),
  QuranSurahMeta(number: 13, name: 'الرَّعْد', englishName: 'Ar-Ra\'d', englishTranslation: 'The Thunder', numberOfAyahs: 43, revelationType: 'Medinan', page: 249),
  QuranSurahMeta(number: 14, name: 'إِبرَاهِيم', englishName: 'Ibrahim', englishTranslation: 'Abraham', numberOfAyahs: 52, revelationType: 'Meccan', page: 255),
  QuranSurahMeta(number: 15, name: 'الحِجْر', englishName: 'Al-Hijr', englishTranslation: 'The Rocky Tract', numberOfAyahs: 99, revelationType: 'Meccan', page: 262),
  QuranSurahMeta(number: 16, name: 'النَّحْل', englishName: 'An-Nahl', englishTranslation: 'The Bee', numberOfAyahs: 128, revelationType: 'Meccan', page: 267),
  QuranSurahMeta(number: 17, name: 'الإِسرَاء', englishName: 'Al-Isra', englishTranslation: 'The Night Journey', numberOfAyahs: 111, revelationType: 'Meccan', page: 282),
  QuranSurahMeta(number: 18, name: 'الكَهْف', englishName: 'Al-Kahf', englishTranslation: 'The Cave', numberOfAyahs: 110, revelationType: 'Meccan', page: 293),
  QuranSurahMeta(number: 19, name: 'مَريَم', englishName: 'Maryam', englishTranslation: 'Mary', numberOfAyahs: 98, revelationType: 'Meccan', page: 305),
  QuranSurahMeta(number: 20, name: 'طه', englishName: 'Taha', englishTranslation: 'Ta-Ha', numberOfAyahs: 135, revelationType: 'Meccan', page: 312),
  QuranSurahMeta(number: 21, name: 'الأَنبِيَاء', englishName: 'Al-Anbiya', englishTranslation: 'The Prophets', numberOfAyahs: 112, revelationType: 'Meccan', page: 322),
  QuranSurahMeta(number: 22, name: 'الحَجّ', englishName: 'Al-Hajj', englishTranslation: 'The Pilgrimage', numberOfAyahs: 78, revelationType: 'Medinan', page: 332),
  QuranSurahMeta(number: 23, name: 'المُؤمِنُون', englishName: 'Al-Mu\'minun', englishTranslation: 'The Believers', numberOfAyahs: 118, revelationType: 'Meccan', page: 342),
  QuranSurahMeta(number: 24, name: 'النُّور', englishName: 'An-Nur', englishTranslation: 'The Light', numberOfAyahs: 64, revelationType: 'Medinan', page: 350),
  QuranSurahMeta(number: 25, name: 'الفُرْقَان', englishName: 'Al-Furqan', englishTranslation: 'The Criterion', numberOfAyahs: 77, revelationType: 'Meccan', page: 359),
  QuranSurahMeta(number: 26, name: 'الشُّعَرَاء', englishName: 'Ash-Shu\'ara', englishTranslation: 'The Poets', numberOfAyahs: 227, revelationType: 'Meccan', page: 367),
  QuranSurahMeta(number: 27, name: 'النَّمْل', englishName: 'An-Naml', englishTranslation: 'The Ant', numberOfAyahs: 93, revelationType: 'Meccan', page: 377),
  QuranSurahMeta(number: 28, name: 'القَصَص', englishName: 'Al-Qasas', englishTranslation: 'The Stories', numberOfAyahs: 88, revelationType: 'Meccan', page: 385),
  QuranSurahMeta(number: 29, name: 'العَنكَبُوت', englishName: 'Al-\'Ankabut', englishTranslation: 'The Spider', numberOfAyahs: 69, revelationType: 'Meccan', page: 396),
  QuranSurahMeta(number: 30, name: 'الرُّوم', englishName: 'Ar-Rum', englishTranslation: 'The Romans', numberOfAyahs: 60, revelationType: 'Meccan', page: 404),
  QuranSurahMeta(number: 31, name: 'لُقمَان', englishName: 'Luqman', englishTranslation: 'Luqman', numberOfAyahs: 34, revelationType: 'Meccan', page: 411),
  QuranSurahMeta(number: 32, name: 'السَّجْدَة', englishName: 'As-Sajdah', englishTranslation: 'The Prostration', numberOfAyahs: 30, revelationType: 'Meccan', page: 415),
  QuranSurahMeta(number: 33, name: 'الأَحزَاب', englishName: 'Al-Ahzab', englishTranslation: 'The Combined Forces', numberOfAyahs: 73, revelationType: 'Medinan', page: 418),
  QuranSurahMeta(number: 34, name: 'سَبَأ', englishName: 'Saba', englishTranslation: 'Sheba', numberOfAyahs: 54, revelationType: 'Meccan', page: 428),
  QuranSurahMeta(number: 35, name: 'فَاطِر', englishName: 'Fatir', englishTranslation: 'Originator', numberOfAyahs: 45, revelationType: 'Meccan', page: 434),
  QuranSurahMeta(number: 36, name: 'يس', englishName: 'Ya-Sin', englishTranslation: 'Ya-Sin', numberOfAyahs: 83, revelationType: 'Meccan', page: 440),
  QuranSurahMeta(number: 37, name: 'الصَّافَّات', englishName: 'As-Saffat', englishTranslation: 'Those Who Set The Ranks', numberOfAyahs: 182, revelationType: 'Meccan', page: 446),
  QuranSurahMeta(number: 38, name: 'ص', englishName: 'Sad', englishTranslation: 'The Letter Sad', numberOfAyahs: 88, revelationType: 'Meccan', page: 453),
  QuranSurahMeta(number: 39, name: 'الزُّمَر', englishName: 'Az-Zumar', englishTranslation: 'The Troops', numberOfAyahs: 75, revelationType: 'Meccan', page: 458),
  QuranSurahMeta(number: 40, name: 'غَافِر', englishName: 'Ghafir', englishTranslation: 'The Forgiver', numberOfAyahs: 85, revelationType: 'Meccan', page: 467),
  QuranSurahMeta(number: 41, name: 'فُصِّلَت', englishName: 'Fussilat', englishTranslation: 'Explained in Detail', numberOfAyahs: 54, revelationType: 'Meccan', page: 477),
  QuranSurahMeta(number: 42, name: 'الشُّورَى', englishName: 'Ash-Shura', englishTranslation: 'The Consultation', numberOfAyahs: 53, revelationType: 'Meccan', page: 483),
  QuranSurahMeta(number: 43, name: 'الزُّخْرُف', englishName: 'Az-Zukhruf', englishTranslation: 'The Ornaments of Gold', numberOfAyahs: 89, revelationType: 'Meccan', page: 489),
  QuranSurahMeta(number: 44, name: 'الدُّخَان', englishName: 'Ad-Dukhan', englishTranslation: 'The Smoke', numberOfAyahs: 59, revelationType: 'Meccan', page: 496),
  QuranSurahMeta(number: 45, name: 'الجَاثِيَة', englishName: 'Al-Jathiyah', englishTranslation: 'The Crouching', numberOfAyahs: 37, revelationType: 'Meccan', page: 499),
  QuranSurahMeta(number: 46, name: 'الأَحْقَاف', englishName: 'Al-Ahqaf', englishTranslation: 'The Wind-Curved Sandhills', numberOfAyahs: 35, revelationType: 'Meccan', page: 502),
  QuranSurahMeta(number: 47, name: 'مُحَمَّد', englishName: 'Muhammad', englishTranslation: 'Muhammad', numberOfAyahs: 38, revelationType: 'Medinan', page: 507),
  QuranSurahMeta(number: 48, name: 'الفَتْح', englishName: 'Al-Fath', englishTranslation: 'The Victory', numberOfAyahs: 29, revelationType: 'Medinan', page: 511),
  QuranSurahMeta(number: 49, name: 'الحُجُرَات', englishName: 'Al-Hujurat', englishTranslation: 'The Rooms', numberOfAyahs: 18, revelationType: 'Medinan', page: 515),
  QuranSurahMeta(number: 50, name: 'ق', englishName: 'Qaf', englishTranslation: 'The Letter Qaf', numberOfAyahs: 45, revelationType: 'Meccan', page: 518),
  QuranSurahMeta(number: 51, name: 'الذَّارِيَات', englishName: 'Adh-Dhariyat', englishTranslation: 'The Winnowing Winds', numberOfAyahs: 60, revelationType: 'Meccan', page: 520),
  QuranSurahMeta(number: 52, name: 'الطُّور', englishName: 'At-Tur', englishTranslation: 'The Mount', numberOfAyahs: 49, revelationType: 'Meccan', page: 523),
  QuranSurahMeta(number: 53, name: 'النَّجْم', englishName: 'An-Najm', englishTranslation: 'The Star', numberOfAyahs: 62, revelationType: 'Meccan', page: 526),
  QuranSurahMeta(number: 54, name: 'القَمَر', englishName: 'Al-Qamar', englishTranslation: 'The Moon', numberOfAyahs: 55, revelationType: 'Meccan', page: 528),
  QuranSurahMeta(number: 55, name: 'الرَّحْمَن', englishName: 'Ar-Rahman', englishTranslation: 'The Beneficent', numberOfAyahs: 78, revelationType: 'Medinan', page: 531),
  QuranSurahMeta(number: 56, name: 'الوَاقِعَة', englishName: 'Al-Waqi\'ah', englishTranslation: 'The Inevitable', numberOfAyahs: 96, revelationType: 'Meccan', page: 534),
  QuranSurahMeta(number: 57, name: 'الحَدِيد', englishName: 'Al-Hadid', englishTranslation: 'The Iron', numberOfAyahs: 29, revelationType: 'Medinan', page: 537),
  QuranSurahMeta(number: 58, name: 'المُجَادَلَة', englishName: 'Al-Mujadila', englishTranslation: 'The Pleading Woman', numberOfAyahs: 22, revelationType: 'Medinan', page: 542),
  QuranSurahMeta(number: 59, name: 'الحَشْر', englishName: 'Al-Hashr', englishTranslation: 'The Exile', numberOfAyahs: 24, revelationType: 'Medinan', page: 545),
  QuranSurahMeta(number: 60, name: 'المُمتَحَنَة', englishName: 'Al-Mumtahanah', englishTranslation: 'She that is to be examined', numberOfAyahs: 13, revelationType: 'Medinan', page: 549),
  QuranSurahMeta(number: 61, name: 'الصَّفّ', englishName: 'As-Saf', englishTranslation: 'The Ranks', numberOfAyahs: 14, revelationType: 'Medinan', page: 551),
  QuranSurahMeta(number: 62, name: 'الجُمُعَة', englishName: 'Al-Jumu\'ah', englishTranslation: 'Friday', numberOfAyahs: 11, revelationType: 'Medinan', page: 553),
  QuranSurahMeta(number: 63, name: 'المُنَافِقُون', englishName: 'Al-Munafiqun', englishTranslation: 'The Hypocrites', numberOfAyahs: 11, revelationType: 'Medinan', page: 554),
  QuranSurahMeta(number: 64, name: 'التَّغَابُن', englishName: 'At-Taghabun', englishTranslation: 'Mutual Disillusion', numberOfAyahs: 18, revelationType: 'Medinan', page: 556),
  QuranSurahMeta(number: 65, name: 'الطَّلَاق', englishName: 'At-Talaq', englishTranslation: 'Divorce', numberOfAyahs: 12, revelationType: 'Medinan', page: 558),
  QuranSurahMeta(number: 66, name: 'التَّحْرِيم', englishName: 'At-Tahrim', englishTranslation: 'The Prohibition', numberOfAyahs: 12, revelationType: 'Medinan', page: 560),
  QuranSurahMeta(number: 67, name: 'المُلْك', englishName: 'Al-Mulk', englishTranslation: 'The Sovereignty', numberOfAyahs: 30, revelationType: 'Meccan', page: 562),
  QuranSurahMeta(number: 68, name: 'القَلَم', englishName: 'Al-Qalam', englishTranslation: 'The Pen', numberOfAyahs: 52, revelationType: 'Meccan', page: 564),
  QuranSurahMeta(number: 69, name: 'الحَاقَّة', englishName: 'Al-Haqqah', englishTranslation: 'The Reality', numberOfAyahs: 52, revelationType: 'Meccan', page: 566),
  QuranSurahMeta(number: 70, name: 'المَعَارِج', englishName: 'Al-Ma\'arij', englishTranslation: 'The Ascending Stairways', numberOfAyahs: 44, revelationType: 'Meccan', page: 568),
  QuranSurahMeta(number: 71, name: 'نُوح', englishName: 'Nuh', englishTranslation: 'Noah', numberOfAyahs: 28, revelationType: 'Meccan', page: 570),
  QuranSurahMeta(number: 72, name: 'الجِنّ', englishName: 'Al-Jinn', englishTranslation: 'The Jinn', numberOfAyahs: 28, revelationType: 'Meccan', page: 572),
  QuranSurahMeta(number: 73, name: 'المُزَّمِّل', englishName: 'Al-Muzzammil', englishTranslation: 'The Enshrouded One', numberOfAyahs: 20, revelationType: 'Meccan', page: 574),
  QuranSurahMeta(number: 74, name: 'المُدَّثِّر', englishName: 'Al-Muddaththir', englishTranslation: 'The Cloaked One', numberOfAyahs: 56, revelationType: 'Meccan', page: 575),
  QuranSurahMeta(number: 75, name: 'القِيَامَة', englishName: 'Al-Qiyamah', englishTranslation: 'The Resurrection', numberOfAyahs: 40, revelationType: 'Meccan', page: 577),
  QuranSurahMeta(number: 76, name: 'الإِنسَان', englishName: 'Al-Insan', englishTranslation: 'Man', numberOfAyahs: 31, revelationType: 'Medinan', page: 578),
  QuranSurahMeta(number: 77, name: 'المُرْسَلَات', englishName: 'Al-Mursalat', englishTranslation: 'The Emissaries', numberOfAyahs: 50, revelationType: 'Meccan', page: 580),
  QuranSurahMeta(number: 78, name: 'النَّبَأ', englishName: 'An-Naba', englishTranslation: 'The Tidings', numberOfAyahs: 40, revelationType: 'Meccan', page: 582),
  QuranSurahMeta(number: 79, name: 'النَّازِعَات', englishName: 'An-Nazi\'at', englishTranslation: 'Those who drag forth', numberOfAyahs: 46, revelationType: 'Meccan', page: 583),
  QuranSurahMeta(number: 80, name: 'عَبَس', englishName: '\'Abasa', englishTranslation: 'He frowned', numberOfAyahs: 42, revelationType: 'Meccan', page: 585),
  QuranSurahMeta(number: 81, name: 'التَّكْوِير', englishName: 'At-Takwir', englishTranslation: 'The Overthrowing', numberOfAyahs: 29, revelationType: 'Meccan', page: 586),
  QuranSurahMeta(number: 82, name: 'الانفِطَار', englishName: 'Al-Infitar', englishTranslation: 'The Cleaving', numberOfAyahs: 19, revelationType: 'Meccan', page: 587),
  QuranSurahMeta(number: 83, name: 'المُطَفِّفِين', englishName: 'Al-Mutaffifin', englishTranslation: 'Defrauding', numberOfAyahs: 36, revelationType: 'Meccan', page: 587),
  QuranSurahMeta(number: 84, name: 'الانشِقَاق', englishName: 'Al-Inshiqaq', englishTranslation: 'The Splitting Open', numberOfAyahs: 25, revelationType: 'Meccan', page: 589),
  QuranSurahMeta(number: 85, name: 'البُرُوج', englishName: 'Al-Buruj', englishTranslation: 'The Constellations', numberOfAyahs: 22, revelationType: 'Meccan', page: 590),
  QuranSurahMeta(number: 86, name: 'الطَّارِق', englishName: 'At-Tariq', englishTranslation: 'The Morning Star', numberOfAyahs: 17, revelationType: 'Meccan', page: 591),
  QuranSurahMeta(number: 87, name: 'الأَعْلَى', englishName: 'Al-A\'la', englishTranslation: 'The Most High', numberOfAyahs: 19, revelationType: 'Meccan', page: 591),
  QuranSurahMeta(number: 88, name: 'الغَاشِيَة', englishName: 'Al-Ghashiyah', englishTranslation: 'The Overwhelming', numberOfAyahs: 26, revelationType: 'Meccan', page: 592),
  QuranSurahMeta(number: 89, name: 'الفَجْر', englishName: 'Al-Fajr', englishTranslation: 'The Dawn', numberOfAyahs: 30, revelationType: 'Meccan', page: 593),
  QuranSurahMeta(number: 90, name: 'البَلَد', englishName: 'Al-Balad', englishTranslation: 'The City', numberOfAyahs: 20, revelationType: 'Meccan', page: 594),
  QuranSurahMeta(number: 91, name: 'الشَّمْس', englishName: 'Ash-Shams', englishTranslation: 'The Sun', numberOfAyahs: 15, revelationType: 'Meccan', page: 595),
  QuranSurahMeta(number: 92, name: 'اللَّيْل', englishName: 'Al-Layl', englishTranslation: 'The Night', numberOfAyahs: 21, revelationType: 'Meccan', page: 595),
  QuranSurahMeta(number: 93, name: 'الضُّحَى', englishName: 'Ad-Duha', englishTranslation: 'The Morning Hours', numberOfAyahs: 11, revelationType: 'Meccan', page: 596),
  QuranSurahMeta(number: 94, name: 'الشَّرْح', englishName: 'Ash-Sharh', englishTranslation: 'The Relief', numberOfAyahs: 8, revelationType: 'Meccan', page: 596),
  QuranSurahMeta(number: 95, name: 'التِّين', englishName: 'At-Tin', englishTranslation: 'The Fig', numberOfAyahs: 8, revelationType: 'Meccan', page: 597),
  QuranSurahMeta(number: 96, name: 'العَلَق', englishName: 'Al-\'Alaq', englishTranslation: 'The Clot', numberOfAyahs: 19, revelationType: 'Meccan', page: 597),
  QuranSurahMeta(number: 97, name: 'القَدْر', englishName: 'Al-Qadr', englishTranslation: 'The Power', numberOfAyahs: 5, revelationType: 'Meccan', page: 598),
  QuranSurahMeta(number: 98, name: 'البَيِّنَة', englishName: 'Al-Bayyinah', englishTranslation: 'The Clear Proof', numberOfAyahs: 8, revelationType: 'Medinan', page: 598),
  QuranSurahMeta(number: 99, name: 'الزَّلْزَلَة', englishName: 'Az-Zalzalah', englishTranslation: 'The Earthquake', numberOfAyahs: 8, revelationType: 'Medinan', page: 599),
  QuranSurahMeta(number: 100, name: 'العَادِيَات', englishName: 'Al-\'Adiyat', englishTranslation: 'The Courser', numberOfAyahs: 11, revelationType: 'Meccan', page: 599),
  QuranSurahMeta(number: 101, name: 'القَارِعَة', englishName: 'Al-Qari\'ah', englishTranslation: 'The Calamity', numberOfAyahs: 11, revelationType: 'Meccan', page: 600),
  QuranSurahMeta(number: 102, name: 'التَّكَاثُر', englishName: 'At-Takathur', englishTranslation: 'The Rivalry in World Increase', numberOfAyahs: 8, revelationType: 'Meccan', page: 600),
  QuranSurahMeta(number: 103, name: 'العَصْر', englishName: 'Al-\'Asr', englishTranslation: 'The Declining Day', numberOfAyahs: 3, revelationType: 'Meccan', page: 601),
  QuranSurahMeta(number: 104, name: 'الهُمَزَة', englishName: 'Al-Humazah', englishTranslation: 'The Traducer', numberOfAyahs: 9, revelationType: 'Meccan', page: 601),
  QuranSurahMeta(number: 105, name: 'الفِيل', englishName: 'Al-Fil', englishTranslation: 'The Elephant', numberOfAyahs: 5, revelationType: 'Meccan', page: 601),
  QuranSurahMeta(number: 106, name: 'قُرَيْش', englishName: 'Quraysh', englishTranslation: 'Quraysh', numberOfAyahs: 4, revelationType: 'Meccan', page: 602),
  QuranSurahMeta(number: 107, name: 'المَاعُون', englishName: 'Al-Ma\'un', englishTranslation: 'The Small Kindness', numberOfAyahs: 7, revelationType: 'Meccan', page: 602),
  QuranSurahMeta(number: 108, name: 'الكَوْثَر', englishName: 'Al-Kawthar', englishTranslation: 'The Abundance', numberOfAyahs: 3, revelationType: 'Meccan', page: 602),
  QuranSurahMeta(number: 109, name: 'الكَافِرُون', englishName: 'Al-Kafirun', englishTranslation: 'The Disbelievers', numberOfAyahs: 6, revelationType: 'Meccan', page: 603),
  QuranSurahMeta(number: 110, name: 'النَّصْر', englishName: 'An-Nasr', englishTranslation: 'The Divine Support', numberOfAyahs: 3, revelationType: 'Medinan', page: 603),
  QuranSurahMeta(number: 111, name: 'المَسَد', englishName: 'Al-Masad', englishTranslation: 'The Palm Fibre', numberOfAyahs: 5, revelationType: 'Meccan', page: 603),
  QuranSurahMeta(number: 112, name: 'الإِخْلَاص', englishName: 'Al-Ikhlas', englishTranslation: 'The Sincerity', numberOfAyahs: 4, revelationType: 'Meccan', page: 604),
  QuranSurahMeta(number: 113, name: 'الفَلَق', englishName: 'Al-Falaq', englishTranslation: 'The Daybreak', numberOfAyahs: 5, revelationType: 'Meccan', page: 604),
  QuranSurahMeta(number: 114, name: 'النَّاس', englishName: 'An-Nas', englishTranslation: 'Mankind', numberOfAyahs: 6, revelationType: 'Meccan', page: 604),
];
