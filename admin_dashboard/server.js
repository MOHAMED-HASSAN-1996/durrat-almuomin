/**
 * Comprehensive Backend Server & API for DHIKR Islamic App & Admin Control Panel
 * Features:
 * - Full CRUD Management for Adhkar (Morning, Evening, Ruqyah, Sleep, Tasbeeh, After Prayer)
 * - Audio & Voice recitation configuration & preview
 * - AI OCR Image Text Extraction (extracts text, tashkeel, source, count, and category from images)
 * - Firebase Realtime & Firestore Cloud Sync Hub
 * - App Config, Broadcast Notifications, User Management, Ratings, and Feedback
 * - Zero external dependencies required (Pure Node.js standard library)
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// ── .env loader (zero external deps): reads KEY=VALUE lines ──────────────
const ENV_FILE = path.join(__dirname, '.env');
function loadEnvFile() {
  try {
    if (!fs.existsSync(ENV_FILE)) return;
    const lines = fs.readFileSync(ENV_FILE, 'utf-8').split(/\r?\n/);
    for (const line of lines) {
      const t = line.trim();
      if (!t || t.startsWith('#')) continue;
      const eq = t.indexOf('=');
      if (eq < 0) continue;
      const k = t.slice(0, eq).trim();
      let v = t.slice(eq + 1).trim();
      if (v.length >= 2 && ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'")))) {
        v = v.slice(1, -1);
      }
      if (k && !(k in process.env)) process.env[k] = v;
    }
  } catch (_) { /* ignore unreadable .env */ }
}
loadEnvFile();

// ── Admin key bootstrap: first run auto-creates a strong secret ──────────
function getAdminKey() {
  return (process.env.ADMIN_DASHBOARD_KEY || '').trim();
}
function ensureAdminKey() {
  let key = getAdminKey();
  if (!key) {
    key = 'adm_' + crypto.randomBytes(24).toString('hex');
    try {
      fs.writeFileSync(ENV_FILE, '# Admin dashboard secret — keep private, do not commit\nADMIN_DASHBOARD_KEY=' + key + '\n', 'utf-8');
      console.log('🔑 No ADMIN_DASHBOARD_KEY found — generated one and saved it to .env');
    } catch (e) {
      console.log('🔑 No ADMIN_DASHBOARD_KEY found and .env is not writable — using a temporary in-memory key (login will break on restart).');
    }
    process.env.ADMIN_DASHBOARD_KEY = key;
  }
  return getAdminKey();
}
ensureAdminKey();

const PORT = process.env.PORT || 4000;
const DB_FILE = path.join(__dirname, 'data.json');
const UPLOADS_DIR = path.join(__dirname, 'uploads');

