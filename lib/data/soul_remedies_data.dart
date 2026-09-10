import 'package:flutter/material.dart';

/// عنصر الآية القرآنية
class QuranAyahItem {
  const QuranAyahItem({
    required this.ayah,
    required this.surah,
    this.translation = '',
  });
  final String ayah;
  final String surah;
  final String translation;
}

/// عنصر الدعاء النبوي
class PropheticDuaItem {
  const PropheticDuaItem({
    required this.dua,
    required this.source,
    this.repeat = 1,
    this.note = '',
  });
  final String dua;
  final String source;
  final int repeat;
  final String note;

  int get targetRepeat => repeat;
}

/// نموذج بيانات صيدلية الروح ودواء القلوب الموسّع
class SoulRemedy {
  const SoulRemedy({
    required this.id,
    required this.feelingAr,
    required this.feelingEn,
    required this.emoji,
    required this.descriptionAr,
    required this.accentColor,
    required this.gradientColors,
    required this.ayahs,
    required this.duas,
    required this.solacePointsAr,
    required this.solacePointsEn,
  });

  final String id;
  final String feelingAr;
  final String feelingEn;
  final String emoji;
  final String descriptionAr;
  final Color accentColor;
  final List<Color> gradientColors;
  final List<QuranAyahItem> ayahs;
  final List<PropheticDuaItem> duas;
  final List<String> solacePointsAr;
  final List<String> solacePointsEn;

  String get icon => emoji;

  IconData get iconData => switch (id) {
    'sad' => Icons.water_drop_rounded,
    'anxious' => Icons.shield_rounded,
    'distress' => Icons.spa_rounded,
    'confused' => Icons.explore_rounded,
    'angry' => Icons.local_fire_department_rounded,
    'guilty' => Icons.refresh_rounded,
    'grateful' => Icons.auto_awesome_rounded,
    'sick' => Icons.healing_rounded,
    'lonely' => Icons.nightlight_round,
    _ => Icons.favorite_rounded,
  };

  // توافق مع أي استدعاءات سابقة
  String get quranAyah => ayahs.isNotEmpty ? ayahs.first.ayah : '';
  String get surahReference => ayahs.isNotEmpty ? ayahs.first.surah : '';
  String get propheticDua => duas.isNotEmpty ? duas.first.dua : '';
  String get duaSource => duas.isNotEmpty ? duas.first.source : '';
  int get repeat => duas.isNotEmpty ? duas.first.repeat : 1;
  String get heartSolaceAr => solacePointsAr.isNotEmpty ? solacePointsAr.first : '';
  String get heartSolaceEn => solacePointsEn.isNotEmpty ? solacePointsEn.first : '';
}

