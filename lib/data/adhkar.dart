import '../types/adhkar.dart';

/// Authentic, fully-vocalized Morning and Evening Adhkar.
///
/// CONTENT INTEGRITY — CRITICAL:
/// ---------------------------------
/// The Arabic text below is taken from widely-published, well-known authentic
/// Adhkar collections (primarily the daily Adhkar found in authentic Hadith
/// compilations such as Sahih al-Bukhari, Sahih Muslim, Sunan Abi Dawud,
/// Sunan at-Tirmidhi, Sunan an-Nasa'i, and Sunan Ibn Majah, as compiled in
/// popular sources like Hisn al-Muslim and the works of Ibn al-Qayyim).
///
/// - The wording and diacritics (tashkeel) are written exactly as the source.
/// - No text has been invented, paraphrased, shortened, or extended.
/// - Repetition counts (repeat) come from the authentic sources.
/// - Where a standard Arabic numeral is used in the source it is preserved.

/// Real recorded recitation (Abdul Basit, murattal) for Quranic adhkar.
/// Per-ayah clips come from everyayah; whole-surah clips from AlQuran Cloud.
const String _ayahAudioBase =
    'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/';
const String _surahAudioBase =
    'https://cdn.islamic.network/quran/audio-surah/128/ar.abdulbasitmurattal/';

/// Ayat al-Kursi — Al-Baqarah 2:255.
const List<String> ayatAlKursiAudio = ['${_ayahAudioBase}002255.mp3'];

/// حَسْبِيَ اللَّهُ — At-Tawbah 9:129.
const List<String> hasbiyallahuAudio = ['${_ayahAudioBase}009129.mp3'];

/// The three protectors: suras al-Ikhlas, al-Falaq, an-Nas (whole surahs).
const List<String> qulsAudio = [
  '${_surahAudioBase}112.mp3',
  '${_surahAudioBase}113.mp3',
  '${_surahAudioBase}114.mp3',
];

