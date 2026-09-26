import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../services/haptics.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import 'in_app_player_screen.dart';

/// Unified model for Hajj and Umrah Ritual steps
class RitualStep {
  const RitualStep({
    required this.id,
    required this.dayTitle,
    required this.title,
    required this.timing,
    required this.summary,
    required this.details,
    required this.duas,
    required this.sunnahs,
    required this.icon,
    this.badgeColor,
  });

  final String id;
  final String dayTitle;
  final String title;
  final String timing;
  final String summary;
  final String details;
  final List<String> duas;
  final List<String> sunnahs;
  final IconData icon;
  final Color? badgeColor;
}

/// Comprehensive Hajj & Umrah Screen
class HajjUmrahScreen extends StatefulWidget {
  const HajjUmrahScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<HajjUmrahScreen> createState() => _HajjUmrahScreenState();
}

class _HajjUmrahScreenState extends State<HajjUmrahScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tawaf / Sa'i Counter State
  int _counterType = 0; // 0 = Tawaf (7), 1 = Sa'i (7)
  int _currentLap = 1;
  final Set<int> _completedLaps = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ══════════════════ DATA: HAJJ DAYS ══════════════════
  static const List<RitualStep> hajjSteps = [
    RitualStep(
      id: 'hajj_tarwiyah',
      dayTitle: 'اليوم الأول: ٨ ذو الحجة',
      title: 'يوم التروية — الإحرام والتوجه إلى منى',
      timing: 'صباح اليوم الثامن من ذي الحجة',
      summary: 'الإحرام بالحج من مكان إقامتك بمكة والتوجه إلى منى للمبيت بها.',
      details:
          'يغتسل الحاج ويتطيب في بدنه دون ثياب إحرامه، ويلبس إزاراً ورداءً أبيضين نظيفين، ثم ينوي قائلاً: "لبيك حجاً" أو "لبيك اللهم حجاً". ينطلق الحاج إلى مشعر منى ضحى، ويصلي بها الظهر والعصر والمغرب والعشاء وفجر يوم عرفة، كل صلاة في وقتها قصراً للرباعية ركعتين دون جمع.',
      sunnahs: [
        'المبيت بمشعر منى ليلة التاسع من ذي الحجة سنة مؤكدة عن النبي ﷺ.',
        'الإكثار من التلبية بصوت مرتفع للرجال وخافت للنساء حتى رمي جمرة العقبة.',
        'قصر الصلاة الرباعية إلى ركعتين دون جمع الصلوات.',
      ],
      duas: [
        'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الحَمْدَ وَالنِّعْمَةَ لَكَ وَالمُلْكَ، لا شَرِيكَ لَكَ.',
        'اللَّهُمَّ هَذِهِ حَجَّةٌ لا رِيَاءَ فِيهَا وَلا سُمْعَةَ.',
      ],
      icon: LucideIcons.tent,
      badgeColor: Color(0xFF10B981),
    ),
    RitualStep(
      id: 'hajj_arafat',
      dayTitle: 'اليوم الثاني: ٩ ذو الحجة',
      title: 'يوم عرفة — الركن الأعظم للحج',
      timing: 'من زوال شمس يوم ٩ إلى مغربها',
      summary: 'الوقوف بعرفة، وصلاة الظهر والعصر جمعاً وقصراً، والتفرغ التام للدعاء والضراعة.',
      details:
          'بعد طلوع شمس يوم التاسع ينطلق الحاج إلى عرفة ويستحب النزول بنمرة حتى الزوال إن تيسر. بعد الزوال يستمع الحاج لخطبة عرفة ويصلي الظهر والعصر جمع تقديم وقصراً بأذان وإقامتين. ثم يتفرغ داخل حدود عرفة للدعاء والذكر والتضرع والاستغفار إلى غروب الشمس. قال رسول الله ﷺ: "الحَجُّ عَرَفَةُ".',
      sunnahs: [
        'استقبال القبلة ورفع اليدين والإلحاح بالدعاء متخشعاً طوال العصر.',
        'التأكد من التواجد التام داخل حدود مشعر عرفات المعلومة باللوحات.',
        'عدم مغادرة عرفات إطلاقاً قبل غروب الشمس بمغيب القرص تماماً.',
      ],
      duas: [
        'لا إِلَهَ إِلا اللَّهُ وَحْدَهُ لا شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. (خير الدعاء)',
        'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ العَفْوَ فَاعْفُ عَنِّي، رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.',
      ],
      icon: LucideIcons.sun,
      badgeColor: Color(0xFFF59E0B),
    ),
    RitualStep(
      id: 'hajj_muzdalifah',
      dayTitle: 'ليلة ١٠ ذو الحجة',
      title: 'المبيت بمزدلفة والمشعر الحرام',
      timing: 'بعد غروب شمس يوم عرفة حتى فجر العيد',
      summary: 'النفرة بسكينة إلى مزدلفة، وصلاة المغرب والعشاء جمع تأخير، والمبيت وجمع الحصى.',
      details:
          'بعد غروب شمس عرفة ينفر الحجاج بسكينة ووقار ملبين إلى مزدلفة. وفور الوصول يصلي الحاج المغرب ثلاث ركعات والعشاء ركعتين جمع تأخير بأذان واحد وإقامتين قبل حط الرحال. ثم يبيت بمزدلفة حتى يصلي فجر يوم النحر، ويقف عند المشعر الحرام داعياً حتى يسفر الفجر جداً. ويجوز للضعفاء والنساء الدفع بعد منتصف الليل.',
      sunnahs: [
        'النفرة بسكينة وهدوء وتجنب التزاحم تأسياً بالنبي ﷺ: "السكينةَ السكينةَ".',
        'المبيت بمزدلفة حتى الفجر، والوقوف عند المشعر الحرام والدعاء إلى الإسفار.',
        'التقاط ٧ حصيات بحجم حبة الحمص لجمرة العقبة الكبرى.',
      ],
      duas: [
        '﴿فَإِذَا أَفَضْتُم مِّنْ عَرَفَاتٍ فَاذْكُرُوا اللَّهَ عِندَ الْمَشْعَرِ الْحَرَامِ وَاذْكُرُوهُ كَمَا هَدَاكُمْ﴾',
        'اللَّهُمَّ كَمَا أَوْقَفْتَنَا فِيهِ وَأَرَيْتَنَا إِيَّاهُ فَوَفِّقْنَا لِذِكْرِكَ كَمَا هَدَيْتَنَا، وَاغْفِرْ لَنَا وَارْحَمْنَا.',
      ],
      icon: LucideIcons.moon,
      badgeColor: Color(0xFF6366F1),
    ),
    RitualStep(
      id: 'hajj_nahr',
      dayTitle: 'اليوم الثالث: ١٠ ذو الحجة',
      title: 'يوم النحر — يوم الحج الأكبر',
      timing: 'يوم عيد الأضحى المبارك',
      summary: 'رمي جمرة العقبة، ذبح الهدي، الحلق والتقصير (التحلل الأول)، وطواف الإفاضة والسعي (التحلل الأكبر).',
      details:
          'يتوجه الحاج من مزدلفة إلى منى صباح يوم النحر ويقوم بالأعمال الأربعة الآتية مرتبة:\n'
          '١) رمي جمرة العقبة الكبرى: بسبع حصيات متعاقبة يكبر مع كل حصاة، ويقطع التلبية مع أول حصاة.\n'
          '٢) ذبح الهدي: للمتمتع والقارن.\n'
          '٣) الحلق أو التقصير: الحلق أفضل للرجال بالموس، والمرأة تقص قدر أنملة (٢ سم) من جميع ضفائرها. وبذلك يحصل التحلل الأول (الأصغر) فيحل له كل محظور إلا النساء.\n'
          '٤) طواف الإفاضة والسعي: يتوجه لمكة ليطوف طواف الإفاضة ٧ أشواط ويسعى ٧ أشواط. وبذلك يحصل التحلل الثاني (الأكبر) ويحل له كل شيء.',
      sunnahs: [
        'التكبير مع كل حصاة: "الله أكبر رغماً للشيطان وحزبه".',
        'الحلق بالموسى للرجال؛ لدعاء النبي ﷺ للمحلقين ثلاثاً وللمقصرين واحدة.',
        'الشرب من ماء زمزم والتضلع منه والدعاء بما تيسر بعد الطواف.',
      ],
      duas: [
        'بِسْمِ اللَّهِ، وَاللَّهُ أَكْبَرُ، رَغْماً لِلشَّيْطَانِ وَحِزْبِهِ وَرِضاً لِلرَّحْمَنِ.',
        'اللَّهُمَّ اجْعَلْهُ حَجّاً مَبْرُوراً، وَذَنْباً مَغْفُوراً، وَسَعْياً مَشْكُوراً.',
      ],
      icon: LucideIcons.sparkles,
      badgeColor: Color(0xFFEF4444),
    ),
    RitualStep(
      id: 'hajj_tashreeq',
      dayTitle: 'أيام التشريق: ١١، ١٢، ١٣ ذو الحجة',
      title: 'رمي الجمرات الثلاث والمبيت بمنى',
      timing: 'بعد زوال الشمس في كل يوم من أيام التشريق',
      summary: 'المبيت بمنى ليالي التشريق ورمي الجمرات الثلاث (الصغرى، الوسطى، الكبرى) بعد أذان الظهر.',
      details:
          'يبيت الحاج ليالي أيام التشريق بمنى. وفي كل يوم بعد زوال الشمس (أذان الظهر) يرمي الجمرات الثلاث على الترتيب:\n'
          '• الجمرة الأولى (الصغرى): ٧ حصيات مع التكبير، ثم يتقدم ويدعو طويلاً رافعاً يديه.\n'
          '• الجمرة الثانية (الوسطى): ٧ حصيات مع التكبير، ثم يتقدم ذات الشمال ويدعو طويلاً.\n'
          '• جمرة العقبة (الكبرى): ٧ حصيات مع التكبير، ويمضي ولا يقف عندها للدعاء.\n\n'
          'التعجل: يجوز للحاج أن يتعجل في يومين فيغادر منى في اليوم الثاني عشر قبل غروب الشمس ﴿فَمَن تَعَجَّلَ فِي يَوْمَيْنِ فَلَا إِثْمَ عَلَيْهِ وَمَن تَأَخَّرَ فَلَا إِثْمَ عَلَيْهِ لِمَنِ اتَّقَىٰ﴾.',
      sunnahs: [
        'الرمي بعد الزوال ولا يصح قبله عند جمهور العلماء في أيام التشريق.',
        'إطالة الدعاء بعد الجمرتين الأولى والثانية مستقبلاً القبلة بخشوع.',
        'الخروج من منى قبل مغيب شمس اليوم الثاني عشر لمن أراد التعجل.',
      ],
      duas: [
        'اللَّهُمَّ اجْعَلْهُ حَجّاً مَبْرُوراً وَذَنْباً مَغْفُوراً وَتِجَارَةً لَنْ تَبُورَ.',
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.',
      ],
      icon: LucideIcons.flame,
      badgeColor: Color(0xFF8B5CF6),
    ),
    RitualStep(
      id: 'hajj_wadaa',
      dayTitle: 'خاتمة الحج',
      title: 'طواف الوداع بمكة المكرمة',
      timing: 'قبيل السفر ومغادرة مكة المكرمة مباشرة',
      summary: 'الطواف بالبيت العتيق سبعة أشواط ليكون آخر عهد الحاج بالبيت.',
      details:
          'عندما يعزم الحاج على مغادرة مكة عائداً إلى بلده، يجب عليه أن يطوف بالبيت سبعة أشواط طواف الوداع، دون سعي بعده، ويصلي ركعتي الطواف ثم يغادر فوراً.\n'
          'وقد خفف الله عز وجل عن المرأة الحائض والنفساء فيسقط عنها طواف الوداع ولا فدية عليها لحديث ابن عباس: "أُمِرَ الناسُ أن يكون آخرُ عهدهم بالبيت، إلا أنه خُفِّفَ عن الحائض".',
      sunnahs: [
        'أن يكون الطواف آخر شيء يفعله الحاج بمكة قبل ركوب وسيلة السفر.',
        'صلاة ركعتين خلف مقام إبراهيم والشرب من ماء زمزم بنية الشفاء والبركة.',
      ],
      duas: [
        'اللَّهُمَّ البَيْتُ بَيْتُكَ، وَالعَبْدُ عَبْدُكَ، وَابْنُ عَبْدِكَ، حَمَلْتَنِي عَلَى مَا سَخَّرْتَ لِي مِنْ خَلْقِكَ، حَتَّى سَيَّرْتَنِي إِلَى بِلادِكَ، وَبَلَّغْتَنِي بِنِعْمَتِكَ حَتَّى أَعَنْتَنِي عَلَى قَضَاءِ مَنَاسِكِي.',
        'اللَّهُمَّ لا تَجْعَلْ هَذَا آخِرَ العَهْدِ بِبَيْتِكَ الحَرَامِ، وَإِنْ جَعَلْتَهُ فَاجْعَلْنِي مَرْحُوماً وَلا تَجْعَلْنِي مَحْرُوماً.',
      ],
      icon: LucideIcons.flag,
      badgeColor: Color(0xFF0EA5E9),
    ),
  ];

  // ══════════════════ DATA: UMRAH STEPS ══════════════════
  static const List<RitualStep> umrahSteps = [
    RitualStep(
      id: 'u_ihram',
      dayTitle: 'الخطوة الأولى',
      title: 'الإحرام من الميقات',
      timing: 'عند محاذاة الميقات أو المطار',
      summary: 'نية الدخول في النسك، الاغتسال، ولبس ثياب الإحرام والتلبية.',
      details:
          'يستحب الاغتسال والتطيب في البدن والتجرد من المخيط للرجال ولبس إزار ورداء أبيضين نظيفين، وتلبس المرأة لباسها الشرعي الساتر دون نقاب أو قفازين. ثم ينوي بقلبه ويلبي بلسانه: "لبيك اللهم عمرة". ويبقى يلبي حتى يرى الكعبة المشرفة.',
      sunnahs: [
        'الاغتسال والتنظف وقص الشارب والأظافر قبل الإحرام.',
        'الاستمرار بالتلبية ورفع الصوت بها للرجال حتى بداية الطواف.',
      ],
      duas: [
        'لَبَّيْكَ اللَّهُمَّ عُمْرَةً، لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لا شَرِيكَ لَكَ لَبَّيْكَ.',
      ],
      icon: LucideIcons.shirt,
      badgeColor: Color(0xFF10B981),
    ),
    RitualStep(
      id: 'u_tawaf',
      dayTitle: 'الخطوة الثانية',
      title: 'طواف العمرة ٧ أشواط بالبيت',
      timing: 'عند دخول المسجد الحرام',
      summary: 'الطواف حول الكعبة المشرفة ٧ أشواط يبدأ بالحجر الأسود وينتهي عنده.',
      details:
          'يدخل المسجد الحرام مقدماً رجله اليمنى قائلاً دعاء دخول المسجد. يضطبع الرجل بجعل رداءه تحت إبطه الأيمن وكاشفاً كتفه. يبدأ الطواف من محاذاة الحجر الأسود مستقبلاً له بالتكبير "بسم الله والله أكبر"، ويطوف ٧ أشواط جاعلاً الكعبة عن يساره، ويرمل (يسرع في المشي) في الأشواط الثلاثة الأولى. ويستلم الركن اليماني دون تقبيل.',
      sunnahs: [
        'الاضطباع للرجال في طواف القدوم والعمرة كاملاً.',
        'الرَمَل (سرعة المشي مع مقاربة الخطى) في الأشواط الثلاثة الأولى للرجال فقط.',
        'صلاة ركعتين خلف مقام إبراهيم عليه السلام، ثم الشرب من زمزم.',
      ],
      duas: [
        'بِسْمِ اللَّهِ وَاللَّهُ أَكْبَرُ، اللَّهُمَّ إِيمَاناً بِكَ، وَتَصْدِيقاً بِكِتَابِكَ، وَوَفَاءً بِعَهْدِكَ، وَاتِّبَاعاً لِسُنَّةِ نَبِيِّكَ مُحَمَّدٍ ﷺ.',
        'بين الركن اليماني والحجر الأسود: ﴿رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ﴾.',
      ],
      icon: LucideIcons.rotateCw,
      badgeColor: Color(0xFF0284C7),
    ),
    RitualStep(
      id: 'u_saee',
      dayTitle: 'الخطوة الثالثة',
      title: 'السعي بين الصفا والمروة ٧ أشواط',
      timing: 'بعد الفراغ من الطواف وركعتيه',
      summary: 'السعي ٧ أشواط يبدأ بجبل الصفا وينتهي بجبل المروة.',
      details:
          'يتوجه إلى الصفا ويقرأ: ﴿إِنَّ الصَّفَا وَالْمَرْوَةَ مِن شَعَائِرِ اللَّهِ﴾ ثم يرقى الصفا ويستقبل القبلة ويوحد الله ويكبره ثلاثاً ويدعو بما شاء. يسعى باتجاه المروة (شوط ١)، ويهرول الرجال بين العلمين الأخضرين. وعند الوصول للمروة يدعو كما دعا على الصفا، ثم يعود للصفا (شوط ٢)، حتى يكمل ٧ أشواط منتهياً بالمروة.',
      sunnahs: [
        'الرقي على جبلي الصفا والمروة واستقبال القبلة ورفع اليدين للدعاء ثلاث مرات.',
        'الهرولة والسرعة بين الضوئين الأخضرين للرجال فقط دون النساء.',
      ],
      duas: [
        'اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، لا إِلَهَ إِلا اللَّهُ وَحْدَهُ لا شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ يُحْيِي وَيُمِيتُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، أَنْجَزَ وَعْدَهُ وَنَصَرَ عَبْدَهُ وَهَزَمَ الأَحْزَابَ وَحْدَهُ.',
        'رَبِّ اغْفِرْ وَارْحَمْ وَأَنْتَ الأَعَزُّ الأَكْرَمُ.',
      ],
      icon: LucideIcons.footprints,
      badgeColor: Color(0xFFF59E0B),
    ),
    RitualStep(
      id: 'u_halq',
      dayTitle: 'الخطوة الرابعة',
      title: 'الحلق أو التقصير والتحلل التام',
      timing: 'بعد إتمام الشوط السابع على المروة',
      summary: 'حلق شعر الرأس أو تقصيره، وبه تتم العمرة ويتحلل المحرم تحللاً كاملاً.',
      details:
          'بعد إتمام السعي على المروة، يحلق الرجل رأسه بالموسى وهو الأفضل لنيله دعوة النبي ﷺ بالرحمة ثلاثاً، أو يقصر من جميع شعر رأسه. أما المرأة فتقص من أطراف شعرها قدر أنملة الأصبع (٢ سم) ولا تحلق. وبذلك تنتهي العمرة ويتحلل المحرم من جميع محظورات الإحرام.',
      sunnahs: [
        'الحلق للرجال أفضل من التقصير اقتداءً بالسنة النبوية الشريفة.',
        'أن يستوعب التقصير جميع جوانب الرأس.',
      ],
      duas: [
        'اللَّهُمَّ اثْبُتْ لِي بِكُلِّ شَعْرَةٍ حَسَنَةً، وَامْحُ عَنِّي بِهَا سَيِّئَةً، وَارْفَعْ لِي بِهَا دَرَجَةً.',
        'الحَمْدُ لِلَّهِ الَّذِي قَضَى عَنَّا نُسُكَنَا وَتَقَبَّلَ مِنَّا بِفَضْلِهِ وَرَحْمَتِهِ.',
      ],
      icon: LucideIcons.scissors,
      badgeColor: Color(0xFF10B981),
    ),
  ];

  // ══════════════════ DATA: TAWAF & SA'I DUAS PER LAP ══════════════════
  static const List<String> tawafDuas = [
    'الشوط الأول: بِسْمِ اللَّهِ وَاللَّهُ أَكْبَرُ، اللَّهُمَّ إِيمَاناً بِكَ، وَتَصْدِيقاً بِكِتَابِكَ، وَوَفَاءً بِعَهْدِكَ، وَاتِّبَاعاً لِسُنَّةِ نَبِيِّكَ مُحَمَّدٍ ﷺ.\n﴿رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ﴾.',
    'الشوط الثاني: اللَّهُمَّ إِنَّ هَذَا البَيْتَ بَيْتُكَ، وَالحَرَمَ حَرَمُكَ، وَالأَمْنَ أَمْنُكَ، وَهَذَا مَقَامُ العَائِذِ بِكَ مِنَ النَّارِ، فَحَرِّمْ لُحُومَنَا وَبَشَرَتَنَا عَلَى النَّارِ.\n﴿رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ﴾.',
    'الشوط الثالث: اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الشَّكِّ وَالشِّرْكِ وَالشِّقَاقِ وَالنِّفَاقِ وَسُوءِ الأَخْلاقِ، وَسُوءِ المُنْقَلَبِ فِي المَالِ وَالأَهْلِ وَالوَلَدِ.\n﴿رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ﴾.',
    'الشوط الرابع: اللَّهُمَّ اجْعَلْهُ حَجّاً مَبْرُوراً، وَسَعْياً مَشْكُوراً، وَذَنْباً مَغْفُوراً، وَعَمَلاً صَالِحاً مَقْبُولاً، وَتِجَارَةً لَنْ تَبُورَ، يَا عَالِمَ مَا فِي الصُّدُورِ أَخْرِجْنِي مِنَ الظُّلُمَاتِ إِلَى النُّورِ.',
    'الشوط الخامس: اللَّهُمَّ أَظِلَّنِي تَحْتَ ظِلِّ عَرْشِكَ يَوْمَ لا ظِلَّ إِلا ظِلُّكَ، وَاسْقِنِي مِنْ حَوْضِ نَبِيِّكَ مُحَمَّدٍ ﷺ شَرْبَةً هَنِيئَةً لا أَظْمَأُ بَعْدَهَا أَبَداً.',
    'الشوط السادس: اللَّهُمَّ إِنَّ لَكَ عَلَيَّ حُقُوقاً كَثِيرَةً فِيمَا بَيْنِي وَبَيْنَكَ، وَحُقُوقاً كَثِيرَةً فِيمَا بَيْنِي وَبَيْنَ خَلْقِكَ، فَمَا كَانَ لَكَ مِنْهَا فَاغْفِرْهُ لِي، وَمَا كَانَ لِخَلْقِكَ فَتَحَمَّلْهُ عَنِّي.',
    'الشوط السابع: اللَّهُمَّ إِنِّي أَسْأَلُكَ إِيمَاناً كَامِلاً، وَيَقِيناً صَادِقاً، وَرِزْقاً وَاسِعاً، وَقَلْباً خَاشِعاً، وَلِسَاناً ذَاكِراً، وَحَلالاً طَيِّباً، وَتَوْبَةً نَصُوحاً قَبْلَ المَوْتِ، وَرَاحَةً عِنْدَ المَوْتِ، وَمَغْفِرَةً وَرَحْمَةً بَعْدَ المَوْتِ.',
  ];

  static const List<String> saeeDuas = [
    'الشوط الأول (من الصفا إلى المروة):\n﴿إِنَّ الصَّفَا وَالْمَرْوَةَ مِن شَعَائِرِ اللَّهِ﴾، نَبْدَأُ بِمَا بَدَأَ اللَّهُ بِهِ. اللَّهُ أَكْبَرُ كَبِيراً، وَالحَمْدُ لِلَّهِ كَثِيراً، لا إِلَهَ إِلا اللَّهُ وَحْدَهُ أَنْجَزَ وَعْدَهُ وَنَصَرَ عَبْدَهُ وَهَزَمَ الأَحْزَابَ وَحْدَهُ.',
    'الشوط الثاني (من المروة إلى الصفا):\nرَبِّ اغْفِرْ وَارْحَمْ، وَاعْفُ عَمَّا تَعْلَمْ، وَأَنْتَ الأَعَزُّ الأَكْرَمُ. اللَّهُمَّ آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.',
    'الشوط الثالث (من الصفا إلى المروة):\nاللَّهُمَّ إِنِّي أَسْأَلُكَ مُوجِبَاتِ رَحْمَتِكَ، وَعَزَائِمَ مَغْفِرَتِكَ، وَالسَّلامَةَ مِنْ كُلِّ إِثْمٍ، وَالغَنِيمَةَ مِنْ كُلِّ بِرٍّ، وَالفَوْزَ بِالجَنَّةِ، وَالنَّجَاةَ مِنَ النَّارِ.',
    'الشوط الرابع (من المروة إلى الصفا):\nاللَّهُمَّ يَا مُقَلِّبَ القُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الهُدَى وَالتُّقَى وَالعَفَافَ وَالغِنَى، وَأَعُوذُ بِكَ مِنْ زَوَالِ نِعْمَتِكَ وَتَحَوُّلِ عَافِيَتِكَ.',
    'الشوط الخامس (من الصفا إلى المروة):\nاللَّهُمَّ حَبِّبْ إِلَيْنَا الإِيمَانَ وَزَيِّنْهُ فِي قُلُوبِنَا، وَكَرِّهْ إِلَيْنَا الكُفْرَ وَالفُسُوقَ وَالعِصْيَانَ، وَاجْعَلْنَا مِنَ الرَّاشِدِينَ.',
    'الشوط السادس (من المروة إلى الصفا):\nاللَّهُمَّ اعْصِمْنَا بِدِينِكَ، وَطَوَاعِيَةِ رَسُولِكَ ﷺ، وَجَنِّبْنَا حُدُودَكَ. اللَّهُمَّ اجْعَلْنَا نُحِبُّكَ وَنُحِبُّ مَلائِكَتَكَ وَأَنْبِيَاءَكَ وَرُسُلَكَ وَعِبَادَكَ الصَّالِحِينَ.',
    'الشوط السابع (من الصفا إلى المروة - ختام السعي):\nاللَّهُمَّ يَسِّرْنَا لِلْيُسْرَى، وَجَنِّبْنَا العُسْرَى، وَاغْفِرْ لَنَا فِي الآخِرَةِ وَالأُولَى. الحَمْدُ لِلَّهِ الَّذِي هَدَانَا لِهَذَا وَمَا كُنَّا لِنَهْتَدِيَ لَوْلا أَنْ هَدَانَا اللَّهُ.',
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = lang == AppLanguage.arabic;

    return Scaffold(
      backgroundColor: dark ? DhikrColors.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isAr ? 'مناسك الحج والعمرة' : 'Hajj & Umrah Guide',
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _HajjTabsChipBar(
            tabController: _tabController,
            isAr: isAr,
            dark: dark,
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildStepsList(umrahSteps, isAr, dark, isHajj: false),
            _buildStepsList(hajjSteps, isAr, dark, isHajj: true),
            _buildInteractiveVideos(isAr, dark),
            _buildTawafCounter(isAr, dark),
            _buildPillarsAndRules(isAr, dark),
          ],
        ),
      ),
    );
  }

  // ══════════════════ TAB: INTERACTIVE VIDEOS ══════════════════
  Widget _buildInteractiveVideos(bool isAr, bool dark) {
    const videos = [
      {
        'title': 'مناسك العمرة خطوة بخطوة — الدليل التفاعلي الموثق',
        'desc': 'شرح مرئي كامل ومعتمد من منصة نُسك لكيفية أداء مناسك العمرة من الميقات والإحرام إلى الحلق والتحلل.',
        'duration': '12 دقيقة',
        'videoId': '5eVdlD1Fs_8',
        'url': 'https://www.youtube.com/watch?v=5eVdlD1Fs_8',
        'tag': 'عمرة معتمدة',
        'source': 'منصة نُسك — وزارة الحج والعمرة',
        'color': Color(0xFF0284C7),
      },
      {
        'title': 'مناسك الحج مفصلة بالرسوم التوضيحية',
        'desc': 'شرح أعمال أيام الحج بالتفصيل: يوم التروية، عرفة، مزدلفة، أعمال النحر، وأيام التشريق، وطواف الوداع.',
        'duration': '20 دقيقة',
        'videoId': 'm_FN8JYVfvI',
        'url': 'https://www.youtube.com/watch?v=m_FN8JYVfvI',
        'tag': 'حج خطوة بخطوة',
        'source': 'دليل ضيوف الرحمن',
        'color': Color(0xFF10B981),
      },
      {
        'title': 'صفة الطواف حول الكعبة والسعي عملياً',
        'desc': 'بيان عملي وسهل لأشواط الطواف السبعة، سنن مقام إبراهيم، والسعي بين الصفا والمروة والأدعية المأثورة.',
        'duration': '14 دقيقة',
        'videoId': 'bmyOs-Ba7rI',
        'url': 'https://www.youtube.com/watch?v=bmyOs-Ba7rI',
        'tag': 'الطواف والسعي',
        'source': 'الإرشاد الديني بالحرمين',
        'color': Color(0xFFF59E0B),
      },
      {
        'title': 'فيلم تعليمي: صفة العمرة من النية إلى تمامها',
        'desc': 'مقطع وثائقي تعليمي معتمد ومصور من داخل الحرم المكي الشريف يوضح السنن والواجبات بدقة.',
        'duration': '9 دقائق',
        'videoId': 'gDdOgAtajn0',
        'url': 'https://www.youtube.com/watch?v=gDdOgAtajn0',
        'tag': 'فيلم تعليمي',
        'source': 'الهيئة العامة للعناية بشؤون الحرمين',
        'color': Color(0xFF8B5CF6),
      },
      {
        'title': 'يوم النحر وأعمال منى ورمي الجمرات',
        'desc': 'شرح دقيق لرمي جمرة العقبة، ذبح الهدي، التحلل الأول والأكبر، والمبيت بمنى وأيام التشريق.',
        'duration': '11 دقيقة',
        'videoId': 'ZiZN02nPv5o',
        'url': 'https://www.youtube.com/watch?v=ZiZN02nPv5o',
        'tag': 'مشاعر منى',
        'source': 'التوعية الإسلامية للحج',
        'color': Color(0xFF14B8A6),
      },
      {
        'title': 'أخطاء شائعة في الحج والعمرة والتحذير منها',
        'desc': 'تنبيهات هامة وفتاوى معتمدة لتجنب المخالفات في الإحرام والطواف والسعي والرمي لضمان صحة النسك.',
        'duration': '16 دقيقة',
        'videoId': 'ksORhqymU_E',
        'url': 'https://www.youtube.com/watch?v=ksORhqymU_E',
        'tag': 'تنبيهات وفتاوى',
        'source': 'إرشاد السائلين',
        'color': Color(0xFFE11D48),
      },
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Intro Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3B2C), Color(0xFF1E5B45)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F3B2C).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.video, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'المكتبة المرئية التفاعلية' : 'Interactive Video Library',
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAr
                          ? 'شروح رسمية موثقة من وزارة الحج والعمرة ورئاسة شؤون الحرمين'
                          : 'Official verified guides from Ministry of Hajj & Two Holy Mosques',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        ...videos.map((v) {
          final color = v['color'] as Color;
          final videoId = v['videoId'] as String;
          final source = v['source'] as String;
          final duration = v['duration'] as String;
          final title = v['title'] as String;
          final desc = v['desc'] as String;
          final tag = v['tag'] as String;
          final url = v['url'] as String;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: dark ? DhikrColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // YouTube Thumbnail with overlay and Play button
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      playYoutubeInFrame(
                        context,
                        url: url,
                        title: title,
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: dark
                                      ? [const Color(0xFF16382E), const Color(0xFF0F2620)]
                                      : [const Color(0xFF1E5243), const Color(0xFF0F2E24)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.video,
                                  size: 40,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                          // Subtle dark gradient
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          // Play Icon Button
                          Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.play,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          // Source badge (top)
                          Positioned(
                            top: 10,
                            right: isAr ? 10 : null,
                            left: isAr ? null : 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.badgeCheck,
                                    size: 13,
                                    color: Color(0xFF38BDF8),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    source,
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Duration badge (bottom)
                          Positioned(
                            bottom: 10,
                            left: isAr ? 10 : null,
                            right: isAr ? null : 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.clock,
                                    size: 12,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    duration,
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Card details & actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: dark ? Colors.white : DhikrColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          desc,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12.5,
                            height: 1.5,
                            color: dark
                                ? DhikrColors.darkMuted
                                : DhikrColors.charcoalSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ══════════════════ TAB 1 & 2: STEPS LIST ══════════════════
  Widget _buildStepsList(
    List<RitualStep> steps,
    bool isAr,
    bool dark, {
    required bool isHajj,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHajj
                  ? [const Color(0xFF065F46), const Color(0xFF047857)]
                  : [const Color(0xFF0369A1), const Color(0xFF0284C7)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isHajj ? const Color(0xFF065F46) : const Color(0xFF0369A1))
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHajj ? LucideIcons.tent : LucideIcons.footprints,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHajj
                              ? (isAr ? 'دليل مناسك الحج خطوة بخطوة' : 'Comprehensive Hajj Guide')
                              : (isAr ? 'دليل مناسك العمرة خطوة بخطوة' : 'Comprehensive Umrah Guide'),
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isHajj
                              ? (isAr
                                  ? '«الحج المبرور ليس له جزاء إلا الجنة»'
                                  : 'The accepted Hajj has no reward but Paradise')
                              : (isAr
                                  ? '«العمرة إلى العمرة كفارة لما بينهما»'
                                  : 'Umrah to Umrah is expiation between them'),
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Steps timeline
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;
          return _buildStepTimelineCard(step, index + 1, isLast, isAr, dark);
        }),
      ],
    );
  }

  Widget _buildStepTimelineCard(
    RitualStep step,
    int stepNumber,
    bool isLast,
    bool isAr,
    bool dark,
  ) {
    final accent = step.badgeColor ?? DhikrColors.forest;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : DhikrColors.charcoal.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tag: Step Number & Day / Timing
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${isAr ? 'الخطوة' : 'Step'} $stepNumber',
                        style: const TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step.dayTitle,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, size: 18, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 12),

                // Title
                Text(
                  step.title,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
                const SizedBox(height: 6),

                // Summary
                Text(
                  step.summary,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: dark ? const Color(0xFF38BDF8) : DhikrColors.forest,
                  ),
                ),
                const SizedBox(height: 10),

                // Full Details
                Text(
                  step.details,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 12.8,
                    height: 1.65,
                    color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                  ),
                ),

                // Sunnahs
                if (step.sunnahs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.03)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.checkCheck, size: 15, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text(
                              isAr ? 'من السنن والآداب:' : 'Sunnahs & Manners:',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...step.sunnahs.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Color(0xFF10B981))),
                                Expanded(
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 12,
                                      height: 1.5,
                                      color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Duas
                if (step.duas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...step.duas.map(
                    (d) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (dark ? const Color(0xFF38BDF8) : DhikrColors.forest)
                            .withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (dark ? const Color(0xFF38BDF8) : DhikrColors.forest)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.quote,
                            size: 16,
                            color: dark ? const Color(0xFF38BDF8) : DhikrColors.forest,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12.5,
                                height: 1.6,
                                fontWeight: FontWeight.w600,
                                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                // Interactive Video Guide Button for Step
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final isHajjStep = step.id.toLowerCase().contains('hajj');
                    final vidUrl = isHajjStep
                        ? 'https://www.youtube.com/watch?v=m_FN8JYVfvI'
                        : 'https://www.youtube.com/watch?v=5eVdlD1Fs_8';
                    playYoutubeInFrame(
                      context,
                      url: vidUrl,
                      title: isAr ? 'شرح مرئي: ${step.title}' : 'Visual Guide: ${step.title}',
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF0000).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.playCircle, size: 16, color: Color(0xFFFF0000)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr ? 'مشاهدة شرح مرئي تفاعلي للخطوة' : 'Watch interactive visual explanation',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : const Color(0xFFCC0000),
                            ),
                          ),
                        ),
                        const Icon(LucideIcons.chevronLeft, size: 15, color: Color(0xFFFF0000)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

  // ══════════════════ TAB 3: PILLARS, OBLIGATIONS & PROHIBITIONS ══════════════════
  Widget _buildPillarsAndRules(bool isAr, bool dark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Types of Hajj Card
        _buildInfoSection(
          title: isAr ? 'أنواع النسك في الحج' : 'Types of Hajj Pilgrimage',
          icon: LucideIcons.compass,
          accentColor: const Color(0xFF0284C7),
          dark: dark,
          children: [
            _buildBulletItem(
              title: '١',
              desc: isAr
                  ? 'التمتع (الأفضل): أن يحرم بالعمرة في أشهر الحج ويفرغ منها ويتحلل، ثم يحرم بالحج في نفس العام من مكة يوم التروية وعليه دم هدي.'
                  : 'Tamattu (Recommended): Perform Umrah first during Hajj months, exit Ihram, then enter Ihram for Hajj on 8 Dhul-Hijjah.',
              dark: dark,
            ),
            _buildBulletItem(
              title: '٢',
              desc: isAr
                  ? 'القِران: أن يحرم بالحج والعمرة معاً، أو يحرم بالعمرة ثم يدخل الحج عليها قبل طوافها، ولا يتحلل بينهما وعليه هدي.'
                  : 'Qiran: Enter Ihram for both Umrah and Hajj together without exiting Ihram between them; requires sacrifice.',
              dark: dark,
            ),
            _buildBulletItem(
              title: '٣',
              desc: isAr
                  ? 'الإفراد: أن يحرم بالحج وحده فقط دون عمرة، ويبقى على إحرامه حتى يوم النحر، ولا يجب عليه هدي.'
                  : 'Ifrad: Enter Ihram for Hajj alone without Umrah; no animal sacrifice is required.',
              dark: dark,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4 Pillars of Hajj
        _buildInfoSection(
          title: isAr ? 'أركان الحج الأربعة (لا يصح الحج إلا بها جميعاً)' : '4 Pillars of Hajj (Indispensable)',
          icon: LucideIcons.shieldCheck,
          accentColor: const Color(0xFFEF4444),
          dark: dark,
          children: [
            _buildBulletItem(
              title: '١',
              desc: isAr ? 'الإحرام: نية الدخول في نسك الحج بقلبه.' : 'Ihram: Intention to enter the sacred state.',
              dark: dark,
            ),
            _buildBulletItem(
              title: '٢',
              desc: isAr ? 'الوقوف بعرفة: الحضور بأي جزء من عرفة في وقته المحدد من زوال ٩ إلى فجر ١٠.' : 'Standing at Arafat: Being present within Arafat boundaries.',
              dark: dark,
            ),
            _buildBulletItem(
              title: '٣',
              desc: isAr ? 'طواف الإفاضة: طواف الركن بالبيت سبعة أشواط بعد الوقوف بعرفة.' : 'Tawaf al-Ifadah: Circumambulating the Kaaba 7 times after Arafat.',
              dark: dark,
            ),
            _buildBulletItem(
              title: '٤',
              desc: isAr ? 'السعي بين الصفا والمروة: سبعة أشواط تبدأ بالصفا وتنتهي بالمروة.' : 'Sa\'i between Safa & Marwa: Walking 7 laps between the two hills.',
              dark: dark,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 7 Obligations of Hajj
        _buildInfoSection(
          title: isAr ? 'واجبات الحج السبعة (تُجبر بدم إن تُركت)' : '7 Obligations of Hajj',
          icon: LucideIcons.listCheck,
          accentColor: const Color(0xFFF59E0B),
          dark: dark,
          children: [
            _buildBulletItem(title: '١', desc: isAr ? 'الإحرام من الميقات المكاني المعتبر شرعاً.' : 'Ihram from designated Miqat.', dark: dark),
            _buildBulletItem(title: '٢', desc: isAr ? 'الوقوف بعرفة إلى غروب الشمس لمن وقف نهاراً.' : 'Staying at Arafat until sunset.', dark: dark),
            _buildBulletItem(title: '٣', desc: isAr ? 'المبيت بمزدلفة ليلة النحر إلى ما بعد منتصف الليل.' : 'Staying overnight at Muzdalifah.', dark: dark),
            _buildBulletItem(title: '٤', desc: isAr ? 'المبيت بمنى ليالي أيام التشريق (١١، ١٢، ١٣).' : 'Overnight stay at Mina during Tashreeq.', dark: dark),
            _buildBulletItem(title: '٥', desc: isAr ? 'رمي الجمرات بالترتيب (الصغرى ثم الوسطى ثم الكبرى).' : 'Pebble throwing in order.', dark: dark),
            _buildBulletItem(title: '٦', desc: isAr ? 'الحلق أو التقصير لجميع شعر الرأس.' : 'Shaving or trimming hair.', dark: dark),
            _buildBulletItem(title: '٧', desc: isAr ? 'طواف الوداع قبيل مغادرة مكة (يسقط عن الحائض).' : 'Farewell Tawaf before departure.', dark: dark),
          ],
        ),
        const SizedBox(height: 16),

        // Prohibitions of Ihram
        _buildInfoSection(
          title: isAr ? 'محظورات الإحرام' : 'Prohibitions of Ihram',
          icon: LucideIcons.ban,
          accentColor: const Color(0xFF8B5CF6),
          dark: dark,
          children: [
            _buildBulletItem(
              title: '١',
              desc: isAr ? 'قص الأظافر وحلق الشعر من الرأس أو سائر البدن.' : 'Cutting nails & shaving hair from head or body.',
              dark: dark,
            ),
            _buildBulletItem(
              title: '٢',
              desc: isAr ? 'استعمال الطيب والعطور في الثياب أو البدن بعد الإحرام.' : 'Perfume & fragrances on body or Ihram clothes.',
              dark: dark,
            ),
            _buildBulletItem(
              title: '٣',
              desc: isAr ? 'تغطية الرأس بملاصق للرجل كالعمامة أو القلنسوة، وتجوز المظلة.' : 'Covering head directly with cap/turban (umbrella allowed).',
              dark: dark,
            ),
            _buildBulletItem(
              title: '٤',
              desc: isAr ? 'لبس المخيط للرجل كالثوب والسراويل، ولبس الإزار والرداء.' : 'Tailored garments for men; use two unstitched sheets.',
              dark: dark,
            ),
            _buildBulletItem(
              title: '٥',
              desc: isAr ? 'النقاب والقفازان للمرأة، وتسدل على وجهها عند مرور الرجال دون نقاب.' : 'Niqab & gloves for women; veil draped loosely when passing men.',
              dark: dark,
            ),
            _buildBulletItem(
              title: '٦',
              desc: isAr ? 'الصيد، عقد النكاح، والجماع مفسد للحج إن وقع قبل التحلل الأول.' : 'Hunting & marital intimacy invalidates Hajj if before 1st exit.',
              dark: dark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required bool dark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : DhikrColors.charcoal.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBulletItem({
    required String title,
    required String desc,
    required bool dark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1A3A2A) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: dark ? const Color(0xFF38BDF8) : DhikrColors.forest,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 13,
                height: 1.6,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════ TAB 4: TAWAF & SA'I COUNTER ══════════════════
  Widget _buildTawafCounter(bool isAr, bool dark) {
    final isTawaf = _counterType == 0;
    final totalLaps = 7;
    final isCompleted = _completedLaps.length >= 7;
    final currentDua = isTawaf
        ? tawafDuas[(_currentLap - 1).clamp(0, 6)]
        : saeeDuas[(_currentLap - 1).clamp(0, 6)];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Mode Selector: Tawaf vs Sa'i
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _counterType = 0;
                      _currentLap = 1;
                      _completedLaps.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isTawaf
                          ? (dark ? const Color(0xFF0369A1) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isTawaf
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        isAr ? 'طواف الكعبة (٧ أشواط)' : 'Tawaf (7 Laps)',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isTawaf
                              ? (dark ? Colors.white : DhikrColors.charcoal)
                              : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _counterType = 1;
                      _currentLap = 1;
                      _completedLaps.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !isTawaf
                          ? (dark ? const Color(0xFF0369A1) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: !isTawaf
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        isAr ? 'سعي الصفا والمروة (٧)' : 'Sa\'i (7 Laps)',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: !isTawaf
                              ? (dark ? Colors.white : DhikrColors.charcoal)
                              : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Combined Compact Counter & Numbered Progress Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark ? Colors.white10 : DhikrColors.sageSoft.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Numbered 7-Step Horizontal Progress Bar (Compact & Connected)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (idx) {
                  final lapNum = idx + 1;
                  final isDone = _completedLaps.contains(lapNum);
                  final isCurrent = _currentLap == lapNum && !isCompleted;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await Haptics.tap();
                        setState(() => _currentLap = lapNum);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF10B981)
                              : (isCurrent
                                  ? (dark ? const Color(0xFF38BDF8) : DhikrColors.forest)
                                  : (dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9))),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? (dark ? const Color(0xFF38BDF8) : DhikrColors.forest)
                                : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isDone ? '✓' : '$lapNum',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: (isDone || isCurrent)
                                  ? Colors.white
                                  : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // 2. Center Counter Info (Compact & Clear)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: _completedLaps.length / totalLaps,
                          strokeWidth: 6.5,
                          backgroundColor: dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted
                                ? const Color(0xFF10B981)
                                : (dark ? const Color(0xFF38BDF8) : DhikrColors.forest),
                          ),
                        ),
                      ),
                      Text(
                        isCompleted ? '✓' : '$_currentLap',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: isCompleted ? 26 : 30,
                          fontWeight: FontWeight.w900,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompleted
                            ? (isAr ? 'اكتملت جميع الأشواط 🎉' : 'All Laps Completed!')
                            : (isAr ? 'الشوط الحالي: رقم $_currentLap' : 'Current Lap: #$_currentLap'),
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isAr
                            ? '${_completedLaps.length} من أصل ۷ أشواط مكتملة'
                            : '${_completedLaps.length} of 7 laps completed',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Current Dua Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : DhikrColors.charcoal.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.bookOpen,
                    size: 18,
                    color: dark ? const Color(0xFF38BDF8) : DhikrColors.forest,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'دعاء وذكر هذا الشوط:' : 'Dua for this Lap:',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currentDua,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 14,
                  height: 1.7,
                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            // Reset Button
            IconButton.filledTonal(
              onPressed: () {
                HapticFeedback.heavyImpact();
                setState(() {
                  _currentLap = 1;
                  _completedLaps.clear();
                });
              },
              icon: const Icon(LucideIcons.rotateCcw),
              tooltip: isAr ? 'إعادة العداد' : 'Reset Counter',
            ),
            const SizedBox(width: 12),

            // Next Lap Button
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  // آخر شوط: نبضة الإتمام الأطول عشان يعرف إن السبع خلصوا.
                  final finishing = _currentLap >= 7;
                  setState(() {
                    _completedLaps.add(_currentLap);
                    if (_currentLap < 7) {
                      _currentLap++;
                    }
                  });
                  if (finishing) {
                    await Haptics.complete();
                  } else {
                    await Haptics.tap();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: isCompleted
                      ? const Color(0xFF10B981)
                      : (dark ? const Color(0xFF38BDF8) : DhikrColors.forest),
                  foregroundColor: isCompleted
                      ? Colors.white
                      : (dark ? Colors.black : Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isCompleted
                      ? (isAr ? 'أتممت ٧ أشواط مباركة' : 'All 7 Laps Done')
                      : (isAr
                          ? 'تسجيل اكتمال الشوط $_currentLap'
                          : 'Complete Lap $_currentLap'),
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A dedicated modern horizontal Chips Bar for Hajj & Umrah tabs
class _HajjTabsChipBar extends StatelessWidget {
  const _HajjTabsChipBar({
    required this.tabController,
    required this.isAr,
    required this.dark,
  });

  final TabController tabController;
  final bool isAr;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (LucideIcons.sparkles, isAr ? 'العمرة' : 'Umrah'),
      (LucideIcons.tent, isAr ? 'الحج' : 'Hajj'),
      (LucideIcons.video, isAr ? 'شروح مرئية' : 'Videos'),
      (LucideIcons.repeat, isAr ? 'العداد' : 'Counter'),
      (LucideIcons.bookOpen, isAr ? 'الأركان والسنن' : 'Pillars'),
    ];

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final selectedIndex = tabController.index;
        return Container(
          height: 54,
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = selectedIndex == index;
                final (icon, label) = tabs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        tabController.animateTo(index);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: dark
                                      ? const [Color(0xFF163E30), Color(0xFF266852)]
                                      : const [Color(0xFF0F3B2C), Color(0xFF1D5A46)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected
                              ? null
                              : (dark ? DhikrColors.darkSurface : Colors.white),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                                : (dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08)),
                            width: isSelected ? 1.2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0F3B2C).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 15,
                              color: isSelected
                                  ? Colors.white
                                  : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
