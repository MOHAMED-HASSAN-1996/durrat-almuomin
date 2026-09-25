# حل خطأ يوتيوب 153 داخل تطبيق درة المؤمن (WebView)

> **المشكلة:** الفيديوهات (الأنمي الإسلامي وقصص الأنبياء والدروس) كانت تظهر خطأ
> **153 Video player configuration error** عند التشغيل داخل التطبيق على أندرويد،
> رغم أن كل الفيديوهات تسمح بالتضمين رسميًا (تم فحصها كلها عبر oEmbed).
>
> **السبب الجذري (من توثيق يوتيوب الرسمي + تقارير إنتاج 2025):** منذ يوليو 2025
> أصبح يوتيوب يشترط إرسال هيدر HTTP `Referer` صالح مع طلب صفحة التضمين، وإلا
> يرفض التشغيل داخل WebView برسالة `embedder.identity.missing.referrer` — وهذه
> هي نفس رسالة خطأ 153.
>
> **الحل:** إرسال هيدر `Referer` بقيمة معرف حزمة التطبيق (بصيغة `https://<bundle_id>`)
> عند تحميل صفحة `youtube.com/embed/...`. هذا هو ما يطلبه توثيق يوتيوب الرسمي
> نفسه في صفحة **YouTube Required Minimum Functionality**.

---

## سبب خطأ 153 بالتفصيل

صفحة التضمين `https://www.youtube.com/embed/VIDEO_ID` تعرض الفيديو داخل one إطار
web. لكي يأذن يوتيوب بالتشغيل، يجب أن يتحقق من **هوية من يطلب التضمين**، ويتم ذلك
عبر هيدر `Referer`. في WebView الخاص بالتطبيقات (Flutter / React Native /
Capacitor / MAUI...) لا يُرسل المتصفح هيدر `Referer` تلقائيًا لصفحة embed على
متصفح أجهزة مختلفة — فيصل الطلب بلا هوية فيرفض يوتيوب التشغيل بخطأ 153.

الرسالة الظاهرة في سجل الأخطاء: `embedder.identity.missing.referrer`.