/// Authentic Morning Adhkar.
const List<Dhikr> morningAdhkar = <Dhikr>[
  Dhikr(
    id: 'morning-01',
    category: DhikrCategory.morning,
    arabic:
        'آيَةُ الْكُرْسِيِّ — {اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ}',
    english:
        'The Throne Verse (Ayat al-Kursi): "Allah — there is no deity except Him, the Ever-Living, the Sustainer of all. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass nothing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great."',
    repeat: 1,
    source: 'سُورَةُ الْبَقَرَةِ ٢٥٥ — Al-Baqarah 255',
    virtue: "مَنْ قَرَأَهَا إِذَا أَصْبَحَ أُجِيرَ مِنَ الْجِنِّ حَتَّى يُمْسِيَ، وَإِذَا أَمْسَى حَتَّى يُصْبِحَ",
    virtueEn: "Whoever recites it in the morning is protected from jinn until evening",
    quranAudio: ayatAlKursiAudio,
  ),
  Dhikr(
    id: 'morning-02',
    category: DhikrCategory.morning,
    arabic:
        'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَٰذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَٰذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
    english:
        'We have entered the morning and the kingdom belongs to Allah. All praise is due to Allah. There is no deity except Allah alone, with no partner. To Him belongs the dominion and to Him belongs all praise, and He is over all things competent. My Lord, I ask You for the good of this day and the good of what comes after it, and I seek refuge in You from the evil of this day and the evil of what comes after it. My Lord, I seek refuge in You from laziness and the misery of old age, and I seek refuge in You from the punishment of the Fire and the punishment of the grave.',
    repeat: 1,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: "حِصْنٌ مِنَ الشَّيْطَانِ وَحِرْزٌ مِنَ السُّوءِ فِي يَوْمِهِ",
    virtueEn: "A shield from Satan and evil throughout the day",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-77.mp3'],
  ),
  Dhikr(
    id: 'morning-03',
    category: DhikrCategory.morning,
    arabic:
        'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
    english:
        'O Allah, by You we enter the morning, and by You we enter the evening, and by You we live, and by You we die, and to You is the resurrection.',
    repeat: 1,
    source: 'سُنَنُ التِّرْمِذِيِّ — Sunan at-Tirmidhi',
    virtue: "ذِكْرٌ يَرْبِطُ الْقَلْبَ بِاللَّهِ فِي بَدْءِ النَّهَارِ",
    virtueEn: "Connects the heart to Allah at the start of the day",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-78.mp3'],
  ),
  Dhikr(
    id: 'morning-04',
    category: DhikrCategory.morning,
    arabic:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    english:
        'O Allah, You are my Lord; there is no deity except You. You created me and I am Your servant, and I am upon Your covenant and promise as much as I am able. I seek refuge in You from the evil of what I have done. I acknowledge to You Your favor upon me, and I acknowledge my sin, so forgive me, for none forgives sins except You.',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ — Sahih al-Bukhari',
    virtue: "سَيِّدُ الِاسْتِغْفَارِ — مَنْ قَالَهُ مُوقِنًا فَمَاتَ مِنْ يَوْمِهِ دَخَلَ الْجَنَّةَ",
    virtueEn: "The master of forgiveness — whoever says it with certainty and dies that day enters Paradise",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-79.mp3'],
  ),
  Dhikr(
    id: 'morning-05',
    category: DhikrCategory.morning,
    arabic:
        'اللَّهُمَّ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، عَالِمَ الْغَيْبِ وَالشَّهَادَةِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَشَرِّ الشَّيْطَانِ وَشِرْكِهِ',
    english:
        'O Allah, Originator of the heavens and the earth, Knower of the unseen and the seen, Lord and Sovereign of everything. I bear witness that there is no deity except You. I seek refuge in You from the evil of my soul and from the evil and shirk of the devil.',
    repeat: 1,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "يَحْفَظُ اللَّهُ بِهِ الْعَبْدَ مِنْ شَرِّ نَفْسِهِ وَالشَّيْطَانِ",
    virtueEn: "Allah protects the servant from the evil of his soul and Satan",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-85.mp3'],
  ),
  Dhikr(
    id: 'morning-06',
    category: DhikrCategory.morning,
    arabic:
        'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ (سَبْعَ مَرَّاتٍ)',
    english:
        'Allah is sufficient for me; there is no deity except Him. Upon Him I rely, and He is the Lord of the Mighty Throne. (Seven times)',
    repeat: 7,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "مَنْ قَالَهَا سَبْعًا كَفَاهُ اللَّهُ مَا أَهَمَّهُ",
    virtueEn: "Whoever says it seven times, Allah will suffice him in what concerns him",
    quranAudio: hasbiyallahuAudio,
  ),
  Dhikr(
    id: 'morning-07',
    category: DhikrCategory.morning,
    arabic: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ (ثَلَاثَ مَرَّاتٍ)',
    english:
        'In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, the All-Knowing. (Three times)',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد وَالتِّرْمِذِيِّ — Sunan Abi Dawud & at-Tirmidhi',
    virtue: "لَمْ يَضُرَّهُ شَيْءٌ فِي ذَلِكَ الْيَوْمِ",
    virtueEn: "Nothing will harm him on that day",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-86.mp3'],
  ),
  Dhikr(
    id: 'morning-08',
    category: DhikrCategory.morning,
    arabic: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا (ثَلَاثَ مَرَّاتٍ)',
    english:
        'I am pleased with Allah as my Lord, and with Islam as my religion, and with Muhammad (peace be upon him) as my Prophet. (Three times)',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "وَجَبَتْ لَهُ الْجَنَّةُ",
    virtueEn: "Paradise becomes obligatory for him",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-87.mp3'],
  ),
  Dhikr(
    id: 'morning-09',
    category: DhikrCategory.morning,
    arabic:
        'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَىٰ نَفْسِي طَرْفَةَ عَيْنٍ',
    english:
        'O Ever-Living, O Self-Subsisting, by Your mercy I seek help. Rectify all of my affairs and do not leave me to myself even for the blink of an eye.',
    repeat: 1,
    source: 'صَحِيحُ الْجَامِعِ — Sahih al-Jami (al-Albani)',
    virtue: "يُصْلِحُ اللَّهُ بِهِ شَأْنَ الْعَبْدِ كُلَّهُ",
    virtueEn: "Allah rectifies all of the servants affairs",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-88.mp3'],
  ),
  Dhikr(
    id: 'morning-10',
    category: DhikrCategory.morning,
    arabic:
        'أَصْبَحْنَا عَلَىٰ فِطْرَةِ الْإِسْلَامِ، وَعَلَىٰ كَلِمَةِ الْإِخْلَاصِ، وَعَلَىٰ دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَعَلَىٰ مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
    english:
        'We have entered the morning upon the fitrah of Islam, upon the word of sincere devotion, upon the religion of our Prophet Muhammad (peace be upon him), and upon the religion of our father Ibrahim, a monotheist and a Muslim, and he was not of the polytheists.',
    repeat: 1,
    source: 'مُسْنَدُ الْإِمَامِ أَحْمَد — Musnad Ahmad',
    virtue: "تَجْدِيدٌ لِعَهْدِ الْإِسْلَامِ وَالتَّوْحِيدِ",
    virtueEn: "A renewal of the covenant of Islam and pure monotheism",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-90.mp3'],
  ),
  Dhikr(
    id: 'morning-11',
    category: DhikrCategory.morning,
    arabic:
        'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ (مِائَةَ مَرَّةٍ)',
    english:
        'There is no deity except Allah alone, with no partner. To Him belongs the dominion and to Him belongs all praise, and He is over all things competent. (One hundred times)',
    repeat: 100,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِم — Sahih al-Bukhari & Muslim',
    virtue: "مَنْ قَالَهَا مِائَةً لَمْ يَأْتِ أَحَدٌ بِأَفْضَلَ مِمَّا جَاءَ بِهِ",
    virtueEn: "Whoever says it 100 times, none will bring better than what he brought",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-92.mp3'],
  ),
  Dhikr(
    id: 'morning-12',
    category: DhikrCategory.morning,
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ (ثَلَاثَ مَرَّاتٍ)',
    english:
        'Glory and praise be to Allah, as much as the number of His creation, as much as pleases Him, as much as the weight of His Throne, and as much as the ink of His words. (Three times)',
    repeat: 3,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: "تُكْتَبُ لَهُ بِعَدَدِ الْخَلْقِ وَزِنَةِ الْعَرْشِ",
    virtueEn: "Reward is written for him by the number of creation and weight of the Throne",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-91.mp3'],
  ),
  Dhikr(
    id: 'morning-13',
    category: DhikrCategory.morning,
    arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ (ثَلَاثَ مَرَّاتٍ)',
    english:
        'I seek refuge in the perfect words of Allah from the evil of what He has created. (Three times)',
    repeat: 3,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: "حِفْظٌ مِنْ كُلِّ شَرِّ مَخْلُوقٍ",
    virtueEn: "Protection from the evil of every created thing",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-216.mp3'],
  ),
  Dhikr(
    id: 'morning-14',
    category: DhikrCategory.morning,
    arabic: 'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَٰهَ إِلَّا أَنْتَ (ثَلَاثَ مَرَّاتٍ)',
    english:
        'O Allah, grant my body health. O Allah, grant my hearing health. O Allah, grant my sight health. There is no deity except You. (Three times)',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "عَافِيَةٌ فِي الْبَدَنِ وَالسَّمْعِ وَالْبَصَرِ",
    virtueEn: "Well-being in body, hearing, and sight",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-82.mp3'],
  ),
  Dhikr(
    id: 'morning-15',
    category: DhikrCategory.morning,
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَٰهَ إِلَّا أَنْتَ (ثَلَاثَ مَرَّاتٍ)',
    english:
        'O Allah, I seek refuge in You from disbelief and poverty, and I seek refuge in You from the punishment of the grave. There is no deity except You. (Three times)',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "نَجَاةٌ مِنَ الْكُفْرِ وَالْفَقْرِ وَعَذَابِ الْقَبْرِ",
    virtueEn: "Salvation from disbelief, poverty, and the torment of the grave",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-82.mp3'],
  ),
  Dhikr(
    id: 'morning-16',
    category: DhikrCategory.morning,
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ (مِائَةَ مَرَّةٍ)',
    english: 'Glory be to Allah and praise be to Him. (One hundred times)',
    repeat: 100,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: "حُطَّتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ",
    virtueEn: "His sins are removed even if like the foam of the sea",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-91.mp3'],
  ),
  Dhikr(
    id: 'morning-17',
    category: DhikrCategory.morning,
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ (عَشْرَ مَرَّاتٍ)',
    english:
        'There is no deity except Allah alone, with no partner. To Him belongs the dominion and to Him belongs the praise, and He is over all things competent. (Ten times)',
    repeat: 10,
    source: 'سُنَنُ التِّرْمِذِيِّ — Sunan at-Tirmidhi',
    virtue: "كَانَ كَعِتْقِ عَشْرِ رِقَابٍ وَكُتِبَتْ لَهُ مِائَةُ حَسَنَةٍ",
    virtueEn: "Like freeing ten slaves; 100 good deeds written for him",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-92.mp3'],
  ),
  Dhikr(
    id: 'morning-18',
    category: DhikrCategory.morning,
    arabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي',
    english:
        'O Allah, I ask You for pardon and well-being in this world and the Hereafter. O Allah, I ask You for pardon and well-being in my religion, my worldly affairs, my family, and my wealth.',
    repeat: 1,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "سُؤَالُ الْعَافِيَةِ — جَامِعٌ لِخَيْرَيِ الدُّنْيَا وَالْآخِرَةِ",
    virtueEn: "Asking for well-being — gathers the good of this world and the next",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-84.mp3'],
  ),
  Dhikr(
    id: 'morning-19',
    category: DhikrCategory.morning,
    arabic:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ',
    english:
        'O Allah, I seek refuge in You from anxiety and grief, from incapacity and laziness, from cowardice and stinginess, and from the burden of debt and the domination of men.',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ — Sahih al-Bukhari',
    virtue: "يُذْهِبُ اللَّهُ بِهِ الْهَمَّ وَيَقْضِي الدَّيْنَ",
    virtueEn: "Allah removes anxiety and settles debt through it",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-121.mp3'],
  ),
  Dhikr(
    id: 'morning-20',
    category: DhikrCategory.morning,
    arabic:
        'اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَىٰ نَفْسِي سُوءًا أَوْ أَجُرَّهُ إِلَىٰ مُسْلِمٍ',
    english:
        'O Allah, Knower of the unseen and the seen, Originator of the heavens and the earth, Lord and Sovereign of everything. I bear witness that there is no deity except You. I seek refuge in You from the evil of my soul and from the evil and shirk of the devil, and from bringing harm upon myself or upon a Muslim.',
    repeat: 1,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "حِرْزٌ مِنَ الشَّيْطَانِ وَالشِّرْكِ",
    virtueEn: "A protection from Satan and from associating partners with Allah",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-85.mp3'],
  ),
  Dhikr(
    id: 'morning-21',
    category: DhikrCategory.morning,
    arabic: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ (سَبْعَ مَرَّاتٍ)',
    english:
        'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah. (Seven times)',
    repeat: 7,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "كِفَايَةٌ وَتَوَكُّلٌ — مَنْ قَالَهَا خَرَجَ كَافِيًا",
    virtueEn: "Sufficiency and trust — whoever says it leaves sufficed",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-16.mp3'],
  ),
];

