/**
 * Seed Firestore with app content from tools/content_dump.json + data.json
 * Uses Identity Toolkit password auth + Firestore REST batchWrite (no firebase-admin).
 */
const fs = require('fs');
const path = require('path');

const PROJECT = 'durrat-al-mumin';
const API_KEY = 'AIzaSyB8pG1aDqlOm4Rhvf_9oqFfcPq205CkbT0';
const EMAIL = 'admin@durrat-al-mumin.app';
const PASSWORD = 'DurratAdmin#2026';
const ROOT = path.resolve(__dirname, '..');
const DUMP = path.join(ROOT, 'tools', 'content_dump.json');
const LEGACY = path.join(ROOT, 'admin_dashboard', 'data.json');

async function signIn() {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: EMAIL,
        password: PASSWORD,
        returnSecureToken: true,
      }),
    }
  );
  const j = await res.json();
  if (!res.ok) throw new Error(j.error?.message || 'signIn failed');
  // Firestore REST needs OAuth2 access_token, not the ID token.
  const tok = await fetch(
    `https://securetoken.googleapis.com/v1/token?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body:
        `grant_type=refresh_token&refresh_token=${encodeURIComponent(j.refreshToken)}` +
        `&id_token=${encodeURIComponent(j.idToken)}`,
    }
  );
  const tj = await tok.json();
  if (!tok.ok) {
    console.error('token exchange failed', tj);
    throw new Error(tj.error_description || 'token exchange failed');
  }
  return tj.access_token;
}

function toVal(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') {
    return Number.isInteger(v)
      ? { integerValue: String(v) }
      : { doubleValue: v };
  }
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toVal) } };
  if (typeof v === 'object') {
    // Firestore timestamp ISO strings → timestampValue when field name suggests it
    const fields = {};
    for (const [k, val] of Object.entries(v)) {
      fields[k] = toVal(val);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(v) };
}

function convertFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v === undefined) continue;
    if (
      (k === 'createdAt' || k === 'updatedAt' || k === 'sentAt' ||
        k === 'lastActive' || k === 'registeredAt' || k === 'lastLoginAt' ||
        k === 'expiresAt' || k === 'updatedAtMs') &&
      typeof v === 'string' &&
      !Number.isNaN(Date.parse(v))
    ) {
      fields[k] = { timestampValue: new Date(v).toISOString() };
    } else if (k === 'createdAt' || k === 'updatedAt') {
      fields[k] = { timestampValue: new Date().toISOString() };
    } else {
      fields[k] = toVal(v);
    }
  }
  return fields;
}

async function batchWrite(token, writes) {
  const LIMIT = 400;
  let ok = 0;
  for (let i = 0; i < writes.length; i += LIMIT) {
    const chunk = writes.slice(i, i + LIMIT);
    const res = await fetch(
      `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:commit`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ writes: chunk }),
      }
    );
    const text = await res.text();
    if (!res.ok) {
      console.error('commit HTTP', res.status, text.slice(0, 500));
      throw new Error(`commit failed at chunk ${i}`);
    }
    const j = JSON.parse(text);
    if (j.writeResults) ok += j.writeResults.length;
    const failed = (j.writeResults || []).filter(
      (w) => w.updateTime === undefined && !w.transformResult
    ).length;
    if (failed) {
      console.warn(`  chunk ${i}: ${failed} writes without updateTime`);
      const sample = (j.writeResults || []).find((w) => !w.updateTime);
      if (sample) console.warn(JSON.stringify(sample).slice(0, 400));
    }
    process.stdout.write(`  chunk ${i}-${i + chunk.length} done\n`);
  }
  return ok;
}

function docWrite(collection, id, data) {
  const safeId = String(id).replace(/[^\w\-.~]/g, '_');
  return {
    update: {
      name: `projects/${PROJECT}/databases/(default)/documents/${collection}/${safeId}`,
      fields: convertFields(data),
    },
    updateMask: { fieldPaths: Object.keys(convertFields(data)) },
    currentDocument: { exists: false },
  };
}

function docUpsert(collection, id, data) {
  const safeId = String(id).replace(/[^\w\-.~]/g, '_');
  const fields = convertFields(data);
  return {
    update: {
      name: `projects/${PROJECT}/databases/(default)/documents/${collection}/${safeId}`,
      fields,
    },
    updateMask: { fieldPaths: Object.keys(fields) },
  };
}

async function listCount(token, collection) {
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/${collection}?pageSize=1&key=${API_KEY}`,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  if (!res.ok) return -1;
  const j = await res.json();
  return (j.documents || []).length;
}

