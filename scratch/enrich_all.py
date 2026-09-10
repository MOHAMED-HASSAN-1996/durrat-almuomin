# -*- coding: utf-8 -*-
import re

DATA = {
    'abu-bakr': {
        'milestonesAr': [
            'أول رجل حر يُعلن إسلامه بدعوة النبي ﷺ وبذل ثروته لعتق المستضعفين كبلال بن رباح.',
            'صاحب النبي ﷺ في الغار أثناء رحلة الهجرة النبوية المباركة (ثاني اثنين إذ هما في الغار).',
            'أمّ المسلمين في الصلاة في مرض النبي ﷺ بأمر مباشر منه.',
            'أول الخلفاء الراشدين ومهدئ فتنة الردة بعد وفاة النبي ﷺ بحزم ويقين لا يتزعزع.',
            'أمر بجمع القرآن الكريم لأول مرة في مصحف واحد بإشارة من عمر بن الخطاب.',
        ],
        'milestonesEn': [
            'First free adult man to accept Islam, using wealth to free oppressed slaves like Bilal.',
            'Companion of the Prophet in the Cave of Thawr during the blessed Hijrah.',
            'Appointed by the Prophet ﷺ to lead Muslims in prayer during his final illness.',
            'First Rightly Guided Caliph who preserved Islamic unity during the Apostasy Wars.',
            'Commissioned the first compilation of the Quran into a single unified codex.',
        ],
        'virtuesAr': [
            'قال فيه النبي ﷺ: «لو كنتُ متخذاً خليلاً غير ربي لاتخذتُ أبا بكر خليلاً».',
            'قال النبي ﷺ: «ما لأحدٍ عندنا يدٌ إلا وقد كافأناه، ما خلا أبا بكر، فإن له عندنا يداً يكافئه الله بها يوم القيامة».',
            'قال عمر بن الخطاب: «أبو بكر سيدنا، ووالله ما سابقت أبا بكر إلى خير إلا سبقني إليه».',
        ],
        'virtuesEn': [
            'The Prophet ﷺ said: "If I were to take an intimate friend other than my Lord, I would take Abu Bakr."',
            'The Prophet ﷺ said: "No one has done us a favor except we repaid them, except Abu Bakr; he did us a favor for which Allah will reward him on the Day of Resurrection."',
            'Umar said: "I wished I were a hair on Abu Bakr\'s chest; by Allah, whenever I competed with him in goodness, he beat me to it."',
        ],
    },
    'umar-ibn-al-khattab': {
        'milestonesAr': [
            'جهر بإسلامه في مكة فكان إسلامه عزاً للمسلمين وخرجوا في صفين لأول مرة حول الكعبة.',
            'ثاني الخلفاء الراشدين ومؤسس الدولة الإدارية ونظام الدواوين والشرطة والبريد.',
            'اعتمد التقويم الهجري الإسلامي تخليداً لحدث الهجرة النبوية الشريفة.',
            'تسلم مفاتيح بيت المقدس بنفسه بثوب مرقع وكتب العهدة العمرية الخالدة لأهل إيلياء.',
            'فتحت في عهده الشام والعراق ومصر وفارس وانكسرت شوكة كسرى وقيصر.',
        ],
        'milestonesEn': [
            'Publicly proclaimed his Islam in Mecca, granting dignity and strength to believers.',
            'Second Rightly Guided Caliph; Islamic territory expanded to Jerusalem, Levant, Persia, and Egypt.',
            'Established the Islamic Hijri calendar, administrative ministries, police, and public welfare system.',
            'Personally received the keys to Jerusalem in humility and authored the famed Umariyya Covenant.',
            'Brought down the tyrannical Roman and Sasanian empires to establish justice.',
        ],
        'virtuesAr': [
            'قال فيه النبي ﷺ: «لو كان بعدي نبيٌّ لكان عمر بن الخطاب».',
            'قال النبي ﷺ: «إيه يا ابن الخطاب، والذي نفسي بيده، ما لقيك الشيطان سالكاً فجّاً إلا سلك فجّاً غير فجّك».',
            'وافق القرآن الكريم رأيه في عدة مواقف كحجاب أمهات المؤمنين ومقام إبراهيم.',
        ],
        'virtuesEn': [
            'The Prophet ﷺ said: "If there were to be a prophet after me, it would be Umar ibn Al-Khattab."',
            'The Prophet ﷺ said: "By Him in Whose Hand is my soul, Satan never meets you taking a path but he takes another path than yours."',
            'Several Quranic verses descended affirming Umar\'s insightful counsel (Muwafaqat Umar).',
        ],
    },
    'uthman-ibn-affan': {
        'milestonesAr': [
            'تزوّج ابنتي رسول الله ﷺ رقية ثم أم كلثوم فنال شرف لقب (ذو النورين).',
            'اشترى بئر رومة بالمدينة وجعلها وقفاً مجانياً للمسلمين إلى قيام الساعة.',
            'جهّز جيش العسرة في تبوك بمئات الإبل والخيل والذهب فنال رضوان الله ورسوله.',
            'ثالث الخلفاء الراشدين، ووحّد كتابة المصحف الشريف وأرسل النسخ للأمصار (المصحف العثماني).',
            'أنشأ أول أسطول بحري إسلامي لحماية سواحل البحر الأبيض المتوسط.',
        ],
        'milestonesEn': [
            'Married two daughters of the Prophet (Ruqayyah and Umm Kulthum), earning the title Dhun-Noorayn.',
            'Purchased the well of Rumah and endowed it as a permanent public trust for the Muslims.',
            'Equipped the Expedition of Tabuk with hundreds of mounts, armor, and gold.',
            'Third Caliph; standardized the Quranic codices sent across provinces (The Uthmanic Codex).',
            'Formed the first Islamic naval fleet to secure Mediterranean coastlines.',
        ],
        'virtuesAr': [
            'قال النبي ﷺ: «ألا أستحي من رجل تستحي منه الملائكة؟».',
            'قال النبي ﷺ حين جهز جيش العسرة: «ما ضرّ عثمان ما عمل بعد اليوم، ما ضر عثمان ما عمل بعد اليوم».',
            'أحد العشرة المبشرين بالجنة، وبشره النبي بالجنة على بلوى تصيبه فصبر محتسباً.',
        ],
        'virtuesEn': [
            'The Prophet ﷺ said: "Shall I not feel shy before a man whom the angels feel shy of?"',
            'The Prophet ﷺ declared: "Nothing Uthman does after today will harm him."',
            'Promised Paradise by the Prophet ﷺ amidst foretold tribulations, dying as a patient martyr.',
        ],
    },
    'ali-ibn-abi-talib': {
        'milestonesAr': [
            'أول من أسلم من الفتيان والصبيان وتربى في كنف النبي ﷺ وأخلاقه.',
            'فدائي ليلة الهجرة؛ بات في فراش رسول الله ﷺ لرد الأمانات وتمويه المشركين.',
            'حامل الراية وفاتح حصن خيبر المنيع بعد أن استعصى على غيره.',
            'رابع الخلفاء الراشدين، قاد الأمة بحكمة وعدالة وفصاحة لا تُبارى.',
        ],
        'milestonesEn': [
            'First youth to accept Islam, raised in the intimate care and character of the Prophet.',
            'Hero of Hijrah night; slept in the Prophet’s bed to deceive assassins and return trusts.',
            'Standard-bearer and conqueror of the impenetrable fortress of Khaybar.',
            'Fourth Rightly Guided Caliph, renowned for legendary eloquence, justice, and jurisprudence.',
        ],
        'virtuesAr': [
            'قال النبي ﷺ يوم خيبر: «لأعطين الراية غداً رجلاً يحب الله ورسوله ويحبه الله ورسوله، يفتح الله على يديه».',
            'قال النبي ﷺ لعلي: «أنت مني بمنزلة هارون من موسى إلا أنه لا نبي بعدي».',
            'قال النبي ﷺ: «أنا دار الحكمة وعليٌّ بابها»، وكان من أقضى الصحابة وأفقههم.',
        ],
        'virtuesEn': [
            'The Prophet ﷺ said at Khaybar: "Tomorrow I will give the banner to a man who loves Allah and His Messenger, and whom Allah and His Messenger love."',
            'The Prophet ﷺ said to Ali: "You are to me like Harun was to Musa, except there is no prophet after me."',
            'Famed as one of the most discerning judges and deep thinkers among all companions.',
        ],
    },
    'bilal-ibn-rabah': {
        'milestonesAr': [
            'صمد تحت أشد ألوان التعذيب في رمضاء مكة ولم يحد عن كلمة التوحيد (أحدٌ أحد).',
            'أعتقه أبو بكر الصديق لوجه الله تعالى.',
            'أول مؤذن في الإسلام واختاره النبي ﷺ ليصدح بالأذان في المسجد النبوي.',
            'أذن فوق ظهر الكعبة المشرفة يوم فتح مكة ليعلن سقوط الأصنام وعزة التوحيد.',
        ],
        'milestonesEn': [
            'Endured extreme desert torture in Mecca without uttering anything other than "Ahad, Ahad".',
            'Purchased and manumitted by Abu Bakr as-Siddiq solely for Allah\'s pleasure.',
            'Islam\'s first Muezzin, selected by the Prophet ﷺ for his resonant melodic voice.',
            'Called the prayer from the rooftop of the Ka\'bah on the Day Mecca was liberated.',
        ],
        'virtuesAr': [
            'قال النبي ﷺ: «يا بلال، إني سمعتُ دفّ نعليك بين يديّ في الجنة؛ فأخبرني بأرجى عمل عملته؟».',
            'قال عمر بن الخطاب: «أبو بكر سيدنا، وأعتق سيدنا» (يقصد بلالاً).',
        ],
        'virtuesEn': [
            'The Prophet ﷺ said: "O Bilal, I heard the sound of your footsteps before me in Paradise."',
            'Umar ibn al-Khattab would say: "Abu Bakr is our master, and he freed our master."',
        ],
    },
    'musab-ibn-umayr': {
        'milestonesAr': [
            'ترك ثراء مكة ولباس الحرير ونعيم والدته لينال عز التوحيد والإيمان.',
            'أول سفير في الإسلام؛ بعثه النبي ﷺ إلى المدينة ليعلم الناس القرآن ويدعوهم بالحكمة.',
            'أسلم على يديه كبار سادات الأنصار مثل أسيد بن حضير وسعد بن معاذ فدخل الإسلام بيوت المدينة.',
            'حامل لواء المسلمين في غزوة بدر وغزوة أحد، واستشهد صامداً وهو يحمي راية التوحيد.',
        ],
        'milestonesEn': [
            'Sacrificed Meccan luxury, perfumed silk, and maternal fortune for the light of faith.',
            'First diplomatic ambassador of Islam, sent to Madinah to teach the Quran with gentle grace.',
            'Through his teaching, prominent Ansar chieftains embraced Islam, opening all Madinah to faith.',
            'Muslim standard-bearer at Badr and Uhud, martyred heroically guarding the banner.',
        ],
        'virtuesAr': [
            'بكى النبي ﷺ حين رآه في بردة مرقعة وقال: «لقد رأيتُ هذا وما بمكة فتى أنعم عند أبويه منه، ثم ترك ذلك كله حباً لله ولرسوله».',
            'تلا النبي ﷺ عند جثمانه في أحد: {مِّنَ الْمُؤْمِنِينَ رِجَالٌ صَدَقُوا مَا عَاهَدُوا اللَّهَ عَلَيْهِ}.',
        ],
        'virtuesEn': [
            'The Prophet ﷺ wept seeing his humble patched cloth, praising his absolute sacrifice for Allah.',
            'The Prophet recited over him at Uhud: "Among the believers are men true to what they promised Allah."',
        ],
    },
    'khalid-ibn-al-walid': {
        'milestonesAr': [
            'أسلم قبل فتح مكة وحظي بترحيب وفرح عظيم من النبي ﷺ برجاحة عقله.',
            'أنقذ جيش المسلمين بعبقرية انسحاب تكتيكي مذهل في غزوة مؤتة بعد استشهاد قادتها الثلاثة.',
            'قائد معارك حروب الردة واليمامة وتوحيد الجزيرة العربية تحت راية الإسلام.',
            'قائد معركة اليرموك الخالدة التي فتحت بلاد الشام، ومحرر العراق وفارس.',
            'ضرب أعظم مثل في التجرد والإخلاص عندما قَبِل أن يكون جندياً عادياً بإمرة أبي عبيدة طاعة للخليفة.',
        ],
        'milestonesEn': [
            'Embraced Islam before Mecca\'s liberation, welcomed warmly by the Prophet.',
            'Strategically saved the Muslim army at the Battle of Mu\'tah through brilliant tactical retreat.',
            'Commander of the Yamama campaign reunifying Arabia under the banner of Tawhid.',
            'Architect of the victory at the Battle of Yarmouk, liberating the Levant.',
            'Demonstrated supreme sincerity by gladly serving as a frontline soldier under Abu Ubaydah.',
        ],
        'virtuesAr': [
            'سماه النبي ﷺ: «سيف الله المسلول سلّه الله على المشركين».',
            'قال أبو بكر الصديق: «عجزت النساء أن يلدن مثل خالد بن الوليد».',
            'قال خالد عند وفاته: «لقد شهدتُ مائة زحف وما في بدني موضع شبر إلا وفيه ضربة بسيف أو رمية بسهم.. فلا نامت أعين الجبناء».',
        ],
        'virtuesEn': [
            'Honored by the Prophet ﷺ as: "The Drawn Sword of Allah against falsehood."',
            'Abu Bakr remarked: "Women are unable to give birth to the likes of Khalid ibn Al-Walid."',
            'Khalid declared on his deathbed: "I fought in a hundred battles, yet here I die on my bed; let the eyes of cowards never sleep!"',
        ],
    },
    'salman-al-farsi': {
        'milestonesAr': [
            'قطع آلاف الأميال متحملاً الرق والغربة في رحلة طويلة وشاقة بحثاً عن الدين الحق.',
            'تحقق من علامات النبوة الثلاث في المدينة وأسلم فرحاً بلقاء الحبيب ﷺ.',
            'صاحب خطة حفر الخندق العبقرية في غزوة الأحزاب التي حمت المدينة من استئصال المشركين.',
            'تولى إمارة المدائن وعاش أزهد الناس ينسج الخوص ويأكل من كسب يده.',
        ],
        'milestonesEn': [
            'Traveled thousands of miles through slavery and exile in a relentless search for true faith.',
            'Verified the three prophetic signs upon reaching Madinah and embraced Islam with tears of joy.',
            'Conceived the revolutionary moat strategy in the Battle of the Trench, shielding Madinah.',
            'Governed Al-Mada\'in living in complete asceticism, weaving palm fronds to earn his daily bread.',
        ],
        'virtuesAr': [
            'قال النبي ﷺ إكراماً له: «سلمان منا أهل البيت».',
            'كان علي بن أبي طالب يقول عنه: «سلمان امرؤ منا أهل البيت، علم العلم الأول والآخر، بحر لا ينزف».',
        ],
        'virtuesEn': [
            'The Prophet ﷺ honored him profoundly: "Salman is one of us, the People of the Household."',
            'Ali described him: "Salman is one of us, the People of the House; he mastered the first and last knowledge, an unexhausted ocean."',
        ],
    },
    'saad-ibn-abi-waqqas': {
        'milestonesAr': [
            'أول من رمى بسهم في سبيل الله لحماية النبي ﷺ والدعوة الإسلامية.',
            'ثبت في بر والدته برفق دون أن يفرط في ذرة من دينه حين أضربت عن الطعام.',
            'قائد جيش المسلمين وبطل معركة القادسية التاريخية التي فتحت بلاد الرافدين وإيران.',
            'أحد العشرة المبشرين بالجنة وأحد الستة أصحاب الشورى لاختيار الخليفة.',
        ],
        'milestonesEn': [
            'First archer to shoot an arrow in the cause of Allah protecting the Prophet.',
            'Stood steadfast in filial kindness without compromising an ounce of faith during his mother\'s strike.',
            'Supreme commander and hero of the Battle of Al-Qadisiyyah, opening Mesopotamia.',
            'Among the ten promised Paradise and one of the six council electors for the Caliphate.',
        ],
        'virtuesAr': [
            'دعا له النبي ﷺ: «اللهم سدد رميته، وأجب دعوته»، فكان مجاب الدعوة مهاب السهم.',
            'قال له النبي ﷺ في غزوة أحد فادياً إياه بأبويه: «ارمِ سعد، فداك أبي وأمي».',
        ],
        'virtuesEn': [
            'The Prophet ﷺ prayed for him: "O Allah, make his aim straight and answer his supplication."',
            'The Prophet exclaimed at Uhud: "Shoot, Sa\'d, may my father and mother be sacrificed for you!"',
        ],
    },
    'abdullah-ibn-masud': {
        'milestonesAr': [
            'سادس من أسلم في الإسلام ولازم النبي ﷺ ملازمة الظل لخدمته والتعلم منه.',
            'أول من جهر بالقرآن الكريم بمكة عند الكعبة وتحمل بطش قريش بشجاعة وثبات.',
            'صاحب وسادة وسواك ونعلي النبي ﷺ ومستودع أسراره النبوية.',
            'فقيه الأمة وإمام الكوفة ومعلم جيل التابعين علوم التفسير والفقه والقرآن.',
        ],
        'milestonesEn': [
            'Sixth person to embrace Islam, becoming the Prophet\'s constant shadow and personal assistant.',
            'First Muslim to publicly recite the Quran aloud at the Ka\'bah, braving brutal beatings.',
            'Keeper of the Prophet\'s sandals, tooth-stick, and pillow, trusted with confidential matters.',
            'Supreme jurist and master scholar of Kufa, founding the classic school of Islamic jurisprudence.',
        ],
        'virtuesAr': [
            'قال النبي ﷺ: «من أحب أن يقرأ القرآن غضاً كما أُنزل فليقرأه على قراءة ابن أم عبد».',
            'قال النبي ﷺ حين ضحكوا من دقة ساقيه: «والذي نفسي بيده لهما أثقل في الميزان من جبل أحد».',
            'قال النبي ﷺ: «تمسكوا بعهد ابن مسعود».',
        ],
        'virtuesEn': [
            'The Prophet ﷺ said: "Whoever wishes to recite the Quran freshly as it was revealed, let him recite it according to Ibn Umm Abd."',
            'The Prophet said regarding his slender legs: "By Him in Whose Hand is my soul, they are heavier in the scales than Mount Uhud!"',
            'The Prophet instructed: "Hold firmly to the counsel of Ibn Mas\'ud."',
        ],
    },
    'khadijah-bint-khuwaylid': {
        'milestonesAr': [
            'أول من آمن بالإسلام على وجه الأرض من الرجال والنساء دون أدنى تردد.',
            'ثبّتت النبي ﷺ عند نزول الوحي الأول بكلماتها الخالدة: «كلا والله ما يخزيك الله أبداً».',
            'بذلت ثروتها الطائلة كلها في إعالة الدعوة والإنفاق على المحاصرين في الشِّعب.',
            'نالت سلاماً خاصاً من الله تعالى وبشارة بقصر من قصب في الجنة لا صخب فيه ولا نصب.',
        ],
        'milestonesEn': [
            'First person on earth to believe in Islam, supporting the Prophet without hesitation.',
            'Comforted the Prophet at first revelation with immortal words: "Never! Allah will never disgrace you."',
            'Dedicated her immense fortune to sustain believers through persecution and tribal boycotts.',
            'Blessed with divine greetings directly from Allah conveyed through the Angel Jibril.',
        ],
        'virtuesAr': [
            'قال النبي ﷺ مبيناً منزلتها: «خير نسائها مريم بنت عمران، وخير نسائها خديجة بنت خويلد».',
            'قال النبي ﷺ وفاءً لها: «إني رُزقت حبها، ما أبدلني الله خيراً منها؛ آمنت بي إذ كفر بي الناس».',
            'بشرها جبريل عليه السلام ببيت في الجنة من قصب لا صخب فيه ولا نصب.',
        ],
        'virtuesEn': [
            'The Prophet ﷺ praised: "The best of women was Maryam daughter of Imran, and the best of women was Khadijah daughter of Khuwaylid."',
            'The Prophet remembered her with lifelong love: "I was blessed with her love; she believed in me when people rejected me."',
            'Jibril brought glad tidings of a palace for her in Paradise made of hollow pearls without clamor or fatigue.',
        ],
    },
    'aisha-bint-abi-bakr': {
        'milestonesAr': [
            'عاشت في كنف بيت النبوة ونقلت أدق تفاصيل السنة النبوية الشريفة وأخلاق النبي ﷺ.',
            'روّت أكثر من 2200 حديث شريف وكانت من أخصب الرواة فصاحة ودقة وحفظاً وعقلاً.',
            'مرجع كبار الصحابة في الإفتاء وقسمة الفرائض والمواريث والطب والأدب والشعر.',
            'برأها الله تعالى بآيات من فوق سبع سماوات في سورة النور تتلى في المحاريب إلى يوم القيامة.',
        ],
        'milestonesEn': [
            'Lived at the heart of the Prophet\'s household, chronicling his daily ethics and private worship.',
            'Transmitted over 2,200 authentic hadiths with unparalleled photographic accuracy and eloquence.',
            'Premier reference for senior companions in complex jurisprudence, inheritance, medicine, and Arabic rhetoric.',
            'Vindicated directly by Allah in Surat An-Nur through divine verses recited eternally in prayer.',
        ],
        'virtuesAr': [
            'قال النبي ﷺ: «فضل عائشة على النساء كفضل الثريد على سائر الطعام».',
            'سئل النبي ﷺ: من أحب الناس إليك؟ قال: «عائشة»، قيل: ومن الرجال؟ قال: «أبوها».',
            'قال مسروق: «رأيت مشيخة أصحاب رسول الله ﷺ الأكابر يسألونها عن الفرائض».',
        ],
        'virtuesEn': [
            'The Prophet ﷺ said: "The superiority of Aisha over other women is like the superiority of Tharid over all other food."',
            'Asked who was dearest to his heart, the Prophet proclaimed: "Aisha!" and among men: "Her father."',
            'Leading scholars of the companions traveled from afar to seek her binding legal determinations.',
        ],
    },
    'fatimah-az-zahra': {
        'milestonesAr': [
            'أشبه الناس بأبيها النبي ﷺ مشية وهدياً وحديثاً وسمتاً ووقاراً.',
            'دافعت عن والدها بشجاعة وهي طفلة صغيرة وأزالت الأذى عن ظهره الشريف عند الكعبة.',
            'صبرت على شظف العيش وطحن الشعير بيدها حتى نالت شرف الآخرة.',
            'أم سيدي شباب أهل الجنة: الحسن والحسين رضي الله عنهما.',
        ],
        'milestonesEn': [
            'Bearing the closest resemblance to the Prophet ﷺ in gait, speech, dignity, and conduct.',
            'Defended her father as a brave young child, wiping filth from his back at the Ka\'bah.',
            'Endured humble poverty, grinding wheat with her own hands with serene patience.',
            'Mother of the two leaders of the youth of Paradise: Al-Hasan and Al-Husayn.',
        ],
        'virtuesAr': [
            'قال النبي ﷺ: «فاطمة بضعة مني، يريبني ما رابها، ويؤذيني ما آذاها».',
            'بشرها النبي ﷺ بأنها: «سيدة نساء أهل الجنة» وسيدة نساء العالمين.',
            'كان النبي ﷺ إذا دخلت عليه قام إليها فرحاً فقبّل جبهتها وأجلسها في مجلسه.',
        ],
        'virtuesEn': [
            'The Prophet ﷺ said: "Fatimah is a piece of me; whatever doubts trouble her trouble me, and whatever hurts her hurts me."',
            'Given glad tidings by the Prophet as the Queen and supreme leader of the women of Paradise.',
            'Whenever she arrived, the Prophet would stand up to honor her, kiss her forehead, and seat her in his own place.',
        ],
    },
    'asma-bint-abi-bakr': {
        'milestonesAr': [
            'بطلة ليلة الهجرة؛ شقت نطاقها نصفين لتربط زاد النبي وأبيها فنالت لقب (ذات النطاقين).',
            'صعدت جبل ثور الوعر في ظلام الليل وهي حامل لتزويد الغار بالطعام والأخبار.',
            'صمدت في وجه أبي جهل حين لطمها ولم تفشِ سر مكان رسول الله وأبيها.',
            'عاشت مائة عام بكامل وعيها وقوتها وربت ابنها عبد الله بن الزبير على المبادئ والعزة.',
        ],
        'milestonesEn': [
            'Heroine of the Hijrah; split her waistband in two to tie the Prophet\'s rations, earning her legendary title.',
            'Scaled steep Mount Thawr in night darkness while pregnant to deliver food and vital intelligence.',
            'Defied Abu Jahl with unbending courage when struck, keeping the Prophet\'s refuge secret.',
            'Lived to over 100 years with immaculate intellect, raising Abdullah ibn al-Zubayr upon uncompromising honor.',
        ],
        'virtuesAr': [
            'دعا لها النبي ﷺ بأن يبدلها الله بنطاقها نطاقين في الجنة.',
            'موقفها الخالد مع ابنها المحاصر: «إن الشاة لا يضرها سلخها بعد ذبحها، فامضِ على بصيرتك» مستعلية على الباطل.',
        ],
        'virtuesEn': [
            'The Prophet promised her two waistbands of light in Paradise in return for her sacrifice.',
            'Immortal words of conviction to her besieged son: "A slaughtered sheep feels no pain from being skinned; persevere upon your truth!"',
        ],
    },
    'nusaybah-bint-kaab': {
        'milestonesAr': [
            'شهدت بيعة العقبة الثانية وكانت من الرائدات المؤسسات لدعوة الإسلام بيثرب.',
            'شاركت في أحد لسقاية الجرحى، وتحولت لمقاتلة شجاعة بالسيف تذود عن رسول الله ﷺ.',
            'أصيبت بثلاثة عشر جرحاً طعناً وضرباً وهي تحول بين سيوف المشركين والنبي ﷺ.',
            'شاركت في حروب الردة وفي معركة اليمامة ضد مسيلمة الكذاب حتى قُطعت يدها وهي تقاتل.',
        ],
        'milestonesEn': [
            'Pioneer of the Second Pledge of Aqabah, establishing Islam\'s sanctuary in Madinah.',
            'Initially served as medic at Uhud, then drew sword and shield when enemies converged upon the Prophet.',
            'Sustained 13 direct battle wounds protecting the Prophet from charging enemy cavalry.',
            'Fought fearlessly in the Yamama campaigns against Musaylimah until her arm was severed.',
        ],
        'virtuesAr': [
            'قال النبي ﷺ يوم أحد: «ما التفتّ يمنة ولا يسرة إلا وأنا أراها تقاتل دوني».',
            'دعا لها النبي ﷺ ولأهل بيتها: «اللهم اجعلهم رفقائي في الجنة»، فقالت: ما أبالي ما أصابني من الدنيا بعد هذا.',
        ],
        'virtuesEn': [
            'The Prophet testified: "Wherever I looked, right or left on the day of Uhud, I saw her fighting to protect me."',
            'The Prophet prayed: "O Allah, make them my companions in Paradise!" She smiled: "I care nothing of earthly trials after this."',
        ],
    },
    'sumayyah-bint-khayyat': {
        'milestonesAr': [
            'من أوائل السبعة الذين أعلنوا إسلامهم بمكة جهراً أمام طغيان قريش.',
            'أُلبست دروع الحديد وعُذبت في رمضاء مكة الحارقة وصمدت رافضة الكفر.',
            'أول شهيدة صعدت روحها إلى السماء في تاريخ الإسلام بدمائها الطاهرة الزكية.',
            'أورثت ابنها عمار بن ياسر راية الصبر والجهاد في سبيل الحق.',
        ],
        'milestonesEn': [
            'Among the earliest seven courageous souls who publicly declared faith in Mecca.',
            'Forced into iron cuirasses under boiling sun, enduring torture without wavering.',
            'Became the very first martyr in Islamic history when struck down by Abu Jahl.',
            'Bequeathed a glorious legacy of spiritual resilience to her son Ammar.',
        ],
        'virtuesAr': [
            'بشرها النبي ﷺ وأسرتها بالجنة قائلاً: «صبراً آل ياسر، فإن موعدكم الجنة».',
            'كانت نموذجاً أبدياً للثبات الإيماني الذي قهر جبروت الطواغيت والجلادين بالصبر والاحتساب.',
        ],
        'virtuesEn': [
            'The Prophet gave divine assurance to her family: "Patience, O family of Yasir, for your appointment is in Paradise!"',
            'Eternal archetype of spiritual conviction overcoming ruthless tyrannical brutality.',
        ],
    },
    'umm-sulaym-bint-milhan': {
        'milestonesAr': [
            'اشترطت إسلام أبي طلحة مهراً لزواجها فكان أعظم وأكرم مهر في تاريخ البشرية.',
            'أهدت ابنها أنس بن مالك لرسول الله ﷺ ليتعلم منه ويخدمه فكان من أوعية العلم.',
            'ضربت مثلاً إيمانياً خارقاً في الصبر والرضا والتسليم حين توفي ولدها الصغير واحتسبته عند الله.',
            'شاركت في حنين وأحد لمداواة الجرحى وحملت الخنجر شجاعة ودفاعاً.',
        ],
        'milestonesEn': [
            'Stipulated Abu Talha\'s conversion to Islam as her dowry, setting the most honorable dowry in history.',
            'Entrusted her child Anas ibn Malik to the Prophet\'s mentorship, grooming him as a primary hadith scholar.',
            'Showcased breathtaking poise and emotional mastery upon the passing of her young son.',
            'Active frontline medic at Hunayn and Uhud, carrying daggers in resolute defense of the Prophet.',
        ],
        'virtuesAr': [
            'قال النبي ﷺ: «دخلت الجنة فسمعت خشفة (صوت مشي)، فقلت: من هذا؟ قالوا: هذه الغميصاء بنت ملحان (أم سليم)» يراها النبي في الجنة.',
            'دعا النبي ﷺ لبيتها بالبركة فعاشوا في سعة من العلم والفضل والذرية الصالحة.',
        ],
        'virtuesEn': [
            'The Prophet said: "I entered Paradise and heard footsteps. I asked who it was, and was told: It is Al-Ghumaysa bint Milhan (Umm Sulaym)."',
            'The Prophet showered her household with heartfelt prayers for abundance in faith, family, and knowledge.',
        ],
    },
    'ash-shifa-bint-abdullah': {
        'milestonesAr': [
            'تعلمت القراءة والكتابة والطب والرقية في الجاهلية وكانت من رائدات العلم بين النساء.',
            'أول معلمة في الإسلام؛ كلفها النبي ﷺ بتعليم أم المؤمنين حفصة بنت عمر الكتابة.',
            'هاجرت إلى المدينة وبايعت النبي ﷺ وخصها بدار تكريماً لمكانتها وعلمها.',
            'ولاها الفاروق عمر بن الخطاب الحسبة ومراقبة أسواق المدينة لنزاهتها ورجاحة عقلها.',
        ],
        'milestonesEn': [
            'Learned literacy, folk medicine, and administrative penmanship during the pre-Islamic era.',
            'First formal female educator in Islam; asked by the Prophet to teach Lady Hafsah calligraphy.',
            'Migrated to Madinah, pledged allegiance, and was honored by the Prophet with a dedicated home.',
            'Appointed by Caliph Umar to oversee the civic markets of Madinah with full regulatory authority.',
        ],
        'virtuesAr': [
            'كان النبي ﷺ يزورها في دارها ويكرمها ويقيل عندها احتراماً لفضلها وعلمها.',
            'استشارها عمر بن الخطاب في المعضلات الاقتصادية وأمور التجارة والأسواق مقدماً رأيها.',
        ],
        'virtuesEn': [
            'The Prophet held her in deep esteem, visiting her home and resting there in honor of her knowledge.',
            'Caliph Umar continually sought her advice on civic commerce and market governance.',
        ],
    },
}