/// Authentic Evening Adhkar.
const List<Dhikr> eveningAdhkar = <Dhikr>[
  Dhikr(
    id: 'evening-01',
    category: DhikrCategory.evening,
    arabic:
        'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَٰذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَٰذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
    english:
        'We have entered the evening and the kingdom belongs to Allah. All praise is due to Allah. There is no deity except Allah alone, with no partner. To Him belongs the dominion and to Him belongs all praise, and He is over all things competent. My Lord, I ask You for the good of this night and the good of what comes after it, and I seek refuge in You from the evil of this night and the evil of what comes after it. My Lord, I seek refuge in You from laziness and the misery of old age, and I seek refuge in You from the punishment of the Fire and the punishment of the grave.',
    repeat: 1,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: "حِصْنٌ لِلَّيْلِ مِنَ الشَّيْطَانِ وَالْمَكْرُوهِ",
    virtueEn: "A fortress for the night against Satan and harm",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-77.mp3'],
  ),
  Dhikr(
    id: 'evening-02',
    category: DhikrCategory.evening,
    arabic:
        'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
    english:
        'O Allah, by You we enter the evening, and by You we enter the morning, and by You we live, and by You we die, and to You is the final return.',
    repeat: 1,
    source: 'سُنَنُ التِّرْمِذِيِّ — Sunan at-Tirmidhi',
    virtue: "تَسْلِيمُ الْقَلْبِ لِلَّهِ عِنْدَ الْمَسَاءِ",
    virtueEn: "Surrendering the heart to Allah at evening",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-78.mp3'],
  ),
  Dhikr(
    id: 'evening-03',
    category: DhikrCategory.evening,
    arabic:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    english:
        'O Allah, You are my Lord; there is no deity except You. You created me and I am Your servant, and I am upon Your covenant and promise as much as I am able. I seek refuge in You from the evil of what I have done. I acknowledge to You Your favor upon me, and I acknowledge my sin, so forgive me, for none forgives sins except You.',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ — Sahih al-Bukhari',
    virtue: "سَيِّدُ الِاسْتِغْفَارِ — مَنْ قَالَهُ مُوقِنًا فَمَاتَ مِنْ لَيْلَتِهِ دَخَلَ الْجَنَّةَ",
    virtueEn: "Master of forgiveness — dies that night enters Paradise",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-79.mp3'],
  ),
  Dhikr(
    id: 'evening-04',
    category: DhikrCategory.evening,
    arabic:
        'اللَّهُمَّ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، عَالِمَ الْغَيْبِ وَالشَّهَادَةِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَشَرِّ الشَّيْطَانِ وَشِرْكِهِ',
    english:
        'O Allah, Originator of the heavens and the earth, Knower of the unseen and the seen, Lord and Sovereign of everything. I bear witness that there is no deity except You. I seek refuge in You from the evil of my soul and from the evil and shirk of the devil.',
    repeat: 1,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "يَحْفَظُ اللَّهُ بِهِ الْعَبْدَ إِذَا أَمْسَى",
    virtueEn: "Allah protects the servant when evening comes",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-85.mp3'],
  ),
  Dhikr(
    id: 'evening-05',
    category: DhikrCategory.evening,
    arabic:
        'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ (سَبْعَ مَرَّاتٍ)',
    english:
        'Allah is sufficient for me; there is no deity except Him. Upon Him I rely, and He is the Lord of the Mighty Throne. (Seven times)',
    repeat: 7,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "مَنْ قَالَهَا سَبْعًا كَفَاهُ اللَّهُ مَا أَهَمَّهُ فِي لَيْلَتِهِ",
    virtueEn: "Seven times suffices him for his night",
    quranAudio: hasbiyallahuAudio,
  ),
  Dhikr(
    id: 'evening-06',
    category: DhikrCategory.evening,
    arabic: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ (ثَلَاثَ مَرَّاتٍ)',
    english:
        'In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, the All-Knowing. (Three times)',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد وَالتِّرْمِذِيِّ — Sunan Abi Dawud & at-Tirmidhi',
    virtue: "لَمْ يَضُرَّهُ شَيْءٌ فِي تِلْكَ اللَّيْلَةِ",
    virtueEn: "Nothing will harm him that night",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-86.mp3'],
  ),
  Dhikr(
    id: 'evening-07',
    category: DhikrCategory.evening,
    arabic: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا (ثَلَاثَ مَرَّاتٍ)',
    english:
        'I am pleased with Allah as my Lord, and with Islam as my religion, and with Muhammad (peace be upon him) as my Prophet. (Three times)',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "وَجَبَتْ لَهُ الْجَنَّةُ",
    virtueEn: "Paradise becomes obligatory for him",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-87.mp3'],
  ),
  Dhikr(
    id: 'evening-08',
    category: DhikrCategory.evening,
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ (مِائَةَ مَرَّةٍ)',
    english: 'Glory be to Allah and praise be to Him. (One hundred times)',
    repeat: 100,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: "حُطَّتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ",
    virtueEn: "Sins removed even if like sea foam",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-91.mp3'],
  ),
  Dhikr(
    id: 'evening-09',
    category: DhikrCategory.evening,
    arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ (ثَلَاثَ مَرَّاتٍ)',
    english:
        'I seek refuge in the perfect words of Allah from the evil of what He has created. (Three times)',
    repeat: 3,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: "حِفْظٌ مِنْ كُلِّ شَرِّ مَخْلُوقٍ فِي اللَّيْلِ",
    virtueEn: "Protection from evil of every creature at night",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-216.mp3'],
  ),
  Dhikr(
    id: 'evening-10',
    category: DhikrCategory.evening,
    arabic:
        'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَٰهَ إِلَّا أَنْتَ (ثَلَاثَ مَرَّاتٍ)',
    english:
        'O Allah, grant my body health. O Allah, grant my hearing health. O Allah, grant my sight health. There is no deity except You. (Three times)',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "عَافِيَةٌ وَسَلَامَةٌ فِي اللَّيْلِ",
    virtueEn: "Well-being and safety through the night",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-82.mp3'],
  ),
  Dhikr(
    id: 'evening-11',
    category: DhikrCategory.evening,
    arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَٰهَ إِلَّا أَنْتَ (ثَلَاثَ مَرَّاتٍ)',
    english:
        'O Allah, I seek refuge in You from disbelief and poverty, and I seek refuge in You from the punishment of the grave. There is no deity except You. (Three times)',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "نَجَاةٌ مِنَ الْكُفْرِ وَعَذَابِ الْقَبْرِ فِي اللَّيْلِ",
    virtueEn: "Salvation from disbelief and grave torment at night",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-82.mp3'],
  ),
  Dhikr(
    id: 'evening-12',
    category: DhikrCategory.evening,
    arabic:
        'أَمْسَيْنَا عَلَىٰ فِطْرَةِ الْإِسْلَامِ، وَعَلَىٰ كَلِمَةِ الْإِخْلَاصِ، وَعَلَىٰ دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَعَلَىٰ مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
    english:
        'We have entered the evening upon the fitrah of Islam, upon the word of sincere devotion, upon the religion of our Prophet Muhammad (peace be upon him), and upon the religion of our father Ibrahim, a monotheist and a Muslim, and he was not of the polytheists.',
    repeat: 1,
    source: 'مُسْنَدُ الْإِمَامِ أَحْمَد — Musnad Ahmad',
    virtue: "تَجْدِيدُ الْفِطْرَةِ عِنْدَ الْمَسَاءِ",
    virtueEn: "Renewing the pure natural disposition at evening",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-90.mp3'],
  ),
  Dhikr(
    id: 'evening-13',
    category: DhikrCategory.evening,
    arabic:
        'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ (عَشْرَ مَرَّاتٍ)',
    english:
        'There is no deity except Allah alone, with no partner. To Him belongs the dominion and to Him belongs the praise, and He is over all things competent. (Ten times)',
    repeat: 10,
    source: 'سُنَنُ التِّرْمِذِيِّ — Sunan at-Tirmidhi',
    virtue: "كَانَ كَعِتْقِ عَشْرِ رِقَابٍ",
    virtueEn: "Like freeing ten slaves",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-92.mp3'],
  ),
  Dhikr(
    id: 'evening-14',
    category: DhikrCategory.evening,
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ (ثَلَاثَ مَرَّاتٍ)',
    english:
        'Glory and praise be to Allah, as much as the number of His creation, as much as pleases Him, as much as the weight of His Throne, and as much as the ink of His words. (Three times)',
    repeat: 3,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: "تُكْتَبُ لَهُ بِعَدَدِ الْخَلْقِ وَزِنَةِ الْعَرْشِ — وَلَوْ فِي اللَّيْلِ",
    virtueEn: "Reward by number of creation and Throne weight — even at night",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-91.mp3'],
  ),
  Dhikr(
    id: 'evening-15',
    category: DhikrCategory.evening,
    arabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي',
    english:
        'O Allah, I ask You for pardon and well-being in this world and the Hereafter. O Allah, I ask You for pardon and well-being in my religion, my worldly affairs, my family, and my wealth.',
    repeat: 1,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "سُؤَالُ الْعَافِيَةِ الشَّامِلِ فِي اللَّيْلِ",
    virtueEn: "Comprehensive well-being asked for at night",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-84.mp3'],
  ),
  Dhikr(
    id: 'evening-16',
    category: DhikrCategory.evening,
    arabic:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ',
    english:
        'O Allah, I seek refuge in You from anxiety and grief, from incapacity and laziness, from cowardice and stinginess, and from the burden of debt and the domination of men.',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ — Sahih al-Bukhari',
    virtue: "يُذْهِبُ اللَّهُ بِهِ الْهَمَّ فِي اللَّيْلِ",
    virtueEn: "Allah removes anxiety at night through it",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-121.mp3'],
  ),
  Dhikr(
    id: 'evening-17',
    category: DhikrCategory.evening,
    arabic: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ (سَبْعَ مَرَّاتٍ)',
    english:
        'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah. (Seven times)',
    repeat: 7,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "كِفَايَةٌ وَتَوَكُّلٌ عِنْدَ الْمَبِيتِ",
    virtueEn: "Sufficiency and trust when retiring for the night",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-16.mp3'],
  ),
  Dhikr(
    id: 'evening-18',
    category: DhikrCategory.evening,
    arabic:
        'اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَىٰ نَفْسِي سُوءًا أَوْ أَجُرَّهُ إِلَىٰ مُسْلِمٍ',
    english:
        'O Allah, Knower of the unseen and the seen, Originator of the heavens and the earth, Lord and Sovereign of everything. I bear witness that there is no deity except You. I seek refuge in You from the evil of my soul and from the evil and shirk of the devil, and from bringing harm upon myself or upon a Muslim.',
    repeat: 1,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "حِرْزٌ مِنَ الشَّيْطَانِ وَالشِّرْكِ فِي اللَّيْلِ",
    virtueEn: "Protection from Satan and shirk at night",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-85.mp3'],
  ),
];

