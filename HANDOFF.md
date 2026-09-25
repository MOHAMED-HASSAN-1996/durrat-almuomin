# حزمة التسليم — تطبيق «درة المؤمن» (Durrat Al-Mu'min)

> مستند تسليم شامل لمطوّر يستلم المشروع. تاريخ الإصدار: 22 سبتمبر 2026.

---

## 1. نظرة عامة على المشروع

| البند | القيمة |
|---|---|
| اسم التطبيق | **درة المؤمن** (بدون تشكيل في الواجهات) |
| اسم حزمة المشروع | `adhkar` (Dart package name) |
| Application ID | `com.dhikr.adhkar` |
| الإصدار | `1.0.0+1` (`version: 1.0.0+1` في pubspec) |
| المنصة | Android فقط (iOS غير مهيأ) |
| Flutter SDK | `^3.12.0` |
| Java/Kotlin | JVM 17 |
| Firebase projectId | `durrat-al-mumin` |
| Git repo | لا يوجد (المشروع ليس repo) |

تطبيق إسلامي شامل: أذكار صباح/مساء، مصحف عثماني 15 سطراً، إذاعة قرآن بنمط Spotify، مواقيت صلاة وأذان، قبلة، سجل التزام، أحاديث، صيدلية الروح، جوامع الذكر، أهل البيت، تسبيح، زكاة، حج وعمرة، حساب ليلة القدر، مساجد قريبة، دروس الشعراوي، قصص صحابة وأنبياء.

---

## 2. ملفات التسليم الجاهزة

| الملف | المسار | الحجم | SHA256 |
|---|---|---|---|
| **APK النهائي** | `release/درة_المؤمن_v1.0.0_النهائية.apk` | 119.65 MB | `BFA06D1365A888A89E9413C709E8514F12FEF64753896EBEEB0A027220F2AB7B` |
| نسخة بديلة | `درة_المؤمن_v1.0.0_النهائية.apk` | 119.65 MB | مطابق |
| مسار البناء | `build/app/outputs/flutter-apk/app-release.apk` | 119.65 MB | مطابق |

> ملاحظة: اسم الملف بالعربية قد يظهر `???` في PowerShell — استخدم File Explorer للتحقق.

---

## 3. أوامر التشغيل

### فحص وبناء
```bash
# تحليل ثابت (يجب 0 أخطاء)
flutter analyze

# بناء APK الإصدار (الحجم الحالي 119.65 MB)
flutter build apk --release
# الناتج: build/app/outputs/flutter-apk/app-release.apk
```

### تشغيل لوحة التحكم
```bash
cd admin_dashboard
# الإعداد: انسخ .env.example إلى .env وضع ADMIN_DASHBOARD_KEY طويلاً
# أو اتركه فارغاً وسيولّده السيرفر تلقائياً ويحفظه في .env
npm install   # أو npm ci
npm start     # node server.js — المنفذ 4000
# المتصفح: http://localhost:4000
```

### نشر لوحة التحكم
```bash
# Vercel
cd admin_dashboard && vercel --prod
# أو Firebase Hosting (public: admin_dashboard حسب firebase.json)
firebase deploy --only hosting
```

### تثبيت على جهاز/محاكي
```bash
adb install -r "release/درة_المؤمن_v1.0.0_النهائية.apk"
adb shell am force-stop com.dhikr.adhkar
adb shell am start -n com.dhikr.adhkar/.MainActivity
```

---

## 4. التوقيع Release Signing

⚠️ **حفظ جوجل بلاي يرتبط بهذا المفتاح — لا تفقده.**

| البند | القيمة |
|---|---|
| Keystore | `android/app/upload-keystore.jks` |
| Properties | `android/key.properties` |
| Keystore Password | `DurratAlMuumin@2026` |
| Key Alias | `upload` |
| Key Password | `DurratAlMuumin@2026` |
| Type | PKCS12, صالح ~27 سنة |

`build.gradle.kts` يقرأ `android/key.properties` تلقائياً ويطبّق `signingConfig = release` على buildType الإصدار.

---

## 5. إعدادات البناء (android/app/build.gradle.kts)

- **abiFilters**: `arm64-v8a` (أجهزة حقيقية) + `x86_64` (محاكي) — تم حذف `armeabi-v7a`.
- **Minify + Shrink**: `isMinifyEnabled = true`, `isShrinkResources = true`
- **Proguard**: `android/app/proguard-rules.pro` (يحمي الصوت/الويب/الإشعارات)
- **Core library desugaring** مفعّل.
- لا تستخدم `--split-per-abi` في الإصدار الحالي (Universal APK).

---

## 6. حجم APK وتخفيضه

- الحجم الحالي: **119.65 MB** (كان 126.68MB — توفير ~7MB).
- تحسينات منفّذة:
  1. إعادة ترميز `adhan.mp3` إلى **64 kbps mono** (215 ثانية، ~1.7MB) — SHA256: `6457DA07A23581089E9897860426F225C2CF2903FDD380843378D5F6C5AA4D6B`
  2. تنظيف حزمة `qcf_quran` (لقطات شاشة).
  3. `abiFilters` محدودة (بدون 32-bit).
  4. R8 minify + resource shrink.