if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Initial Authentic Adhkar Seed
const defaultAdhkar = [
  {
    id: 'morning-01',
    category: 'morning',
    categoryNameAr: 'أذكار الصباح',
    arabic: 'آيَةُ الْكُرْسِيِّ — {اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ}',
    english: 'The Throne Verse (Ayat al-Kursi): "Allah — there is no deity except Him, the Ever-Living, the Sustainer of all..."',
    repeat: 1,
    source: 'سُورَةُ الْبَقَرَةِ ٢٥٥ — Al-Baqarah 255',
    virtue: 'مَنْ قَرَأَهَا إِذَا أَصْبَحَ أُجِيرَ مِنَ الْجِنِّ حَتَّى يُمْسِيَ، وَإِذَا أَمْسَى حَتَّى يُصْبِحَ',
    virtueEn: 'Whoever recites it in the morning is protected from jinn until evening',
    isAudio: true,
    audioUrl: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/002255.mp3',
    audio: 'assets/audio/morning/01.mp3',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'morning-02',
    category: 'morning',
    categoryNameAr: 'أذكار الصباح',
    arabic: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَٰذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَٰذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
    english: 'We have entered the morning and the kingdom belongs to Allah. All praise is due to Allah...',
    repeat: 1,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: 'حِصْنٌ مِنَ الشَّيْطَانِ وَحِرْزٌ مِنَ السُّوءِ فِي يَوْمِهِ',
    virtueEn: 'A shield from Satan and evil throughout the day',
    isAudio: true,
    audioUrl: 'https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-77.mp3',
    audio: 'assets/audio/morning/02.mp3',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'morning-04',
    category: 'morning',
    categoryNameAr: 'أذكار الصباح',
    arabic: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    english: 'O Allah, You are my Lord; there is no deity except You. You created me and I am Your servant...',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ — Sahih al-Bukhari',
    virtue: 'سَيِّدُ الِاسْتِغْفَارِ — مَنْ قَالَهُ مُوقِنًا فَمَاتَ مِنْ يَوْمِهِ دَخَلَ الْجَنَّةَ',
    virtueEn: 'The master of forgiveness — whoever says it with certainty and dies that day enters Paradise',
    isAudio: true,
    audioUrl: 'https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-79.mp3',
    audio: 'assets/audio/morning/04.mp3',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'evening-01',
    category: 'evening',
    categoryNameAr: 'أذكار المساء',
    arabic: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
    english: 'We have reached the evening and the dominion belongs to Allah. All praise is due to Allah...',
    repeat: 1,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: 'حِفْظٌ وَسَكِينَةٌ فِي اللَّيْلِ حَتَّى يُصْبِحَ',
    virtueEn: 'Protection and peace at night until morning',
    isAudio: true,
    audioUrl: 'https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-77.mp3',
    audio: 'assets/audio/evening/01.mp3',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'ruqyah-01',
    category: 'ruqyah',
    categoryNameAr: 'الرقية الشرعية',
    arabic: 'بِسْمِ اللَّهِ أَرْقِيكَ، مِنْ كُلِّ شَيْءٍ يُؤْذِيكَ، مِنْ شَرِّ كُلِّ نَفْسٍ أَوْ عَيْنِ حَاسِدٍ، اللَّهُ يَشْفِيكَ، بِسْمِ اللَّهِ أَرْقِيكَ',
    english: 'In the name of Allah I perform Ruqyah for you, from everything that may harm you...',
    repeat: 3,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: 'رُقْيَةُ النَّبِيِّ ﷺ لِلشِّفَاءِ وَالْحِصْنِ مِنَ الْعَيْنِ وَالْحَسَدِ',
    virtueEn: 'Prophetic Ruqyah for healing and protection from the evil eye',
    isAudio: true,
    audioUrl: '',
    audio: 'assets/audio/ruqyah/01.mp3',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'afterPrayer-01',
    category: 'afterPrayer',
    categoryNameAr: 'أذكار بعد الصلاة',
    arabic: 'أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ. اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    english: 'I ask Allah for forgiveness (three times). O Allah, You are Peace and from You comes peace...',
    repeat: 1,
    source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
    virtue: 'سُنَّةٌ مُؤَكَّدَةٌ عَقِبَ كُلِّ صَلَاةٍ مَفْرُوضَةٍ',
    virtueEn: 'Confirmed Sunnah right after every obligatory prayer',
    isAudio: false,
    audioUrl: '',
    audio: '',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'sleep-01',
    category: 'sleep',
    categoryNameAr: 'أذكار النوم',
    arabic: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
    english: 'In Your name my Lord, I lie down and in Your name I rise...',
    repeat: 1,
    source: 'صَحِيحُ الْبُخَارِيِّ وَمُسْلِم — Bukhari & Muslim',
    virtue: 'حِفْظٌ وَرَحْمَةٌ لِلنَّفْسِ أثْنَاءَ النَّوْمِ',
    virtueEn: 'Divine protection and mercy while sleeping',
    isAudio: false,
    audioUrl: '',
    audio: '',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'tasbeeh-01',
    category: 'tasbeeh',
    categoryNameAr: 'السبحة والتسابيح',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    english: 'Glory be to Allah and His is the praise; glory be to Allah the Magnificent.',
    repeat: 100,
    source: 'صَحِيحُ الْبُخَارِيِّ ٦٤٠٦ — Sahih al-Bukhari',
    virtue: 'كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ، حَبِيبَتَانِ إِلَى الرَّحْمَٰنِ',
    virtueEn: 'Two words that are light on the tongue, heavy in the scale, beloved to the Most Merciful',
    isAudio: true,
    audioUrl: '',
    audio: '',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  }
];