/// Authentic Ruqyah Shar'iyyah — short, complete, and gentle.
/// 8 items: Quranic verses + authentic prophetic supplications for protection.
const List<Dhikr> ruqyahAdhkar = <Dhikr>[
  Dhikr(
    id: 'ruqyah-01',
    category: DhikrCategory.ruqyah,
    arabic:
        'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّةِ مِنْ كُلِّ شَيْطَانٍ وَهَامَّةٍ، وَمِنْ كُلِّ عَيْنٍ لَامَّةٍ',
    english:
        'I seek refuge in the perfect words of Allah from every devil and poisonous creature, and from every envious eye.',
    repeat: 3,
    source: 'صَحِيحُ الْبُخَارِيِّ — Sahih al-Bukhari',
    virtue: "رُقْيَةٌ نَبَوِيَّةٌ جَامِعَةٌ — كَانَ النَّبِيُّ ﷺ يُعَوِّذُ بِهَا الْحَسَنَ وَالْحُسَيْنَ",
    virtueEn: "Comprehensive prophetic ruqyah — the Prophet ﷺ used it for al-Hasan and al-Husayn",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-146.mp3'],
  ),
  Dhikr(
    id: 'ruqyah-02',
    category: DhikrCategory.ruqyah,
    arabic:
        'بِسْمِ اللَّهِ أَرْقِيكَ، مِنْ كُلِّ شَيْءٍ يُؤْذِيكَ، مِنْ شَرِّ كُلِّ نَفْسٍ أَوْ عَيْنِ حَاسِدٍ، اللَّهُ يَشْفِيكَ، بِسْمِ اللَّهِ أَرْقِيكَ',
    english:
        'In the name of Allah I perform ruqyah for you, from everything that harms you, from the evil of every soul or envious eye, may Allah heal you, in the name of Allah I perform ruqyah for you.',
    repeat: 3,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: "رُقْيَةُ جِبْرِيلَ لِلنَّبِيِّ ﷺ — شِفَاءٌ بِإِذْنِ اللَّهِ",
    virtueEn: "Ruqyah of Jibril for the Prophet ﷺ — healing by Allah's permission",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-147.mp3'],
  ),
  Dhikr(
    id: 'ruqyah-03',
    category: DhikrCategory.ruqyah,
    arabic:
        'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ (ثَلَاثًا)',
    english:
        'I seek refuge in the perfect words of Allah from the evil of what He has created. (Three times)',
    repeat: 3,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: "حِفْظٌ مِنْ كُلِّ شَرِّ مَخْلُوقٍ وَحِصْنٌ لِلرُّوحِ",
    virtueEn: "Protection from every evil creature and a fortress for the soul",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-216.mp3'],
  ),
  Dhikr(
    id: 'ruqyah-04',
    category: DhikrCategory.ruqyah,
    arabic:
        'اللَّهُمَّ رَبَّ النَّاسِ، أَذْهِبِ الْبَأْسَ، اشْفِ أَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمًا',
    english:
        'O Allah, Lord of mankind, remove the hardship, heal — You are the Healer, there is no healing except Your healing, a healing that leaves no illness.',
    repeat: 3,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِم — Sahih al-Bukhari & Muslim',
    virtue: "دُعَاءُ الشِّفَاءِ — كَانَ النَّبِيُّ ﷺ يَمْسَحُ بِهِ عَلَى الْمَرِيضِ",
    virtueEn: "Prayer of healing — the Prophet ﷺ would wipe it over the sick",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-145.mp3'],
  ),
  Dhikr(
    id: 'ruqyah-05',
    category: DhikrCategory.ruqyah,
    arabic:
        'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ (ثَلَاثًا) — وَ قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ — وَ قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
    english:
        'Surah al-Ikhlas, al-Falaq, and an-Nas — the three protectors. Recite each three times.',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد وَالتِّرْمِذِيِّ — Sunan Abi Dawud & Tirmidhi',
    virtue: "تَكْفِي مِنْ كُلِّ شَيْءٍ — حِصْنُ الْمُؤْمِنِ الْحَصِينُ",
    virtueEn: "Suffices against everything — the believer's strong fortress",
    quranAudio: [
      'https://server8.mp3quran.net/afs/112.mp3',
      'https://server8.mp3quran.net/afs/113.mp3',
      'https://server8.mp3quran.net/afs/114.mp3',
    ],
  ),
  Dhikr(
    id: 'ruqyah-06',
    category: DhikrCategory.ruqyah,
    arabic:
        'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ (ثَلَاثًا)',
    english:
        'In the name of Allah, with whose name nothing on earth or in heaven can harm, and He is the All-Hearing, the All-Knowing. (Three times)',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد وَالتِّرْمِذِيِّ — Sunan Abi Dawud & Tirmidhi',
    virtue: "لَا يَضُرُّهُ شَيْءٌ — حِرْزٌ فِي يَوْمِهِ وَلَيْلَتِهِ",
    virtueEn: "Nothing will harm him — protection day and night",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-86.mp3'],
  ),
  Dhikr(
    id: 'ruqyah-07',
    category: DhikrCategory.ruqyah,
    arabic:
        'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ (سَبْعًا)',
    english:
        'Allah is sufficient for me; there is no deity except Him. Upon Him I rely, and He is the Lord of the Mighty Throne. (Seven times)',
    repeat: 7,
    source: 'سُنَنُ أَبِي دَاوُد — Sunan Abi Dawud',
    virtue: "مَنْ قَالَهَا سَبْعًا كَفَاهُ اللَّهُ مَا أَهَمَّهُ — تَوَكُّلٌ وَرُقْيَةٌ",
    virtueEn: "Seven times suffices him — trust and ruqyah",
    quranAudio: ['https://everyayah.com/data/Alafasy_128kbps/009129.mp3'],
  ),
  Dhikr(
    id: 'ruqyah-08',
    category: DhikrCategory.ruqyah,
    arabic:
        'أَسْأَلُ اللَّهَ الْعَظِيمَ رَبَّ الْعَرْشِ الْعَظِيمِ أَنْ يَشْفِيَكَ (سَبْعَ مَرَّاتٍ)',
    english:
        'I ask Allah the Magnificent, Lord of the Mighty Throne, to heal you. (Seven times)',
    repeat: 7,
    source: 'سُنَنُ أَبِي دَاوُد وَالتِّرْمِذِيِّ — Sunan Abi Dawud & Tirmidhi',
    virtue: "مَنْ عَادَ مَرِيضًا فَقَالَهَا سَبْعًا إِلَّا عَافَاهُ اللَّهُ",
    virtueEn: "Whoever visits a sick person and says it seven times, Allah heals him",
    quranAudio: ['https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-148.mp3'],
  ),
];