- خيارات إضافية مقترحة (لم تنفَّذ): `--split-per-abi` أو حذف `x86_64` (~27MB)، ضغط الصور، AAB لـ Play Store.

### ملفات الصوت الحرجة (لا تحذف)
| الملف | الحجم | SHA256 |
|---|---|---|
| `assets/audio/adhan.mp3` + `res/raw/adhan.mp3` | 1,722,336 | `6457DA07...AA4D6B` (متطابقان) |
| `assets/audio/iqtarabat.mp3` + `res/raw/iqtarabat.mp3` | 71,514 | متطابقان |
| `res/raw/keep.xml` | — | يحمي iqtarabat من الـ shrinker |

⚠️ `iqtarabat_saudi` غير موجود حالياً (عدم وجود ملف بهذا الاسم).

---

## 7. نظام الأذان والتنبيهات (الأهم صيانةً)

المرجع الكامل: **`ADHAN_FIX_NOTES.md`**. الملخص:

### المبدأ
1. تنبيه «اقتربت الصلاة» قبل الأذان بـ **10 دقائق** (قناة `adhkar_pre_prayer_v5_reminder_channel`، صوت `iqtarabat`).
2. الأذان عند الموعد لا يتوقف إلا **بطلب المستخدم** — لا يُلغى من كود التطبيق.

### آليات الحماية
- **adhan slot registry**: `Map<int, DateTime> _adhanSlots` في `prayer_alert_service.dart`.
- `_adhanGraceMinutes = 20` — خلال 20 دقيقة من وقت الأذان لا يستطيع أي مسار إلغاء الإشعار.
- `isAdhanActive(id)`, `_setAdhanSlot()`, `stopAzan()` (فقط بطلب المستخدم), `cleanupStaleAdhanNotifications()` عند resume.
- إشعار الأذان: `ongoing: true`, `autoCancel: false`, `timeoutAfter: 5 دقائق`, **بدون** `fullScreenIntent` (لا صلاحيات إضافية).
- قناة الأذان: `adhkar_prayer_azan_v9_fullscreen_audio_channel` — أي تغيير صوت يتطلب **رفع رقم الجيل** في `_channelId`.

### ملفات الكود
- `lib/services/prayer_alert_service.dart` — كل المنطق (قنوات ≈415/640/678، AssetSource ≈1261/1273، `adhanSoundMs=5*60*1000`، slots ≈1281-1344).
- `lib/screens/permissions_control_screen.dart` — أزرار المعاينة (زر «معاينة سريعة» `_adhanPreviewId=991`).
- `lib/app.dart` — تنظيف عند resume.

### قواعد صارمة
- لا تضف `cancel(id:)` للأذان إلا داخل `_setAdhanSlot` أو `stopAzan`.
- لا تُعِد `fullScreenIntent` / `AdhanAlertScreen`.
- لا تحذف `adhan.mp3` أو `iqtarabat.mp3` أو `keep.xml`.

---

## 8. بنية المشروع (lib/)

```
lib/
├── main.dart                 # نقطة الدخول
├── app.dart                  # Provider root + تنظيف الأذان عند resume
├── firebase_options.dart     # إعدادات Firebase (project: durrat-al-mumin)
├── data/                     # محتوى ثابت: adhkar, hadith, companions, shaarawi, anime, quran_surahs, soul_remedies, riyad_hadith...
├── l10n/strings.dart         # عربي / إنجليزي
├── models/                   # zakat_model, loved_one
├── screens/                  # ~40 شاشة (home, prayer_times, quran_mushaf, quran_radio, permissions_control, loved_ones, zakat, tasbih, qibla, ...)
├── services/                 # prayer_alert, prayer_times, storage, audio, quran_radio, firebase_auth, home_widget, remote_content, admin_sync, ...
├── state/app_state.dart      # Provider مركزي
├── theme/app_theme.dart      # ألوان الهوية (أخضر غابة، حكيم، عاجي، فحم، رمل)
├── types/adhkar.dart
└── widgets/                  # home_hero_card, bottom_nav, dhikr_counter, calendar, ...
```

خطوط التطبيق: **SomarSans** (400/500/700) + Thuluth. الخط نفسه في لوحة التحكم (OTF داخل `admin_dashboard/fonts/`).

---

## 9. لوحة التحكم (Admin Dashboard) — الشكل النهائي

### التشغيل والوصول
- **المنفذ**: 4000 (أو `PORT`)
- **URL**: `http://localhost:4000`
- **تسجيل الدخول**: مفتاح `ADMIN_DASHBOARD_KEY` من `.env` (حماية: 8 محاولات/5 دقائق، جلسات 7 أيام في `sessions.json`).
- **API Base**: `http://localhost:4000/api/...`

