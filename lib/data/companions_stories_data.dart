/// التصنيف بين رجال حول الرسول ونساء حول الرسول
enum CompanionCategory { men, women }

/// نموذج بيانات قصة الصحابي أو الصحابية
class CompanionStory {
  const CompanionStory({
    required this.id,
    required this.category,
    required this.nameAr,
    required this.nameEn,
    required this.titleAr,
    required this.titleEn,
    required this.emoji,
    required this.summaryAr,
    required this.summaryEn,
    required this.storyAr,
    required this.storyEn,
    required this.lessonsAr,
    required this.lessonsEn,
    required this.famousQuoteAr,
    required this.famousQuoteEn,
    required this.readTimeMinutes,
    this.milestonesAr = const [],
    this.milestonesEn = const [],
    this.virtuesAr = const [],
    this.virtuesEn = const [],
  });

  final String id;
  final CompanionCategory category;
  final String nameAr;
  final String nameEn;
  final String titleAr;
  final String titleEn;
  final String emoji;
  final String summaryAr;
  final String summaryEn;
  final String storyAr;
  final String storyEn;
  final List<String> lessonsAr;
  final List<String> lessonsEn;
  final String famousQuoteAr;
  final String famousQuoteEn;
  final int readTimeMinutes;
  final List<String> milestonesAr;
  final List<String> milestonesEn;
  final List<String> virtuesAr;
  final List<String> virtuesEn;
}