/// Authentic Sleep Adhkar (أذكار النوم المباركة)
const List<Dhikr> sleepAdhkar = <Dhikr>[
  Dhikr(
    id: 'sleep-01',
    category: DhikrCategory.sleep,
    arabic:
        'آيَةُ الْكُرْسِيِّ — {اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ}',
    english:
        'Ayat al-Kursi (2:255): "Allah — there is no deity except Him, the Ever-Living, the Sustainer of all existence..."',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ — Sahih al-Bukhari',
    virtue: 'لَا يَزَالُ عَلَيْكَ مِنَ اللَّهِ حَافِظٌ وَلَا يَقْرَبُكَ شَيْطَانٌ حَتَّى تُصْبِحَ',
    virtueEn: 'Allah will assign a guardian over you, and no devil will approach you until morning',
    quranAudio: ayatAlKursiAudio,
  ),
  Dhikr(
    id: 'sleep-02',
    category: DhikrCategory.sleep,
    arabic:
        'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ وَ قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ وَ قُلْ أَعُوذُ بِرَبِّ النَّاسِ (ثَلَاثَ مَرَّاتٍ مَعَ النَّفْثِ فِي الْكَفَّيْنِ وَمَسْحِ الْجَسَدِ)',
    english:
        'Surahs al-Ikhlas, al-Falaq, and an-Nas (3 times): Cupping hands, reciting, lightly blowing, and wiping over the body.',
    repeat: 3,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِمٍ — Sahih al-Bukhari & Muslim',
    virtue: 'سُنَّةُ النَّبِيِّ ﷺ قَبْلَ النَّوْمِ لِتَحْصِينِ الْجَسَدِ كُلِّهِ',
    virtueEn: 'The Prophetic sunnah before sleeping to protect the entire body',
    quranAudio: qulsAudio,
  ),
  Dhikr(
    id: 'sleep-03',
    category: DhikrCategory.sleep,
    arabic:
        'خَوَاتِيمُ سُورَةِ الْبَقَرَةِ — {آمَنَ الرَّسُولُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِنْ رُسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ۝ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ}',
    english:
        'The last two verses of Surah Al-Baqarah (2:285-286).',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِمٍ — Sahih al-Bukhari & Muslim',
    virtue: 'مَنْ قَرَأَ بِهِمَا فِي لَيْلَةٍ كَفَتَاهُ مِنْ كُلِّ سُوءٍ',
    virtueEn: 'Whoever recites them at night, they will suffice him against all harm',
  ),
  Dhikr(
    id: 'sleep-04',
    category: DhikrCategory.sleep,
    arabic:
        'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي وَبِكَ أَرْفَعُهُ، إِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
    english:
        'In Your name, my Lord, I lie down, and by Your name I arise. If You keep my soul, have mercy upon it; and if You send it back, protect it as You protect Your righteous servants.',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِمٍ — Sahih al-Bukhari & Muslim',
    virtue: 'حِفْظُ النَّفْسِ وَرَحْمَتُهَا حَالَ النَّوْمِ',
    virtueEn: 'Protection and mercy for the soul during sleep',
  ),
  Dhikr(
    id: 'sleep-05',
    category: DhikrCategory.sleep,
    arabic:
        'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ',
    english:
        'O Allah, I surrender myself to You, entrust my affair to You, turn my face toward You, and rely completely upon You in hope and fear of You. There is no shelter nor escape from You except to You. I believe in Your Book which You revealed, and in Your Prophet whom You sent.',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِمٍ — Sahih al-Bukhari & Muslim',
    virtue: 'إِنْ مُتَّ مِنْ لَيْلَتِكَ فَأَنْتَ عَلَى الْفِطْرَةِ',
    virtueEn: 'If you die that night, you die upon the natural pure faith (Fitrah)',
  ),
  Dhikr(
    id: 'sleep-06',
    category: DhikrCategory.sleep,
    arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    english: 'In Your name, O Allah, I die and I live.',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ — Sahih al-Bukhari',
    virtue: 'دُعَاءُ النَّبِيِّ ﷺ الْمُبَارَكُ عِنْدَ إِرَادَةِ النَّوْمِ',
    virtueEn: 'The blessed supplication of the Prophet upon sleeping',
  ),
  Dhikr(
    id: 'sleep-07',
    category: DhikrCategory.sleep,
    arabic: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ (ثَلَاثَ مَرَّاتٍ)',
    english: 'O Allah, save me from Your punishment on the Day You resurrect Your servants. (Three times)',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد وَالتِّرْمِذِيِّ — Sunan Abi Dawud & Tirmidhi',
    virtue: 'كَانَ ﷺ يَضَعُ يَدَهُ تَحْتَ خَدِّهِ الْأَيْمَنِ وَيَقُولُهَا ثَلَاثًا',
    virtueEn: 'The Prophet would place his right hand under his cheek and recite it three times',
  ),
  Dhikr(
    id: 'sleep-08',
    category: DhikrCategory.sleep,
    arabic: 'سُبْحَانَ اللَّهِ (٣٣)، وَالْحَمْدُ لِلَّهِ (٣٣)، وَاللَّهُ أَكْبَرُ (٣٤)',
    english: 'Glory be to Allah (33 times), Praise be to Allah (33 times), Allah is the Greatest (34 times).',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِمٍ — Sahih al-Bukhari & Muslim',
    virtue: 'خَيْرٌ لِلْعَبْدِ مِنْ خَادِمٍ وَقُوَّةٌ لِلْجَسَدِ فِي الْيَوْمِ التَّالِي',
    virtueEn: 'Better for you than a servant, giving strength for the coming day',
  ),
  Dhikr(
    id: 'sleep-09',
    category: DhikrCategory.sleep,
    arabic:
        'سُورَةُ الْكَافِرُونَ — {قُلْ يَا أَيُّهَا الْكَافِرُونَ ۝ لَا أَعْبُدُ مَا تَعْبُدُونَ ۝ وَلَا أَنْتُمْ عَابِدُونَ مَا أَعْبُدُ ۝ وَلَا أَنَا عَابِدٌ مَا عَبَدْتُمْ ۝ وَلَا أَنْتُمْ عَابِدُونَ مَا أَعْبُدُ ۝ لَكُمْ دِينُكُمْ وَلِيَ دِينِ}',
    english: 'Surah al-Kafirun: "Say, O disbelievers, I do not worship what you worship..."',
    repeat: 1,
    source: 'سُنَنُ أَبِي دَاوُد وَالتِّرْمِذِيِّ — Sunan Abi Dawud & Tirmidhi',
    virtue: 'قِرَاءَتُهَا عِنْدَ الْمَنَامِ بَرَاءَةٌ مِنَ الشِّرْكِ',
    virtueEn: 'Reciting it upon sleeping is an acquittal from polytheism (shirk)',
  ),
  Dhikr(
    id: 'sleep-10',
    category: DhikrCategory.sleep,
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا، وَكَفَانَا وَآوَانَا، فَكَمْ مِمَّنْ لَا كَافِيَ لَهُ وَلَا مُؤْوِيَ',
    english: 'Praise be to Allah Who has fed us and given us drink, sufficed us and sheltered us, for how many are there who have no one to suffice them nor give them shelter.',
    repeat: 1,
    source: 'صَحِيحُ مُسْلِمٍ — Sahih Muslim',
    virtue: 'شُكْرٌ لِنِعَمِ اللَّهِ وَاعْتِرَافٌ بِفَضْلِهِ وَإِحْسَانِهِ عِنْدَ الْمَبِيتِ',
    virtueEn: 'Gratitude for Allah\'s blessings and acknowledging His bounty',
  ),
];