/// قائمة أدوية القلوب الشاملة (تحتوي كل حالة على عدة آيات وأدعية وبلسم)
const List<SoulRemedy> soulRemediesList = [
  SoulRemedy(
    id: 'sad',
    feelingAr: 'حزين أو مهموم',
    feelingEn: 'Sad or Grieved',
    emoji: '🌧️',
    descriptionAr: 'حين يخيم الحزن على قلبك وتثقل روحك الأيام',
    accentColor: Color(0xFF3B82F6),
    gradientColors: [Color(0xFF1E3A8A), Color(0xFF172554)],
    ayahs: [
      QuranAyahItem(
        ayah: '﴿لَا تَحْزَنْ إِنَّ اللَّهَ مَعَنَا﴾',
        surah: 'سورة التوبة: ٤٠',
      ),
      QuranAyahItem(
        ayah: '﴿وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ﴾',
        surah: 'سورة آل عمران: ١٣٩',
      ),
      QuranAyahItem(
        ayah: '﴿وَقَالُوا الْحَمْدُ لِلَّهِ الَّذِي أَذْهَبَ عَنَّا الْحَزَنَ ۖ إِنَّ رَبَّنَا لَغَفُورٌ شَكُورٌ﴾',
        surah: 'سورة فاطر: ٣٤',
      ),
    ],
    duas: [
      PropheticDuaItem(
        dua: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ',
        source: 'صحيح البخاري — كان النبي ﷺ يكثر منه',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'اللَّهُمَّ إِنِّي عَبْدُكَ، ابْنُ عَبْدِكَ، ابْنُ أَمَتِكَ، نَاصِيَتِي بِيَدِكَ، مَاضٍ فِيَّ حُكْمُكَ، عَدْلٌ فِيَّ قَضَاؤُكَ، أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ، أَنْ تَجْعَلَ الْقُرْآنَ رَبِيعَ قَلْبِي، وَنُورَ صَدْرِي، وَجَلَاءَ حُزْنِي، وَذَهَابَ هَمِّي',
        source: 'مسند أحمد وصححه الألباني',
        repeat: 1,
      ),
      PropheticDuaItem(
        dua: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
        source: 'سنن الترمذي وحسنه الألباني',
        repeat: 3,
      ),
    ],
    solacePointsAr: [
      'ما أغلقت الدنيا باباً إلا وفتح الله برحمته أبواباً خفية.. حزنك لن يدوم.',
      'دموعك التي لا يراها الناس يعلمها الله ويجبر كسرها بألطافه التي لا تخطر ببالك.',
      'قم وتوضأ وصل ركعتين خفيفتين؛ فإن الصلاة كانت مفزع النبي ﷺ إذا حزبه أمر.',
    ],
    solacePointsEn: [
      'Whatever door closes in this world, Allah opens countless gates through His mercy.',
      'Tears unseen by humans are fully witnessed and gently mended by Allah.',
      'Perform ablution and pray two units; prayer was the Prophet\'s sanctuary in times of sorrow.',
    ],
  ),
  SoulRemedy(
    id: 'anxious',
    feelingAr: 'قلق أو خائف',
    feelingEn: 'Anxious or Fearful',
    emoji: '⚡',
    descriptionAr: 'حين يتسارع نبضك وتخشى من الغد أو المجهول',
    accentColor: Color(0xFFF59E0B),
    gradientColors: [Color(0xFF78350F), Color(0xFF451A03)],
    ayahs: [
      QuranAyahItem(
        ayah: '﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾',
        surah: 'سورة الرعد: ٢٨',
      ),
      QuranAyahItem(
        ayah: '﴿الَّذِينَ قَالَ لَهُمُ النَّاسُ إِنَّ النَّاسَ قَدْ جَمَعُوا لَكُمْ فَاخْشَوْهُمْ فَزَادَهُمْ إِيمَانًا وَقَالُوا حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ﴾',
        surah: 'سورة آل عمران: ١٧٣',
      ),
      QuranAyahItem(
        ayah: '﴿فَسَيَكْفِيكَهُمُ اللَّهُ ۚ وَهُوَ السَّمِيعُ الْعَلِيمُ﴾',
        surah: 'سورة البقرة: ١٣٧',
      ),
    ],
    duas: [
      PropheticDuaItem(
        dua: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ، عَلَى اللَّهِ تَوَكَّلْنَا',
        source: 'صحيح البخاري — قالها إبراهيم ومحمد عليهما الصلاة والسلام',
        repeat: 7,
      ),
      PropheticDuaItem(
        dua: 'اللَّهُمَّ رَحْمَتَكَ أَرْجُو، فَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ، وَأَصْلِحْ لِي شَأْنِي كُلَّهُ، لَا إِلَهَ إِلَّا أَنْتَ',
        source: 'سنن أبي داود وصححه الألباني',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
        source: 'سنن أبي داود والترمذي — أمان من كل فجأة وضرر',
        repeat: 3,
      ),
    ],
    solacePointsAr: [
      'قلقك من الغد لن يغير من قدر الله شيئاً، لكن توكلك على الحي القيوم يحول خوفك إلى سكينة.',
      'كل ما تخافه وتتوجس منه يقع تحت تصرف رب رحيم يحفظك من حيث لا تحتسب.',
      'تنفس بهدوء واذكر الله ثلاثاً بلسانك وقلبك، فما ذكر الله في ضيق إلا اتسع.',
    ],
    solacePointsEn: [
      'Worrying changes nothing of tomorrow, but trusting the Ever-Living brings peace.',
      'Everything you dread is under the control of a Most Merciful Lord.',
      'Breathe deeply and remember Allah; divine remembrance expands every constricted chest.',
    ],
  ),
  SoulRemedy(
    id: 'distress',
    feelingAr: 'في كرب أو ضيق شديد',
    feelingEn: 'In Distress or Crisis',
    emoji: '🤲',
    descriptionAr: 'حين تضيق عليك الأرض بما رحبت وتبحث عن مخرج عاجل',
    accentColor: Color(0xFF10B981),
    gradientColors: [Color(0xFF064E3B), Color(0xFF022C22)],
    ayahs: [
      QuranAyahItem(
        ayah: '﴿فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ الْعُسْرِ يُسْرًا﴾',
        surah: 'سورة الشرح: ٥-٦',
      ),
      QuranAyahItem(
        ayah: '﴿وَذَا النُّونِ إِذ ذَّهَبَ مُغَاضِبًا فَظَنَّ أَن لَّن نَّقْدِرَ عَلَيْهِ فَنَادَىٰ فِي الظُّلُمَاتِ أَن لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ ۝ فَاسْتَجَبْنَا لَهُ وَنَجَّيْنَاهُ مِنَ الْغَمِّ ۚ وَكَذَٰلِكَ نُنجِي الْمُؤْمِنِينَ﴾',
        surah: 'سورة الأنبياء: ٨٧-٨٨',
      ),
      QuranAyahItem(
        ayah: '﴿سَيَجْعَلُ اللَّهُ بَعْدَ عُسْرٍ يُسْرًا﴾',
        surah: 'سورة الطلاق: ٧',
      ),
    ],
    duas: [
      PropheticDuaItem(
        dua: 'لَا إِلَهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ السَّمَاوَاتِ وَرَبُّ الْأَرْضِ وَرَبُّ الْعَرْشِ الْكَرِيمِ',
        source: 'صحيح البخاري ومسلم — دعاء الكرب النبوي',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
        source: 'سنن الترمذي — دعوة يونس في بطن الحوت',
        repeat: 10,
      ),
      PropheticDuaItem(
        dua: 'اللَّهُ اللَّهُ رَبِّي لَا أُشْرِكُ بِهِ شَيْئًا',
        source: 'سنن أبي داود وابن ماجه وصححه الألباني',
        repeat: 7,
      ),
    ],
    solacePointsAr: [
      'لن يغلب عسر يسرين.. اشتداد الكرب دلالة على قرب الفرج.',
      'يونس عليه السلام نجا من ثلاث ظلمات (الليل، والبحر، وبطن الحوت) بكلمة التوحيد والتسبيح.',
      'الجأ إلى الصدقة والاستغفار؛ فإنهما مفتاح الأرزاق ومجلبة الفرج السريع.',
    ],
    solacePointsEn: [
      'No hardship can overpower two divine reliefs; the climax of distress signals near deliverance.',
      'Yunus was saved from triple darkness by pure tawhid and praise.',
      'Engage in charity and seeking forgiveness; they are keys to instant ease.',
    ],
  ),
  SoulRemedy(
    id: 'confused',
    feelingAr: 'محتار في قرار أو أمر',
    feelingEn: 'Confused or Indecisive',
    emoji: '🎯',
    descriptionAr: 'حين تتشعب أمامك الطرق وتتردد في اتخاذ خطوة مصيرية',
    accentColor: Color(0xFF8B5CF6),
    gradientColors: [Color(0xFF4C1D95), Color(0xFF2E1065)],
    ayahs: [
      QuranAyahItem(
        ayah: '﴿وَمَنْ يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ﴾',
        surah: 'سورة الطلاق: ٣',
      ),
      QuranAyahItem(
        ayah: '﴿وَعَسَىٰ أَن تَكْرَهُوا شَيْئًا وَهُوَ خَيْرٌ لَّكُمْ ۖ وَعَسَىٰ أَن تُحِبُّوا شَيْئًا وَهُوَ شَرٌّ لَّكُمْ ۗ وَاللَّهُ يَعْلَمُ وَأَنتُمْ لَا تَعْلَمُونَ﴾',
        surah: 'سورة البقرة: ٢١٦',
      ),
      QuranAyahItem(
        ayah: '﴿فَإِذَا عَزَمْتَ فَتَوَكَّلْ عَلَى اللَّهِ ۚ إِنَّ اللَّهَ يُحِبُّ الْمُتَوَكِّلِينَ﴾',
        surah: 'سورة آل عمران: ١٥٩',
      ),
    ],
    duas: [
      PropheticDuaItem(
        dua: 'اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي، وَاذْكُرْ بِالْهُدَى هِدَايَتَكَ الطَّرِيقَ، وَبِالسَّدَادِ سَدَادَ السَّهْمِ',
        source: 'صحيح مسلم',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'اللَّهُمَّ خِرْ لِي وَاخْتَرْ لِي، وَلَا تَكِلْنِي إِلَى خِيَرَتِي لِنَفْسِي',
        source: 'دعاء مأثور عن السلف الصالح',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ، وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ، وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ، فَإِنَّكَ تَقْدِرُ وَلَا أَقْدِرُ، وَتَعْلَمُ وَلَا أَعْلَمُ، وَأَنْتَ عَلَّامُ الْغُيُوبِ',
        source: 'صحيح البخاري — دعاء صلاة الاستخارة',
        repeat: 1,
      ),
    ],
    solacePointsAr: [
      'أنت ترى البدايات فقط، والله سبحانه يرى النهايات والعواقب.. فسلّم أمرك لعلمه.',
      'صل ركعتي الاستخارة واستشر أهل الحكمة والتقوى، ثم امضِ متوكلاً على الله.',
      'ما كتبه الله لك فلن يخطئك وما صرفه عنك فلعظيم شر كان سيلحق بك.',
    ],
    solacePointsEn: [
      'You only see the beginnings, but Allah encompasses all outcomes; entrust all to Him.',
      'Pray the Istikhara prayer and seek pious counsel, then proceed with confidence.',
      'Whatever is destined for you will never miss you, and what is kept away is pure protection.',
    ],
  ),
  SoulRemedy(
    id: 'angry',
    feelingAr: 'غضبان أو فاقد لأعصابك',
    feelingEn: 'Angry or Frustrated',
    emoji: '🔥',
    descriptionAr: 'حين تفور نار الغضب في صدرك وتكاد تنطق بما تندم عليه',
    accentColor: Color(0xFFEF4444),
    gradientColors: [Color(0xFF7F1D1D), Color(0xFF450A0A)],
    ayahs: [
      QuranAyahItem(
        ayah: '﴿وَالْكَاظِمِينَ الْغَيْظَ وَالْعَافِينَ عَنِ النَّاسِ ۗ وَاللَّهُ يُحِبُّ الْمُحْسِنِينَ﴾',
        surah: 'سورة آل عمران: ١٣٤',
      ),
      QuranAyahItem(
        ayah: '﴿وَإِذَا مَا غَضِبُوا هُمْ يَغْفِرُونَ﴾',
        surah: 'سورة الشورى: ٣٧',
      ),
      QuranAyahItem(
        ayah: '﴿خُذِ الْعَفْوَ وَأْمُرْ بِالْعُرْفِ وَأَعْرِضْ عَنِ الْجَاهِلِينَ﴾',
        surah: 'سورة الأعراف: ١٩٩',
      ),
    ],
    duas: [
      PropheticDuaItem(
        dua: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
        source: 'صحيح البخاري ومسلم — يذهب به الغضب فوراً',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'اللَّهُمَّ اغْفِرْ لِي ذَنْبِي، وَأَذْهِبْ غَيْظَ قَلْبِي، وَأَجِرْنِي مِنَ الشَّيْطَانِ',
        source: 'مأثور من هدي النبوة',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
        source: 'صحيح البخاري ومسلم — تطفئ لهيب الانفعال',
        repeat: 7,
      ),
    ],
    solacePointsAr: [
      'الشدة ليست بالصرعة وقوة الجسد، بل الشديد من يملك نفسه عند الغضب كما قال ﷺ.',
      'غيّر هيئتك فوراً: إن كنت واقفاً فاجلس، وإن كنت جالساً فاضطجع، واشرب ماءً بارداً.',
      'توضأ بماء عذب؛ فإن الغضب من الشيطان والشيطان خلق من نار وإنما تطفأ النار بالماء.',
    ],
    solacePointsEn: [
      'True strength is not physical dominance, but mastering yourself in anger.',
      'Change your posture immediately: sit if standing, and sip cool water.',
      'Perform wudu; anger is fiery from Satan, and water extinguishes fire.',
    ],
  ),
  SoulRemedy(
    id: 'guilty',
    feelingAr: 'مقصر أو نادم على ذنب',
    feelingEn: 'Guilty or Repentant',
    emoji: '💔',
    descriptionAr: 'حين تشعر بألم التقصير في حق الله وتطمع في مغفرته ولطفه',
    accentColor: Color(0xFF6366F1),
    gradientColors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
    ayahs: [
      QuranAyahItem(
        ayah: '﴿قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ ۚ إِنَّ اللَّهَ يَغْفِرُ الذُّنُوبَ جَمِيعًا ۚ إِنَّهُ هُوَ الْغَفُورُ الرَّحِيمُ﴾',
        surah: 'سورة الزمر: ٥٣',
      ),
      QuranAyahItem(
        ayah: '﴿وَإِنِّي لَغَفَّارٌ لِّمَن تَابَ وَآمَنَ وَعَمِلَ صَالِحًا ثُمَّ اهْتَدَىٰ﴾',
        surah: 'سورة طه: ٨٢',
      ),
      QuranAyahItem(
        ayah: '﴿وَمَن يَعْمَلْ سُوءًا أَوْ يَظْلِمْ نَفْسَهُ ثُمَّ يَسْتَغْفِرِ اللَّهَ يَجِدِ اللَّهَ غَفُورًا رَّحِيمًا﴾',
        surah: 'سورة النساء: ١١٠',
      ),
    ],
    duas: [
      PropheticDuaItem(
        dua: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
        source: 'صحيح البخاري — سيد الاستغفار',
        repeat: 1,
      ),
      PropheticDuaItem(
        dua: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
        source: 'سنن أبي داود والترمذي — يغفر للعبد وإن فر من الزحف',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
        source: 'سورة الأعراف: ٢٣ — دعاء آدم وحواء عليهما السلام',
        repeat: 3,
      ),
    ],
    solacePointsAr: [
      'ندمك وخوفك دلالة حياة قلبك.. فافرح بالتوبة واقبل على ربك.',
      'الله أشد فرحاً بتوبة عبده من رجل وجد ناقته وطعامه وشرابه في أرض مهلكة.',
      'أتبع السيئة الحسنة تمحها: صل ركعتين، تصدق، وأكثر من الاستغفار وسماع القرآن.',
    ],
    solacePointsEn: [
      'Your remorse proves your heart is alive with faith; turn to Allah with hope.',
      'Allah is more joyful over His servant\'s repentance than one finding life after near death.',
      'Follow a mistake with good deeds: pray, give charity, and seek forgiveness abundantly.',
    ],
  ),
  SoulRemedy(
    id: 'grateful',
    feelingAr: 'شاكر ومستبشر بنعمة',
    feelingEn: 'Grateful & Blessed',
    emoji: '🌸',
    descriptionAr: 'حين يفيض قلبك بالحمد والشكر لله على نعمة أو فرحة غمرتك',
    accentColor: Color(0xFFEC4899),
    gradientColors: [Color(0xFF831843), Color(0xFF500724)],
    ayahs: [
      QuranAyahItem(
        ayah: '﴿لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ﴾',
        surah: 'سورة إبراهيم: ٧',
      ),
      QuranAyahItem(
        ayah: '﴿وَإِن تَعُدُّوا نِعْمَةَ اللَّهِ لَا تُحْصُوهَا ۗ إِنَّ اللَّهَ لَغَفُورٌ رَّحِيمٌ﴾',
        surah: 'سورة النحل: ١٨',
      ),
      QuranAyahItem(
        ayah: '﴿رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَىٰ وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ﴾',
        surah: 'سورة الأحقاف: ١٥',
      ),
    ],
    duas: [
      PropheticDuaItem(
        dua: 'اللَّهُمَّ مَا أَصْبَحَ (أَوْ أَمْسَى) بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ، فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ',
        source: 'سنن أبي داود — من قالها فقد أدى شكر يومه وليلته',
        repeat: 1,
      ),
      PropheticDuaItem(
        dua: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
        source: 'سنن أبي داود وصححه الألباني — وصية النبي ﷺ لمعاذ',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'الْحَمْدُ لِلَّهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ كَمَا يُحِبُّ رَبُّنَا وَيَرْضَى',
        source: 'سنن أبي داود وصححه الألباني',
        repeat: 3,
      ),
    ],
    solacePointsAr: [
      'الشكر قيد النعم الموجودة، وصيد النعم المفقودة.. بالشكر تدوم وتزداد.',
      'اسجد سجدة شكر لله بخشوع وعين دامعة امتناناً لفضله الذي لا ينقطع.',
      'شارك النعمة مع المحتاجين؛ فشكر الغنى بالإنفاق، وشكر العافية بخدمة الضعفاء.',
    ],
    solacePointsEn: [
      'Gratitude anchors existing blessings and invites more; through praise, blessings endure.',
      'Offer a prostration of gratitude with humble tears of appreciation.',
      'Share your blessings with the needy; thankfulness in wealth is charity.',
    ],
  ),
  SoulRemedy(
    id: 'sick',
    feelingAr: 'مريض أو متألم جسدياً',
    feelingEn: 'Sick or In Pain',
    emoji: '🩺',
    descriptionAr: 'حين ينهك الجسد المرض أو الوجع وتبتغي الشفاء والراحة',
    accentColor: Color(0xFF06B6D4),
    gradientColors: [Color(0xFF164E63), Color(0xFF083344)],
    ayahs: [
      QuranAyahItem(
        ayah: '﴿وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ﴾',
        surah: 'سورة الشعراء: ٨٠',
      ),
      QuranAyahItem(
        ayah: '﴿وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ﴾',
        surah: 'سورة الإسراء: ٨٢',
      ),
      QuranAyahItem(
        ayah: '﴿أَنِّي مَسَّنِيَ الضُّرُّ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ ۝ فَاسْتَجَبْنَا لَهُ فَكَشَفْنَا مَا بِهِ مِن ضُرٍّ﴾',
        surah: 'سورة الأنبياء: ٨٣-٨٤',
      ),
    ],
    duas: [
      PropheticDuaItem(
        dua: 'اللَّهُمَّ رَبَّ النَّاسِ، أَذْهِبِ الْبَاسَ، اشْفِ أَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمًا',
        source: 'صحيح البخاري ومسلم — رقية النبي ﷺ للمريض',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'بِسْمِ اللَّهِ (٣ مرات)، أَعُوذُ بِاللَّهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ (٧ مرات)',
        source: 'صحيح مسلم — ضع يدك على مكان الألم وقلها',
        repeat: 1,
      ),
      PropheticDuaItem(
        dua: 'أَسْأَلُ اللَّهَ الْعَظِيمَ رَبَّ الْعَرْشِ الْعَظِيمِ أَنْ يَشْفِيَكَ (يَشْفِيَنِي)',
        source: 'سنن أبي داود والترمذي — ما قالها مريض إلا عوفي',
        repeat: 7,
      ),
    ],
    solacePointsAr: [
      'ما يصيب المسلم من وصب ولا نصب ولا سقم إلا كفّر الله به من خطاياه حتى الشوكة يشاكها.',
      'ضع يدك اليمنى على موضع الألم واقرأ الفاتحة وآية الكرسي والمعوذات بثقة ويقين تام.',
      'المرض زائر يخفف الأوزار ويرفع الدرجات فاصبر واحتسب الأجر عند الشافي سبحانه.',
    ],
    solacePointsEn: [
      'No pain or illness befalls a Muslim except that Allah expiates sins thereby.',
      'Place your right hand over the pain and recite Al-Fatiha with absolute faith.',
      'Illness is an expiation and an elevation of ranks; be patient and hope in the Healer.',
    ],
  ),
  SoulRemedy(
    id: 'lonely',
    feelingAr: 'وحيد أو غريب',
    feelingEn: 'Lonely or Alienated',
    emoji: '🌌',
    descriptionAr: 'حين تنعزل عن العالم وتشعر بقلة الرفيق وألم الغربة',
    accentColor: Color(0xFF64748B),
    gradientColors: [Color(0xFF334155), Color(0xFF0F172A)],
    ayahs: [
      QuranAyahItem(
        ayah: '﴿وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ ۚ وَاللَّهُ بِمَا تَعْمَلُونَ بَصِيرٌ﴾',
        surah: 'سورة الحديد: ٤',
      ),
      QuranAyahItem(
        ayah: '﴿وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ﴾',
        surah: 'سورة ق: ١٦',
      ),
      QuranAyahItem(
        ayah: '﴿إِنَّنِي مَعَكُمَا أَسْمَعُ وَأَرَىٰ﴾',
        surah: 'سورة طه: ٤٦',
      ),
    ],
    duas: [
      PropheticDuaItem(
        dua: 'اللَّهُمَّ آنِسْ وَحْشَتِي، وَثَبِّتْ جَنَانِي، وَاشْرَحْ صَدْرِي، وَاجْعَلْ لِي مِنْ لَدُنْكَ وَلِيًّا وَنَصِيرًا',
        source: 'دعاء مأثور للأنس بالله ومحبته',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ غَضَبِهِ وَعِقَابِهِ وَشَرِّ عِبَادِهِ، وَمِنْ هَمَزَاتِ الشَّيَاطِينِ وَأَنْ يَحْضُرُونِ',
        source: 'سنن أبي داود والترمذي — رقية الفزع والوحشة',
        repeat: 3,
      ),
      PropheticDuaItem(
        dua: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
        source: 'صحيح مسلم — الباقيات الصالحات وأنيس الوحيد',
        repeat: 10,
      ),
    ],
    solacePointsAr: [
      'من كان الله معه فكيف يكون وحيداً؟ الأنس بالله جنة في الدنيا قبل الآخرة.',
      'افتح المصحف واقرأ آياته بقلبك، فالقرآن أنيس القلوب وأعظم رفيق لا يفارق صاحبه.',
      'المؤمن الصادق لا يستوحش من قلة السالكين، فطوبى للغرباء الذين يصلحون ما أفسد الناس.',
    ],
    solacePointsEn: [
      'How can one be lonely when Allah is with him? Solace with Allah is paradise on earth.',
      'Open the Quran; divine words are the intimate friend of every pure heart.',
      'Blessed are the strangers whose loyalty to truth remains unshakeable.',
    ],
  ),
];