القنوات/المواضيع المرجعية المؤكدة لهذا السبب (2025):
- مناقشة `react-native-webview` — Error 153 in YouTube Iframe (#3855)
- StackOverflow: "YouTube video in WebView gives error code 153 on Android"
- StackOverflow: "YouTube Error 153: Video Player Configuration Error"
- مدونة corsproxy.io: "Fix YouTube Error 150/153 in WebViews"
- توثيق يوتيوب: youtube.com/terms/required-minimum-functionality

---

## مكان التطبيق في الكود

الملف: `lib/screens/in_app_player_screen.dart`

### 1. ثابت هوية التطبيق

```dart
/// معرف التطبيق — يُستخدم كهوية رسمية أمام يوتيوب في هيدر Referer/Origin
/// أثناء تحميل صفحة التضمين (اشتراط YouTube Required Minimum Functionality).
const String YOUTUBE_APP_ID = 'com.dhikr.adhkar';
```

### 2. إرسال الهيدر مع طلب التحميل

```dart
Future<void> _loadCurrentUrl() async {
  final c = _controller;
  if (c == null) throw StateError('no controller');
  final url = _currentLoadUrl;
  if (url.contains('/embed/')) {
    // إرسال هوية التطبيق في Referer — اشتراط يوتيوب الرسمي منذ 2025
    // (Required Minimum Functionality) لمنع خطأ 153 في WebView.
    await c.loadRequest(
      Uri.parse(url),
      headers: const {
        'Referer': 'https://${YOUTUBE_APP_ID}',
      },
    );
  } else {
    await c.loadRequest(Uri.parse(url));
  }
}
```

### 3. ملاحظات مهمة للتحقق

- `WebViewController.loadRequest()` يدعم `headers` في `webview_flutter` من الإصدار 4.x.
- DOM storage مُفعّل تلقائيًا في `webview_flutter_android` (لا حاجة لتعطيله يدويًا).
- لتشغيل تلقائي فعلى أندرويد شغّل:
  ```dart
  final platformController = _controller?.platform;
  if (platformController is AndroidWebViewController) {
    await platformController.setMediaPlaybackRequiresUserGesture(false);
  }
  ```

---

## الوضع القانوني لهذا الحل (لماذا لا يوجد أي انتهاك)

**لا توجد أي حقوق بث أو انتهاك حقوق نشر في هذا الحل، والسبب:**

1. **المصدر رسمي** — التطبيق لا يحمّل الفيديو ولا يعيد رفعه؛ بل يعرض صفحة
   `youtube.com/embed/VIDEO_ID` الرسمية نفسها التي يتم التضمين منها. الفيديو
   يبقى مُستضافًا على خوادم يوتيوب الرسمية، ويُشغَّل بمشغّل يوتيوب الأصلي.

2. **إرسال Referer هو ما يطلبه يوتيوب نفسه** — توثيق YouTube الرسمي
   (Required Minimum Functionality) يُلزم التطبيقات بإرسال معرفها في هيدر
   `Referer`. فإرساله ليس "اختراقًا" ولا "تجاوز قيود"؛ بل هو **الطريقة الرسمية
   الموصى بها لتعريف التطبيق لدى يوتيوب** حتى يعمل التضمين بشكل صحيح.

3. **لا إخفاء شعار يوتيوب** — التطبيق لا يخفي العلامة التجارية ولا يشوّه
   الواجهة الرسمية (تم إزالة أي CSS/JS كان يُخفي شعار يوتيوب سابقًا التزامًا
   بشروط الاستخدام).

4. **لا تنزيل ولا فك تشفير DRM** — لا نستخدم أي أدوات استخراج روابط مباشرة
   (yt-dlp أو ما شابه) ولا نكسر أي حماية. الفيديو يُشغَّل فقط من خلال مشغّل
   يوتيوب الرسمي داخل WebView.

5. **يُحترَم قرار الناشر** — إذا كان الفيديو غير مسموح بالتضمين أصلًا، فسيرفضه
   يوتيوب نفسه ضمن مشغّله الرسمي؛ التطبيق لا يجبر على كسر ذلك.

6. **مصطلح "حقوق البث" لا ينطبق** — حقوق البث (Broadcast Rights) تخص قنوات
   التلفزيون والمنصات التي تبث المحتوى. التطبيق **لا يبث** ولا يعيد إرسال
   المحتوى؛ هو مجرد نافذة تعرض مشغّل يوتيوب الرسمي. التشغيل يحدث من مشغّل
   يوتيوب ذاته، وعلى خوادم يوتيوب، داخل الإطار المخصص رسميًا للتضمين.

> **الخلاصة باختصار:** نفس ما تفعله آلاف التطبيقات والقنوات مواقع يستخدمون
> YouTube embed — الفيديو يبقى على يوتيوب، والأرباح/الإعلانات لفائدة صاحب
> القناة، والتطبيق مجرد نافذة عرض رسمية، والهيدر المُرسل هو المتطلب الرسمي
> من يوتيوب نفسه. **صفر انتهاك.**

---

## التحقق من الفيديو أنه يعمل

> بعد آخر بناء وتثبيت على جهاز Samsung SM-A235F، فُتحت حلقة «انمي — قصة النبي
> موسى»، وظهر في `logcat` نشاط حقيقي لفك ترميز الفيديو:
>
> ```
> ACodec: [OMX.qcom.video.decoder.vp9] Now Idle->Executing
> ACodec: configureOutputBuffersFromNativeWindow setBufferCount: 21
> ACodec: [OMX.qcom.video.decoder.vp9] Now Executing
> ```
>
> ولا وجود لأي أثر لخطأ 153 أو رفض تشغيل بعد الإصلاح.

---

## ملاحظات إضافية

- زر التشغيل/الإيقاف الخاص بالتطبيق أُزيل عمدًا؛ التشغيل والإيقاف يتمان من أزرار
  يوتيوب الأصلية داخل الفيديو، وأبقينا في التطبيق: **السابق / التالي / تدوير**
  فقط. السبب: أي أمر JS خارجي يتحكم بعنصر `<video>` قد يتعارض مع إعدادات مشغّل
  يوتيوب الرسمي فيسبب أخطاء.
- (تاريخي) كانت هناك نية سابقة لـ `m.youtube.com/watch` تُراجَع وتُلغى حينها
  كان **embed + Referer** هو الحل الوحيد المعتمد — حتى سبتمبر 2026 حين رفضت
  يوتيوب التضمين من WebView حتى مع Referer صالح (راجع الطبقة الثانية أدناه).

---

# الطبقة الثانية (تحديث 2026): التحويل الحتمي لصفحة المشاهدة الرسمية

> **السياق:** في سبتمبر 2026 عادت بعض الفيديوهات (خالد بن الوليد ف2-4، النبي
> موسى ف1) لا تعمل داخل التطبيق رغم أن هيدر Referer ما زال يُرسَل. التشخيص على
> الجهاز: صفحة التضمين تفتح لكن **لا يبدأ أي نشاط لفك تشفير الفيديو** في logcat
> (لا `ACodec` قيد التنفيذ) — أي أن مشغّل الإطار نفسه يعلن
> `player-unavailable` («حدث خطأ»)، بينما كل الفيديوهات ما زالت قابلة للتشغيل
> على صفحة المشاهدة الرسمية (`playabilityStatus: OK` عبر /watch). يوتيوب
> شدّد قيود «المُضمِّن» ثانيةً على أجهزة WebView معينة لهذه الفيديوهات فقط.

## الحل المعتمد والموفّر الآن (على مرحلتين)

> **📌 تحديث نهائي (سبتمبر 2026):** القرار المعتمد هو **التضمين كمسار أساسي**
> (`embed` + Referer — الحل الأصلي كما كان) مع بقاء المراقب كشبكة أمان: عند
> رفض التضمين يتحوّل تلقائيًا لصفحة المشاهدة داخل نفس الـ WebView. (تجربة
> «الموبايل يبدأ بصفحة المشاهدة مباشرةً» أُلغيت لصالح هذا الترتيب.)

1. **الأصل (الكل):** التضمين الرسمي `youtube.com/embed/ID` + هيدر Referer
   داخل `WebViewController` (المسار النظيف).
2. **شبكة الأمان:** لو رفض التضمين (كشف `ytp-error`/`ytp-embed-error` بعد
   ≈6 ثوانٍ، أو بقاء صفحة `m.youtube.com/watch` بلا عنصر فيديو بعد ≈10 ثوانٍ
   → `m.youtube.com/watch` ثم `www.youtube.com/watch` داخل نفس الـ WebView.
   بمجرد توفّر فيديو يعمل، لا يحدث أي تحويل.

الفيديو المحجوب من يوتيوب نفسه (رمز 151 — قيود مشرف/منطقة/شبكة) يظهر خطأه
الصريح من صفحة يوتيوب الرسمية في الحالتين، وليس للتطبيق دور في حله.

### شبكة الأمان المتبقية (للقوائم/الويب فقط): الكشف وحيد
   ```js
   try{var v=document.querySelector('video');
   if(v&&v.currentSrc){return v.paused?0:1;}
   var pe=document.querySelector('.ytp-error');
   if(pe&&getComputedStyle(pe).display!=='none'){return -2;}
   var pp=document.querySelector('.html5-video-player');
   if(pp&&pp.className.indexOf('ytp-embed-error')>=0){return -2;}
   var pa=document.querySelector('.player-unavailable');
   if(pa&&getComputedStyle(pa).display!=='none'){return -2;}
   return -99;}catch(e){return -99;}
   ```
   > ملاحظة (تشخيص 2026 بالجهاز): الشكل الحقيقي للفشل هو `ytp-embed-error` على
   > `html5-video-player` مع رسالة `ytp-error` («الفيديو غير متاح» تارة و«خطأ في
   > إعدادات مشغّل الفيديو» تارة — حسب الفيديو). تُفحص `-2` بعد 3 جولات متتالية
   > (≈6 ثوانٍ) → `_activateWatchFallback()` لتحميل صفحة المشاهدة داخل نفس الـ
   > WebView. تعمل مرة واحدة لكل فيديو (`_watchFallbackUsed`).

## مكان التطبيق في الكود

الملف: `lib/screens/in_app_player_screen.dart`
- الحقول: `_watchFallbackUsed`، `_desktopWatchFallbackUsed`، `_embedCheckCount`.
- الإعادة عند كل فيديو: `_setupPlayer()`.
- الكشف: `_startStatePoller()` (معادلة `-2` فشل تضمين، و`-99` متكرر لصفحة
  m.youtube بلا عنصر فيديو → تحويل سطح المكتب).
- التحويل: `_activateWatchFallback()` (للموبايل) و`_activateDesktopWatchFallback()`
  (لسطح المكتب `www.youtube.com/watch`).

## التحقق (كتابتي 2026)

بناء جديد + تثبيت على جهاز Samsung SM-A235F / TV box، فتح «خالد الفصل
الثاني» الذي كان يفشل → بعد ~6-8 ثوانٍ يتحول WebView تلقائيًا إلى صفحة
المشاهدة ويبدأ `ACodec: [OMX.qcom.video.decoder.vp9] Executing` في logcat
(علامة نجاح فك التشفير) — بلا أي رسالة خطأ وبدون مغادرة التطبيق.

## نتائج التشخيص مباشرةً (CDP على WebView الجهاز)

على جهاز Samsung SM-A235F (WebView 153.0.8010.36) في سبتمبر 2026:

- صفحة التضمين لكل الفيديوهات ترفض التشغيل الآن — حتى الفصل الأول الذي كان
  يعمل سابقًا:
  - `الفصل الأول`: `ytp-embed-error` + «خطأ في إعدادات مشغّل الفيديو» (153).
  - `الفصل الثاني`: `ytp-embed-error` + «الفيديو غير متاح».
  - لا `videoSrc` في الحالتين، `readyState=0`.
- **نفس الـ WebView** عند فتح `https://m.youtube.com/watch?v=…` مباشرةً:
  `videoSrc=blob:…`، `readyState=4`، `paused=false` — **يشتغل فورًا** بلا
  أخطاء (المعرف التالي يؤكد ذلك: 1a1ntXVfRx8 فصل خالد الأول).

الخلاصة: الحل المعتمد هو التحويل التلقائي لصفحة المشاهدة عند رفض التضمين،
والكشف الصحيح للفشل هو `.ytp-error`/`ytp-embed-error` (وليس `.player-unavailable`).

---