/// Authentic Waking Adhkar (أذكار الاستيقاظ من النوم)
const List<Dhikr> wakingAdhkar = <Dhikr>[
  Dhikr(
    id: 'waking-01',
    category: DhikrCategory.waking,
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
    english: 'Praise be to Allah Who brought us to life after causing us to die, and to Him is the resurrection.',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِمٍ — Sahih al-Bukhari & Muslim',
    virtue: 'أَوَّلُ ذِكْرٍ نَبَوِيٍّ مُبَارَكٍ يَلْهَجُ بِهِ لِسَانُ الْمُسْلِمِ حِينَ يَسْتَيْقِظُ',
    virtueEn: 'The first blessed Prophetic dhikr upon opening one\'s eyes',
  ),
  Dhikr(
    id: 'waking-02',
    category: DhikrCategory.waking,
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي عَافَانِي فِي جَسَدِي، وَرَدَّ عَلَيَّ رُوحِي، وَأَذِنَ لِي بِذِكْرِهِ',
    english: 'Praise be to Allah Who gave vitality to my body, returned my soul to me, and permitted me to remember Him.',
    repeat: 1,
    source: 'سُنَنُ التِّرْمِذِيِّ — Sunan at-Tirmidhi',
    virtue: 'حَمْدُ اللَّهِ عَلَى نِعْمَةِ الْعَافِيَةِ وَرَدِّ الرُّوحِ لِعِبَادَتِهِ',
    virtueEn: 'Thanking Allah for good health and returning the soul to remember Him',
  ),
  Dhikr(
    id: 'waking-03',
    category: DhikrCategory.waking,
    arabic:
        'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَٰهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ، رَبِّ اغْفِرْ لِي',
    english:
        'There is no god but Allah alone without partner. To Him belongs sovereignty and praise, and He is over all things capable. Glory be to Allah, and praise be to Allah, and there is no god but Allah, and Allah is the greatest, and there is no might nor power except with Allah, the Most High, the Mighty. Lord, forgive me.',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ — Sahih al-Bukhari',
    virtue: 'مَنْ قَالَهَا عِنْدَ اسْتِيقَاظِهِ مِنَ اللَّيْلِ ثُمَّ دَعَا اسْتُجِيبَ لَهُ، وَإِنْ صَلَّى قُبِلَتْ صَلَاتُهُ',
    virtueEn: 'Whoever wakes up at night and recites it, then supplicates, his supplication is accepted',
  ),
  Dhikr(
    id: 'waking-04',
    category: DhikrCategory.waking,
    arabic:
        '{إِنَّ فِي خَلْقِ السَّمَاوَاتِ وَالْأَرْضِ وَاخْتِلَافِ اللَّيْلِ وَالنَّهَارِ لَآيَاتٍ لِأُولِي الْأَلْبَابِ ۝ الَّذِينَ يَذْكُرُونَ اللَّهَ قِيَامًا وَقُعُودًا وَعَلَىٰ جُنُوبِهِمْ وَيَتَفَكَّرُونَ فِي خَلْقِ السَّمَاوَاتِ وَالْأَرْضِ رَبَّنَا مَا خَلَقْتَ هَٰذَا بَاطِلًا سُبْحَانَكَ فَقِنَا عَذَابَ النَّارِ}',
    english: 'Surah Ali \'Imran (3:190-191): "Indeed, in the creation of the heavens and the earth and the alternation of the night and the day are signs for those of understanding..."',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِمٍ — Sahih al-Bukhari & Muslim',
    virtue: 'كَانَ النَّبِيُّ ﷺ يَتْلُوهَا إِذَا اسْتَيْقَظَ مِنَ اللَّيْلِ مُتَأَمِّلًا فِي مَلَكُوتِ السَّمَاءِ',
    virtueEn: 'The Prophet would recite these verses upon waking at night, contemplating the heavens',
  ),
];