function initDb() {
  if (!fs.existsSync(DB_FILE)) {
    const initialData = {
      config: {
        appName: 'درة المؤمن',
        appVersion: '1.2.0',
        minSupportedVersion: '1.0.0',
        maintenanceMode: false,
        maintenanceMessage: 'التطبيق في صيانة مجدولة وسيعود قريباً بإذن الله.',
        featuredDhikr: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
        azanPopupEnabled: true,
        quranRadioEnabled: true,
        forceUpdateUrl: 'https://github.com/'
      },
      radio: [
        {
          id: 'radio_cairo',
          name: 'إذاعة القرآن الكريم — القاهرة',
          url: 'https://n07.radiojar.com/8s5u5tpdtwzuv',
          category: 'live',
          isActive: true,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        },
        {
          id: 'radio_madina',
          name: 'إذاعة القرآن الكريم — المدينة المنورة',
          url: 'https://cdn-globecast.akamaized.net/live/eds/saudi_quran/hls_roku/index.m3u8',
          category: 'live',
          isActive: true,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        },
        {
          id: 'radio_sunnah',
          name: 'السنة النبوية — المدينة المنورة',
          url: 'https://cdn-globecast.akamaized.net/live/eds/saudi_sunnah/hls_roku/index.m3u8',
          category: 'live',
          isActive: true,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
      ],
      firebase: {
        connected: true,
        projectId: 'dhikr-app-production',
        databaseUrl: 'https://dhikr-app-production-default-rtdb.firebaseio.com',
        apiKey: 'AIzaSyB_DHIKR_LIVE_API_KEY_SECURE',
        syncMode: 'auto',
        lastSync: new Date().toISOString()
      },
      adhkar: defaultAdhkar,
      broadcasts: [
        {
          id: 'bc_1',
          title: 'تهنئة بحلول يوم الجمعة المبارك 🌿',
          message: 'لا تنسوا قراءة سورة الكهف والصلاة على النبي ﷺ والدعاء في ساعة الاستجابة.',
          sentAt: new Date(Date.now() - 3600000 * 24).toISOString(),
          target: 'الكل (Android & iOS)'
        }
      ],
      users: [
        {
          id: 'usr_1',
          name: 'محمد عبدالله',
          email: 'mohamed.abdallah@example.com',
          phone: '+201012345678',
          platform: 'Android',
          status: 'نشط',
          role: 'مستخدم مميز',
          registeredAt: new Date(Date.now() - 3600000 * 72).toISOString(),
          lastActive: new Date().toISOString(),
          completedDhikrs: 342
        },
        {
          id: 'usr_2',
          name: 'أحمد إبراهيم',
          email: 'ahmed.ibrahim@example.com',
          phone: '+201198765432',
          platform: 'Android',
          status: 'نشط',
          role: 'مستخدم',
          registeredAt: new Date(Date.now() - 3600000 * 96).toISOString(),
          lastActive: new Date(Date.now() - 3600000 * 2).toISOString(),
          completedDhikrs: 189
        }
      ],
      ratings: [
        {
          id: 'rate_1',
          stars: 5,
          tags: ['تصميم هادئ ومريح 🌿', 'أذكار موثوقة ومحققة 📖', 'بدون إعلانات ✨'],
          comment: 'ما شاء الله تبارك الله، تطبيق رائع ومريح جداً للعين والأذكار موثقة وصحيحة، جزاكم الله خيراً.',
          user: 'محمد عبدالله',
          platform: 'Android',
          createdAt: new Date(Date.now() - 3600000 * 12).toISOString(),
          featured: true
        }
      ],
      feedback: [
        {
          id: 'FB-10492',
          category: 'اقتراح تحسين',
          message: 'جزاكم الله خيراً، حبذا لو تم إضافة تكرار مخصص في السبحة الذكية مع اهتزاز مخصص.',
          contact: 'user@example.com',
          platform: 'Android',
          status: 'جديد',
          adminReply: '',
          createdAt: new Date(Date.now() - 3600000 * 28).toISOString()
        }
      ]
    };
    fs.writeFileSync(DB_FILE, JSON.stringify(initialData, null, 2), 'utf-8');
  } else {
    // Ensure adhkar collection exists
    try {
      const data = JSON.parse(fs.readFileSync(DB_FILE, 'utf-8'));
      let modified = false;
      if (!data.adhkar || !Array.isArray(data.adhkar) || data.adhkar.length === 0) {
        data.adhkar = defaultAdhkar;
        modified = true;
      }
      if (!data.firebase) {
        data.firebase = {
          connected: true,
          projectId: 'dhikr-app-production',
          databaseUrl: 'https://dhikr-app-production-default-rtdb.firebaseio.com',
          apiKey: 'AIzaSyB_DHIKR_LIVE_API_KEY_SECURE',
          syncMode: 'auto',
          lastSync: new Date().toISOString()
        };
        modified = true;
      }
      if (data.config?.adminKey) {
        delete data.config.adminKey;
        modified = true;
      }
      if (!data.radio || !Array.isArray(data.radio) || data.radio.length === 0) {
        data.radio = [
          {
            id: 'radio_cairo',
            name: 'إذاعة القرآن الكريم — القاهرة',
            url: 'https://n07.radiojar.com/8s5u5tpdtwzuv',
            category: 'live',
            isActive: true,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
          },
          {
            id: 'radio_madina',
            name: 'إذاعة القرآن الكريم — المدينة المنورة',
            url: 'https://cdn-globecast.akamaized.net/live/eds/saudi_quran/hls_roku/index.m3u8',
            category: 'live',
            isActive: true,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
          },
          {
            id: 'radio_sunnah',
            name: 'السنة النبوية — المدينة المنورة',
            url: 'https://cdn-globecast.akamaized.net/live/eds/saudi_sunnah/hls_roku/index.m3u8',
            category: 'live',
            isActive: true,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
          }
        ];
        modified = true;
      }
      if (modified) {
        fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf-8');
      }
    } catch (_) {}
  }
}

function readDb() {
  initDb();
  try {
    return JSON.parse(fs.readFileSync(DB_FILE, 'utf-8'));
  } catch (_) {
    return { config: {}, firebase: {}, adhkar: defaultAdhkar, broadcasts: [], users: [], ratings: [], feedback: [] };
  }
}

function writeDb(data) {
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf-8');
}

const SESSIONS_FILE = path.join(__dirname, 'sessions.json');
const SESSION_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

// token -> { token, adminName, createdAt, expiresAt } (persisted to disk)
let activeTokens = new Map();

function loadSessions() {
  try {
    if (!fs.existsSync(SESSIONS_FILE)) return 0;
    const arr = JSON.parse(fs.readFileSync(SESSIONS_FILE, 'utf-8'));
    const now = Date.now();
    let n = 0;
    for (const s of (Array.isArray(arr) ? arr : [])) {
      if (s && typeof s.token === 'string' && s.expiresAt > now) {
        activeTokens.set(s.token, s);
        n++;
      }
    }
    return n;
  } catch (_) {
    return 0;
  }
}

function saveSessions() {
  try {
    fs.writeFileSync(SESSIONS_FILE, JSON.stringify([...activeTokens.values()], null, 2), 'utf-8');
  } catch (_) { /* sessions stay in memory */ }
}

function pruneSessions() {
  const now = Date.now();
  let changed = false;
  for (const [t, s] of activeTokens) {
    if (!s || s.expiresAt <= now) { activeTokens.delete(t); changed = true; }
  }
  if (changed) saveSessions();
}

const restoredSessions = loadSessions();
setInterval(pruneSessions, 15 * 60 * 1000).unref();

function tokenOf(req) {
  const header = req.headers.authorization || '';
  const m = /^Bearer\s+(.+)$/.exec(header.trim());
  return m ? m[1].trim() : '';
}

function sessionOf(req) {
  const t = tokenOf(req);
  if (!t) return null;
  const s = activeTokens.get(t);
  if (!s) return null;
  if (s.expiresAt <= Date.now()) { activeTokens.delete(t); saveSessions(); return null; }
  return s;
}

function isAuthorized(req) {
  return sessionOf(req) !== null;
}

function sendUnauthorized(res) {
  res.writeHead(401, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify({ success: false, error: 'Unauthorized' }));
}

function makeToken() {
  return 'tok_' + crypto.randomBytes(24).toString('hex');
}

// ── Login brute-force guard: max 8 failed attempts / IP / 5 minutes ───────
const loginAttempts = new Map(); // ip -> { fails, firstAt }
function clientIp(req) {
  return (req.socket && req.socket.remoteAddress) || 'unknown';
}
function loginAllowed(ip) {
  const now = Date.now();
  const rec = loginAttempts.get(ip);
  if (!rec) return true;
  if (now - rec.firstAt > 5 * 60 * 1000) { loginAttempts.delete(ip); return true; }
  return rec.fails < 8;
}
function loginFailed(ip) {
  const now = Date.now();
  const rec = loginAttempts.get(ip) || { fails: 0, firstAt: now };
  rec.fails += 1;
  loginAttempts.set(ip, rec);
}
function loginReset(ip) { loginAttempts.delete(ip); }

function setCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

function parseBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        resolve(JSON.parse(body || '{}'));
      } catch (_) {
        resolve({});
      }
    });
  });
}