/// قصص رجال حول الرسول ﷺ
const List<CompanionStory> menCompanionsList = [
  CompanionStory(
    id: 'abu-bakr',
    category: CompanionCategory.men,
    nameAr: 'أبو بكر الصديق',
    nameEn: 'Abu Bakr As-Siddiq',
    titleAr: 'الصاحب الوفي وثاني اثنين في الغار',
    titleEn: 'The Truthful Friend & Cave Companion',
    emoji: '⭐',
    summaryAr:
        'أول من آمن من الرجال، وصاحب النبي ﷺ في الهجرة، وبذل ماله كله لنصرة دين الله.',
    summaryEn:
        'The first adult man to believe, the Prophet\'s companion in the cave, who gave all his wealth for Islam.',
    storyAr:
        '''كان أبو بكر رضي الله عنه أقرب الناس إلى قلب رسول الله ﷺ، ولُقّب بـ "الصديق" لأنه كان يصدّق النبي في كل ما يقول دون أي تردد، حتى عندما كذّب أهل مكة حادثة الإسراء والمعراج، قال بكل يقين وثقة: "إن كان قال ذلك فقد صدق".

في يوم الهجرة النبوية المباركة، كان رفيق النبي ﷺ في الغار وسط مطاردة كفار قريش، وحين خاف على حياة رسول الله، قال له النبي الكلمة الخالدة التي وثقها القرآن: "يا أبا بكر، ما ظنك باثنين الله ثالثهما؟".

وحين دعا النبي ﷺ للصدقة، جاء عمر بنصف ماله، بينما جاء أبو بكر بماله كله! فسأله النبي ﷺ: "ما أبقيت لأهلك؟"، فأجاب بجملته الإيمانية العظيمة: "أبقيتُ لهم الله ورسوله". وبعد وفاة الحبيب ﷺ، ثبت كالجبل الأشم وقال للأمة: "من كان يعبد محمداً فإن محمداً قد مات، ومن كان يعبد الله فإن الله حي لا يموت".''',
    storyEn:
        '''Abu Bakr was the closest companion to the Messenger of Allah ﷺ. He was called "As-Siddiq" (The Truthful) because he believed the Prophet without a moment of hesitation. When the people of Mecca denied the miraculous Night Journey (Isra and Mi'raj), he said with profound faith: "If he said so, then he speaks the truth."

During the Hijrah, he accompanied the Prophet in the cave. When enemies surrounded them, the Prophet comforted him with words immortalized in the Quran: "What do you think of two with whom Allah is the third?"

When donations were requested for the Muslim army, Abu Bakr brought his entire wealth. When asked what he left for his family, he replied: "I left them Allah and His Messenger." Upon the Prophet's passing, he stood like an unshakeable mountain, reminding the believers: "Whoever worshipped Muhammad, Muhammad has passed away; but whoever worships Allah, Allah is Ever-Living and never dies."''',
    lessonsAr: [
      'الصدق المطلق والثقة في وعد الله ورسوله.',
      'التضحية بالمال والنفس في سبيل نصرة الحق.',
      'الوفاء والشهامة في الصداقة وقت الشدائد والأزمات.',
    ],
    lessonsEn: [
      'Unwavering trust in Allah\'s promise.',
      'Generosity and sacrifice for truth.',
      'Noble loyalty in friendship through thick and thin.',
    ],
    famousQuoteAr: '«أبقيتُ لهم الله ورسوله»',
    famousQuoteEn: '"I left them Allah and His Messenger"',
    readTimeMinutes: 3,
    milestonesAr: [
      'أول رجل حر يُعلن إسلامه بدعوة النبي ﷺ وبذل ثروته لعتق المستضعفين كبلال بن رباح.',
      'صاحب النبي ﷺ في الغار أثناء رحلة الهجرة النبوية المباركة (ثاني اثنين إذ هما في الغار).',
      'أمّ المسلمين في الصلاة في مرض النبي ﷺ بأمر مباشر منه.',
      'أول الخلفاء الراشدين ومهدئ فتنة الردة بعد وفاة النبي ﷺ بحزم ويقين لا يتزعزع.',
      'أمر بجمع القرآن الكريم لأول مرة في مصحف واحد بإشارة من عمر بن الخطاب.',
    ],
    milestonesEn: [
      'First free adult man to accept Islam, using wealth to free oppressed slaves like Bilal.',
      'Companion of the Prophet in the Cave of Thawr during the blessed Hijrah.',
      'Appointed by the Prophet ﷺ to lead Muslims in prayer during his final illness.',
      'First Rightly Guided Caliph who preserved Islamic unity during the Apostasy Wars.',
      'Commissioned the first compilation of the Quran into a single unified codex.',
    ],
    virtuesAr: [
      'قال فيه النبي ﷺ: «لو كنتُ متخذاً خليلاً غير ربي لاتخذتُ أبا بكر خليلاً».',
      'قال النبي ﷺ: «ما لأحدٍ عندنا يدٌ إلا وقد كافأناه، ما خلا أبا بكر، فإن له عندنا يداً يكافئه الله بها يوم القيامة».',
      'قال عمر بن الخطاب: «أبو بكر سيدنا، ووالله ما سابقت أبا بكر إلى خير إلا سبقني إليه».',
    ],
    virtuesEn: [
      'The Prophet ﷺ said: "If I were to take an intimate friend other than my Lord, I would take Abu Bakr."',
      'The Prophet ﷺ said: "No one has done us a favor except we repaid them, except Abu Bakr; he did us a favor for which Allah will reward him on the Day of Resurrection."',
      'Umar said: "I wished I were a hair on Abu Bakr\'s chest; by Allah, whenever I competed with him in goodness, he beat me to it."',
    ],
  ),
  CompanionStory(
    id: 'umar-ibn-al-khattab',
    category: CompanionCategory.men,
    nameAr: 'عمر بن الخطاب',
    nameEn: 'Umar ibn Al-Khattab',
    titleAr: 'الفاروق الذي فرّق الله به بين الحق والباطل',
    titleEn: 'Al-Farooq: The Distinguisher between Truth and Falsehood',
    emoji: '⚖️',
    summaryAr:
        'رمز العدالة والقوة في الحق، الذي كان إسلامه عزاً للمسلمين وفتحاً مبيناً.',
    summaryEn:
        'The emblem of justice, courage, and humble leadership whose conversion empowered Muslims.',
    storyAr:
        '''قبل إسلامه كان عمر رجلاً شديداً مهاباً، حتى دعا النبي ﷺ ربه قائلاً: "اللهم أعز الإسلام بأحب هذين الرجلين إليك: بأبي جهل أو بعمر بن الخطاب"، فاختار الله عمر. ولما أسلم قال بشجاعته المعهودة: "ألسنا على الحق وهم على الباطل؟ إذن علامَ نخفي ديننا؟"، فخرج المسلمون في صفين لأول مرة يطوفون حول الكعبة رافعين رؤوسهم.

عندما تولى الخلافة، أصبح أعظم مثال للعدل والتواضع في تاريخ البشرية؛ كان ينام تحت ظل شجرة دون حراسة وثوبه مرقّع، حتى رآه رسول كسرى فقال مندهشاً: "حكمتَ فعدلتَ فأمنتَ فنمتَ يا عمر".

كان يطوف بالليل يتفقد أحوال الفقراء بنفسه، وحمل كيس الدقيق على ظهره ليطعم أطفالاً جياعاً بكوا من شدة الجوع، وقال مقولته التاريخية: "لو عثرت بغلة في العراق لسألني الله عنها: لِمَ لم تُمهّد لها الطريق يا عمر؟".''',
    storyEn:
        '''Before embracing Islam, Umar was known for his fierce strength. The Prophet ﷺ prayed: "O Allah, strengthen Islam with whichever of the two men is more beloved to You: Abu Jahl or Umar ibn Al-Khattab." Allah chose Umar. Upon becoming Muslim, he declared: "Are we not upon the truth? Then why should we hide our faith?" For the first time, Muslims walked openly in public rows to the Ka'bah.

As Caliph, he embodied unprecedented justice and humility. He slept under the shade of a tree with no guards, wearing a patched garment. An envoy of the Persian Emperor observed him and remarked: "You ruled, you were just, you felt safe, so you slept peacefully, O Umar."

He walked the streets at night checking on the poor, personally carrying sacks of flour on his back to feed hungry orphans, declaring: "If a mule stumbled in Iraq, I fear Allah would ask me why I did not pave the road for it."''',
    lessonsAr: [
      'العدل أساس الملك وكرامة الإنسان.',
      'التواضع الشديد مع امتلاك القوة والسلطة.',
      'الشعور بالمسؤولية التامة تجاه كل ضعيف ومحتاج.',
    ],
    lessonsEn: [
      'Justice is the foundation of true leadership.',
      'Humility and simplicity even with ultimate power.',
      'Deep personal empathy for the vulnerable.',
    ],
    famousQuoteAr: '«حكمتَ فعدلتَ فأمنتَ فنمتَ يا عمر»',
    famousQuoteEn:
        '"You ruled with justice, so you felt safe, so you slept peacefully"',
    readTimeMinutes: 4,
    milestonesAr: [
      'جهر بإسلامه في مكة فكان إسلامه عزاً للمسلمين وخرجوا في صفين لأول مرة حول الكعبة.',
      'ثاني الخلفاء الراشدين ومؤسس الدولة الإدارية ونظام الدواوين والشرطة والبريد.',
      'اعتمد التقويم الهجري الإسلامي تخليداً لحدث الهجرة النبوية الشريفة.',
      'تسلم مفاتيح بيت المقدس بنفسه بثوب مرقع وكتب العهدة العمرية الخالدة لأهل إيلياء.',
      'فتحت في عهده الشام والعراق ومصر وفارس وانكسرت شوكة كسرى وقيصر.',
    ],
    milestonesEn: [
      'Publicly proclaimed his Islam in Mecca, granting dignity and strength to believers.',
      'Second Rightly Guided Caliph; Islamic territory expanded to Jerusalem, Levant, Persia, and Egypt.',
      'Established the Islamic Hijri calendar, administrative ministries, police, and public welfare system.',
      'Personally received the keys to Jerusalem in humility and authored the famed Umariyya Covenant.',
      'Brought down the tyrannical Roman and Sasanian empires to establish justice.',
    ],
    virtuesAr: [
      'قال فيه النبي ﷺ: «لو كان بعدي نبيٌّ لكان عمر بن الخطاب».',
      'قال النبي ﷺ: «إيه يا ابن الخطاب، والذي نفسي بيده، ما لقيك الشيطان سالكاً فجّاً إلا سلك فجّاً غير فجّك».',
      'وافق القرآن الكريم رأيه في عدة مواقف كحجاب أمهات المؤمنين ومقام إبراهيم.',
    ],
    virtuesEn: [
      'The Prophet ﷺ said: "If there were to be a prophet after me, it would be Umar ibn Al-Khattab."',
      'The Prophet ﷺ said: "By Him in Whose Hand is my soul, Satan never meets you taking a path but he takes another path than yours."',
      'Several Quranic verses descended affirming Umar\'s insightful counsel (Muwafaqat Umar).',
    ],
  ),
  CompanionStory(
    id: 'uthman-ibn-affan',
    category: CompanionCategory.men,
    nameAr: 'عثمان بن عفان',
    nameEn: 'Uthman ibn Affan',
    titleAr: 'ذو النورين وجامع المصحف الشريف',
    titleEn: 'Possessor of Two Lights & Compiler of the Quran',
    emoji: '📖',
    summaryAr:
        'الصحابي الحيي الكريم الذي تستحي منه ملائكة الرحمن، وجهّز جيش العسرة وجمع القرآن.',
    summaryEn:
        'The modest, incredibly generous companion whom angels felt shy of; he funded armies and unified the Quran.',
    storyAr:
        '''لُقّب عثمان رضي الله عنه بـ "ذي النورين" لأنه تزوّج ابنتي رسول الله ﷺ: رقية ثم أم كلثوم بعد وفاتها. وكان شديد الحياء والأدب، حتى قال عنه النبي ﷺ: "ألا أستحي من رجل تستحي منه الملائكة؟".

كان عثمان تاجراً ثرياً، لكنه جعل ثروته كلها في خدمة دين الله ونفع الناس؛ فعندما هاجر المسلمون إلى المدينة وعانوا من قلة الماء العذب، اشترى بئر رومة بماله الخاص وجعلها وقفاً مجانياً يشرب منها المسلمون دون مقابل.

وفي غزوة تبوك (جيش العسرة)، جهّز عثمان ثلث الجيش بأكمله من ماله؛ بالخيل والإبل والعتاد، حتى قال النبي ﷺ مسروراً: "ما ضرّ عثمان ما عمل بعد اليوم". ومن أعظم حسناته التي نعيش بفضلها حتى اليوم أنه جمع الأمة على مصحف واحد منعاً للاختلاف والفرقة.''',
    storyEn:
        '''Uthman was known as "Dhun-Noorayn" (Possessor of the Two Lights) because he married two daughters of the Prophet ﷺ: Ruqayyah and, after her passing, Umm Kulthum. He was renowned for his unmatched modesty; the Prophet ﷺ said: "Shall I not feel shy before a man whom even the angels feel shy of?"

A prosperous merchant, Uthman dedicated his immense wealth to serving the community. When emigrants suffered water shortages in Madinah, he bought the well of Rumah and made it a free endowment for everyone.

During the Battle of Tabuk, he single-handedly outfitted a third of the entire army with mounts, provisions, and equipment. The Prophet ﷺ exclaimed: "Nothing Uthman does after today can harm him." His greatest legacy remains the unification of the Quran into one standardized codex, preserving it for all generations.''',
    lessonsAr: [
      'الحياء زينة المؤمن وخلق إسلامي رفيع.',
      'إنفاق المال بسخاء في المشاريع الخيرية النافعة للبشرية.',
      'الحرص على وحدة الأمة واجتماع كلمتها على القرآن.',
    ],
    lessonsEn: [
      'Modesty is a core virtue of faith.',
      'Using wealth as a tool to uplift society.',
      'Uniting the community upon divine guidance.',
    ],
    famousQuoteAr: '«ما ضرّ عثمان ما عمل بعد اليوم»',
    famousQuoteEn: '"Nothing Uthman does after today can harm him"',
    readTimeMinutes: 3,
    milestonesAr: [
      'تزوّج ابنتي رسول الله ﷺ رقية ثم أم كلثوم فنال شرف لقب (ذو النورين).',
      'اشترى بئر رومة بالمدينة وجعلها وقفاً مجانياً للمسلمين إلى قيام الساعة.',
      'جهّز جيش العسرة في تبوك بمئات الإبل والخيل والذهب فنال رضوان الله ورسوله.',
      'ثالث الخلفاء الراشدين، ووحّد كتابة المصحف الشريف وأرسل النسخ للأمصار (المصحف العثماني).',
      'أنشأ أول أسطول بحري إسلامي لحماية سواحل البحر الأبيض المتوسط.',
    ],
    milestonesEn: [
      'Married two daughters of the Prophet (Ruqayyah and Umm Kulthum), earning the title Dhun-Noorayn.',
      'Purchased the well of Rumah and endowed it as a permanent public trust for the Muslims.',
      'Equipped the Expedition of Tabuk with hundreds of mounts, armor, and gold.',
      'Third Caliph; standardized the Quranic codices sent across provinces (The Uthmanic Codex).',
      'Formed the first Islamic naval fleet to secure Mediterranean coastlines.',
    ],
    virtuesAr: [
      'قال النبي ﷺ: «ألا أستحي من رجل تستحي منه الملائكة؟».',
      'قال النبي ﷺ حين جهز جيش العسرة: «ما ضرّ عثمان ما عمل بعد اليوم، ما ضر عثمان ما عمل بعد اليوم».',
      'أحد العشرة المبشرين بالجنة، وبشره النبي بالجنة على بلوى تصيبه فصبر محتسباً.',
    ],
    virtuesEn: [
      'The Prophet ﷺ said: "Shall I not feel shy before a man whom the angels feel shy of?"',
      'The Prophet ﷺ declared: "Nothing Uthman does after today will harm him."',
      'Promised Paradise by the Prophet ﷺ amidst foretold tribulations, dying as a patient martyr.',
    ],
  ),
  CompanionStory(
    id: 'ali-ibn-abi-talib',
    category: CompanionCategory.men,
    nameAr: 'علي بن أبي طالب',
    nameEn: 'Ali ibn Abi Talib',
    titleAr: 'فدائي ليلة الهجرة وباب مدينة العلم',
    titleEn: 'Hero of Hijrah Night & Gateway of Knowledge',
    emoji: '⚔️',
    summaryAr:
        'ابن عم النبي وصهره، أول من أسلم من الفتيان، وفارس الإسلام الشجاع العالم الحكيم.',
    summaryEn:
        'Cousin and son-in-law of the Prophet, first youth to accept Islam, renowned for valor and profound wisdom.',
    storyAr:
        '''تربى علي رضي الله عنه في بيت النبي ﷺ، فتشرب من أخلاقه العظيمة وكان أول من آمن من الصبيان وهو في العاشرة من عمره.

وفي ليلة الهجرة النبوية، سطّر علي أروع مواقف الشجاعة والفداء في تاريخ الإنسانية؛ إذ نام في فراش النبي ﷺ وهو يعلم أن سيوف مشركي قريش تحيط بالبيت لتقتل من فيه، وذلك ليمكّن النبي من الخروج بسلام، وردّ الأمانات التي كانت عند رسول الله إلى أهلها من قريش رغم كفرهم!

كان علي بطلاً لا يُشق له غبار في كل الغزوات، وفي غزوة خيبر قال النبي ﷺ: "لأعطينّ الراية غداً رجلاً يحب الله ورسوله، ويحبه الله ورسوله، يفتح الله على يديه"، فنادى علياً وسلّمه الراية ففتح الحصن العظيم. ومع شجاعته الفائقة، كان بحراً في العلم والفصاحة والحكمة والقضاء العادل.''',
    storyEn:
        '''Raised in the household of the Prophet ﷺ, Ali absorbed divine character and became the first youth to accept Islam at just ten years old.

On the night of Hijrah, Ali showcased legendary courage. He volunteered to sleep in the Prophet's bed knowing that assassins' swords were poised outside, allowing the Prophet to escape safely and staying behind to return all entrusted valuables to their owners in Mecca.

At the Battle of Khaybar, the Prophet ﷺ announced: "Tomorrow I will give the banner to a man who loves Allah and His Messenger, and whom Allah and His Messenger love." He summoned Ali, entrusted him with the banner, and victory was achieved. Beyond his battlefield valor, Ali was an ocean of knowledge, eloquence, and justice.''',
    lessonsAr: [
      'الفداء والتضحية بالنفس نصرة للحق والمبدأ.',
      'الأمانة المطلقة حتى مع من يخالفك في الرأي أو الدين.',
      'الجمع بين الشجاعة العسكرية والحكمة والعلم النافع.',
    ],
    lessonsEn: [
      'Fearless sacrifice for righteous principles.',
      'Absolute trustworthiness even towards adversaries.',
      'Balancing physical courage with deep wisdom.',
    ],
    famousQuoteAr: '«لأعطين الراية رجلاً يحب الله ورسوله ويحبه الله ورسوله»',
    famousQuoteEn:
        '"A man who loves Allah and His Messenger, and whom Allah and His Messenger love"',
    readTimeMinutes: 4,
    milestonesAr: [
      'أول من أسلم من الفتيان والصبيان وتربى في كنف النبي ﷺ وأخلاقه.',
      'فدائي ليلة الهجرة؛ بات في فراش رسول الله ﷺ لرد الأمانات وتمويه المشركين.',
      'حامل الراية وفاتح حصن خيبر المنيع بعد أن استعصى على غيره.',
      'رابع الخلفاء الراشدين، قاد الأمة بحكمة وعدالة وفصاحة لا تُبارى.',
    ],
    milestonesEn: [
      'First youth to accept Islam, raised in the intimate care and character of the Prophet.',
      'Hero of Hijrah night; slept in the Prophet’s bed to deceive assassins and return trusts.',
      'Standard-bearer and conqueror of the impenetrable fortress of Khaybar.',
      'Fourth Rightly Guided Caliph, renowned for legendary eloquence, justice, and jurisprudence.',
    ],
    virtuesAr: [
      'قال النبي ﷺ يوم خيبر: «لأعطين الراية غداً رجلاً يحب الله ورسوله ويحبه الله ورسوله، يفتح الله على يديه».',
      'قال النبي ﷺ لعلي: «أنت مني بمنزلة هارون من موسى إلا أنه لا نبي بعدي».',
      'قال النبي ﷺ: «أنا دار الحكمة وعليٌّ بابها»، وكان من أقضى الصحابة وأفقههم.',
    ],
    virtuesEn: [
      'The Prophet ﷺ said at Khaybar: "Tomorrow I will give the banner to a man who loves Allah and His Messenger, and whom Allah and His Messenger love."',
      'The Prophet ﷺ said to Ali: "You are to me like Harun was to Musa, except there is no prophet after me."',
      'Famed as one of the most discerning judges and deep thinkers among all companions.',
    ],
  ),
  CompanionStory(
    id: 'bilal-ibn-rabah',
    category: CompanionCategory.men,
    nameAr: 'بلال بن رباح',
    nameEn: 'Bilal ibn Rabah',
    titleAr: 'مؤذن الرسول وصوت الحرية والتوحيد',
    titleEn: 'The Prophet\'s Muezzin & Voice of Freedom',
    emoji: '🕌',
    summaryAr:
        'العبد الحبشي الذي صمد أمام أشد أنواع التعذيب رافعاً شعار: «أحدٌ أحد»، فرفعه الإسلام ليكون مؤذن الأمة.',
    summaryEn:
        'The formerly enslaved Abyssinian whose steadfastness against torture elevated him to become Islam\'s first caller to prayer.',
    storyAr:
        '''كان بلال رضي الله عنه عبداً حبشياً مملوكاً لأمية بن خلف في مكة. لما سمع برسالة التوحيد، دخل الإيمان قلبه كالنور الساطع. ولما علم سيده بإسلامه، صبّ عليه ألواناً من العذاب لا تطيقها الجبال؛ كان يخرجه في رمضاء مكة الحارقة في وقت الظهيرة، ويضع الصخرة العظيمة على صدره ليجبره على الرجوع عن دينه.

لكن بلالاً كان يبتسم في وجه العذاب ويردد كلمته الخالدة التي هزت مكة: "أحَدٌ.. أحَدٌ.. أحَدٌ.."، حتى اشتراه أبو بكر الصديق وأعتقه لوجه الله، وقال عمر بن الخطاب: "أبو بكر سيدنا وأعتق سيدنا".

وعندما بُني المسجد النبوي في المدينة، اختاره رسول الله ﷺ ليكون أول مؤذن في الإسلام بصوته الشجي المؤثر. وفي يوم فتح مكة، صعد بلال فوق ظهر الكعبة المشرفة وصدح بالأذان: "الله أكبر.. الله أكبر"، ليعلن الإسلام أن لا فضل لعربي على أعجمي إلا بالتقوى.''',
    storyEn:
        '''Bilal was an enslaved Abyssinian in Mecca under the brutal ownership of Umayyah ibn Khalaf. When he embraced Islam, his master subjected him to horrific torment, laying him on scorching desert sands with a giant boulder on his chest to force him to renounce his faith.

Through the agony, Bilal smiled with defiance and repeated his iconic proclamation: "Ahad! Ahad!" (Allah is One! Allah is One!). Abu Bakr purchased and freed him, prompting Umar to declare: "Abu Bakr is our master, and he freed our master."

The Prophet ﷺ chose Bilal's resonant, beautiful voice to be Islam's first Muezzin. On the day Mecca was liberated, Bilal climbed atop the Ka'bah itself, raising the call to prayer across the valley to announce that human dignity and piety surpass race and social status.''',
    lessonsAr: [
      'الثبات الراسخ على العقيدة مهما بلغت التحديات والشدائد.',
      'الإسلام حطّم الفوارق الطبقية والعنصرية وجعل المعيار هو التقوى.',
      'عزة النفس والكرامة تبدأ من الإيمان بالله وحده.',
    ],
    lessonsEn: [
      'Unshakable conviction in the face of hardship.',
      'Islam eliminated racism: all humans are equal before Allah.',
      'True dignity springs from faith in the One Creator.',
    ],
    famousQuoteAr: '«أحدٌ.. أحد.. ربي الله»',
    famousQuoteEn: '"Ahad! Ahad! (Allah is One! One!)"',
    readTimeMinutes: 3,
    milestonesAr: [
      'صمد تحت أشد ألوان التعذيب في رمضاء مكة ولم يحد عن كلمة التوحيد (أحدٌ أحد).',
      'أعتقه أبو بكر الصديق لوجه الله تعالى.',
      'أول مؤذن في الإسلام واختاره النبي ﷺ ليصدح بالأذان في المسجد النبوي.',
      'أذن فوق ظهر الكعبة المشرفة يوم فتح مكة ليعلن سقوط الأصنام وعزة التوحيد.',
    ],
    milestonesEn: [
      'Endured extreme desert torture in Mecca without uttering anything other than "Ahad, Ahad".',
      'Purchased and manumitted by Abu Bakr as-Siddiq solely for Allah\'s pleasure.',
      'Islam\'s first Muezzin, selected by the Prophet ﷺ for his resonant melodic voice.',
      'Called the prayer from the rooftop of the Ka\'bah on the Day Mecca was liberated.',
    ],
    virtuesAr: [
      'قال النبي ﷺ: «يا بلال، إني سمعتُ دفّ نعليك بين يديّ في الجنة؛ فأخبرني بأرجى عمل عملته؟».',
      'قال عمر بن الخطاب: «أبو بكر سيدنا، وأعتق سيدنا» (يقصد بلالاً).',
    ],
    virtuesEn: [
      'The Prophet ﷺ said: "O Bilal, I heard the sound of your footsteps before me in Paradise."',
      'Umar ibn al-Khattab would say: "Abu Bakr is our master, and he freed our master."',
    ],
  ),
  CompanionStory(
    id: 'musab-ibn-umayr',
    category: CompanionCategory.men,
    nameAr: 'مصعب بن عمير',
    nameEn: 'Mus\'ab ibn Umayr',
    titleAr: 'سفير الإسلام الأول وشاب التضحية',
    titleEn: 'First Ambassador of Islam & Youth of Sacrifice',
    emoji: '🌿',
    summaryAr:
        'أثرى وأجمل شباب مكة، ترك النعيم والقصور واختار الإيمان، ففتح المدينة المنورة بالقرآن.',
    summaryEn:
        'Mecca\'s most pampered youth who sacrificed luxury for faith and peacefully introduced Islam to Madinah.',
    storyAr:
        '''كان مصعب بن عمير رضي الله عنه يُعرف بـ "فتى مكة المدلل"؛ كان أبهى شباب قريش ثياباً، وأعطرهم ريحاً، تدلله أمه الثرية ولا ترد له طلباً.

حين سمع بدعوة النبي ﷺ، ذهب إلى دار الأرقم سراً فدخل الإيمان قلبه وغيّر بوصلة حياته بالكامل. لما علمت أمه، حبسته وحرمته من كل أموالها ونعيمها، لكنه اختار الله ورسوله وفضّل الخشونة والفقر على الشرك.

اقتنع النبي ﷺ بحكمته ورجاحة عقله، فاختاره ليكون "أول سفير في الإسلام" وأرسله إلى يثرب (المدينة المنورة) ليعلم الناس القرآن ويدعوهم بالحكمة والموعظة الحسنة. وبفضل أسلوبه الهادئ ونور القرآن على لسانه، أسلم على يديه كبار الأنصار مثل سعد بن معاذ، حتى دخل الإسلام كل بيت في المدينة قبل هجرة النبي ﷺ إليها! استشهد بطلاً في غزوة أحد حاملاً راية المسلمين.''',
    storyEn:
        '''Mus'ab was the most fashionable and pampered youth in Mecca, draped in fine silks and expensive perfumes by his wealthy mother.

When he heard of the Prophet's call, he embraced Islam in secret. His mother locked him away and stripped him of his inheritance, but Mus'ab joyfully traded opulent wealth for faith and righteousness.

Recognizing his wisdom, gentleness, and profound intellect, the Prophet ﷺ appointed him Islam's first diplomatic ambassador, sending him to Yathrib (Madinah). Through his inspiring manners and Quran recitation, influential leaders like Sa'd ibn Mu'adh embraced Islam, and practically every home in Madinah opened its heart to Islam before the Prophet even arrived! He was martyred heroically in Uhud carrying the Muslim standard.''',
    lessonsAr: [
      'الدعوة إلى الله تكون بالحكمة والأسلوب الطيب الرفيق.',
      'التضحية بالمظاهر الزائلة من أجل القيم والمبادئ الخالدة.',
      'طاقات الشباب قادرة على تغيير مجرى التاريخ بإيمانها وعلمها.',
    ],
    lessonsEn: [
      'Calling to faith requires gentle wisdom and compassion.',
      'Material luxury is transient; spiritual legacy is eternal.',
      'Youthful dedication can change the course of history.',
    ],
    famousQuoteAr: '«جلس مصعب يتلو القرآن فانسابت القلوب لنوره»',
    famousQuoteEn:
        '"Mus\'ab recited the Quran and hearts surrendered to its light"',
    readTimeMinutes: 3,
    milestonesAr: [
      'ترك ثراء مكة ولباس الحرير ونعيم والدته لينال عز التوحيد والإيمان.',
      'أول سفير في الإسلام؛ بعثه النبي ﷺ إلى المدينة ليعلم الناس القرآن ويدعوهم بالحكمة.',
      'أسلم على يديه كبار سادات الأنصار مثل أسيد بن حضير وسعد بن معاذ فدخل الإسلام بيوت المدينة.',
      'حامل لواء المسلمين في غزوة بدر وغزوة أحد، واستشهد صامداً وهو يحمي راية التوحيد.',
    ],
    milestonesEn: [
      'Sacrificed Meccan luxury, perfumed silk, and maternal fortune for the light of faith.',
      'First diplomatic ambassador of Islam, sent to Madinah to teach the Quran with gentle grace.',
      'Through his teaching, prominent Ansar chieftains embraced Islam, opening all Madinah to faith.',
      'Muslim standard-bearer at Badr and Uhud, martyred heroically guarding the banner.',
    ],
    virtuesAr: [
      'بكى النبي ﷺ حين رآه في بردة مرقعة وقال: «لقد رأيتُ هذا وما بمكة فتى أنعم عند أبويه منه، ثم ترك ذلك كله حباً لله ولرسوله».',
      'تلا النبي ﷺ عند جثمانه في أحد: {مِّنَ الْمُؤْمِنِينَ رِجَالٌ صَدَقُوا مَا عَاهَدُوا اللَّهَ عَلَيْهِ}.',
    ],
    virtuesEn: [
      'The Prophet ﷺ wept seeing his humble patched cloth, praising his absolute sacrifice for Allah.',
      'The Prophet recited over him at Uhud: "Among the believers are men true to what they promised Allah."',
    ],
  ),
  CompanionStory(
    id: 'khalid-ibn-al-walid',
    category: CompanionCategory.men,
    nameAr: 'خالد بن الوليد',
    nameEn: 'Khalid ibn Al-Walid',
    titleAr: 'سيف الله المسلول والعبقري العسكري',
    titleEn: 'The Drawn Sword of Allah & Military Genius',
    emoji: '🗡️',
    summaryAr:
        'القائد الذي لم يُهزم في أكثر من مائة معركة، سيف من سيوف الله سلّه على الباطل.',
    summaryEn:
        'The undefeated tactical genius who fought over a hundred battles without a single loss.',
    storyAr:
        '''سماه النبي ﷺ "سيف الله المسلول"، وهو أحد أعظم القادة العسكريين والعباقرة التكتيكيين في تاريخ البشرية، خاض أكثر من مائة معركة حاسمة ولم يُهزم في معركة واحدة قط!

لما دخل الإسلام قلبه وأتى مسلماً إلى المدينة، رحب به النبي ﷺ وقال له: "الحمد لله الذي هداك، قد كنت أرى لك عقلاً رجوت ألا يسلمك إلا إلى خير".

في غزوة مؤتة استشهد القادة الثلاثة، فأخذ خالد الراية بحكمة وأنقذ الجيش الإسلامي بعبقرية انسحاب تكتيكي مذهل. وقاد معارك اليرموك واليمامة وفتح بلاد الشام والعراق مخلّصاً الشعوب من ظلم الإمبراطوريات الرومانية والفارسية.

ورغم كل هذه البطولات والأوسمة، كان قمة في الإخلاص؛ فعندما أمره عمر بن الخطاب بالتنازل عن قيادة الجيش لأبي عبيدة، أطاع فوراً وقاتل كجندي شجاع في الصفوف الأولى، قائلاً: "أنا لا أقاتل لعمر، إنما أقاتل لرب عمر".''',
    storyEn:
        '''Honored by the Prophet ﷺ with the title "The Drawn Sword of Allah," Khalid was one of the greatest military strategists in world history, fighting in over 100 battles without suffering a single defeat.

When he arrived in Madinah to accept Islam, the Prophet smiled: "Praise be to Allah who guided you; I always knew you had an intellect that would lead you to goodness."

At the Battle of Mu'tah, after three commanders fell, Khalid took the standard and brilliantly maneuvered the army to safety. He went on to lead pivotal campaigns in Yarmouk, liberating the Levant and Iraq from imperial tyranny. Despite his triumphs, his sincerity was paramount: when Caliph Umar relieved him of supreme command in favor of Abu Ubaydah, Khalid obeyed without hesitation and fought as an ordinary frontline soldier, proclaiming: "I do not fight for Umar, I fight for the Lord of Umar."''',
    lessonsAr: [
      'الإخلاص والتجرد للهدف الأسمى وليس للمناصب والشهرة.',
      'العبقرية والتخطيط الدقيق مع التوكل الكامل على الله.',
      'التواضع عند النصر والعمل بروح الفريق الواحد.',
    ],
    lessonsEn: [
      'Pure sincerity: working for the mission, not titles or glory.',
      'Meticulous planning combined with complete trust in Allah.',
      'Humility in victory and selfless teamwork.',
    ],
    famousQuoteAr: '«إني أقاتل لربّ عمر»',
    famousQuoteEn: '"I fight for the Lord of Umar"',
    readTimeMinutes: 4,
    milestonesAr: [
      'أسلم قبل فتح مكة وحظي بترحيب وفرح عظيم من النبي ﷺ برجاحة عقله.',
      'أنقذ جيش المسلمين بعبقرية انسحاب تكتيكي مذهل في غزوة مؤتة بعد استشهاد قادتها الثلاثة.',
      'قائد معارك حروب الردة واليمامة وتوحيد الجزيرة العربية تحت راية الإسلام.',
      'قائد معركة اليرموك الخالدة التي فتحت بلاد الشام، ومحرر العراق وفارس.',
      'ضرب أعظم مثل في التجرد والإخلاص عندما قَبِل أن يكون جندياً عادياً بإمرة أبي عبيدة طاعة للخليفة.',
    ],
    milestonesEn: [
      'Embraced Islam before Mecca\'s liberation, welcomed warmly by the Prophet.',
      'Strategically saved the Muslim army at the Battle of Mu\'tah through brilliant tactical retreat.',
      'Commander of the Yamama campaign reunifying Arabia under the banner of Tawhid.',
      'Architect of the victory at the Battle of Yarmouk, liberating the Levant.',
      'Demonstrated supreme sincerity by gladly serving as a frontline soldier under Abu Ubaydah.',
    ],
    virtuesAr: [
      'سماه النبي ﷺ: «سيف الله المسلول سلّه الله على المشركين».',
      'قال أبو بكر الصديق: «عجزت النساء أن يلدن مثل خالد بن الوليد».',
      'قال خالد عند وفاته: «لقد شهدتُ مائة زحف وما في بدني موضع شبر إلا وفيه ضربة بسيف أو رمية بسهم.. فلا نامت أعين الجبناء».',
    ],
    virtuesEn: [
      'Honored by the Prophet ﷺ as: "The Drawn Sword of Allah against falsehood."',
      'Abu Bakr remarked: "Women are unable to give birth to the likes of Khalid ibn Al-Walid."',
      'Khalid declared on his deathbed: "I fought in a hundred battles, yet here I die on my bed; let the eyes of cowards never sleep!"',
    ],
  ),
  CompanionStory(
    id: 'salman-al-farsi',
    category: CompanionCategory.men,
    nameAr: 'سلمان الفارسي',
    nameEn: 'Salman Al-Farsi',
    titleAr: 'الباحث الدؤوب عن الحقيقة وصاحب الخندق',
    titleEn: 'The Truth Seeker & Architect of the Trench',
    emoji: '🔍',
    summaryAr:
        'ترك بلاده وراحته وسافر آلاف الكيلومترات بحثاً عن نبي آخر الزمان حتى لقيه بالمدينة.',
    summaryEn:
        'Traveled thousands of miles through slavery and hardship in pursuit of truth until finding the Prophet.',
    storyAr:
        '''قصة سلمان هي ملحمة البحث عن الحق واليقين؛ كان ابناً لزعيم فارسي غني في أصبهان، وعبَد النار كما كان قومه يفعلون، لكن قلبه لم يطمئن.

ترك ثروة أهله وسافر إلى الشام ثم الموصل ثم نصيبين متتلمذاً على يد الرهبان الصالحين بحثاً عن دين الله الحقيقي. وقبل وفاة آخر معلم له، أخبره: "قد أظلّك زمان نبي يخرج في أرض العرب، يهاجر إلى أرض بين حرتين فيها نخل، وله علامات: لا يأكل الصدقة، ويقبل الهدية، وبين كتفيه خاتم النبوة".

باع نفسه لقافلة لتنقله إلى بلاد العرب، فغدروا به وباعوه عبداً ليهودي حتى استقر به الحال في المدينة المنورة. وعندما هاجر النبي ﷺ، تحقق سلمان من العلامات الثلاث بدقة حتى رآها كلها، فبكى وقبّل رأس رسول الله ﷺ معلناً إسلامه!

وفي غزوة الأحزاب، عندما تحالفت قبائل العرب مع اليهود لمحاصرة المدينة، اقترح سلمان فكرة عسكرية لم تكن تعرفها العرب: "يا رسول الله، كنا بفارس إذا حُوصِرنا خندقنا"، فكان حفر الخندق سبباً رئيسياً في نجاة المسلمين. وقرّبه النبي ﷺ حتى قال: "سلمان منا أهل البيت".''',
    storyEn:
        '''Salman's life was an epic odyssey for truth. Born to an affluent nobleman in Persia, he was groomed for high priesthood, but his heart found no peace in idolizing fire.

Abandoning luxury, he traveled across Damascus, Mosul, and Amuria learning from devout Christian monks. His final teacher told him: "The time of a Prophet has drawn near in Arabia. He migrates to a palm-strewn land. His marks are clear: he eats from gifts but not charity, and between his shoulders is the Seal of Prophethood."

Deceived by merchants who enslaved him, Salman was sold until he ended up in Madinah. When the Prophet arrived, Salman verified every single sign, broke into joyful tears, and embraced Islam. During the Battle of the Trench, he introduced the strategy of digging an uncrossable moat, saving Madinah. The Prophet honored him deeply, stating: "Salman is one of us, the People of the House."''',
    lessonsAr: [
      'السعي الدؤوب والشجاع للوصول إلى الحقيقة مهما طال الطريق.',
      'الإبداع والانفتاح على تجارب الشعوب وثقافاتهم النافعة.',
      'الإسلام يكرم الصادقين ويرفع من شأنهم.',
    ],
    lessonsEn: [
      'Unrelenting pursuit of truth regardless of hardship.',
      'Openness to beneficial knowledge and innovative strategies.',
      'Faith elevates seekers above worldly origins.',
    ],
    famousQuoteAr: '«سلمانُ منّا أهلَ البيت»',
    famousQuoteEn:
        '"Salman is one of us, the People of the Prophetic Household"',
    readTimeMinutes: 4,
    milestonesAr: [
      'قطع آلاف الأميال متحملاً الرق والغربة في رحلة طويلة وشاقة بحثاً عن الدين الحق.',
      'تحقق من علامات النبوة الثلاث في المدينة وأسلم فرحاً بلقاء الحبيب ﷺ.',
      'صاحب خطة حفر الخندق العبقرية في غزوة الأحزاب التي حمت المدينة من استئصال المشركين.',
      'تولى إمارة المدائن وعاش أزهد الناس ينسج الخوص ويأكل من كسب يده.',
    ],
    milestonesEn: [
      'Traveled thousands of miles through slavery and exile in a relentless search for true faith.',
      'Verified the three prophetic signs upon reaching Madinah and embraced Islam with tears of joy.',
      'Conceived the revolutionary moat strategy in the Battle of the Trench, shielding Madinah.',
      'Governed Al-Mada\'in living in complete asceticism, weaving palm fronds to earn his daily bread.',
    ],
    virtuesAr: [
      'قال النبي ﷺ إكراماً له: «سلمان منا أهل البيت».',
      'كان علي بن أبي طالب يقول عنه: «سلمان امرؤ منا أهل البيت، علم العلم الأول والآخر، بحر لا ينزف».',
    ],
    virtuesEn: [
      'The Prophet ﷺ honored him profoundly: "Salman is one of us, the People of the Household."',
      'Ali described him: "Salman is one of us, the People of the House; he mastered the first and last knowledge, an unexhausted ocean."',
    ],
  ),
  CompanionStory(
    id: 'saad-ibn-abi-waqqas',
    category: CompanionCategory.men,
    nameAr: 'سعد بن أبي وقاص',
    nameEn: 'Sa\'d ibn Abi Waqqas',
    titleAr: 'أول من رمى بسهم في سبيل الله ومستجاب الدعوة',
    titleEn: 'The Archer of Islam & The Man Whose Prayers Were Answered',
    emoji: '🏹',
    summaryAr:
        'خال النبي ﷺ، وأحد العشرة المبشرين بالجنة، وبطل معركة القادسية التاريخية.',
    summaryEn:
        'Maternal uncle of the Prophet, promised Paradise, and victorious general of the Battle of Al-Qadisiyyah.',
    storyAr:
        '''أسلم سعد وهو شاب في السابعة عشرة من عمره، وكان من أوائل من دخلوا في دين الله. كان النبي ﷺ يعتز به ويقول مازحاً بفخر: "هذا خالي فليرني امرؤ خاله!".

دعا له رسول الله ﷺ بدعوة مباركة: "اللهم سدّد رميته، وأجب دعوته"، فكان سعد لا يرمي سهماً إلا أصاب هدفه بدقة، ولا يدعو الله بدعاء إلا استُجيب له في الحال، فكان الصحابة يهابون دعوته ويحرصون على بره.

واجه سعد امتحاناً صعباً في بر والدته؛ إذ أضربت أمه عن الطعام والشراب حتى تكاد تموت لتجبره على ترك الإسلام، فثبت برفق وحزم وقال لها ببر صادق: "يا أماه، لو كانت لك مائة نفس فخرجت نفساً نفساً ما تركت ديني هذا لشيء، فإن شئتِ فكلي وإن شئتِ فلا تأكلي"، فلما رأت ثباته أكلت ورضخت.

قاد جيوش المسلمين في معركة القادسية الفاصلة التي أنهت الوجود الإمبراطوري لكسرى وفتحت العراق لنور الإسلام والعدالة.''',
    storyEn:
        '''Sa'd embraced Islam at seventeen, among the very first pioneers. The Prophet was fond of him and would proudly joke: "This is my maternal uncle; let anyone show me his uncle!"

The Prophet ﷺ made a special supplication for him: "O Allah, make his aim straight and answer his prayers." Consequently, Sa'd never shot an arrow that missed, and whenever he supplicated, Allah answered immediately.

He faced a fierce test of devotion when his mother went on a hunger strike to force him away from Islam. With gentle firmness, he said: "O mother! Even if you had a hundred souls and each left one by one, I would never abandon my faith. So eat if you wish, or abstain." Seeing his unwavering faith, she yielded. He later commanded the epochal Battle of Al-Qadisiyyah, bringing freedom and justice to the lands of the East.''',
    lessonsAr: [
      'الثبات على الحق مع المحافظة على بر الوالدين وأدب الحوار.',
      'أثر الدعاء المستجاب في حياة المؤمن ونصرة أمته.',
      'إتقان المهارات والبراعة في العمل.',
    ],
    lessonsEn: [
      'Steadfast adherence to truth paired with respectful kindness to parents.',
      'The immense power of answered prayer.',
      'Mastery and excellence in one\'s craft and responsibilities.',
    ],
    famousQuoteAr: '«اللهم سدّد رميته، وأجب دعوته»',
    famousQuoteEn: '"O Allah, make his aim straight and answer his prayers"',
    readTimeMinutes: 3,
    milestonesAr: [
      'أول من رمى بسهم في سبيل الله لحماية النبي ﷺ والدعوة الإسلامية.',
      'ثبت في بر والدته برفق دون أن يفرط في ذرة من دينه حين أضربت عن الطعام.',
      'قائد جيش المسلمين وبطل معركة القادسية التاريخية التي فتحت بلاد الرافدين وإيران.',
      'أحد العشرة المبشرين بالجنة وأحد الستة أصحاب الشورى لاختيار الخليفة.',
    ],
    milestonesEn: [
      'First archer to shoot an arrow in the cause of Allah protecting the Prophet.',
      'Stood steadfast in filial kindness without compromising an ounce of faith during his mother\'s strike.',
      'Supreme commander and hero of the Battle of Al-Qadisiyyah, opening Mesopotamia.',
      'Among the ten promised Paradise and one of the six council electors for the Caliphate.',
    ],
    virtuesAr: [
      'دعا له النبي ﷺ: «اللهم سدد رميته، وأجب دعوته»، فكان مجاب الدعوة مهاب السهم.',
      'قال له النبي ﷺ في غزوة أحد فادياً إياه بأبويه: «ارمِ سعد، فداك أبي وأمي».',
    ],
    virtuesEn: [
      'The Prophet ﷺ prayed for him: "O Allah, make his aim straight and answer his supplication."',
      'The Prophet exclaimed at Uhud: "Shoot, Sa\'d, may my father and mother be sacrificed for you!"',
    ],
  ),
  CompanionStory(
    id: 'abdullah-ibn-masud',
    category: CompanionCategory.men,
    nameAr: 'عبد الله بن مسعود',
    nameEn: 'Abdullah ibn Mas\'ud',
    titleAr: 'صاحب سر رسول الله وأول من جهر بالقرآن',
    titleEn: 'Keeper of the Prophet\'s Secrets & Reciter of Mecca',
    emoji: '📜',
    summaryAr:
        'الراعي البسيط الذي أصبح فقيهاً وقارئاً تهتز لصوته القلوب، وثبت أمام جبروت قريش.',
    summaryEn:
        'A humble shepherd who became Islam\'s preeminent scholar and reciter, courageous in proclaiming the Quran.',
    storyAr:
        '''كان عبد الله بن مسعود شاباً نحيلاً يرعى غنم عقبة بن أبي معيط. التقى بالنبي ﷺ وأبي بكر وهما مطاردان، فأكرمهما بلبن شاة لم ينزُ عليها فحل ببركة يد النبي الشريفة، فطلب ابن مسعود أن يتعلم منه، فقال له النبي: "إنك غلام معلّم".

كان ابن مسعود أول من جهر بالقرآن الكريم بمكة المكرمة؛ خرج إلى مقام إبراهيم في بطن مكة ورفع صوته بتلاوة سورة الرحمن أمام صناديد قريش وهم مجتمعون، فهجموا عليه وضربوه ضرباً مبرحاً حتى سالت دماؤه، ثم عاد في اليوم التالي مستعداً لتلاوته ثانية دون خوف!

كان ملازماً لرسول الله ﷺ؛ يحمل نعليه وسواكه ووسادته، حتى قال عنه النبي: "من أحب أن يقرأ القرآن غضاً كما أُنزل فليقرأه بقراءة ابن أم عبد". وحين ضحك بعض الصحابة من دقة ساقيه، قال النبي ﷺ معلماً درساً في موازين القيم: "والذي نفسي بيده، لهما أثقل في الميزان يوم القيامة من جبل أُحد!".''',
    storyEn:
        '''Abdullah ibn Mas'ud was a slender young shepherd in Mecca. When he met the Prophet ﷺ and Abu Bakr, he recognized the miraculous light of prophethood and requested knowledge. The Prophet smiled: "You are a boy destined to be taught."

He was the first Muslim to publicly recite the Quran aloud in Mecca. Walking boldly to the Ka'bah, he chanted Surah Ar-Rahman in the faces of Mecca's arrogant chiefs. They assaulted him until his face bled, yet he declared he was ready to do it again the next morning!

He became the Prophet's personal confidant, carrying his sandals and miswak. The Prophet praised his recitation: "Whoever desires to recite the Quran freshly as it was revealed, let him recite it according to the recitation of Ibn Umm Abd." When companions once giggled at the thinness of his legs, the Prophet corrected them: "By Him in whose hand is my soul, they are heavier in the scales on the Day of Judgment than Mount Uhud!"''',
    lessonsAr: [
      'ميزان التفاضل عند الله هو التقوى والعمل الصالح وليس المظهر الجسدي.',
      'الشجاعة في نصرة كتاب الله والاعتزاز بتلاوته وسماعه.',
      'ملازمة أهل العلم والصلاح تورث الفقه والحكمة.',
    ],
    lessonsEn: [
      'True weight before Allah is measured by virtue, not physical appearance.',
      'Fearless devotion to divine words.',
      'Keeping company with teachers of wisdom cultivates deep understanding.',
    ],
    famousQuoteAr: '«لهما أثقل في الميزان من جبل أُحد»',
    famousQuoteEn: '"They are heavier in the scale than Mount Uhud"',
    readTimeMinutes: 3,
    milestonesAr: [
      'سادس من أسلم في الإسلام ولازم النبي ﷺ ملازمة الظل لخدمته والتعلم منه.',
      'أول من جهر بالقرآن الكريم بمكة عند الكعبة وتحمل بطش قريش بشجاعة وثبات.',
      'صاحب وسادة وسواك ونعلي النبي ﷺ ومستودع أسراره النبوية.',
      'فقيه الأمة وإمام الكوفة ومعلم جيل التابعين علوم التفسير والفقه والقرآن.',
    ],
    milestonesEn: [
      'Sixth person to embrace Islam, becoming the Prophet\'s constant shadow and personal assistant.',
      'First Muslim to publicly recite the Quran aloud at the Ka\'bah, braving brutal beatings.',
      'Keeper of the Prophet\'s sandals, tooth-stick, and pillow, trusted with confidential matters.',
      'Supreme jurist and master scholar of Kufa, founding the classic school of Islamic jurisprudence.',
    ],
    virtuesAr: [
      'قال النبي ﷺ: «من أحب أن يقرأ القرآن غضاً كما أُنزل فليقرأه على قراءة ابن أم عبد».',
      'قال النبي ﷺ حين ضحكوا من دقة ساقيه: «والذي نفسي بيده لهما أثقل في الميزان من جبل أحد».',
      'قال النبي ﷺ: «تمسكوا بعهد ابن مسعود».',
    ],
    virtuesEn: [
      'The Prophet ﷺ said: "Whoever wishes to recite the Quran freshly as it was revealed, let him recite it according to Ibn Umm Abd."',
      'The Prophet said regarding his slender legs: "By Him in Whose Hand is my soul, they are heavier in the scales than Mount Uhud!"',
      'The Prophet instructed: "Hold firmly to the counsel of Ibn Mas\'ud."',
    ],
  ),
];