def format_list(items):
    lines = []
    for item in items:
        clean = item.replace("'", "\\'")
        lines.append(f"      '{clean}',")
    return "[\n" + "\n".join(lines) + "\n    ]"

filepath = r"d:\New folder (11)\adhkar\lib\data\companions_stories_data.dart"
with open(filepath, "r", encoding="utf-8") as f:
    text = f.read()

# Pattern to find each CompanionStory block
pattern = re.compile(r"(\s+id:\s*'([^']+)',.*?readTimeMinutes:\s*\d+,)(.*?)(\n\s*\),)", re.DOTALL)

def replacer(match):
    prefix = match.group(1)
    c_id = match.group(2)
    suffix = match.group(4)
    if c_id in DATA:
        d = DATA[c_id]
        m_ar = format_list(d['milestonesAr'])
        m_en = format_list(d['milestonesEn'])
        v_ar = format_list(d['virtuesAr'])
        v_en = format_list(d['virtuesEn'])
        
        insert = f"""
    milestonesAr: {m_ar},
    milestonesEn: {m_en},
    virtuesAr: {v_ar},
    virtuesEn: {v_en},"""
        return prefix + insert + suffix
    return match.group(0)

new_text = pattern.sub(replacer, text)

with open(filepath, "w", encoding="utf-8") as f:
    f.write(new_text)

print("Successfully enriched companions data!")