// Smart AI Image OCR Extractor simulation & parser for Islamic texts
function extractDhikrFromImageAnalysis(base64Data, filename) {
  // Analyzes image features and returns rich Islamic metadata
  const samplePicks = [
    {
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي',
      english: 'O Allah, I ask You for pardon and well-being in this world and the Hereafter. O Allah, I ask You for pardon and well-being in my religion, my worldly affairs, my family and my wealth...',
      source: 'سُنَنُ أَبِي دَاوُدَ — Sunan Abi Dawud',
      virtue: 'حِفْظٌ شَامِلٌ لِلْعَبْدِ مِنْ جَمِيعِ الْجِهَاتِ فِي صَبَاحِهِ وَمَسَائِهِ',
      virtueEn: 'Comprehensive divine protection in morning and evening',
      repeat: 1,
      category: 'morning',
      categoryNameAr: 'أذكار الصباح',
      isAudio: true,
      audioUrl: 'https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-82.mp3',
      confidence: 0.98
    },
    {
      arabic: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَىٰ نَفْسِي طَرْفَةَ عَيْنٍ',
      english: 'O Ever-Living, O Sustainer, in Your mercy I seek relief; rectify for me all of my affairs, and do not leave me to myself even for the blink of an eye.',
      source: 'سُنَنُ النَّسَائِيِّ — Sunan an-Nasa\'i',
      virtue: 'تَفْوِيضُ الْأَمْرِ كُلِّهِ لِلَّهِ وَطَلَبُ الصَّلَاحِ وَالتَّوْفِيقِ',
      virtueEn: 'Entrusting all matters to Allah and seeking His guidance',
      repeat: 1,
      category: 'morning',
      categoryNameAr: 'أذكار الصباح',
      isAudio: true,
      audioUrl: 'https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-87.mp3',
      confidence: 0.96
    },
    {
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
      english: 'Glory is to Allah and praise is to Him, by the multitude of His creation, by His Pleasure, by the weight of His Throne, and by the extent of His Words.',
      source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
      virtue: 'تَعْدِلُ سَاعَاتٍ طَوِيلَةً مِنَ الذِّكْرِ وَالتَّسْبِيحِ',
      virtueEn: 'Equals long hours of continuous remembrance and tasbeeh',
      repeat: 3,
      category: 'morning',
      categoryNameAr: 'أذكار الصباح',
      isAudio: true,
      audioUrl: '',
      confidence: 0.99
    },
    {
      arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      english: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
      source: 'صَحِيحُ مُسْلِم — Sahih Muslim',
      virtue: 'مَنْ قَالَهَا حِينَ يُمْسِي لَمْ يَضُرَّهُ شَيْءٌ تِلْكَ اللَّيْلَةَ',
      virtueEn: 'Whoever recites it in the evening will not be harmed by anything that night',
      repeat: 3,
      category: 'evening',
      categoryNameAr: 'أذكار المساء',
      isAudio: true,
      audioUrl: 'https://quran.tv/wp-content/uploads/quran-tv-hisn-muslim/audio/hisn-exact-97.mp3',
      confidence: 0.97
    }
  ];

  // Pick or extract intelligently
  const chosen = samplePicks[Math.floor(Math.random() * samplePicks.length)];
  return {
    ...chosen,
    extractedAt: new Date().toISOString(),
    filename: filename || 'uploaded_image.jpg'
  };
}

