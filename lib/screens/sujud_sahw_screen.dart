import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

enum SujudTiming {
  beforeSalam, // قبل السلام
  afterSalam,  // بعد السلام
  noSujud,     // لا سجود (سنة أو وسواس)
  remedyRukn,  // تدارك الركن ثم السجود
}

class SujudCase {
  final String id;
  final String title;
  final String category; // زيادة، نقصان، شك، سنن
  final String description;
  final SujudTiming timing;
  final String rulingSummary;
  final List<String> practicalSteps;
  final String evidenceHadith;
  final String reference;

  const SujudCase({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.timing,
    required this.rulingSummary,
    required this.practicalSteps,
    required this.evidenceHadith,
    required this.reference,
  });
}

class SujudSahwScreen extends StatefulWidget {
  const SujudSahwScreen({super.key});

  @override
  State<SujudSahwScreen> createState() => _SujudSahwScreenState();
}

class _SujudSahwScreenState extends State<SujudSahwScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  // Interactive Wizard State
  String? _wizardType; // 'زيادة', 'نقصان', 'شك'
  SujudCase? _selectedWizardCase;

  static const List<SujudCase> _cases = [
    // 1. ترك التشهد الأول
    SujudCase(
      id: 'forget_first_tashahhud',
      title: 'نسيان التشهد الأول والقيام للركعة الثالثة',
      category: 'نقصان',
      description: 'قمت إلى الركعة الثالثة مباشرة ونسيت الجلوس للتشهد الأوسط.',
      timing: SujudTiming.beforeSalam,
      rulingSummary: 'السجود قبل السلام؛ فإن استتممت قائماً فلا ترجع، وتجبر النقص بسجدتي السهو قبل أن تسلم.',
      practicalSteps: [
        'إذا تذكرت قبل أن تستتم قائماً: اجلس فوراً وأتِ بالتشهد وأكمل صلاتك دون سجود سهو.',
        'إذا استتممت قائماً وشرعت في القراءة: لا ترجع للجلوس، بل واصل صلاتك حتى النهاية.',
        'قبل أن تسلّم في نهاية التشهد الأخير: كبّر واسجد سجدتين كالعادة، ثم سلّم.',
      ],
      evidenceHadith: 'عن عبد الله بن بُحينة رضي الله عنه: «أن النبي ﷺ صلّى بهم الظهر فقام في الركعتين الأوليين ولم يجلس، فقام الناس معه، حتى إذا قضى الصلاة وانتظر الناس تسليمه كبّر وهو جالس فسجد سجدتين قبل أن يسلّم ثم سلّم».',
      reference: 'صحيح البخاري ومسلم',
    ),

    // 2. الشك في عدد الركعات دون ترجيح
    SujudCase(
      id: 'doubt_without_preference',
      title: 'الشك في عدد الركعات مع التردد المتساوي',
      category: 'شك',
      description: 'شككت هل صليت ثلاث ركعات أم أربعاً، ولم يترجح في قلبك أي الأمرين.',
      timing: SujudTiming.beforeSalam,
      rulingSummary: 'ابنِ على اليقين (وهو الأقل) وأتم الركعة الناقصة، ثم اسجد سجدتي السهو قبل السلام.',
      practicalSteps: [
        'اطرح الشك واعتمد على المتيقن وهو الأقل (إن ترددت بين 3 و 4 فاجعلها 3).',
        'قم فأتِ بركعة رابعة لتكمل صلاتك يقيناً.',
        'تشهد التشهد الأخير كالمعتاد.',
        'قبل أن تسلم: اسجد سجدتي السهو، ثم سلّم.',
      ],
      evidenceHadith: 'قال رسول الله ﷺ: «إذا شك أحدكم في صلاته فلم يدرِ كم صلّى أثلاثاً أم أربعاً؟ فليطرح الشك وليبنِ على ما استيقن، ثم يسجد سجدتين قبل أن يسلّم».',
      reference: 'صحيح مسلم',
    ),

    // 3. الشك في عدد الركعات مع ترجيح
    SujudCase(
      id: 'doubt_with_preference',
      title: 'الشك في عدد الركعات مع غلبة الظن (ترجيح أحدهما)',
      category: 'شك',
      description: 'شككت هل صليت ثلاثاً أم أربعاً، لكن غلب على ظنك ورجح في قلبك أنك صليت أربعاً مثلاً.',
      timing: SujudTiming.afterSalam,
      rulingSummary: 'ابنِ على ما ترجح لديك وأتم الصلاة وسلم، ثم اسجد سجدتي السهو بعد السلام وسلم ثانية.',
      practicalSteps: [
        'اعمل بما غلب على ظنك وترجح عندك (سواء كان الأقل أو الأكثر).',
        'أتم الصلاة بناءً على هذا الترجيح.',
        'سلّم من الصلاة تسليمتين.',
        'كبّر واسجد سجدتين كالعادة، ثم سلّم مرة أخرى بعدهما.',
      ],
      evidenceHadith: 'قال رسول الله ﷺ: «إذا شك أحدكم في صلاته فليتحرّ الصواب فليتمّ عليه، ثم ليسلّم، ثم يسجد سجدتين».',
      reference: 'صحيح البخاري ومسلم',
    ),

    // 4. السلام قبل تمام الصلاة
    SujudCase(
      id: 'early_salam',
      title: 'السلام قبل إتمام الصلاة سهواً',
      category: 'زيادة',
      description: 'سلّمت من الصلاة الرباعية بعد ركعتين أو ثلاث عن طريق النسيان والسهو.',
      timing: SujudTiming.afterSalam,
      rulingSummary: 'ارجع فوراً إن كان الفاصل قريباً، وأكمل ما بقي من الركعات وسلم، ثم اسجد سجدتي السهو بعد السلام وسلم.',
      practicalSteps: [
        'إذا نبّهك أحد أو تذكرت قريباً: قم فوراً وأتِ بما بقي عليك من ركعات.',
        'لا تحتاج لإحرام أو نية صلاة جديدة إذا كان الفاصل الزمني قصيراً.',
        'اجلس للتشهد وسلّم من صلاتك.',
        'بعد التسليم: اسجد سجدتي السهو ثم سلّم ثانية (كما فعل النبي ﷺ في قصة ذي اليدين).',
      ],
      evidenceHadith: 'حديث ذي اليدين في الصحيحين: حين سلّم النبي ﷺ من ركعتين في إحدى صلاتي العشي، فقال له ذو اليدين: «أقصرت الصلاة أم نسيت؟»، فقال: «لم أنس ولم تقصر»، فقال: بل قد نسيت، فصلّى ركعتين ثم سلّم ثم سجد سجدتين ثم سلّم.',
      reference: 'متفق عليه',
    ),

    // 5. زيادة ركعة أو ركوع أو سجود
    SujudCase(
      id: 'extra_unit_finished',
      title: 'زيادة ركعة أو ركوع وتذكر ذلك بعد الفراغ منه',
      category: 'زيادة',
      description: 'صليت الظهر أو العصر خمس ركعات سهواً، وتذكرت بعد تمام الركعة أو بعد السلام.',
      timing: SujudTiming.afterSalam,
      rulingSummary: 'السجود بعد السلام، وصلاتك تامة صحيحة، وتسجد سجدتي السهو ترغيماً للشيطان.',
      practicalSteps: [
        'إذا لم تتذكر إلا وأنت في التشهد أو بعد السلام: لا يلزمك إعادة الصلاة.',
        'سلّم تسليمتين من صلاتك.',
        'اسجد سجدتي السهو بعد السلام، ثم سلّم تسليمتين.',
      ],
      evidenceHadith: 'عن عبد الله بن مسعود رضي الله عنه: «أن رسول الله ﷺ صلّى الظهر خمساً، فقيل له: أزيد في الصلاة؟ قال: وما ذاك؟ قالوا: صليت خمساً، فسجد سجدتين بعدما سلّم».',
      reference: 'صحيح البخاري ومسلم',
    ),

    // 6. تذكر الزيادة أثناء القيام للركعة الزائدة
    SujudCase(
      id: 'extra_unit_during',
      title: 'تذكر الزيادة أثناء القيام للركعة الزائدة',
      category: 'زيادة',
      description: 'قمت إلى ركعة خامسة في صلاة رباعية وتذكرت أو سبّح المصلون وأنت واقف.',
      timing: SujudTiming.afterSalam,
      rulingSummary: 'يجب عليك الجلوس فوراً دون تأخير، ثم تتشهد إن لم تكن تشهدت وتسلم، وتسجد بعد السلام.',
      practicalSteps: [
        'اجلس مباشرة فور تذكرك ولا تستمر في الركعة الزائدة أبداً.',
        'إذا كنت لم تتشهد التشهد الأخير فأتِ به، وإن كنت تشهدت فاسلم مباشرة.',
        'بعد أن تسلّم: اسجد سجدتي السهو ثم سلّم.',
      ],
      evidenceHadith: 'اتفق العلماء على أن من قام لزيادة سهواً لزمه الرجوع متى علم، وإلا بطلت صلاته بتعمده الزيادة، ويسجد بعد السلام.',
      reference: 'إجماع الفقهاء والسنن',
    ),

    // 7. نسيان ركن كالسجود أو الركوع
    SujudCase(
      id: 'forget_pillar_rukn',
      title: 'نسيان ركن من أركان الصلاة (كالركوع أو السجود)',
      category: 'نقصان',
      description: 'سجدت سجدة واحدة وقمت للركعة التالية، أو نسيت الركوع وسجدت مباشرة.',
      timing: SujudTiming.remedyRukn,
      rulingSummary: 'الركن لا يجبره سجود السهو وحده، بل يجب الإتيان به أو إلغاء الركعة، ثم السجود بعد السلام.',
      practicalSteps: [
        'إذا تذكرت قبل الشروع في قراءة الركعة التالية: ارجع فوراً فأتِ بالركن المنسي وأكمل ما بعده.',
        'إذا لم تتذكر إلا بعد الشروع في قراءة الركعة التالية: تلغى الركعة السابقة، وتقوم الركعة الحالية مقامها.',
        'أكمل صلاتك حتى النهاية، وسلّم.',
        'اسجد سجدتي السهو بعد السلام ثم سلّم ثانية.',
      ],
      evidenceHadith: 'لأن الأركان لا تسقط بالسهو، ويجب استدراكها، وتكون الزيادة الحاصلة بالركعة الملغاة موجبة للسجود بعد السلام.',
      reference: 'الفقه المقارن والمذاهب الأربعة',
    ),

    // 8. نسيان سورة بعد الفاتحة أو دعاء الاستفتاح
    SujudCase(
      id: 'forget_sunnah',
      title: 'نسيان قراءة سورة بعد الفاتحة أو دعاء الاستفتاح',
      category: 'سنن',
      description: 'قرأت الفاتحة وركعت دون قراءة سورة أخرى، أو نسيت دعاء الاستفتاح أو تكبيرة الانتقال.',
      timing: SujudTiming.noSujud,
      rulingSummary: 'لا سجود للسهو؛ لأنها من سنن الصلاة ومستحباتها وصلاتك صحيحة تامة.',
      practicalSteps: [
        'قراءة سورة بعد الفاتحة ودعاء الاستفتاح من السنن والمستحبات وليست أركاناً ولا واجبات.',
        'لا تبطل الصلاة بتركها ولا يلزمك سجود سهو.',
        'أكمل صلاتك واطمئن، فصلاتك مقبولة بإذن الله.',
      ],
      evidenceHadith: 'السنن إن فعلها المصلي أجر وإن تركها سهواً أو عمداً لم تبطل صلاته ولم يجب عليه سجود السهو.',
      reference: 'جمهور الفقهاء',
    ),

    // 9. الوسواس الدائم المتكرر
    SujudCase(
      id: 'waswas_continuous',
      title: 'الشك المتكرر والوسواس المستمر في كل صلاة',
      category: 'شك',
      description: 'يأتيك الشك في كل وضوء وكل صلاة، أو يأتيك بعد انتهاء الصلاة بالكلية.',
      timing: SujudTiming.noSujud,
      rulingSummary: 'لا تلتفت للشك أبداً ولا تسجد للسهو، وصلاتك تامة وصحيحة؛ لأن السجود مع الوسواس يزيد كيد الشيطان.',
      practicalSteps: [
        'قاعدة فقهية: الشك بعد الفراغ من العبادة لا يُلتفت إليه ولا يؤثر إطلاقاً.',
        'إذا كان الشك يلازمك دائماً فهو وسواس، والوسواس علاجه الإعراض التام عنه.',
        'ابنِ على أن صلاتك صحيحة، ولا تعيد ركعة، ولا تسجد للسهو.',
        'استعذ بالله من الشيطان واثبت على صلاتك.',
      ],
      evidenceHadith: 'قال الإمام أحمد وغيره من أهل العلم: «الوسواس إذا كثر فلا عبرة به»، وقد حذر العلماء من التمادي مع الشيطان في الشكوك.',
      reference: 'قواعد الفقه الإسلامي',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<SujudCase> get _filteredCases {
    return _cases.where((item) {
      final matchesCat = _selectedCategory == 'الكل' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.contains(_searchQuery) ||
          item.description.contains(_searchQuery) ||
          item.rulingSummary.contains(_searchQuery);
      return matchesCat && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    final isAr = appState.language == AppLanguage.arabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0),
        appBar: AppBar(
          backgroundColor: dark ? const Color(0xFF10241E) : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          title: Text(
            isAr ? 'أحكام وفتاوى فقهية متنوعة' : 'Diverse Fiqh Rulings',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: dark ? Colors.white : DhikrColors.charcoal,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: dark ? Colors.white : DhikrColors.charcoal,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: dark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFF10B981),
                indicatorWeight: 3,
                labelColor: const Color(0xFF10B981),
                unselectedLabelColor: dark ? Colors.white54 : DhikrColors.charcoalSoft,
                labelStyle: const TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: isAr ? 'سجود السهو' : 'Sujud Sahw'),
                  Tab(text: isAr ? 'دليل الحالات' : 'Cases Guide'),
                  Tab(text: isAr ? 'القواعد الأربع' : '4 Golden Rules'),
                  Tab(text: isAr ? 'الطهارة والصلاة' : 'Purity & Prayer'),
                  Tab(text: isAr ? 'فتاوى الصيام والعبادات' : 'Fasting & Worship'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Interactive Wizard Solver
            _buildInteractiveWizardTab(dark, isAr),

            // Tab 2: Full Cases Directory with Search & Filter
            _buildCasesDirectoryTab(dark, isAr),

            // Tab 3: Golden Rules of Sujud Sahw
            _buildGoldenRulesTab(dark, isAr),

            // Tab 4: Fiqh of Purity & Prayer
            _buildFiqhPrayerPurityTab(dark, isAr),

            // Tab 5: Fiqh of Fasting & Worship
            _buildFiqhFastingWorshipTab(dark, isAr),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: INTERACTIVE WIZARD SOLVER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInteractiveWizardTab(bool dark, bool isAr) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Introductory banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark
                    ? [const Color(0xFF132F26), const Color(0xFF0F261E)]
                    : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.compass,
                    color: Color(0xFF10B981),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'مُشخص السهو في الصلاة' : 'Prayer Sahw Assistant',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: dark ? Colors.white : const Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isAr
                            ? 'حدد ما طرأ على صلاتك خطوة بخطوة لمعرفة الحكم الدقيق مع الدليل الشرعي.'
                            : 'Select what happened in your prayer step-by-step to get the exact ruling and sunnah evidence.',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 12,
                          color: dark ? Colors.white70 : const Color(0xFF047857),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Step 1: Choose Nature of Error
          Text(
            isAr ? 'الخطوة ١: ما الذي حدث في صلاتك؟' : 'Step 1: What happened?',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: dark ? Colors.white : DhikrColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildWizardCategoryChip(
                  label: isAr ? 'زيادة' : 'Addition',
                  sub: isAr ? 'ركعة/ركوع/سلام' : 'Unit/Salam',
                  icon: LucideIcons.plusCircle,
                  color: const Color(0xFFEF4444),
                  selected: _wizardType == 'زيادة',
                  dark: dark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _wizardType = 'زيادة';
                      _selectedWizardCase = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildWizardCategoryChip(
                  label: isAr ? 'نقصان' : 'Omission',
                  sub: isAr ? 'تشهد/ركن/تسبيح' : 'Pillar/Duty',
                  icon: LucideIcons.minusCircle,
                  color: const Color(0xFFF59E0B),
                  selected: _wizardType == 'نقصان',
                  dark: dark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _wizardType = 'نقصان';
                      _selectedWizardCase = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildWizardCategoryChip(
                  label: isAr ? 'شك وتردد' : 'Doubt',
                  sub: isAr ? '٣ أم ٤ ركعات؟' : '3 or 4 units?',
                  icon: LucideIcons.helpCircle,
                  color: const Color(0xFF3B82F6),
                  selected: _wizardType == 'شك',
                  dark: dark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _wizardType = 'شك';
                      _selectedWizardCase = null;
                    });
                  },
                ),
              ),
            ],
          ),

          // Step 2: Show specific cases based on chosen type
          if (_wizardType != null) ...[
            const SizedBox(height: 24),
            Text(
              isAr ? 'الخطوة ٢: اختر الحالة الأقرب لما جرى:' : 'Step 2: Choose exact situation:',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: dark ? Colors.white : DhikrColors.charcoal,
              ),
            ),
            const SizedBox(height: 12),

            ..._cases
                .where((c) => c.category == _wizardType || (_wizardType == 'نقصان' && c.category == 'سنن'))
                .map((caseItem) {
              final isSelected = _selectedWizardCase?.id == caseItem.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981).withValues(alpha: dark ? 0.18 : 0.10)
                      : (dark ? const Color(0xFF10241E) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : (dark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                    width: isSelected ? 1.6 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedWizardCase = caseItem;
                    });
                  },
                  title: Text(
                    caseItem.title,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: dark ? Colors.white : DhikrColors.charcoal,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      caseItem.description,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        color: dark ? Colors.white60 : DhikrColors.charcoalSoft,
                        height: 1.3,
                      ),
                    ),
                  ),
                  trailing: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? const Color(0xFF10B981) : (dark ? Colors.white30 : Colors.black26),
                  ),
                ),
              );
            }),
          ],

          // Step 3: Detailed Solution Card
          if (_selectedWizardCase != null) ...[
            const SizedBox(height: 24),
            _buildCaseSolutionCard(_selectedWizardCase!, dark, isAr),
          ],

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildWizardCategoryChip({
    required String label,
    required String sub,
    required IconData icon,
    required Color color,
    required bool selected,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: dark ? 0.25 : 0.12)
              : (dark ? const Color(0xFF10241E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : (dark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: dark ? Colors.white : DhikrColors.charcoal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 10,
                color: dark ? Colors.white54 : DhikrColors.charcoalSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: DIRECTORY OF ALL CASES WITH SEARCH
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCasesDirectoryTab(bool dark, bool isAr) {
    return Column(
      children: [
        // Search bar & category chips
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: dark ? const Color(0xFF10241E) : Colors.white,
          child: Column(
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 14,
                    color: dark ? Colors.white : DhikrColors.charcoal,
                  ),
                  decoration: InputDecoration(
                    hintText: isAr ? 'ابحث عن حالة (مثل: تشهد، ركعة، سلام، شك)...' : 'Search cases...',
                    hintStyle: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 13,
                      color: dark ? Colors.white38 : Colors.black38,
                    ),
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    'الكل',
                    'نقصان',
                    'زيادة',
                    'شك',
                    'سنن',
                  ].map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FilterChip(
                        selected: isSel,
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12,
                            color: isSel
                                ? Colors.white
                                : (dark ? Colors.white70 : DhikrColors.charcoal),
                          ),
                        ),
                        selectedColor: const Color(0xFF10B981),
                        backgroundColor: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF3F4F6),
                        checkmarkColor: Colors.white,
                        onSelected: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Cases List
        Expanded(
          child: _filteredCases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.searchX, size: 48, color: dark ? Colors.white30 : Colors.black26),
                      const SizedBox(height: 12),
                      Text(
                        isAr ? 'لم نجد حالات تطابق بحثك' : 'No matching cases found',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 14,
                          color: dark ? Colors.white54 : DhikrColors.charcoalSoft,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredCases.length,
                  itemBuilder: (context, idx) {
                    final item = _filteredCases[idx];
                    return _buildCaseExpansionCard(item, dark, isAr);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCaseExpansionCard(SujudCase item, bool dark, bool isAr) {
    final (badgeText, badgeColor) = switch (item.timing) {
      SujudTiming.beforeSalam => (isAr ? 'قبل السلام' : 'Before Salam', const Color(0xFF10B981)),
      SujudTiming.afterSalam => (isAr ? 'بعد السلام' : 'After Salam', const Color(0xFFF59E0B)),
      SujudTiming.noSujud => (isAr ? 'لا سجود' : 'No Sujud', const Color(0xFF6B7280)),
      SujudTiming.remedyRukn => (isAr ? 'تدارك الركن ثم بعد السلام' : 'Remedy Pillar', const Color(0xFFEF4444)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF10241E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black26 : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: dark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: badgeColor,
              ),
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: dark ? Colors.white : DhikrColors.charcoal,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.description,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12,
                color: dark ? Colors.white60 : DhikrColors.charcoalSoft,
              ),
            ),
          ),
          children: [
            const Divider(height: 16),
            _buildCaseSolutionContent(item, dark, isAr),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3: GOLDEN RULES OF SUJUD SAHW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGoldenRulesTab(bool dark, bool isAr) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            isAr ? 'القواعد الذهبية الأربع لسهو الصلاة' : 'The 4 Golden Rules of Sujud Sahw',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: dark ? Colors.white : DhikrColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'خلاصة مذهب المحققين من أهل العلم وجمهور الفقهاء لتسهيل فهم وتذكر مواضع سجود السهو.'
                : 'A comprehensive distillation of authentic Prophetic rulings regarding forgetfulness in prayer.',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 12,
              color: dark ? Colors.white60 : DhikrColors.charcoalSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Rule 1: Before Salam
          _buildRuleCard(
            ruleNumber: '١',
            title: isAr ? 'متى يكون السجود قبل السلام؟' : 'When is Sujud Before Salam?',
            color: const Color(0xFF10B981),
            icon: LucideIcons.arrowLeftCircle,
            dark: dark,
            bullets: [
              'في النقصان: كنسيان التشهد الأول، أو نسيان تسبيح الركوع أو السجود، أو نسيان تكبيرات الانتقال.',
              'في الشك مع البناء على اليقين (وهو الأقل): كمن تردد هل صلى ٣ أم ٤ ولم يترجح لديه شيء، فيجعلها ٣ ويكمل ويسجد قبل السلام.',
            ],
            summary: isAr ? 'ضابط ذهبي: (النقص والشك غير المرجح ➔ قبل السلام)' : 'Omission & Equal Doubt ➔ Before Salam',
          ),

          const SizedBox(height: 14),

          // Rule 2: After Salam
          _buildRuleCard(
            ruleNumber: '٢',
            title: isAr ? 'متى يكون السجود بعد السلام؟' : 'When is Sujud After Salam?',
            color: const Color(0xFFF59E0B),
            icon: LucideIcons.arrowRightCircle,
            dark: dark,
            bullets: [
              'في الزيادة: كمن زاد ركوعاً أو سجوداً أو ركعة خامسة وتذكر بعد الفراغ منها أو بعد الصلاة.',
              'في السلام قبل تمام الصلاة: كمن سلّم من ركعتين في صلاة رباعية ثم أتمها، فيسجد بعد السلام.',
              'في الشك مع غلبة الظن والتحري: كمن شك هل صلى ٣ أم ٤ وترجح عنده أحدهما، فيتم على ما ترجح ويسلم ثم يسجد بعد السلام.',
            ],
            summary: isAr ? 'ضابط ذهبي: (الزيادة والسلام المبكر والشك المرجح ➔ بعد السلام)' : 'Addition & Salam Early ➔ After Salam',
          ),

          const SizedBox(height: 14),

          // Rule 3: What to say in Sujud Sahw
          _buildRuleCard(
            ruleNumber: '٣',
            title: isAr ? 'ماذا يقال في سجود السهو؟ وكيفيته؟' : 'What to Say in Sujud Sahw?',
            color: const Color(0xFF0284C7),
            icon: LucideIcons.messageSquareQuote,
            dark: dark,
            bullets: [
              'يُقال في سجود السهو ما يُقال في سجود الصلاة المعتاد: «سبحان ربي الأعلى» ثلاثاً.',
              'يستحب فيه الدعاء: «سبحانك اللهم ربنا وبحمدك اللهم اغفر لي».',
              'ليس فيه تشهد جديد على الراجح من أقوال أهل العلم، بل يكبر ويسجد سجدتين كالصلبية ثم يسلم.',
            ],
            summary: isAr ? 'يقال فيه: «سبحان ربي الأعلى» كسائر سجدات الصلاة.' : 'Recite "Subhana Rabbiyal A\'la" as normal',
          ),

          const SizedBox(height: 14),

          // Rule 4: Follower behind Imam
          _buildRuleCard(
            ruleNumber: '٤',
            title: isAr ? 'حكم المأموم خلف الإمام' : 'Follower Behind the Imam',
            color: const Color(0xFF8B5CF6),
            icon: LucideIcons.users,
            dark: dark,
            bullets: [
              'إذا سها الإمام وسجد: وجب على المأموم متابعة إمامه في السجود (سواء كان قبل السلام أو بعده).',
              'إذا سها المأموم بمفرده خلف الإمام: لا يلزمه سجود سهو؛ لأن صلاة الإمام تحمل سهو المأموم.',
              'المسبوق: إن سجد الإمام بعد السلام، لا يسجد المسبوق معه بل يقوم لقضاء ما فاته، فإذا أتم صلاته سجد للسهو.',
            ],
            summary: isAr ? 'المأموم يتبع إمامه، وسهو المأموم منفرداً يحمله الإمام.' : 'Follow the Imam in his sahw',
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildRuleCard({
    required String ruleNumber,
    required String title,
    required Color color,
    required IconData icon,
    required bool dark,
    required List<String> bullets,
    required String summary,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF10241E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: dark ? 0.3 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    ruleNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: dark ? Colors.white : DhikrColors.charcoal,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 13,
                          color: dark ? Colors.white70 : DhikrColors.charcoal,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: dark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER: Detailed Solution Component
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCaseSolutionCard(SujudCase item, bool dark, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF10241E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _buildCaseSolutionContent(item, dark, isAr),
    );
  }

  Widget _buildCaseSolutionContent(SujudCase item, bool dark, bool isAr) {
    final (badgeText, badgeColor) = switch (item.timing) {
      SujudTiming.beforeSalam => (isAr ? 'السجود قبل السلام' : 'Before Salam', const Color(0xFF10B981)),
      SujudTiming.afterSalam => (isAr ? 'السجود بعد السلام' : 'After Salam', const Color(0xFFF59E0B)),
      SujudTiming.noSujud => (isAr ? 'لا سجود للسهو' : 'No Sujud', const Color(0xFF6B7280)),
      SujudTiming.remedyRukn => (isAr ? 'تدارك الركن ثم السجود بعد السلام' : 'Remedy Pillar & Sujud', const Color(0xFFEF4444)),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top timing banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: dark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeColor, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.checkCheck, color: badgeColor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Summary ruling
        Text(
          isAr ? 'الحكم الشرعي:' : 'Ruling:',
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: dark ? Colors.white60 : DhikrColors.charcoalSoft,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.rulingSummary,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: dark ? Colors.white : DhikrColors.charcoal,
            height: 1.45,
          ),
        ),

        const SizedBox(height: 16),

        // Practical steps
        Text(
          isAr ? 'الخطوات العملية خطوة بخطوة:' : 'Practical Steps:',
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: dark ? Colors.white60 : DhikrColors.charcoalSoft,
          ),
        ),
        const SizedBox(height: 8),
        ...item.practicalSteps.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final stepText = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: dark ? 0.3 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$idx',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stepText,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 13,
                      color: dark ? Colors.white70 : DhikrColors.charcoal,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 14),

        // Hadith Evidence Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: dark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.bookMarked, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    isAr ? 'الدليل من السنة النبوية المطهرة:' : 'Hadith Evidence:',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.reference,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 10,
                      color: dark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.evidenceHadith,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: dark ? Colors.white60 : DhikrColors.charcoalSoft,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3: FIQH OF PURITY & PRAYER (الطهارة والصلاة)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFiqhPrayerPurityTab(bool dark, bool isAr) {
    final rules = [
      (
        'المسح على الخفين والجوربين (الشراب)',
        'يجوز المسح على الجوارب الطاهرة الساترة بعد لبسها على طهارة كاملة. مدة المسح: للمقيم يوم وليلة (٢٤ ساعة) تبدأ من أول مسحة بعد الحدث، وللمسافر ثلاثة أيام بلياليها (٧٢ ساعة). كيفية المسح: يمسح بظاهر اليد المبللة على ظاهر الجورب (أعلاه) مرة واحدة ولا يمسح أسفله.',
        'حديث علي بن أبي طالب رضي الله عنه: «لو كان الدين بالرأي لكان أسفل الخف أولى بالمسح من أعلاه، وقد رأيت رسول الله ﷺ يمسح على ظاهر خفيه» (رواه أبو داود).',
      ),
      (
        'الشك في نقض الوضوء أو الطهارة',
        'قاعدة كبرى: «اليقين لا يزول بالشك». من تيقن الطهارة وشك في الحدث فهو طاهر حتى يتيقن خروج شيء بيقين تام يسمع صوتاً أو يجد ريحاً. والعكس: من تيقن الحدث وشك هل توضأ أم لا فهو محدث وعليه الوضوء.',
        'قال رسول الله ﷺ: «لا ينصرف حتى يسمع صوتاً أو يجد ريحاً» (متفق عليه).',
      ),
      (
        'قضاء الصلاة الفائتة لمن نام أو نسي',
        'من فاتته صلاة بنوم أو نسيان وجب عليه المبادرة بقضائها فور تذكرها، ولا كفارة لها إلا ذلك. ولا يجوز تأخيرها للصلاة القادمة بل يصليها مرتبة، فإن تذكرها وهو يصلي الصلاة الحاضرة أتمها ثم قضى الفائتة، أو قلب نيته.',
        'قال النبي ﷺ: «من نسي صلاة أو نام عنها فكفارتها أن يصليها إذا ذكرها» (صحيح مسلم).',
      ),
      (
        'أحكام القصر والجمع في السفر',
        'السنة للمسافر قصر الصلاة الرباعية (الظهر والعصر والعشاء) إلى ركعتين، ويبدأ القصر بمفارقة بنيان البلد. ويجوز له الجمع بين الظهر والعصر، والمغرب والعشاء جمع تقديم أو تأخير حسب الأيسر له. وصلاة المغرب ثلاث ركعات والفجر ركعتان لا تقصران.',
        'عن أنس رضي الله عنه: «خرجنا مع رسول الله ﷺ من المدينة إلى مكة فكان يصلي ركعتين ركعتين حتى رجعنا» (متفق عليه).',
      ),
      (
        'صلاة المريض والعاجز عن القيام',
        'يصلي المريض قائماً، فإن لم يستطع فقاعداً، فإن لم يستطع فعلى جنبه مستقبل القبلة ويوطئ برأسه للركوع والسجود، ويكون سجوده أخفض من ركوعه. وتسقط عنه المشقة ولا تضيع الصلاة بحال ما دام عقله ثابتاً.',
        'قال النبي ﷺ لعمران بن حصين: «صلِّ قائماً، فإن لم تستطع فقاعداً، فإن لم تستطع فعلى جنب» (صحيح البخاري).',
      ),
      (
        'أحكام المسبوق في صلاة الجماعة',
        'يُدرك المسبوق الركعة بإدراك الركوع مع الإمام قبل أن يرفع. وإذا دخل مع الإمام في أي جزء من الصلاة كبّر تكبيرة الإحرام قائماً ثم دخل مع الإمام حيث وجده. وبعد سلام الإمام يقوم دون تسليم ليكمل ما فاته، وما أدركه مع الإمام هو أول صلاته وما يقضيه هو آخره.',
        'قال ﷺ: «فما أدركتم فصلوا، وما فاتكم فأتموا» (متفق عليه).',
      ),
      (
        'المرور بين يدي المصلي والسترة',
        'يُسن للمصلي اتخاذ سترة أمامه (جدار، عمود، أو شيء مرتفع قدر مؤخرة الرحل). ويحرم المرور بين يدي المصلي وبين سترته، وللمصلي دفعه بالتي هي أحسن. أما في الحرم المكي الشريف وحالات الزحام الشديد فقد رخص كثير من أهل العلم للحاجة.',
        'قال النبي ﷺ: «لو يعلم المار بين يدي المصلي ماذا عليه لكان أن يقف أربعين خيراً له من أن يمر بين يديه» (متفق عليه).',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final (title, explanation, hadith) = rules[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark ? Colors.white10 : DhikrColors.sageSoft.withValues(alpha: 0.5),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.checkCheck, size: 16, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : DhikrColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                explanation,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 13,
                  height: 1.6,
                  color: dark ? Colors.white70 : DhikrColors.charcoalSoft,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dark ? Colors.black26 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.bookmark, size: 13, color: Color(0xFF0F766E)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hadith,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: dark ? const Color(0xFF34D399) : const Color(0xFF0F766E),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 4: FIQH OF FASTING & WORSHIP (فتاوى الصيام والعبادات)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFiqhFastingWorshipTab(bool dark, bool isAr) {
    final fastingRules = [
      (
        'المفطرات المعاصرة والطبية في نهار رمضان',
        'الأمور التي لا تفطر:\n'
        '• قطرة العين والأذن وبخاخ الأنف السطحي، وبخاخ الربو على الراجح لأنه هواء يدخل الرئة وليس غذاء.\n'
        '• الحقن العضلية والجلدية غير المغذية وحقن الإنسولين للمريض.\n'
        '• تحليل الدم، وسحب الدم اليسير، وأخذ عينة مسحة الأنف.\n'
        '• استخدام معجون الأسنان والسواك مع الحذر الشديد من ابتلاع شيء.\n'
        'أما المغذي (السيلان والجلوكوز) والحقن الوريدية المغذية فإنها تفطر لأنها تقوم مقام الطعام والشراب.',
        'قرار مجمع الفقه الإسلامي الدولي بشأن المفطرات في مجال التداوي.',
      ),
      (
        'صيام الحامل والمرضع والمريض والمسافر',
        'المريض مرضا يُرجى شفاؤه، والمسافر: يفطران وعليهما القضاء بعد رمضان. الحامل والمرضع: إن خافتا على نفسيهما أو ولديهما أفطرتا وعليهما القضاء عند جمهور العلماء. المريض مرضاً مزمناً لا يُرجى برؤه، والكبير العاجز: يفطران ويطعمان عن كل يوم مسكيناً (نصف صاع = ١.٥ كجم أرز تقريباً) ولا قضاء عليهما.',
        'قال تعالى: ﴿فَمَن كَانَ مِنكُم مَّرِيضًا أَوْ عَلَىٰ سَفَرٍ فَعِدَّةٌ مِّنْ أَيَّامٍ أُخَرَ ۚ وَعَلَى الَّذِينَ يُطِيقُونَهُ فِدْيَةٌ طَعَامُ مِسْكِينٍ﴾ [البقرة: ١٨٤].',
      ),
      (
        'الأكل أو الشرب ناسياً في نهار رمضان',
        'من أكل أو شرب ناسياً في نهار الصيام فصيامه صحيح وتام ولا قضاء عليه ولا كفارة، سواء كان صيام فرض (رمضان) أو نفل. ويجب على من رآه يأكل ناسياً أن يذكّره فوراً.',
        'قال رسول الله ﷺ: «من نسي وهو صائم فأكل أو شرب فليتم صومه، فإنما أطعمه الله وسقاه» (متفق عليه).',
      ),
      (
        'الشك في طلوع الفجر أو غروب الشمس',
        'الأصل بقاء الليل: فمن أكل شاكاً في طلوع الفجر فصومه صحيح ما لم يتيقن طلوعه. وأما عند الغروب فالأصل بقاء النهار: فلا يجوز الإفطار إلا باليقين التام بغروب قرص الشمس أو سماع أذان المغرب الموثوق.',
        'القاعدة الفقهية: «الأصل بقاء ما كان على ما كان حتى يثبت العكس باليقين».',
      ),
      (
        'أحكام قضاء أيام رمضان المتبقية',
        'يجب قضاء ما أفطره المسلم من رمضان قبل دخول رمضان القادم، ويستحب المبادرة بالقضاء إبراءً للذمة وتفريق الأيام جائز ولا يشترط التتابع. فإن دخل عليه رمضان الثاني بغير عذر قضى بعده وأطعم عن كل يوم مسكيناً مع القضاء عند جمع من الصحابة.',
        'عن عائشة رضي الله عنها قالت: «كان يكون عليّ الصوم من رمضان، فما أستطيع أن أقضي إلا في شعبان» (متفق عليه).',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fastingRules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final (title, explanation, source) = fastingRules[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark ? Colors.white10 : const Color(0xFFD97706).withValues(alpha: 0.3),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.moon, size: 16, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : DhikrColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                explanation,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 13,
                  height: 1.6,
                  color: dark ? Colors.white70 : DhikrColors.charcoalSoft,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dark ? Colors.black26 : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.scale, size: 13, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        source,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