/// قصص نساء حول الرسول ﷺ
const List<CompanionStory> womenCompanionsList = [
  CompanionStory(
    id: 'khadijah-bint-khuwaylid',
    category: CompanionCategory.women,
    nameAr: 'خديجة بنت خويلد',
    nameEn: 'Khadijah bint Khuwaylid',
    titleAr: 'أم المؤمنين وسند الرسول وسيدة نساء العالمين',
    titleEn: 'Mother of the Believers & The Prophet\'s Greatest Comfort',
    emoji: '👑',
    summaryAr:
        'أول من آمن بالإسلام مطلقاً، واحتضنت النبي ﷺ في أحلك ساعاته وبذلت ثروتها كلها في سبيل الله.',
    summaryEn:
        'The first person to embrace Islam, comforting the Prophet during revelation and dedicating everything to him.',
    storyAr:
        '''كانت خديجة رضي الله عنها سيدة نساء قريش حكمة ونسباً وشرفاً وتجارة. عرفت صدق وأمانة محمد ﷺ قبل البعثة فتزوجته وكانت نعم الزوجة والسند.

حين نزل الوحي على النبي ﷺ في غار حراء لأول مرة، عاد إلى بيته يرتجف فزعاً وهو يقول: "زمّلوني.. دثّروني!". فما كان من خديجة إلا أن احتضنته بحنان وحكمة وطمأنته بجملتها التاريخية الخالدة التي تفيض يقيناً:
"كلا والله! ما يخزيك الله أبداً؛ إنك لتصل الرحم، وتحمل الكلّ، وتكسب المعدوم، وتقري الضيف، وتعين على نوائب الحق".

كانت أول من أسلم على وجه الأرض، وبذلت كل أموالها لخدمة الدعوة وإطعام المحاصرين في شِعب أبي طالب. أقرأها الله السلام من فوق سبع سماوات على لسان جبريل عليه السلام وبشّرها ببيت في الجنة من قصب لا صخب فيه ولا نَصَب. وظل النبي ﷺ يذكر فضلها وحبها طوال حياته ويقول: "إني رُزقتُ حبّها".''',
    storyEn:
        '''Khadijah was the most respected and noble businesswoman in Mecca. Recognizing Muhammad's ﷺ honesty and immaculate character, she married him and became his greatest lifelong confidante.

When divine revelation first struck the Prophet in the cave of Hira, he returned trembling with awe, crying: "Cover me! Wrap me up!" Khadijah embraced him with maternal tenderness and utter certainty, uttering words of timeless solace:
"Never! By Allah, Allah will never disgrace you; for you uphold ties of kinship, bear burdens for the weak, help the destitute, honor guests, and stand by those struck by calamities."

She was the first human to believe in Islam. She exhausted her vast fortune feeding Muslims during the brutal boycott in Mecca. The Angel Jibril conveyed greetings of peace (Salam) to her directly from Allah, promising her a palace in Paradise free of fatigue and clamor. The Prophet cherished her memory throughout his life, saying: "I was blessed with her love."''',
    lessonsAr: [
      'الدور العظيم للمرأة الصالحة في تثبيت زوجها ودعم رسالته.',
      'أن صنائع المعروف والخير تمنع مصارع السوء وتقي من الخوف.',
      'الوفاء الخالد والحب الصادق الذي لا يغيره الزمان.',
    ],
    lessonsEn: [
      'The tremendous power of emotional support and wisdom in partnership.',
      'Good deeds, charity, and honoring others bring divine reassurance.',
      'Enduring love and loyalty that outlive this world.',
    ],
    famousQuoteAr: '«كلا والله لا يخزيك الله أبداً»',
    famousQuoteEn: '"Never by Allah! Allah will never disgrace you"',
    readTimeMinutes: 4,
    milestonesAr: [
      'أول من آمن بالإسلام على وجه الأرض من الرجال والنساء دون أدنى تردد.',
      'ثبّتت النبي ﷺ عند نزول الوحي الأول بكلماتها الخالدة: «كلا والله ما يخزيك الله أبداً».',
      'بذلت ثروتها الطائلة كلها في إعالة الدعوة والإنفاق على المحاصرين في الشِّعب.',
      'نالت سلاماً خاصاً من الله تعالى وبشارة بقصر من قصب في الجنة لا صخب فيه ولا نصب.',
    ],
    milestonesEn: [
      'First person on earth to believe in Islam, supporting the Prophet without hesitation.',
      'Comforted the Prophet at first revelation with immortal words: "Never! Allah will never disgrace you."',
      'Dedicated her immense fortune to sustain believers through persecution and tribal boycotts.',
      'Blessed with divine greetings directly from Allah conveyed through the Angel Jibril.',
    ],
    virtuesAr: [
      'قال النبي ﷺ مبيناً منزلتها: «خير نسائها مريم بنت عمران، وخير نسائها خديجة بنت خويلد».',
      'قال النبي ﷺ وفاءً لها: «إني رُزقت حبها، ما أبدلني الله خيراً منها؛ آمنت بي إذ كفر بي الناس».',
      'بشرها جبريل عليه السلام ببيت في الجنة من قصب لا صخب فيه ولا نصب.',
    ],
    virtuesEn: [
      'The Prophet ﷺ praised: "The best of women was Maryam daughter of Imran, and the best of women was Khadijah daughter of Khuwaylid."',
      'The Prophet remembered her with lifelong love: "I was blessed with her love; she believed in me when people rejected me."',
      'Jibril brought glad tidings of a palace for her in Paradise made of hollow pearls without clamor or fatigue.',
    ],
  ),
  CompanionStory(
    id: 'aisha-bint-abi-bakr',
    category: CompanionCategory.women,
    nameAr: 'عائشة بنت أبي بكر',
    nameEn: 'Aisha bint Abi Bakr',
    titleAr: 'الصديقة العالمة وفقيهة الأمة',
    titleEn: 'The Truthful Scholar & Mother of the Believers',
    emoji: '📚',
    summaryAr:
        'أحب الناس إلى رسول الله ﷺ، والعالمة العبقرية التي حفظت ونقلت ربع الشريعة الإسلامية للأمة.',
    summaryEn:
        'Beloved wife of the Prophet, master jurist, orator, and prolific transmitter of prophetic wisdom.',
    storyAr:
        '''سُئل رسول الله ﷺ يوماً: "من أحب الناس إليك؟"، فقال بلا تردد وبكل وضوح: "عائشة"، فقيل: "ومن الرجال؟"، قال: "أبوها".

كانت عائشة رضي الله عنها تتمتع بذكاء حاد وذاكرة فوتوغرافية مذهلة وبلاغة لغوية نادرة. عاشت في بيت النبوة، فكانت تدقق في كل تصرف وسنة وحكم، ونقلت للأمة أكثر من ألفي حديث شريف، موثقة تفاصيل حياة النبي ﷺ داخل بيته ومحيطه.

كان كبار الصحابة كعمر وعلي وابن عباس يرجعون إليها في المسائل الفقهية والفرائض وحل الخلافات، حتى قال الصحابي أبو موسى الأشعري: "ما أشكل علينا أصحاب رسول الله ﷺ حديث قط فسألنا عائشة إلا وجدنا عندها منه علماً". وكانت إلى جانب علمها الغزير، كريمة زاهدة تتصدق بآلاف الدنانير وهي صائمة ولا تبقي لنفسها حتى رغيف عشاء.''',
    storyEn:
        '''When the Prophet ﷺ was publicly asked: "Who is the most beloved of people to you?", he answered without hesitation: "Aisha." Asked about men, he smiled: "Her father."

Endowed with exceptional intellect, photographic memory, and unmatched eloquence, Aisha lived at the epicenter of revelation. She transmitted over 2,000 hadiths, documenting the intimate ethics and daily conduct of the Prophet.

Eminent companions frequently consulted her on intricate legal rulings and inheritance law. Abu Musa al-Ash'ari testified: "Whenever we companions faced a difficult matter and consulted Aisha, we always found she had decisive knowledge of it." Alongside her scholarship, she was extraordinarily generous, once giving away thousands of dirhams in charity while fasting, leaving not a single loaf of bread for her own dinner.''',
    lessonsAr: [
      'طلب العلم والتفقه في الدين فريضة وشرف عظيم للمرأة والرجل.',
      'قوة حجة المرأة المسلمة ومشاركتها في تعليم وإرشاد المجتمع.',
      'الكرم والسخاء مع الزهد في حطام الدنيا الزائل.',
    ],
    lessonsEn: [
      'Pursuit of rigorous knowledge is a noble obligation for everyone.',
      'The intellectual leadership and scholarship of women in Islam.',
      'Selfless generosity coupled with simplicity of lifestyle.',
    ],
    famousQuoteAr: '«سُئل النبي ﷺ: من أحب الناس إليك؟ قال: عائشة»',
    famousQuoteEn:
        '"The Prophet was asked: Who is most beloved to you? He said: Aisha"',
    readTimeMinutes: 3,
    milestonesAr: [
      'عاشت في كنف بيت النبوة ونقلت أدق تفاصيل السنة النبوية الشريفة وأخلاق النبي ﷺ.',
      'روّت أكثر من 2200 حديث شريف وكانت من أخصب الرواة فصاحة ودقة وحفظاً وعقلاً.',
      'مرجع كبار الصحابة في الإفتاء وقسمة الفرائض والمواريث والطب والأدب والشعر.',
      'برأها الله تعالى بآيات من فوق سبع سماوات في سورة النور تتلى في المحاريب إلى يوم القيامة.',
    ],
    milestonesEn: [
      'Lived at the heart of the Prophet\'s household, chronicling his daily ethics and private worship.',
      'Transmitted over 2,200 authentic hadiths with unparalleled photographic accuracy and eloquence.',
      'Premier reference for senior companions in complex jurisprudence, inheritance, medicine, and Arabic rhetoric.',
      'Vindicated directly by Allah in Surat An-Nur through divine verses recited eternally in prayer.',
    ],
    virtuesAr: [
      'قال النبي ﷺ: «فضل عائشة على النساء كفضل الثريد على سائر الطعام».',
      'سئل النبي ﷺ: من أحب الناس إليك؟ قال: «عائشة»، قيل: ومن الرجال؟ قال: «أبوها».',
      'قال مسروق: «رأيت مشيخة أصحاب رسول الله ﷺ الأكابر يسألونها عن الفرائض».',
    ],
    virtuesEn: [
      'The Prophet ﷺ said: "The superiority of Aisha over other women is like the superiority of Tharid over all other food."',
      'Asked who was dearest to his heart, the Prophet proclaimed: "Aisha!" and among men: "Her father."',
      'Leading scholars of the companions traveled from afar to seek her binding legal determinations.',
    ],
  ),
  CompanionStory(
    id: 'fatimah-az-zahra',
    category: CompanionCategory.women,
    nameAr: 'فاطمة الزهراء',
    nameEn: 'Fatimah Az-Zahra',
    titleAr: 'سيدة نساء أهل الجنة وبضعة الرسول',
    titleEn: 'Leader of the Women of Paradise & Heart of the Prophet',
    emoji: '🌸',
    summaryAr:
        'أصغر بنات النبي ﷺ وأحبهن إلى قلبه، لُقبت بأم أبيها لحنانها ورعايتها لرسول الله ﷺ.',
    summaryEn:
        'Youngest and most cherished daughter of the Prophet, called "The Mother of her Father" for her tender care.',
    storyAr:
        '''كانت فاطمة رضي الله عنها أشبه الناس بأبيها رسول الله ﷺ في مشيتها وكلامها وهديه، وكان النبي إذا رآها مقبلة قام إليها فرحاً وقبّل ما بين عينيها وأجلسها في مجلسه، ويقول عنها: "فاطمة بضعة مني، فمن أغضبها أغضبني".

منذ طفولتها وقفت بجانب أبيها في مكة؛ فلما ألقى المشركون سلا الجزور (أوساخ الشاة) على ظهر النبي وهو ساجد عند الكعبة، هرعت الطفلة الصغيرة فاطمة وأزالت الأذى عن والدها ووبخت المشركين بشجاعة، ولذلك لُقبت بـ "أم أبيها" لحنانها الفائق عليه.

تزوجت من علي بن أبي طالب وعاشت حياة التقشف والصبر وطحن الشعير بيديها حتى مجلت يداها (ظهرت فيها القروح)، وأنجبت سيدي شباب أهل الجنة: الحسن والحسين. بشرها النبي ﷺ بأنها سيدة نساء أهل الجنة في مشهد يفيض بالمحبة والكرامة.''',
    storyEn:
        '''Fatimah closely resembled her father in gait, speech, and noble demeanor. Whenever she entered, the Prophet ﷺ would stand up in joy, kiss her forehead, and seat her in his own place, stating: "Fatimah is a part of me; whoever hurts her hurts me."

Her devotion began in early childhood. When Meccan oppressors cast camel entrails upon the Prophet while he was prostrating at the Ka'bah, the young girl rushed forward, cleaned her father's back, and bravely confronted the tyrants. For her tender protective care, she was honored as "The Mother of her Father."

She married Ali, living a life of humble simplicity, personally grinding flour with millstones until her hands blistered, and raised the beloved grandsons Hasan and Husayn. The Prophet brought her glad tidings that she is the supreme leader of the women of Paradise.''',
    lessonsAr: [
      'بر الوالدين والحنان عليهم ورعايتهم في كل الظروف.',
      'الصبر على شظف العيش والقناعة بما قسم الله.',
      'مكانة الابنة العظيمة في الإسلام والحب النبوي الفياض للبنات.',
    ],
    lessonsEn: [
      'Tender devotion and unconditional care for parents.',
      'Graceful patience and contentment in simple circumstances.',
      'The profound honor and affection shown to daughters in Islam.',
    ],
    famousQuoteAr: '«فاطمة بضعة مني، يريبني ما رابها»',
    famousQuoteEn:
        '"Fatimah is a part of me; whatever troubles her troubles me"',
    readTimeMinutes: 3,
    milestonesAr: [
      'أشبه الناس بأبيها النبي ﷺ مشية وهدياً وحديثاً وسمتاً ووقاراً.',
      'دافعت عن والدها بشجاعة وهي طفلة صغيرة وأزالت الأذى عن ظهره الشريف عند الكعبة.',
      'صبرت على شظف العيش وطحن الشعير بيدها حتى نالت شرف الآخرة.',
      'أم سيدي شباب أهل الجنة: الحسن والحسين رضي الله عنهما.',
    ],
    milestonesEn: [
      'Bearing the closest resemblance to the Prophet ﷺ in gait, speech, dignity, and conduct.',
      'Defended her father as a brave young child, wiping filth from his back at the Ka\'bah.',
      'Endured humble poverty, grinding wheat with her own hands with serene patience.',
      'Mother of the two leaders of the youth of Paradise: Al-Hasan and Al-Husayn.',
    ],
    virtuesAr: [
      'قال النبي ﷺ: «فاطمة بضعة مني، يريبني ما رابها، ويؤذيني ما آذاها».',
      'بشرها النبي ﷺ بأنها: «سيدة نساء أهل الجنة» وسيدة نساء العالمين.',
      'كان النبي ﷺ إذا دخلت عليه قام إليها فرحاً فقبّل جبهتها وأجلسها في مجلسه.',
    ],
    virtuesEn: [
      'The Prophet ﷺ said: "Fatimah is a piece of me; whatever doubts trouble her trouble me, and whatever hurts her hurts me."',
      'Given glad tidings by the Prophet as the Queen and supreme leader of the women of Paradise.',
      'Whenever she arrived, the Prophet would stand up to honor her, kiss her forehead, and seat her in his own place.',
    ],
  ),
  CompanionStory(
    id: 'asma-bint-abi-bakr',
    category: CompanionCategory.women,
    nameAr: 'أسماء بنت أبي بكر',
    nameEn: 'Asma bint Abi Bakr',
    titleAr: 'ذات النطاقين وبطلة الهجرة النبوية',
    titleEn: 'She of the Two Waistbands & Heroine of the Hijrah',
    emoji: '🏔️',
    summaryAr:
        'الفتاة الشجاعة التي حملت المؤونة للغار وشقت نطاقها، ووقفت كالجبل الأشم في أصعب المواقف.',
    summaryEn:
        'The fearless heroine who transported supplies to the cave, tore her belt to pack provisions, and defied tyrants.',
    storyAr:
        '''لُقبت أسماء رضي الله عنها بـ "ذات النطاقين" لأنها في ليلة الهجرة النبوية، حين جهزت طعام النبي ﷺ وأبيها، لم تجد ما تربط به السفرة، فشقت حزامها (نطاقها) نصفين فربطت بأحدهما الطعام وتحزمت بالآخر، فدعا لها النبي بـ "نطاقين في الجنة".

كانت حاملاً تصعد جبل ثور الوعر في ظلام الليل الدامس لتنقل الطعام والأخبار للنبي ﷺ دون أن يشعر بها كفار قريش. ولما جاء أبو جهل إلى بيتها يبحث عن أبيها وصفعها بقسوة على وجهها حتى سقط قرطها، ثبتت كالجبل ولم تنطق بحرف واحد!

عاشت أكثر من مائة عام دون أن يسقط لها سن أو يفقد عقلها ذرة من حكمته. وحين جاءها ابنها عبد الله بن الزبير يستشيرها وهو محاصر يواجه الموت، قالت له كلمتها الخالدة في العزة والكرامة: "يا بني، إن كنت على حق فامضِ له، فلا يلعبنّ بك صبيان بني أمية.. وإن الشاة لا يضرها سلخها بعد ذبحها!".''',
    storyEn:
        '''Asma earned the historic title "Dhat An-Nitaqayn" (She of the Two Waistbands). On the night of the Hijrah, when preparing rations for the Prophet and her father, she found nothing to tie the food bags. Ingeniously, she ripped her waistband in two, using one piece to tie the provisions and the other as her belt. The Prophet promised her two girdles of light in Paradise.

Though heavily pregnant, she navigated treacherous mountain paths in total darkness to supply the cave with sustenance and intelligence. When the tyrant Abu Jahl slapped her fiercely across the face demanding her father's whereabouts, she stood immovable and revealed nothing.

Living past a hundred years with razor-sharp wisdom, when her son Abdullah ibn al-Zubayr consulted her while besieged by imperial forces, she uttered her legendary words of defiance: "O my son, if you are upon the truth, persevere! Do not let tyrant boys toy with your dignity. A slaughtered sheep feels no pain from being skinned!"''',
    lessonsAr: [
      'الشجاعة الفائقة والذكاء التكتيكي في نصرة القضايا العادلة.',
      'كتمان الأسرار وتحمل الأذى في سبيل حماية من تحب.',
      'تربية الأبناء على العزة والشرف والمبادئ التي لا تُباع.',
    ],
    lessonsEn: [
      'Tactical ingenuity and fierce courage in righteous causes.',
      'Guarding confidential matters under pressure.',
      'Raising children upon unyielding honor and principled integrity.',
    ],
    famousQuoteAr: '«إن الشاة لا يضرها سلخها بعد ذبحها»',
    famousQuoteEn: '"A slaughtered sheep feels no pain from being skinned"',
    readTimeMinutes: 4,
    milestonesAr: [
      'بطلة ليلة الهجرة؛ شقت نطاقها نصفين لتربط زاد النبي وأبيها فنالت لقب (ذات النطاقين).',
      'صعدت جبل ثور الوعر في ظلام الليل وهي حامل لتزويد الغار بالطعام والأخبار.',
      'صمدت في وجه أبي جهل حين لطمها ولم تفشِ سر مكان رسول الله وأبيها.',
      'عاشت مائة عام بكامل وعيها وقوتها وربت ابنها عبد الله بن الزبير على المبادئ والعزة.',
    ],
    milestonesEn: [
      'Heroine of the Hijrah; split her waistband in two to tie the Prophet\'s rations, earning her legendary title.',
      'Scaled steep Mount Thawr in night darkness while pregnant to deliver food and vital intelligence.',
      'Defied Abu Jahl with unbending courage when struck, keeping the Prophet\'s refuge secret.',
      'Lived to over 100 years with immaculate intellect, raising Abdullah ibn al-Zubayr upon uncompromising honor.',
    ],
    virtuesAr: [
      'دعا لها النبي ﷺ بأن يبدلها الله بنطاقها نطاقين في الجنة.',
      'موقفها الخالد مع ابنها المحاصر: «إن الشاة لا يضرها سلخها بعد ذبحها، فامضِ على بصيرتك» مستعلية على الباطل.',
    ],
    virtuesEn: [
      'The Prophet promised her two waistbands of light in Paradise in return for her sacrifice.',
      'Immortal words of conviction to her besieged son: "A slaughtered sheep feels no pain from being skinned; persevere upon your truth!"',
    ],
  ),
  CompanionStory(
    id: 'nusaybah-bint-kaab',
    category: CompanionCategory.women,
    nameAr: 'نسيبة بنت كعب (أم عمارة)',
    nameEn: 'Nusaybah bint Ka\'ab (Umm Umarah)',
    titleAr: 'بطلة غزوة أحد وحامية رسول الله بالسيف',
    titleEn: 'Heroine of Uhud & Shield of the Messenger',
    emoji: '🛡️',
    summaryAr:
        'الصحابية الباسلة التي حملت السيف والترس وقاتلت حول النبي ﷺ حتى أثخنتها الجراح.',
    summaryEn:
        'The legendary warrior who stood with sword and shield directly defending the Prophet when troops scattered.',
    storyAr:
        '''خرجت نسيبة رضي الله عنها في غزوة أحد مع زوجها وابنيها لتسقي العطشى وتداوي الجرحى. لكن عندما اضطرب صفوف المسلمين وتراجع الرماة وهاجم جيش المشركين النبي ﷺ مباشرة، ألقت نسيبة قربة الماء ورفعت السيف والترس!

وقفت نسيبة إلى جانب ثلة قليلة تحيط برسول الله ﷺ تدافع عنه بالسيف والرمح وتتلقى الضربات في جسدها الشريف، حتى جُرحت ثلاثة عشر جرحاً، منها جرح عميق في عاتقها كاد يودي بحياتها.

رآها النبي ﷺ تقاتل ببسالة منقطعة النظير فدعا لها: "بارك الله فيكم من أهل بيت! لمقام نسيبة اليوم خير من مقام فلان وفلان، اللهم اجعلهم رفقائي في الجنة". وقال النبي لاحقاً: "ما التفتُّ يوم أحد يمنة ولا يسرة إلا وأنا أراها تقاتل دوني".''',
    storyEn:
        '''Nusaybah set out for the Battle of Uhud alongside her husband and sons to carry water and nurse the wounded. When archers abandoned their posts and enemy cavalry converged directly on the Prophet ﷺ, she dropped her water vessel and took up sword and shield!

Positioning herself like a fortress around the Prophet, she engaged enemy soldiers in direct combat, suffering thirteen battle wounds, including a deep gash on her shoulder.

Observing her astounding valor, the Prophet ﷺ prayed: "May Allah bless your household! Nusaybah's stand today is greater than that of so-and-so. O Allah, make them my companions in Paradise!" The Prophet later attested: "Wherever I turned on the day of Uhud, right or left, I saw her fighting to defend me."''',
    lessonsAr: [
      'شجاعة المرأة المسلمة ووقوفها البطولي في الأوقات المصيرية.',
      'الدفاع عن المبدأ والرسول بكل ما يملك الإنسان من قوة.',
      'الأسرة الصالحة التي تجتمع كلها على نصرة الحق.',
    ],
    lessonsEn: [
      'Incredible courage and frontline heroism of Muslim women.',
      'Defending truth and principles with absolute conviction.',
      'A united family devoted to serving a transcendent purpose.',
    ],
    famousQuoteAr: '«ما التفتُّ يمنة ولا يسرة إلا وأنا أراها تقاتل دوني»',
    famousQuoteEn:
        '"Wherever I looked, right or left, I saw her fighting to protect me"',
    readTimeMinutes: 3,
    milestonesAr: [
      'شهدت بيعة العقبة الثانية وكانت من الرائدات المؤسسات لدعوة الإسلام بيثرب.',
      'شاركت في أحد لسقاية الجرحى، وتحولت لمقاتلة شجاعة بالسيف تذود عن رسول الله ﷺ.',
      'أصيبت بثلاثة عشر جرحاً طعناً وضرباً وهي تحول بين سيوف المشركين والنبي ﷺ.',
      'شاركت في حروب الردة وفي معركة اليمامة ضد مسيلمة الكذاب حتى قُطعت يدها وهي تقاتل.',
    ],
    milestonesEn: [
      'Pioneer of the Second Pledge of Aqabah, establishing Islam\'s sanctuary in Madinah.',
      'Initially served as medic at Uhud, then drew sword and shield when enemies converged upon the Prophet.',
      'Sustained 13 direct battle wounds protecting the Prophet from charging enemy cavalry.',
      'Fought fearlessly in the Yamama campaigns against Musaylimah until her arm was severed.',
    ],
    virtuesAr: [
      'قال النبي ﷺ يوم أحد: «ما التفتّ يمنة ولا يسرة إلا وأنا أراها تقاتل دوني».',
      'دعا لها النبي ﷺ ولأهل بيتها: «اللهم اجعلهم رفقائي في الجنة»، فقالت: ما أبالي ما أصابني من الدنيا بعد هذا.',
    ],
    virtuesEn: [
      'The Prophet testified: "Wherever I looked, right or left on the day of Uhud, I saw her fighting to protect me."',
      'The Prophet prayed: "O Allah, make them my companions in Paradise!" She smiled: "I care nothing of earthly trials after this."',
    ],
  ),
  CompanionStory(
    id: 'sumayyah-bint-khayyat',
    category: CompanionCategory.women,
    nameAr: 'سمية بنت خياط',
    nameEn: 'Sumayyah bint Khayyat',
    titleAr: 'أول شهيدة في الإسلام ورمز الثبات',
    titleEn: 'First Martyr in Islam & Symbol of Unshakable Faith',
    emoji: '🕊️',
    summaryAr:
        'العجوز المستضعفة التي رفضت التراجع عن توحيد الله تحت وطأة أشد ألوان التعذيب، فنالت الشهادة الأولى.',
    summaryEn:
        'An elderly, defenseless woman who refused to deny Allah under agonizing torture, becoming Islam\'s very first martyr.',
    storyAr:
        '''كانت سمية رضي الله عنها امرأة مسنة ضعيفة، أعلنت إسلامها مع زوجها ياسر وابنها عمار بن ياسر في بدايات الدعوة في مكة.

أذاقهم بنو مخزوم بقيادة فرعون هذه الأمة "أبو جهل" أشد صنوف العذاب في هجير مكة؛ ألبسوهم دروع الحديد وأوقفوهم تحت حرارة الشمس المحرقة وجلدوهم ليرتدوا عن دينهم. وكان النبي ﷺ يمر بهم وهم يُعذبون فيدمع قلبه لعجزهم ويواسيهم بوعد الجنة الحق: "صبراً آل ياسر.. فإن موعدكم الجنة!".

رغم كبر سنها وضعف جسدها، كانت سمية أصلب من الفولاذ؛ بصقت في وجه الطاغية أبي جهل وأغلظت له القول معلنة إيمانها بالله الواحد الأحد، فاستشاط غضباً وطعنها بحربته، فصعدت روحها الطاهرة إلى بارئها كأول شهيدة في تاريخ الإسلام، مسطرة بدمائها صفحة من أعظم صفحات المجد والخلود.''',
    storyEn:
        '''Sumayyah was an elderly, humble woman who boldly accepted Islam with her husband Yasir and son Ammar during the earliest, vulnerable days in Mecca.

The clan of Makhzum, headed by Abu Jahl, subjected them to unimaginable torture, dressing them in iron armor under the blistering midday sun and whipping them mercilessly. The Prophet ﷺ would pass by, his heart aching for their plight, comforting them with eternal certainty: "Patience, O family of Yasir, for your destination is Paradise!"

Despite frail age, Sumayyah possessed an unbreakable spirit. She spat in Abu Jahl's face and boldly proclaimed the oneness of Allah. In a fit of fury, the tyrant struck her down with a spear, making her the very first martyr in the history of Islam, engraving her name forever in the annals of glory.''',
    lessonsAr: [
      'العقيدة أقوى من قوى الظلم والجبروت مهما تفرعنت.',
      'أن المرأة كانت في مقدمة ركب الشهداء والتضحية من أجل الإسلام.',
      'وعد الله بالجنة هو أعظم بلسم للمؤمن أمام صعوبات الحياة.',
    ],
    lessonsEn: [
      'Spiritual conviction triumphs over brute force and tyranny.',
      'Women stood at the very forefront of martyrdom and sacrifice in Islam.',
      'The promise of Paradise fuels endurance through every earthly trial.',
    ],
    famousQuoteAr: '«صبراً آل ياسر فإن موعدكم الجنة»',
    famousQuoteEn:
        '"Patience, O family of Yasir, for your appointment is in Paradise!"',
    readTimeMinutes: 3,
    milestonesAr: [
      'من أوائل السبعة الذين أعلنوا إسلامهم بمكة جهراً أمام طغيان قريش.',
      'أُلبست دروع الحديد وعُذبت في رمضاء مكة الحارقة وصمدت رافضة الكفر.',
      'أول شهيدة صعدت روحها إلى السماء في تاريخ الإسلام بدمائها الطاهرة الزكية.',
      'أورثت ابنها عمار بن ياسر راية الصبر والجهاد في سبيل الحق.',
    ],
    milestonesEn: [
      'Among the earliest seven courageous souls who publicly declared faith in Mecca.',
      'Forced into iron cuirasses under boiling sun, enduring torture without wavering.',
      'Became the very first martyr in Islamic history when struck down by Abu Jahl.',
      'Bequeathed a glorious legacy of spiritual resilience to her son Ammar.',
    ],
    virtuesAr: [
      'بشرها النبي ﷺ وأسرتها بالجنة قائلاً: «صبراً آل ياسر، فإن موعدكم الجنة».',
      'كانت نموذجاً أبدياً للثبات الإيماني الذي قهر جبروت الطواغيت والجلادين بالصبر والاحتساب.',
    ],
    virtuesEn: [
      'The Prophet gave divine assurance to her family: "Patience, O family of Yasir, for your appointment is in Paradise!"',
      'Eternal archetype of spiritual conviction overcoming ruthless tyrannical brutality.',
    ],
  ),
  CompanionStory(
    id: 'umm-sulaym-bint-milhan',
    category: CompanionCategory.women,
    nameAr: 'أم سليم بنت ملحان',
    nameEn: 'Umm Sulaym bint Milhan',
    titleAr: 'صاحبة أعظم مهر وأم أنس بن مالك',
    titleEn: 'Bearer of the Greatest Dowry & Mother of Anas',
    emoji: '💍',
    summaryAr:
        'المرأة الحكيمة التي جعلت مهر زواجها إسلام أبي طلحة، وربّت خادم الرسول أنس بن مالك.',
    summaryEn:
        'The wise woman whose dowry was her husband\'s conversion to Islam, mother of the Prophet\'s servant Anas.',
    storyAr:
        '''عُرفت أم سليم رضي الله عنها بعقلها الراجح وشخصيتها الفريدة في الأنصار. لما مات زوجها الأول، تقدم لخطبتها أبو طلحة الأنصاري وكان حينها من أثرياء يثرب وفرسانها، لكنه كان مشركاً.

فقالت له أم سليم بحكمة وبلاغة: "يا أبا طلحة، مثلك لا يُرد، ولكنك رجل كافر وأنا امرأة مسلمة، ولا يحل لي أن أتزوجك، فإن تسلم فذاك مهري، ولا أسألك غيره!". فانشرح صدر أبي طلحة للإسلام على يديها وأسلم، فكان إسلامه أعظم وأطهر مهر في تاريخ البشرية.

أهدت ابنها الصغير أنس بن مالك لرسول الله ﷺ ليخدمه ويتعلم منه، فدعا له النبي بالبركة في ماله وولده وعمره فكان من أكثر الصحابة رواية للعلم. وحين توفي ابنها الصغير في مرض، صبرت واحتسبت واستقبلت زوجها بهدوء وأطعمته قبل أن تخبره برقة: "يا أبا طلحة، أرأيت لو أن قوماً أعاروا أهل بيت عارية فطلبوها، ألهم أن يمنعوهم؟ قال: لا. قالت: فاحتسب ولدك". فعجب النبي ﷺ من صبرها وبرّك في ليلتهما.''',
    storyEn:
        '''Umm Sulaym was famed among the Ansar for exceptional wisdom and composure. Following her first husband's death, Abu Talha—one of Madinah's wealthiest and most eligible bachelors—proposed to her while still a polytheist.

She answered him with unparalleled poise: "O Abu Talha, a man like you is not easily turned down. But you are a polytheist and I am a Muslim woman; it is not lawful for me to marry you. If you accept Islam, that will be my entire dowry, and I will demand nothing else!" Moved by her sincerity, Abu Talha embraced Islam, making their union the most honorable dowry in history.

She gifted her young son Anas ibn Malik to serve and learn directly from the Prophet ﷺ. When another young son passed away, she displayed astonishing patience, comforting her grieving husband gently before sharing the news. The Prophet marveled at her emotional resilience and prayed for blessings upon her household.''',
    lessonsAr: [
      'جعل المقاييس الإيمانية والأخلاقية فوق المظاهر والماديات في الزواج.',
      'الصبر الاستثنائي وضبط النفس والرضا بقضاء الله وقدره.',
      'حرص الأم على تعليم وتربية أبنائها في أحضان القدوة الصالحة.',
    ],
    lessonsEn: [
      'Prioritizing character and spiritual values over material wealth in marriage.',
      'Exceptional emotional intelligence and graceful acceptance of destiny.',
      'Nurturing children in environments of virtue and mentorship.',
    ],
    famousQuoteAr: '«فإن تُسلم فذاك مهري، ولا أسألك غيره»',
    famousQuoteEn:
        '"If you accept Islam, that is my dowry; I ask for nothing else"',
    readTimeMinutes: 4,
    milestonesAr: [
      'اشترطت إسلام أبي طلحة مهراً لزواجها فكان أعظم وأكرم مهر في تاريخ البشرية.',
      'أهدت ابنها أنس بن مالك لرسول الله ﷺ ليتعلم منه ويخدمه فكان من أوعية العلم.',
      'ضربت مثلاً إيمانياً خارقاً في الصبر والرضا والتسليم حين توفي ولدها الصغير واحتسبته عند الله.',
      'شاركت في حنين وأحد لمداواة الجرحى وحملت الخنجر شجاعة ودفاعاً.',
    ],
    milestonesEn: [
      'Stipulated Abu Talha\'s conversion to Islam as her dowry, setting the most honorable dowry in history.',
      'Entrusted her child Anas ibn Malik to the Prophet\'s mentorship, grooming him as a primary hadith scholar.',
      'Showcased breathtaking poise and emotional mastery upon the passing of her young son.',
      'Active frontline medic at Hunayn and Uhud, carrying daggers in resolute defense of the Prophet.',
    ],
    virtuesAr: [
      'قال النبي ﷺ: «دخلت الجنة فسمعت خشفة (صوت مشي)، فقلت: من هذا؟ قالوا: هذه الغميصاء بنت ملحان (أم سليم)» يراها النبي في الجنة.',
      'دعا النبي ﷺ لبيتها بالبركة فعاشوا في سعة من العلم والفضل والذرية الصالحة.',
    ],
    virtuesEn: [
      'The Prophet said: "I entered Paradise and heard footsteps. I asked who it was, and was told: It is Al-Ghumaysa bint Milhan (Umm Sulaym)."',
      'The Prophet showered her household with heartfelt prayers for abundance in faith, family, and knowledge.',
    ],
  ),
  CompanionStory(
    id: 'ash-shifa-bint-abdullah',
    category: CompanionCategory.women,
    nameAr: 'الشفاء بنت عبد الله',
    nameEn: 'Ash-Shifa bint Abdullah',
    titleAr: 'المعلمة الأولى وولية سوق المدينة',
    titleEn: 'The First Female Teacher & Market Inspector',
    emoji: '✨',
    summaryAr:
        'الصحابية الأديبة التي علمت نساء المدينة القراءة والكتابة والطب، وأولاها عمر إدارة الحسبة والسوق.',
    summaryEn:
        'Eminent literate scholar who taught reading, writing, and medicine, appointed by Caliph Umar to oversee the Madinah market.',
    storyAr:
        '''كانت الشفاء رضي الله عنها من أندر النساء في الجاهلية؛ إذ كانت تحسن القراءة والكتابة والطب والرقية في مجتمع تسوده الأمية.

بعد إسلامها، طلب منها النبي ﷺ أن تُعلّم زوجته أم المؤمنين حفصة بنت عمر القراءة والكتابة والرقية، فأصبحت "المعلمة الأولى" في تاريخ الإسلام. وكان النبي ﷺ يحترمها ويزورها في بيتها ويقيل عندها، وقد خصص لها داراً في المدينة المنورة.

بلغت من الفطنة ورجاحة الرأي والأمانة أن أمير المؤمنين عمر بن الخطاب رضي الله عنه كان يستشيرها في شؤون المعاملات ويقدم رأيها، حتى ولاها مسؤولية الحسبة ومراقبة السوق في المدينة المنورة؛ للتأكد من نزاهة الأسعار، ومنع الغش، وتطبيق العدل بين التجار، لتكون نموذجاً ساطعاً لكفاءة وكرامة ومكانة المرأة المسلمة في بناء المجتمع.''',
    storyEn:
        '''Ash-Shifa was a remarkable rarity in pre-Islamic Arabia: fully literate, skilled in administrative writing, and proficient in folk medicine and healing when illiteracy prevailed.

Upon embracing Islam, the Prophet ﷺ personally requested that she teach his wife Hafsah reading, calligraphy, and treatment of skin ailments, making her the first official female schoolteacher in Islamic history. The Prophet held her in high regard, regularly visiting her home and gifting her a house in Madinah.

Her intellect and moral integrity were so trusted that Caliph Umar ibn al-Khattab frequently sought her counsel on commerce and civic governance, eventually appointing her to supervise and inspect the bustling market of Madinah—ensuring fair weights, ethical pricing, and consumer justice, demonstrating the pioneering role of Muslim women in public leadership.''',
    lessonsAr: [
      'أهمية محو الأمية وتعليم البنات القراءة والكتابة والمهن النافعة.',
      'كفاءة المرأة المسلمة وأهليتها لتولي المناصب القيادية والرقابية.',
      'استثمار المواهب والخبرات الفردية لخدمة المجتمع وبنائه.',
    ],
    lessonsEn: [
      'The imperative of women\'s education, literacy, and professional skills.',
      'Competence and trustworthiness of women in public leadership and commerce.',
      'Channeling individual talents into community progress.',
    ],
    famousQuoteAr: '«علمي حفصة رقية النملة كما علمتِها الكتابة»',
    famousQuoteEn: '"Teach Hafsah healing as you taught her writing"',
    readTimeMinutes: 3,
    milestonesAr: [
      'تعلمت القراءة والكتابة والطب والرقية في الجاهلية وكانت من رائدات العلم بين النساء.',
      'أول معلمة في الإسلام؛ كلفها النبي ﷺ بتعليم أم المؤمنين حفصة بنت عمر الكتابة.',
      'هاجرت إلى المدينة وبايعت النبي ﷺ وخصها بدار تكريماً لمكانتها وعلمها.',
      'ولاها الفاروق عمر بن الخطاب الحسبة ومراقبة أسواق المدينة لنزاهتها ورجاحة عقلها.',
    ],
    milestonesEn: [
      'Learned literacy, folk medicine, and administrative penmanship during the pre-Islamic era.',
      'First formal female educator in Islam; asked by the Prophet to teach Lady Hafsah calligraphy.',
      'Migrated to Madinah, pledged allegiance, and was honored by the Prophet with a dedicated home.',
      'Appointed by Caliph Umar to oversee the civic markets of Madinah with full regulatory authority.',
    ],
    virtuesAr: [
      'كان النبي ﷺ يزورها في دارها ويكرمها ويقيل عندها احتراماً لفضلها وعلمها.',
      'استشارها عمر بن الخطاب في المعضلات الاقتصادية وأمور التجارة والأسواق مقدماً رأيها.',
    ],
    virtuesEn: [
      'The Prophet held her in deep esteem, visiting her home and resting there in honor of her knowledge.',
      'Caliph Umar continually sought her advice on civic commerce and market governance.',
    ],
  ),
];