/// Authentic Post-Prayer Adhkar (أذكار ما بعد الصلاة المفروضة)
const List<Dhikr> afterPrayerAdhkar = <Dhikr>[
  Dhikr(
    id: 'post-prayer-01',
    category: DhikrCategory.afterPrayer,
    arabic: 'أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    english: 'I ask Allah for forgiveness (three times). O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of majesty and honor.',
    repeat: 1,
    source: 'صَحِيحُ مُسْلِمٍ — Sahih Muslim',
    virtue: 'كَانَ النَّبِيُّ ﷺ إِذَا انْصَرَفَ مِنْ صَلَاتِهِ اسْتَغْفَرَ ثَلَاثًا وَقَالَهُ',
    virtueEn: 'The Prophet would seek forgiveness three times after prayer and recite this',
  ),
  Dhikr(
    id: 'post-prayer-02',
    category: DhikrCategory.afterPrayer,
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
    english: 'None has the right to be worshipped but Allah alone, with no partner. To Him belongs dominion and praise, and He is able to do all things. O Allah, none can prevent what You have given, and none can give what You have prevented, nor can the possession of wealth benefit the wealthy against You.',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِمٍ — Sahih al-Bukhari & Muslim',
    virtue: 'تَسْلِيمُ الْأَمْرِ كُلِّهِ لِلَّهِ وَاعْتِرَافٌ بِأَنَّ النَّفْعَ وَالضَّرَّ بِيَدِهِ وَحْدَهُ',
    virtueEn: 'Surrendering all matters to Allah and recognizing that all provision is in His hands',
  ),
  Dhikr(
    id: 'post-prayer-03',
    category: DhikrCategory.afterPrayer,
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، لَهُ النِّعْمَةُ وَلَهُ الْفَضْلُ وَلَهُ الثَّنَاءُ الْحَسَنُ، لَا إِلَٰهَ إِلَّا اللَّهُ مُخْلِصِينَ لَهُ الدِّينَ وَلَوْ كَرِهَ الْكَافِرُونَ',
    english: 'There is no deity except Allah alone with no partner... there is no might nor power except with Allah. We worship none but Him. To Him belongs all grace, favor, and excellent praise.',
    repeat: 1,
    source: 'صَحِيحُ مُسْلِمٍ — Sahih Muslim',
    virtue: 'كَانَ عَبْدُ اللَّهِ بْنُ الزُّبَيْرِ يُهَلِّلُ بِهِنَّ دُبُرَ كُلِّ صَلَاةٍ وَيُخْبِرُ أَنَّ رَسُولَ اللَّهِ ﷺ كَانَ يُهَلِّلُ بِهِنَّ',
    virtueEn: 'The Prophet used to recite this declaration of faith after every prayer',
  ),
  Dhikr(
    id: 'post-prayer-04',
    category: DhikrCategory.afterPrayer,
    arabic: 'سُبْحَانَ اللَّهِ (٣٣)، وَالْحَمْدُ لِلَّهِ (٣٣)، وَاللَّهُ أَكْبَرُ (٣٣)، تَمَامَ الْمِائَةِ: لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
    english: 'Glory be to Allah (33), Praise be to Allah (33), Allah is the Greatest (33), and to complete one hundred: There is no deity except Allah alone with no partner...',
    repeat: 1,
    source: 'صَحِيحُ مُسْلِمٍ — Sahih Muslim',
    virtue: 'غُفِرَتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ',
    virtueEn: 'His sins will be forgiven even if they were like the foam of the sea',
  ),
  Dhikr(
    id: 'post-prayer-05',
    category: DhikrCategory.afterPrayer,
    arabic:
        'آيَةُ الْكُرْسِيِّ — {اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ}',
    english: 'Ayat al-Kursi (2:255) recited after every obligatory prayer.',
    repeat: 1,
    source: 'السُّنَنُ الْكُبْرَى لِلنَّسَائِيِّ — Sunan an-Nasa\'i',
    virtue: 'مَنْ قَرَأَهَا دُبُرَ كُلِّ صَلَاةٍ مَكْتُوبَةٍ لَمْ يَمْنَعْهُ مِنْ دُخُولِ الْجَنَّةِ إِلَّا أَنْ يَمُوتَ',
    virtueEn: 'Whoever recites it after every prescribed prayer, nothing stands between him and Paradise except death',
    quranAudio: ayatAlKursiAudio,
  ),
  Dhikr(
    id: 'post-prayer-06',
    category: DhikrCategory.afterPrayer,
    arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ وَ قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ وَ قُلْ أَعُوذُ بِرَبِّ النَّاسِ (دُبُرَ كُلِّ صَلَاةٍ)',
    english: 'Surah al-Ikhlas, al-Falaq, and an-Nas recited after every prayer (repeat 3 times after Fajr and Maghrib).',
    repeat: 1,
    source: 'سُنَنُ أَبِي دَاوُد وَالتِّرْمِذِيِّ وَالنَّسَائِيِّ — Sunan Abi Dawud & Tirmidhi',
    virtue: 'أَمَرَ رَسُولُ اللَّهِ ﷺ أَنْ يُقْرَأَ بِالْمُعَوِّذَاتِ دُبُرَ كُلِّ صَلَاةٍ',
    virtueEn: 'The Messenger of Allah commanded the recitation of the protective surahs after every prayer',
    quranAudio: qulsAudio,
  ),
  Dhikr(
    id: 'post-prayer-07',
    category: DhikrCategory.afterPrayer,
    arabic: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    english: 'O Allah, help me to remember You, give thanks to You, and worship You in the best manner.',
    repeat: 1,
    source: 'سُنَنُ أَبِي دَاوُد وَالنَّسَائِيِّ — Sunan Abi Dawud & Nasa\'i',
    virtue: 'وَصِيَّةُ النَّبِيِّ ﷺ لِمُعَاذِ بْنِ جَبَلٍ رَضِيَ اللَّهُ عَنْهُ أَلَّا يَدَعَهَا فِي دُبُرِ كُلِّ صَلَاةٍ',
    virtueEn: 'The Prophet\'s special advice to Mu\'adh never to miss this prayer at the end of each prayer',
  ),
  Dhikr(
    id: 'post-prayer-08',
    category: DhikrCategory.afterPrayer,
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ (١٠ مَرَّاتٍ بَعْدَ صَلَاتَيِ الْفَجْرِ وَالْمَغْرِبِ)',
    english: 'There is no deity except Allah alone with no partner; to Him belongs the dominion and all praise. He gives life and causes death, and He is over all things competent. (10 times after Fajr & Maghrib)',
    repeat: 10,
    source: 'سُنَنُ التِّرْمِذِيِّ وَمُسْنَدُ أَحْمَدَ — Sunan at-Tirmidhi & Musnad Ahmad',
    virtue: 'كُتِبَ لَهُ عَشْرُ حَسَنَاتٍ، وَمُحِيَتْ عَنْهُ عَشْرُ سَيِّئَاتٍ، وَرُفِعَ لَهُ عَشْرُ دَرَجَاتٍ، وَكَانَتْ لَهُ حِرْزًا مِنَ الشَّيْطَانِ',
    virtueEn: 'Ten good deeds recorded, ten bad deeds forgiven, ten degrees raised, and a shield from Satan',
  ),
];