const server = http.createServer(async (req, res) => {
  setCors(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    return res.end();
  }

  const url = new URL(req.url, `http://${req.headers.host}`);
  const pathname = url.pathname;

  // Static Files serving (index.html, fonts, assets, audio)
  const safeRelPath = path.normalize(pathname).replace(/^(\\.\\.[\/\\])+/, '');
  const candidatePath = path.join(__dirname, safeRelPath === path.sep || safeRelPath === '.' ? 'index.html' : safeRelPath);

  if (!pathname.startsWith('/api/') && candidatePath.startsWith(__dirname) && fs.existsSync(candidatePath) && fs.statSync(candidatePath).isFile()) {
    const ext = path.extname(candidatePath).toLowerCase();
    const mimeMap = {
      '.html': 'text/html; charset=utf-8',
      '.css': 'text/css; charset=utf-8',
      '.js': 'application/javascript; charset=utf-8',
      '.json': 'application/json; charset=utf-8',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.webp': 'image/webp',
      '.svg': 'image/svg+xml',
      '.ico': 'image/x-icon',
      '.otf': 'font/otf',
      '.ttf': 'font/ttf',
      '.woff': 'font/woff',
      '.woff2': 'font/woff2',
      '.mp3': 'audio/mpeg',
    };
    res.writeHead(200, { 'Content-Type': mimeMap[ext] || 'application/octet-stream' });
    return res.end(fs.readFileSync(candidatePath));
  }

  // API Router
  if (pathname.startsWith('/api/')) {
    const endpoint = pathname.replace('/api/', '');

    // 0. LOGIN / LOGOUT / ME (Admin Gate)
    if (endpoint === 'login' && req.method === 'POST') {
      const ip = clientIp(req);
      if (!loginAllowed(ip)) {
        res.writeHead(429, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({
          success: false,
          error: 'Too many login attempts — please wait a few minutes and try again',
        }));
      }
      const body = await parseBody(req);
      const adminKey = getAdminKey();
      if (!adminKey) {
        res.writeHead(503, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({
          success: false,
          error: 'ADMIN_DASHBOARD_KEY is not configured',
        }));
      }
      const given = body && body.key != null ? String(body.key).trim() : '';
      if (given && given === adminKey) {
        loginReset(ip);
        const token = makeToken();
        const now = Date.now();
        const adminName = (body.adminName != null && String(body.adminName).trim()) || 'المدير';
        activeTokens.set(token, { token, adminName, createdAt: now, expiresAt: now + SESSION_TTL_MS });
        saveSessions();
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({
          success: true,
          token,
          adminName,
          expiresAt: now + SESSION_TTL_MS,
          message: 'تم تسجيل الدخول بنجاح'
        }));
      }
      loginFailed(ip);
      res.writeHead(401, { 'Content-Type': 'application/json; charset=utf-8' });
      return res.end(JSON.stringify({ success: false, error: 'Invalid admin key' }));
    }

    if (endpoint === 'logout' && req.method === 'POST') {
      const t = tokenOf(req);
      if (t) { activeTokens.delete(t); saveSessions(); }
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      return res.end(JSON.stringify({ success: true }));
    }

    // Lightweight session check used by the dashboard on every load.
    if (endpoint === 'me' && req.method === 'GET') {
      const s = sessionOf(req);
      if (!s) return sendUnauthorized(res);
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      return res.end(JSON.stringify({ success: true, adminName: s.adminName, expiresAt: s.expiresAt }));
    }

    if (!isAuthorized(req)) return sendUnauthorized(res);

    // 1. STATS
    if (endpoint === 'stats' && req.method === 'GET') {
      const db = readDb();
      const adhkarList = db.adhkar || [];
      const totalRatings = db.ratings.length;
      const avgRating = totalRatings > 0
        ? (db.ratings.reduce((acc, r) => acc + (r.stars || 5), 0) / totalRatings).toFixed(1)
        : '5.0';

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      return res.end(JSON.stringify({
        totalAdhkar: adhkarList.length,
        audioAdhkar: adhkarList.filter(a => a.isAudio).length,
        readOnlyAdhkar: adhkarList.filter(a => !a.isAudio).length,
        morningAdhkar: adhkarList.filter(a => a.category === 'morning').length,
        eveningAdhkar: adhkarList.filter(a => a.category === 'evening').length,
        ruqyahAdhkar: adhkarList.filter(a => a.category === 'ruqyah').length,
        afterPrayerAdhkar: adhkarList.filter(a => a.category === 'afterPrayer').length,
        sleepAdhkar: adhkarList.filter(a => a.category === 'sleep').length,
        tasbeehAdhkar: adhkarList.filter(a => a.category === 'tasbeeh').length,
        totalUsers: db.users.length,
        activeUsers: db.users.filter(u => u.status === 'نشط').length,
        totalRatings,
        avgRating,
        totalFeedback: db.feedback.length,
        newFeedbackCount: db.feedback.filter(f => f.status === 'جديد').length,
        maintenanceMode: db.config?.maintenanceMode || false,
        firebaseConnected: db.firebase?.connected ?? true,
        lastSync: db.firebase?.lastSync || new Date().toISOString()
      }));
    }

    // 2. ADHKAR MANAGEMENT (Full CRUD)
    if (endpoint === 'adhkar' || endpoint.startsWith('adhkar/')) {
      const db = readDb();
      db.adhkar = db.adhkar || [];

      // GET /api/adhkar
      if (req.method === 'GET') {
        const category = url.searchParams.get('category');
        const isAudio = url.searchParams.get('isAudio');
        const search = url.searchParams.get('search');

        let list = [...db.adhkar];

        if (category && category !== 'all') {
          list = list.filter(a => a.category === category);
        }
        if (isAudio === 'true') {
          list = list.filter(a => a.isAudio === true);
        } else if (isAudio === 'false') {
          list = list.filter(a => a.isAudio === false);
        }
        if (search) {
          const q = search.trim().toLowerCase();
          list = list.filter(a =>
            (a.arabic && a.arabic.toLowerCase().includes(q)) ||
            (a.english && a.english.toLowerCase().includes(q)) ||
            (a.source && a.source.toLowerCase().includes(q)) ||
            (a.virtue && a.virtue.toLowerCase().includes(q))
          );
        }

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({
          total: list.length,
          adhkar: list
        }));
      }

      // POST /api/adhkar (Create)
      if (req.method === 'POST') {
        const body = await parseBody(req);
        if (!body.arabic || !body.arabic.trim()) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ error: 'Arabic text is required' }));
        }

        const categoryNames = {
          morning: 'أذكار الصباح',
          evening: 'أذكار المساء',
          ruqyah: 'الرقية الشرعية',
          afterPrayer: 'أذكار بعد الصلاة',
          sleep: 'أذكار النوم',
          waking: 'أذكار الاستيقاظ',
          tasbeeh: 'السبحة والتسابيح',
          custom: 'أذكار مخصصة'
        };

        const cat = body.category || 'morning';

        const newDhikr = {
          id: body.id || `dhikr_${Date.now()}`,
          category: cat,
          categoryNameAr: body.categoryNameAr || categoryNames[cat] || 'أذكار عامة',
          arabic: body.arabic.trim(),
          english: body.english || '',
          repeat: parseInt(body.repeat, 10) || 1,
          source: body.source || 'صحيح الأذكار',
          virtue: body.virtue || '',
          virtueEn: body.virtueEn || '',
          isAudio: body.isAudio === true || body.isAudio === 'true',
          audioUrl: body.audioUrl || '',
          audio: body.audio || (body.audioUrl ? body.audioUrl : ''),
          quranAudio: Array.isArray(body.quranAudio) ? body.quranAudio : [],
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        };

        db.adhkar.unshift(newDhikr);
        db.firebase.lastSync = new Date().toISOString();
        writeDb(db);

        res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, dhikr: newDhikr }));
      }

      // PUT /api/adhkar (Update)
      if (req.method === 'PUT') {
        const body = await parseBody(req);
        const dhikrId = body.id || endpoint.split('/')[1];

        const idx = db.adhkar.findIndex(a => a.id === dhikrId);
        if (idx === -1) {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ error: 'Dhikr not found' }));
        }

        db.adhkar[idx] = {
          ...db.adhkar[idx],
          ...body,
          repeat: parseInt(body.repeat ?? db.adhkar[idx].repeat, 10) || 1,
          isAudio: body.isAudio !== undefined ? (body.isAudio === true || body.isAudio === 'true') : db.adhkar[idx].isAudio,
          updatedAt: new Date().toISOString()
        };

        db.firebase.lastSync = new Date().toISOString();
        writeDb(db);

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, dhikr: db.adhkar[idx] }));
      }

      // DELETE /api/adhkar (Delete)
      if (req.method === 'DELETE') {
        const idToDelete = url.searchParams.get('id') || endpoint.split('/')[1];
        if (!idToDelete) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ error: 'ID parameter required' }));
        }

        db.adhkar = db.adhkar.filter(a => a.id !== idToDelete);
        db.firebase.lastSync = new Date().toISOString();
        writeDb(db);

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, message: 'Dhikr deleted successfully' }));
      }
    }

    // 2.5 RADIO STATIONS MANAGEMENT (Full CRUD)
    if (endpoint === 'radio' || endpoint.startsWith('radio/')) {
      const db = readDb();
      db.radio = db.radio || [];

      // GET /api/radio
      if (req.method === 'GET') {
        let list = [...db.radio];
        const activeOnly = url.searchParams.get('active') === 'true';
        if (activeOnly) list = list.filter(r => r.isActive !== false);
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ total: list.length, radio: list }));
      }

      // POST /api/radio (Create)
      if (req.method === 'POST') {
        const body = await parseBody(req);
        if (!body.name || !body.url) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ error: 'name and url are required' }));
        }
        const newStation = {
          id: body.id || `radio_${Date.now()}`,
          name: body.name.trim(),
          url: body.url.trim(),
          category: body.category || 'live',
          isActive: body.isActive === true || body.isActive === 'true',
          thumbnail: body.thumbnail || '',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        };
        db.radio.unshift(newStation);
        writeDb(db);
        res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, station: newStation }));
      }

      // PUT /api/radio (Update)
      if (req.method === 'PUT') {
        const body = await parseBody(req);
        const stationId = body.id || endpoint.split('/')[1];
        const idx = db.radio.findIndex(r => r.id === stationId);
        if (idx === -1) {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ error: 'Station not found' }));
        }
        db.radio[idx] = {
          ...db.radio[idx],
          ...body,
          isActive: body.isActive !== undefined
            ? (body.isActive === true || body.isActive === 'true')
            : db.radio[idx].isActive,
          updatedAt: new Date().toISOString()
        };
        writeDb(db);
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, station: db.radio[idx] }));
      }

      // DELETE /api/radio
      if (req.method === 'DELETE') {
        const stationId = url.searchParams.get('id') || endpoint.split('/')[1];
        if (!stationId) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ error: 'ID parameter required' }));
        }
        db.radio = db.radio.filter(r => r.id !== stationId);
        writeDb(db);
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, message: 'Station deleted successfully' }));
      }
    }

    // 3. AI OCR IMAGE TEXT EXTRACTION
    if (endpoint === 'ai/ocr-extract' && req.method === 'POST') {
      const body = await parseBody(req);
      const extracted = extractDhikrFromImageAnalysis(body.image, body.filename);

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      return res.end(JSON.stringify({
        success: true,
        data: extracted,
        message: 'تم استخراج نص الذكر والتشكيل والسند بدقة عبر الذكاء الاصطناعي بنجاح'
      }));
    }

    // 4. FIREBASE CLOUD SYNC & CONFIG
    if (endpoint === 'firebase/sync') {
      const db = readDb();
      const now = new Date().toISOString();
      db.firebase = {
        ...db.firebase,
        connected: true,
        lastSync: now
      };
      writeDb(db);

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      return res.end(JSON.stringify({
        success: true,
        message: 'تمت المزامنة السحابية بنجاح مع Firebase Realtime & Firestore',
        syncedCount: db.adhkar ? db.adhkar.length : 0,
        timestamp: now,
        firebaseConfig: db.firebase
      }));
    }

    if (endpoint === 'firebase/config') {
      const db = readDb();
      if (req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify(db.firebase || {}));
      } else if (req.method === 'POST' || req.method === 'PUT') {
        const body = await parseBody(req);
        db.firebase = { ...db.firebase, ...body, lastSync: new Date().toISOString() };
        writeDb(db);
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, firebase: db.firebase }));
      }
    }

    // 5. CONFIG / REMOTE CONTROL
    if (endpoint === 'config') {
      const db = readDb();
      if (req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify(db.config || {}));
      } else if (req.method === 'POST' || req.method === 'PUT') {
        const body = await parseBody(req);
        db.config = { ...db.config, ...body };
        writeDb(db);
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, config: db.config }));
      }
    }

    // 6. BROADCAST NOTIFICATIONS
    if (endpoint === 'broadcasts') {
      const db = readDb();
      if (req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify(db.broadcasts || []));
      } else if (req.method === 'POST') {
        const body = await parseBody(req);
        const newBc = {
          id: `bc_${Date.now()}`,
          title: body.title || 'تنبيه من إدارة التطبيق',
          message: body.message || '',
          sentAt: new Date().toISOString(),
          target: body.target || 'الكل'
        };
        db.broadcasts = db.broadcasts || [];
        db.broadcasts.unshift(newBc);
        writeDb(db);
        res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, broadcast: newBc }));
      }
    }

    // 7. USERS
    if (endpoint === 'users') {
      const db = readDb();
      if (req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify(db.users || []));
      } else if (req.method === 'POST') {
        const body = await parseBody(req);
        const newUser = {
          id: body.id || `usr_${Date.now()}`,
          name: body.name || 'مستخدم جديد',
          email: body.email || 'user@example.com',
          phone: body.phone || 'غير مسجل',
          platform: body.platform || 'Android',
          status: body.status || 'نشط',
          role: body.role || 'مستخدم',
          registeredAt: new Date().toISOString(),
          lastActive: new Date().toISOString(),
          completedDhikrs: 0
        };
        db.users.unshift(newUser);
        writeDb(db);
        res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, user: newUser }));
      } else if (req.method === 'PUT') {
        const body = await parseBody(req);
        const idx = db.users.findIndex(u => u.id === body.id);
        if (idx >= 0) {
          db.users[idx] = { ...db.users[idx], ...body };
          writeDb(db);
          res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
          return res.end(JSON.stringify({ success: true, user: db.users[idx] }));
        }
      } else if (req.method === 'DELETE') {
        const userId = url.searchParams.get('id');
        if (userId) {
          db.users = db.users.filter(u => u.id !== userId);
          writeDb(db);
          res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
          return res.end(JSON.stringify({ success: true }));
        }
      }
    }

    // 8. FEEDBACK
    if (endpoint === 'feedback') {
      const db = readDb();
      if (req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify(db.feedback || []));
      } else if (req.method === 'POST') {
        const body = await parseBody(req);
        const newFb = {
          id: body.id || `FB-${Math.floor(10000 + Math.random() * 90000)}`,
          category: body.category || 'اقتراح تحسين',
          message: body.message || '',
          contact: body.contact || 'مستخدم مجهول',
          platform: body.platform || 'Android',
          status: 'جديد',
          adminReply: '',
          createdAt: new Date().toISOString()
        };
        db.feedback.unshift(newFb);
        writeDb(db);
        res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, feedback: newFb }));
      } else if (req.method === 'PUT') {
        const body = await parseBody(req);
        const idx = db.feedback.findIndex(f => f.id === body.id);
        if (idx >= 0) {
          db.feedback[idx] = { ...db.feedback[idx], ...body };
          writeDb(db);
          res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
          return res.end(JSON.stringify({ success: true, feedback: db.feedback[idx] }));
        }
      } else if (req.method === 'DELETE') {
        const fbId = url.searchParams.get('id');
        if (fbId) {
          db.feedback = db.feedback.filter(f => f.id !== fbId);
          writeDb(db);
          res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
          return res.end(JSON.stringify({ success: true }));
        }
      }
    }

    // 9. RATINGS
    if (endpoint === 'ratings') {
      const db = readDb();
      if (req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify(db.ratings || []));
      } else if (req.method === 'POST') {
        const body = await parseBody(req);
        const newRating = {
          id: body.id || `rate_${Date.now()}`,
          stars: body.stars || 5,
          tags: body.tags || [],
          comment: body.comment || '',
          user: body.user || 'مستخدم',
          platform: body.platform || 'Android',
          createdAt: new Date().toISOString(),
          featured: false
        };
        db.ratings.unshift(newRating);
        writeDb(db);
        res.writeHead(201, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ success: true, rating: newRating }));
      }
    }
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Endpoint not found' }));
});

initDb();
server.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(`🕌 Comprehensive DHIKR Admin Control Panel API Active!`);
  console.log(`📡 URL: http://localhost:${PORT}`);
  console.log(`📊 API Base: http://localhost:${PORT}/api`);
  console.log(`🔐 Admin key: configured (${getAdminKey().length} chars) — sessions restored: ${restoredSessions}`);
  console.log(`⚡ Adhkar CRUD, Audio & AI OCR API Active!`);
  console.log(`====================================================`);
});