### الواجهة (index.html — RTL عربي، هوية «درة المؤمن»)
- **Sidebar**: نظرة عامة، المستخدمين، الاقتراحات، التقييمات، المحتوى والأذكار، الإعدادات، الإشعارات العامّة، الإذاعة، النسخ الاحتياطي.
- **Tab نظرة عامة**: رسم بياني شهري، عداد رضا 98%، جدول ملاحظات، أعلى الدول.
- **إدارة المستخدمين**: بحث/فلترة/تصدير JSON، إضافة/حظر.
- **الإعدادات عن بعد**: toggles (popup الأذان، إذاعة القرآن، وضع الصيانة)، ذكر مميز، force update version.
- **المحتوى**: CRUD كامل للأذكار (صباح/مساء/رقية/نوم/تسبيح/بعد الصلاة) مع صوت وفضل ومصدر.
- **الإذاعة**: CRUD للمحطات.
- **الإشعارات**: بث عام للمنصات.
- **التقييمات/الملاحظات**: عرض ورد.
- خطوط: SomarSans (6 أوزان). ألوان: `#10B981` green, `#111827` charcoal, أبيض/رمادي.

### API endpoints (الكل يتطلب Bearer token بعد login)
| Endpoint | Methods |
|---|---|
| `/api/login`, `/api/logout`, `/api/me` | POST/GET |
| `/api/stats` | GET |
| `/api/adhkar` (+`/id`) | GET, POST, PUT, DELETE |
| `/api/radio` (+`/id`) | GET, POST, PUT, DELETE |
| `/api/config` | GET, POST/PUT |
| `/api/broadcasts` | GET, POST |
| `/api/users` | GET, POST, PUT, DELETE |
| `/api/feedback` | GET, POST, PUT, DELETE |
| `/api/ratings` | GET, POST |
| `/api/firebase/sync`, `/api/firebase/config` | POST/GET |
| `/api/ai/ocr-extract` | POST (محاكاة) |

### ملفات البيانات
- `data.json` — مفاتيح: `config`, `radio`, `broadcasts`, `users`, `ratings`, `feedback`, `adhkar`, `firebase`.
- `.env` / `.env.example` — `ADMIN_DASHBOARD_KEY`.
- `vercel.json` — rewrites لـ `/api` و `/privacy`.
- `firebase.json` hosting public = `admin_dashboard`.

⚠️ بيانات Firebase في `data.json` الحالية (`dhikr-app-production`) **قديمة/تجريبية** — المشروع الفعلي `durrat-al-mumin`. راجعها قبل النشر.

---

## 10. Firebase

- **projectId**: `durrat-al-mumin`
- **appId**: `1:273977925686:android:a3de27f05afa905371b897`
- ملفات: `firebase.json`, `firestore.rules` (مطالبات دعاء: `prayer_requests` + comments + reports), `firestore.indexes.json`, `lib/firebase_options.dart`, `android/app/google-services.json`.
- Auth: `firebase_auth` + `google_sign_in` عبر `lib/services/firebase_auth_service.dart`.

---

## 11. وثائق موجودة في المشروع

| الملف | المحتوى |
|---|---|
| `README.md` | الدليل التقني (تم تحديث الاسم إلى درة المؤمن) |
| `RELEASE_CHECKLIST.md` | قائمة جاهزية النشر — كل البنود مكتملة [x] |
| `KEYSTORE_INFO.txt` | تفاصيل مفتاح التوقيع |
| `ADHAN_FIX_NOTES.md` | تصميم الأذان الحالي بالتفصيل |
| `admin_dashboard/` | لوحة التحكم كاملة |

---

## 12. ما تم إنجازه في هذه الجلسة (للمطوّر القادم)

1. ✅ تقليل حجم APK: 126.68 → **119.65 MB** (64kbps mono للأذان، تنظيف qcf_quran، abiFilters).
2. ✅ `flutter analyze` = 0 أخطاء.
3. ✅ بناء وتوقيع ونسخ APK إلى مسارين (`release/` وجذر المشروع).
4. ✅ تثبيت وتشغيل على محاكي Pixel6_API34 — الجدولة والإذاعة تعملان، لا FATAL.
5. ✅ إصلاح حجب الإشعارات على الجهاز (`POST_NOTIFICATION` → importance DEFAULT).
6. ✅ التحقق من مسارات الأذان (قنوات v9/v5، مصادر الأصوات).
7. ✅ كتابة مستند التسليم هذا + تحديث README لاسم «درة المؤمن».

### مهام متبقية (اختيارية/مؤجلة)
- تجربة صوت الأذان فعلياً عبر زر «معاينة سريعة» والتحقق من `id=990/991` في `dumpsys notification`.
- خيارات حجم إضافية (split-per-abi / AAB / حذف x86_64).
- ترتيب كروت «دعاء بظهر الغيب» في `loved_ones_screen.dart`.
- مزامنة بيانات لوحة التحكم مع مشروع Firebase الصحيح.

---

> تم تجهيز هذا الملف لتسليم المشروع لمطوّر آخر. راجع `ADHAN_FIX_NOTES.md` قبل أي تعديل على الإشعارات، و`KEYSTORE_INFO.txt` قبل أي عملية نشر.
