import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/arabic_text_utils.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';

/// شاشة جوامع الذكر، صلاة الاستخارة، أدعية الأنبياء، والأدعية القرآنية الشاملة
class JawamiDhikrScreen extends StatefulWidget {
  const JawamiDhikrScreen({super.key});

  @override
  State<JawamiDhikrScreen> createState() => _JawamiDhikrScreenState();
}

class _JawamiDhikrScreenState extends State<JawamiDhikrScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';

  // قائمة الأذكار والأدعية الشاملة مبوبة حسب التصنيف
  static const List<Map<String, String>> _jawamiList = [
    // ─────────────── صلاة ودعاء الاستخارة ───────────────
    {
      'category': 'istikhara',
      'categoryNameAr': 'صلاة الاستخارة',
      'title': 'دعاء صلاة الاستخارة النبوي الشريف',
      'arabic':
          'اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ، وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ، وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ، فَإِنَّكَ تَقْدِرُ وَلَا أَقْدِرُ، وَتَعْلَمُ وَلَا أَعْلَمُ، وَأَنْتَ عَلَّامُ الْغُيُوبِ، اللَّهُمَّ إِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ (ويسمي حاجته) خَيْرٌ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي - أَوْ قَالَ: عَاجِلِ أَمْرِي وَآجِلِهِ - فَاقْدُرْهُ لِي وَيَسِّرْهُ لِي ثُمَّ بَارِكْ لِي فِيهِ، وَإِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ شَرٌّ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي - أَوْ قَالَ: عَاجِلِ أَمْرِي وَآجِلِهِ - فَاصْرِفْهُ عَنِّي وَاصْرِفْنِي عَنْهُ، وَاقْدُرْ لِيَ الْخَيْرَ حَيْثُ كَانَ ثُمَّ أَرْضِنِي بِهِ.',
      'virtue':
          'كان النبي ﷺ يعلم أصحابه الاستخارة في الأمور كلها كما يعلمهم السورة من القرآن. تُصلى ركعتين من غير الفريضة ثم يُدعى بهذا الدعاء المبارك.',
      'source': 'صحيح البخاري عن جابر بن عبد الله رضي الله عنه',
    },
    {
      'category': 'istikhara',
      'categoryNameAr': 'صلاة الاستخارة',
      'title': 'كيفية صلاة الاستخارة وهديها النبوي',
      'arabic':
          '١. توضأ وضوءك للصلاة.\n٢. انوِ صلاة الاستخارة في الأمر الذي تريده.\n٣. صلِّ ركعتين نافلة، يُقرأ فيهما بالفاتحة وما تيسر.\n٤. بعد التسليم من الصلاة، ارفع يديك واحمد الله وأثنِ عليه وصلِّ على النبي ﷺ.\n٥. اقرأ دعاء الاستخارة، وسمِّ حاجتك عند قوله: (اللهم إن كنت تعلم أن هذا الأمر...).\n٦. امضِ في أمرك مستعيناً بالله ومتوكلاً عليه، فما قدّره الله لك هو الخير التام.',
      'virtue':
          'الاستخارة تسليم كامل وتفويض لعلام الغيوب، وتُريح القلب من الحيرة والتردد.',
      'source': 'بيان السنة النبوية المطهرة',
    },

    // ─────────────── أدعية الأنبياء عليهم السلام ───────────────
    {
      'category': 'prophets',
      'categoryNameAr': 'أدعية الأنبياء',
      'title': 'دعوة ذي النون (يونس عليه السلام) لكشف الكروب',
      'arabic':
          'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      'virtue':
          'دعوة يونس عليه السلام في بطن الحوت؛ قال ﷺ: «لم يدعُ بها رجل مسلم في شيء قط إلا استجاب الله له».',
      'source': 'سورة الأنبياء ٨٧ • سنن الترمذي وصححه الألباني',
    },
    {
      'category': 'prophets',
      'categoryNameAr': 'أدعية الأنبياء',
      'title': 'دعاء موسى عليه السلام لشرح الصدر وتيسير الأمر',
      'arabic':
          'رَبِّ اشْرَحْ لِي صَدْرِي ۝ وَيَسِّرْ لِي أَمْرِي ۝ وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي ۝ يَفْقَهُوا قَوْلِي',
      'virtue':
          'دعاء كليم الله موسى حين كلفه الله بالرسالة؛ مفتاح لكل عسير وسبب لطلاقة اللسان وثبات الجنان.',
      'source': 'سورة طه ٢٥-٢٨',
    },
    {
      'category': 'prophets',
      'categoryNameAr': 'أدعية الأنبياء',
      'title': 'دعاء موسى عليه السلام عند الفقر والحاجة وتيسير الرزق',
      'arabic': 'رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
      'virtue':
          'دعا به موسى عليه السلام لما ورد ماء مدين وهو غريب ومحتاج؛ فرزقه الله المأوى والعمل والزوجة الصالحة.',
      'source': 'سورة القصص ٢٤',
    },
    {
      'category': 'prophets',
      'categoryNameAr': 'أدعية الأنبياء',
      'title': 'دعاء أيوب عليه السلام لطلب الشفاء ودفع البلاء',
      'arabic': 'أَنِّي مَسَّنِيَ الضُّرُّ وَأَنْتَ أَرْحَمُ الرَّاحِمِينَ',
      'virtue':
          'غاية الأدب في مناجاة الله ونسبة الرحمة إليه سبحانه؛ فاستجاب الله له وكشف ما به من ضر.',
      'source': 'سورة الأنبياء ٨٣',
    },
    {
      'category': 'prophets',
      'categoryNameAr': 'أدعية الأنبياء',
      'title': 'دعاء إبراهيم عليه السلام لصلاح الذرية وإقامة الصلاة',
      'arabic':
          'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِنْ ذُرِّيَّتِي ۚ رَبَّنَا وَتَقَبَّلْ دُعَاءِ ۝ رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
      'virtue':
          'دعاء خليل الرحمن إبراهيم عليه السلام؛ سر الثبات على العبادة وبر الوالدين وحفظ الأبناء.',
      'source': 'سورة إبراهيم ٤٠-٤١',
    },
    {
      'category': 'prophets',
      'categoryNameAr': 'أدعية الأنبياء',
      'title': 'دعاء زكريا عليه السلام لطلب الذرية الصالحة وبلوغ الرجاء',
      'arabic':
          'رَبِّ هَبْ لِي مِنْ لَدُنْكَ ذُرِّيَّةً طَيِّبَةً ۖ إِنَّكَ سَمِيعُ الدُّعَاءِ ۝ رَبِّ لَا تَذَرْنِي فَرْدًا وَأَنْتَ خَيْرُ الْوَارِثِينَ',
      'virtue':
          'دعا به نبي الله زكريا وقد اشتعل رأسه شيباً ووهن عظمه؛ فبشره الله بيحيى نبياً كريماً.',
      'source': 'سورة آل عمران ٣٨ • سورة الأنبياء ٨٩',
    },
    {
      'category': 'prophets',
      'categoryNameAr': 'أدعية الأنبياء',
      'title': 'دعاء يوسف عليه السلام للثبات وحسن الخاتمة',
      'arabic':
          'فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ أَنْتَ وَلِيِّي فِي الدُّنْيَا وَالْآخِرَةِ ۖ تَوَفَّنِي مُسْلِمًا وَأَلْحِقْنِي بِالصَّالِحِينَ',
      'virtue':
          'مناجاة الصديق يوسف بعد اكتمال النعمة وجمع الشمل؛ طلباً للوفاة على الإسلام واللحاق بالصالحين.',
      'source': 'سورة يوسف ١٠١',
    },
    {
      'category': 'prophets',
      'categoryNameAr': 'أدعية الأنبياء',
      'title': 'دعاء آدم وحواء طلباً للمغفرة والتوبة',
      'arabic':
          'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
      'virtue':
          'الكلمات التي تلقاها آدم من ربه فتاب عليه، وهي أنفع دعاء عند التوبة والإنابة.',
      'source': 'سورة الأعراف ٢٣',
    },

    // ─────────────── أدعية قرآنية ───────────────
    {
      'category': 'quranic',
      'categoryNameAr': 'أدعية قرآنية',
      'title': 'جامع خيري الدنيا والآخرة والوقاية من النار',
      'arabic':
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      'virtue':
          'أجمع دعاء في القرآن، وكان النبي ﷺ يكثر منه في طوافه وصلاته ومناجاته.',
      'source': 'سورة البقرة ٢٠١',
    },
    {
      'category': 'quranic',
      'categoryNameAr': 'أدعية قرآنية',
      'title': 'دعاء الثبات ونيل الرحمة الربانية',
      'arabic':
          'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً ۚ إِنَّكَ أَنْتَ الْوَهَّابُ',
      'virtue':
          'دعاء الراسخين في العلم، يسألون الله الثبات على الهداية بعد إنعامها.',
      'source': 'سورة آل عمران ٨',
    },
    {
      'category': 'quranic',
      'categoryNameAr': 'أدعية قرآنية',
      'title': 'دعاء قرة الأعين وصلاح الأهل والذرية',
      'arabic':
          'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
      'virtue':
          'دعاء عباد الرحمن؛ يجمع صلاح البيت المسلم والقدوة الحسنة في التقوى.',
      'source': 'سورة الفرقان ٧٤',
    },
    {
      'category': 'quranic',
      'categoryNameAr': 'أدعية قرآنية',
      'title': 'دعاء الصبر والثبات والنصر على الظالمين',
      'arabic':
          'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      'virtue':
          'دعا به طالوت وجنوده الصابرون حين برزوا لجالوت وجنوده، فنصرهم الله.',
      'source': 'سورة البقرة ٢٥٠',
    },
    {
      'category': 'quranic',
      'categoryNameAr': 'أدعية قرآنية',
      'title': 'دعاء سلامة الصدر والمحبة بين المؤمنين',
      'arabic':
          'رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَحِيمٌ',
      'virtue':
          'دعاء الصفاء القلبي وطهارة النفس من الغل والحسد تجاه كل مؤمن.',
      'source': 'سورة الحشر ١٠',
    },
    {
      'category': 'quranic',
      'categoryNameAr': 'أدعية قرآنية',
      'title': 'دعاء شكر النعمة وبر الوالدين وحسن العمل',
      'arabic':
          'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَىٰ وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ وَأَدْخِلْنِي بِرَحْمَتِكَ فِي عِبَادِكَ الصَّالِحِينَ',
      'virtue':
          'دعاء سليمان عليه السلام؛ شكر النعم والتوفيق للأعمال الصالحة المرضية.',
      'source': 'سورة النمل ١٩',
    },

    // ─────────────── جوامع الذكر المأثورة ───────────────
    {
      'category': 'jawami',
      'categoryNameAr': 'جوامع الذكر',
      'title': 'أحب الكلام إلى الله (الباقيات الصالحات)',
      'arabic':
          'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      'virtue':
          'أحب الكلام إلى الله تعالى، وغراس الجنة، ومكفرات للذنوب والخطايا كما تنفض الشجرة ورقها.',
      'source': 'صحيح مسلم ومسند أحمد',
    },
    {
      'category': 'jawami',
      'categoryNameAr': 'جوامع الذكر',
      'title': 'ذكر مضاعفة الحسنات بعدد الخلق',
      'arabic':
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ: عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
      'virtue':
          'قال ﷺ لأم المؤمنين جويرية: «لقد قلت بعدك أربع كلمات ثلاث مرات لو وزنت بما قلت منذ اليوم لوزنتهن».',
      'source': 'صحيح مسلم',
    },
    {
      'category': 'jawami',
      'categoryNameAr': 'جوامع الذكر',
      'title': 'سيد الاستغفار وأعظم توبة',
      'arabic':
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
      'virtue':
          'من قالها موقناً بها حين يمسي فمات دخل الجنة، ومن قالها موقناً بها حين يصبح فمات دخل الجنة.',
      'source': 'صحيح البخاري',
    },
    {
      'category': 'jawami',
      'categoryNameAr': 'جوامع الذكر',
      'title': 'كنز من تحت عرش الرحمن',
      'arabic': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      'virtue':
          'كنز من كنوز الجنة وباب من أبوابها، واستسلام وتفويض مطلق لقدرة الله وقوته.',
      'source': 'صحيح البخاري ومسلم',
    },
  ];

  static const List<({String key, String titleAr, String titleEn, IconData icon})> _categories = [
    (key: 'all', titleAr: 'الكل', titleEn: 'All', icon: Icons.all_inclusive_rounded),
    (key: 'istikhara', titleAr: 'صلاة الاستخارة', titleEn: 'Istikhara', icon: Icons.explore_rounded),
    (key: 'prophets', titleAr: 'أدعية الأنبياء', titleEn: 'Prophets', icon: Icons.stars_rounded),
    (key: 'quranic', titleAr: 'أدعية قرآنية', titleEn: 'Quranic Duas', icon: Icons.menu_book_rounded),
    (key: 'jawami', titleAr: 'جوامع الذكر', titleEn: 'Comprehensive', icon: Icons.auto_awesome_rounded),
  ];

  Map<String, int> get _categoryCounts {
    final m = <String, int>{};
    for (final d in _jawamiList) {
      final c = d['category'] ?? '';
      m[c] = (m[c] ?? 0) + 1;
    }
    m['all'] = _jawamiList.length;
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _jawamiList.where((item) {
      final matchesCat = _selectedCategory == 'all' || item['category'] == _selectedCategory;
      if (!matchesCat) return false;

      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final title = item['title']?.toLowerCase() ?? '';
      final text = item['arabic']?.toLowerCase() ?? '';
      final virtue = item['virtue']?.toLowerCase() ?? '';
      return title.contains(q) || text.contains(q) || virtue.contains(q);
    }).toList();

    const emerald = Color(0xFF1E5243);
    const gold = Color(0xFFD4AF37);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0D1411) : const Color(0xFFFAF8F5),
        appBar: AppBar(
          backgroundColor: dark ? const Color(0xFF101C17) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isAr ? 'جوامع الذكر وصلاة الاستخارة' : "Jawami' Dhikr & Istikhara",
            style: const TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                children: [
                  // شريط البحث المريح
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontFamily: DhikrTheme.arabicFont, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: isAr ? 'ابحث في الأدعية وجوامع الذكر...' : 'Search supplications...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // شريط تصنيفات الأدعية (Chips مع عداد)
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSelected = _selectedCategory == cat.key;
                        final count = _categoryCounts[cat.key] ?? 0;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : (dark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAr ? cat.titleAr : cat.titleEn,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (dark
                                            ? DhikrColors.darkText
                                            : DhikrColors.charcoal),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? gold.withValues(alpha: 0.28)
                                      : (dark
                                            ? Colors.white.withValues(
                                                alpha: 0.08)
                                            : emerald.withValues(alpha: 0.08)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : (dark
                                              ? Colors.white70
                                              : emerald),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: emerald,
                          backgroundColor:
                              dark ? const Color(0xFF101C17) : Colors.white,
                          elevation: isSelected ? 3 : 0,
                          pressElevation: 0,
                          side: BorderSide(
                            color: isSelected
                                ? gold.withValues(alpha: 0.7)
                                : (dark
                                      ? Colors.white12
                                      : DhikrColors.charcoal.withValues(
                                          alpha: 0.12)),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = cat.key);
                            }
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // قائمة الأذكار المعروضة
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              isAr ? 'لم يتم العثور على نتائج' : 'No supplications found',
                              style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: dark ? const Color(0xFF131E19) : Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: dark
                                        ? emerald.withValues(alpha: 0.3)
                                        : DhikrColors.forest.withValues(alpha: 0.12),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: dark ? 0.3 : 0.04),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // العنوان + نسخ
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ArabicTextUtils.stripTashkeel(
                                                item['title'] ?? ''),
                                            style: TextStyle(
                                              fontFamily: DhikrTheme.arabicFont,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14.5,
                                              color: dark ? gold : DhikrColors.forest,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 18),
                                          color: dark ? Colors.white60 : Colors.black45,
                                          tooltip: isAr ? 'نسخ الدعاء' : 'Copy',
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            Clipboard.setData(ClipboardData(
                                              text: '${item['title']}\n\n${item['arabic']}\n\nالمصدر: ${item['source']}',
                                            ));
                                            AppToast.show(context, 
                                              SnackBar(
                                                content: Text(isAr ? 'تم نسخ الدعاء بنجاح' : 'Copied to clipboard'),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    // متن الدعاء بدون تشكيل — محاذاة يمين لتفادي فراغات الـ justify
                                    Text(
                                      ArabicTextUtils.stripTashkeel(
                                          item['arabic'] ?? ''),
                                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        height: 1.9,
                                        color: dark ? Colors.white : const Color(0xFF1B241E),
                                      ),
                                    ),

                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),

                                    // الفضل والمصدر
                                    if (item['virtue'] != null && item['virtue']!.isNotEmpty) ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 16, color: gold),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              ArabicTextUtils.stripTashkeel(
                                                  item['virtue']!),
                                              style: TextStyle(
                                                fontFamily: DhikrTheme.arabicFont,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                height: 1.6,
                                                color: dark ? Colors.white70 : const Color(0xFF4A5550),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                    ],

                                    Row(
                                      children: [
                                        const Icon(Icons.menu_book_rounded, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item['source'] ?? '',
                                            style: TextStyle(
                                              fontFamily: DhikrTheme.arabicFont,
                                              fontSize: 11,
                                              color: dark ? Colors.white54 : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // شارة التصنيف في آخر الكارت تحت
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: isAr
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: emerald.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: emerald.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          item['categoryNameAr'] ?? 'ذكر',
                                          style: const TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: emerald,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