async function main() {
  console.log('Signing in…');
  const token = await signIn();
  console.log('Signed in as', EMAIL);

  const dump = JSON.parse(fs.readFileSync(DUMP, 'utf8'));
  const legacy = JSON.parse(fs.readFileSync(LEGACY, 'utf8'));

  const writes = [];

  // app_config/main — full config the Flutter app listens for
  const homeCards = {
    shaarawi: true,
    companions: true,
    animeStories: true,
    quranRadio: true,
    soulMedicine: true,
    commitmentTree: true,
    namesOfAllah: true,
    morningEvening: true,
    smartTasbeeh: true,
    prayerTimes: true,
  };
  writes.push(
    docUpsert('app_config', 'main', {
      appName: legacy.config?.appName || 'درة المؤمن',
      appVersion: legacy.config?.appVersion || '1.2.0',
      minSupportedVersion: legacy.config?.minSupportedVersion || '1.0.0',
      maintenanceMode: false,
      maintenanceMessage:
        legacy.config?.maintenanceMessage ||
        'التطبيق في صيانة مجدولة وسيعود قريباً بإذن الله.',
      featuredDhikr:
        legacy.config?.featuredDhikr ||
        'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
      azanPopupEnabled: legacy.config?.azanPopupEnabled !== false,
      quranRadioEnabled: legacy.config?.quranRadioEnabled !== false,
      forceUpdateUrl: legacy.config?.forceUpdateUrl || '',
      homeCards,
      updatedAt: new Date().toISOString(),
    })
  );

  // Legacy collections
  for (const u of legacy.users || []) {
    writes.push(
      docUpsert('users', u.id, {
        displayName: u.name,
        name: u.name,
        email: u.email,
        phone: u.phone || '',
        platform: u.platform || 'Android',
        status: u.status || 'نشط',
        role: u.role || 'مستخدم',
        provider: 'password',
        streak: u.completedDhikrs || 0,
        completedDhikrs: u.completedDhikrs || 0,
        registeredAt: u.registeredAt,
        lastActive: u.lastActive,
        lastLoginAt: u.lastActive,
        updatedAt: u.updatedAt || u.lastActive,
      })
    );
  }
  for (const r of legacy.radio || []) {
    writes.push(docUpsert('radio', r.id, r));
  }
  for (const b of legacy.broadcasts || []) {
    writes.push(docUpsert('broadcasts', b.id, b));
  }
  for (const r of legacy.ratings || []) {
    writes.push(docUpsert('ratings', r.id, r));
  }
  for (const f of legacy.feedback || []) {
    writes.push(docUpsert('feedback', f.id, f));
  }
  for (const d of legacy.adhkar || []) {
    writes.push(docUpsert('adhkar', d.id, d));
  }

  // Dart dump collections
  const mapList = (collection, list) => {
    for (const item of list || []) {
      const id = item.id || `${collection}_${Math.random().toString(36).slice(2)}`;
      writes.push(docUpsert(collection, id, item));
    }
  };
  mapList('anime_stories', dump.anime_stories);
  mapList('shaarawi_lessons', dump.shaarawi_lessons);
  mapList('hadith', dump.hadith);
  mapList('companions', dump.companions);
  mapList('soul_remedies', dump.soul_remedies);
  mapList('riyad_hadith', dump.riyad_hadith);

  // quran meta: store as single meta doc + paginated list docs (keep small)
  if (dump.quran_surahs?.length) {
    writes.push(
      docUpsert('quran_meta', 'surahs', {
        count: dump.quran_surahs.length,
        updatedAt: new Date().toISOString(),
      })
    );
    for (const s of dump.quran_surahs) {
      writes.push(docUpsert('quran_surahs', `s${s.number}`, s));
    }
  }

  console.log(`Writing ${writes.length} documents…`);
  const n = await batchWrite(token, writes);
  console.log('Write results:', n);

  // Verify counts
  for (const c of [
    'app_config',
    'users',
    'adhkar',
    'anime_stories',
    'shaarawi_lessons',
    'hadith',
    'riyad_hadith',
    'companions',
    'soul_remedies',
    'radio',
    'broadcasts',
    'ratings',
    'feedback',
    'prayer_requests',
    'reports',
    'quran_surahs',
  ]) {
    const cnt = await listCount(token, c);
    console.log(`  ${c}: ~${cnt} (first page sample)`);
  }

  // Exact counts via list with pageSize 300 where possible
  async function exact(collection, pageSize = 300) {
    let pageToken = '';
    let total = 0;
    for (let i = 0; i < 20; i++) {
      const url =
        `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/${collection}` +
        `?pageSize=${pageSize}${pageToken ? `&pageToken=${pageToken}` : ''}`;
      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) break;
      const j = await res.json();
      total += (j.documents || []).length;
      if (!j.nextPageToken) break;
      pageToken = j.nextPageToken;
    }
    return total;
  }

  console.log('Exact counts:');
  for (const c of [
    'users',
    'adhkar',
    'anime_stories',
    'shaarawi_lessons',
    'hadith',
    'companions',
    'soul_remedies',
    'radio',
    'broadcasts',
    'ratings',
    'feedback',
    'riyad_hadith',
  ]) {
    console.log(`  ${c}: ${await exact(c, c === 'riyad_hadith' ? 300 : 100)}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