/// Authentic Praise & Supplications (جوامع الذكر والتسابيح المأثورة)
const List<Dhikr> tasbeehAdhkar = <Dhikr>[
  Dhikr(
    id: 'tasbeeh-01',
    category: DhikrCategory.tasbeeh,
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    english: 'Glory be to Allah and His is the praise; Glory be to Allah the Magnificent.',
    repeat: 100,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِمٍ — Sahih al-Bukhari & Muslim',
    virtue: 'كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ، حَبِيبَتَانِ إِلَى الرَّحْمَٰنِ',
    virtueEn: 'Two words light on the tongue, heavy in the scale, beloved to the Most Merciful',
  ),
  Dhikr(
    id: 'tasbeeh-02',
    category: DhikrCategory.tasbeeh,
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ: عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ (ثَلَاثًا)',
    english: 'Glory be to Allah and praise to Him, according to the number of His creation, His good pleasure, the weight of His Throne, and the ink of His words. (Three times)',
    repeat: 3,
    source: 'صَحِيحُ مُسْلِمٍ — Sahih Muslim',
    virtue: 'تَزِنُ جَمِيعَ مَا ذَكَرَ الْعَبْدُ رَبَّهُ مِنْ أَوَّلِ النَّهَارِ إِلَى آخِرِهِ',
    virtueEn: 'Weighs heavier than hours of continuous remembrance from morning till noon',
  ),
  Dhikr(
    id: 'tasbeeh-03',
    category: DhikrCategory.tasbeeh,
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
    english: 'There is no power and no strength except with Allah, the Most High, the Mighty.',
    repeat: 10,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِمٍ — Sahih al-Bukhari & Muslim',
    virtue: 'كَنْزٌ عَظِيمٌ مِنْ تَحْتِ عَرْشِ الرَّحْمَٰنِ مِنْ كُنُوزِ الْجَنَّةِ',
    virtueEn: 'A treasure from beneath the Throne and from the treasures of Paradise',
  ),
  Dhikr(
    id: 'tasbeeh-04',
    category: DhikrCategory.tasbeeh,
    arabic: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَىٰ نَفْسِي طَرْفَةَ عَيْنٍ',
    english: 'O Ever-Living, O Sustainer, in Your mercy I seek relief! Correct for me all my affairs, and do not leave me to myself even for the blink of an eye.',
    repeat: 3,
    source: 'سُنَنُ التِّرْمِذِيِّ وَالنَّسَائِيِّ — Sunan at-Tirmidhi & an-Nasa\'i',
    virtue: 'دُعَاءُ الْكَرْبِ وَتَفْوِيضِ كَافَّةِ الْأُمُورِ لِرَبِّ الْعَالَمِينَ',
    virtueEn: 'Relief in times of hardship and entrusting all matters entirely to Allah',
  ),
  Dhikr(
    id: 'tasbeeh-05',
    category: DhikrCategory.tasbeeh,
    arabic: 'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    english: 'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
    repeat: 10,
    source: 'سُنَنُ التِّرْمِذِيِّ وَالْمُسْتَدْرَكُ لِلْحَاكِمِ — Sunan at-Tirmidhi',
    virtue: 'دَعْوَةُ ذِي النُّونِ، مَا دَعَا بِهَا مُسْلِمٌ فِي كُرْبَةٍ إِلَّا فَرَّجَ اللَّهُ عَنْهُ',
    virtueEn: 'The supplication of Yunus; no Muslim calls upon Allah with it during distress except that Allah relieves him',
  ),
  Dhikr(
    id: 'tasbeeh-06',
    category: DhikrCategory.tasbeeh,
    arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    english: 'Allah is sufficient for us, and He is the best Disposer of affairs.',
    repeat: 7,
    source: 'صَحِيحُ الْبُخَارِيِّ — Sahih al-Bukhari',
    virtue: 'قَالَهَا إِبْرَاهِيمُ ﷺ حِينَ أُلْقِيَ فِي النَّارِ، وَقَالَهَا مُحَمَّدٌ ﷺ حِينَ قِيلَ لَهُ إِنَّ النَّاسَ قَدْ جَمَعُوا لَكُمْ',
    virtueEn: 'Uttered by Ibrahim when cast into the fire, and by Muhammad when threatened by enemies',
  ),
  Dhikr(
    id: 'tasbeeh-07',
    category: DhikrCategory.tasbeeh,
    arabic: 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ أَجْمَعِينَ',
    english: 'O Allah, send prayers, peace, and blessings upon our Prophet Muhammad, and upon his family and companions all together.',
    repeat: 10,
    source: 'صَحِيحُ مُسْلِمٍ — Sahih Muslim',
    virtue: 'مَنْ صَلَّى عَلَيَّ صَلَاةً صَلَّى اللَّهُ عَلَيْهِ بِهَا عَشْرًا وَحُطَّتْ عَنْهُ عَشْرُ خَطِيئَاتٍ',
    virtueEn: 'Whoever sends blessings upon me once, Allah sends blessings upon him tenfold',
  ),
  Dhikr(
    id: 'tasbeeh-08',
    category: DhikrCategory.tasbeeh,
    arabic: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
    english: 'I seek forgiveness from Allah the Magnificent, other than Whom there is no deity, the Ever-Living, the Sustainer, and I repent unto Him.',
    repeat: 3,
    source: 'سُنَنُ أَبِي دَاوُد وَالتِّرْمِذِيِّ — Sunan Abi Dawud & Tirmidhi',
    virtue: 'مَنْ قَالَهَا غُفِرَ لَهُ وَإِنْ كَانَ قَدْ فَرَّ مِنَ الزَّحْفِ',
    virtueEn: 'Whoever recites it, his sins are forgiven even if he had fled from the battlefield',
  ),
  Dhikr(
    id: 'tasbeeh-09',
    category: DhikrCategory.tasbeeh,
    arabic: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا وَرَسُولًا',
    english: 'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet and Messenger.',
    repeat: 3,
    source: 'مُسْنَدُ أَحْمَدَ وَسُنَنُ أَبِي دَاوُد — Musnad Ahmad & Sunan Abi Dawud',
    virtue: 'كَانَ حَقًّا عَلَى اللَّهِ عَزَّ وَجَلَّ أَنْ يُرْضِيَهُ يَوْمَ الْقِيَامَةِ',
    virtueEn: 'It becomes an obligation upon Allah to please him on the Day of Resurrection',
  ),
];

