/* Import adhkar from lib/data/adhkar.dart (Flutter) into admin_dashboard/data.json */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const DART = path.join(ROOT, 'lib/data/adhkar.dart');
const DATA = path.join(ROOT, 'admin_dashboard/data.json');

const src = fs.readFileSync(DART, 'utf8');
const db = JSON.parse(fs.readFileSync(DATA, 'utf8'));

const CATEGORIES = {
  morning: 'أذكار الصباح',
  evening: 'أذكار المساء',
  ruqyah: 'الرقية الشرعية',
  afterPrayer: 'أذكار بعد الصلاة',
  sleep: 'أذكار النوم',
  waking: 'أذكار الاستيقاظ',
  tasbeeh: 'السبحة والتسابيح',
  custom: 'أذكار مخصصة',
};

// ---- Dart string literal reader: reads from src[i] (first quote) until terminator.
function readString(src, i, quote) {
  let out = '';
  i += 1;
  while (i < src.length) {
    const c = src[i];
    if (c === '\\') {
      out += src[i + 1];
      i += 2;
      continue;
    }
    if (c === quote) { i += 1; break; }
    out += c;
    i += 1;
  }
  return { value: out, index: i };
}

// ---- Find all Dhikr( ... ) blocks. Paren depth only counts OUTSIDE strings.
function findBlocks(src) {
  const blocks = [];
  let i = 0;
  while (i < src.length) {
    const idx = src.indexOf('Dhikr(', i);
    if (idx === -1) break;
    let j = idx + 6; // after 'Dhikr('
    let depth = 1;
    let k = j;
    while (k < src.length && depth > 0) {
      const c = src[k];
      if (c === "'" || c === '"') {
        const r = readString(src, k, c);
        k = r.index;
        continue;
      }
      if (c === '(') depth += 1;
      else if (c === ')') depth -= 1;
      k += 1;
    }
    blocks.push(src.slice(idx, k));
    i = k;
  }
  return blocks;
}

// ---- Split a block into top-level `name: value` chunks.
function splitArgs(block) {
  const inner = block.slice('Dhikr('.length, block.length - 1);
  const parts = [];
  let cur = '';
  let paren = 0;
  let bracket = 0;
  let i = 0;
  while (i < inner.length) {
    const c = inner[i];
    if (c === "'" || c === '"') {
      const r = readString(inner, i, c);
      cur += inner.slice(i, r.index);
      i = r.index;
      continue;
    }
    if (c === '(') paren += 1;
    else if (c === ')') paren -= 1;
    else if (c === '[') bracket += 1;
    else if (c === ']') bracket -= 1;
    if (c === ',' && paren === 0 && bracket === 0) {
      parts.push(cur.trim());
      cur = '';
      i += 1;
      continue;
    }
    cur += c;
    i += 1;
  }
  if (cur.trim()) parts.push(cur.trim());
  return parts;
}

function readListValue(src, i) {
  // src[i] === '[' ; returns array of string literals.
  const values = [];
  let k = i + 1;
  while (k < src.length) {
    const c = src[k];
    if (c === "'" || c === '"') {
      const r = readString(src, k, c);
      values.push(r.value);
      k = r.index;
      continue;
    }
    if (c === ']') break;
    k += 1;
  }
  return { value: values, index: k + 1 };
}

function parseArgValue(v) {
  v = v.trim();
  if (v === '') return '';
  const c0 = v[0];
  if (c0 === "'" || c0 === '"') {
    const r = readString(v, 0, c0);
    return r.value;
  }
  if (c0 === '[') {
    const r = readListValue(v, 0);
    return r.value;
  }
  if (v.startsWith('DhikrCategory.')) return v.split('.').pop().trim();
  if (/^[0-9]+$/.test(v)) return parseInt(v, 10);
  return v;
}

const blocks = findBlocks(src);
const imported = [];

for (const b of blocks) {
  const args = splitArgs(b);
  const obj = {};
  for (const arg of args) {
    const idx = arg.indexOf(':');
    if (idx === -1) continue;
    const name = arg.slice(0, idx).trim();
    let value = arg.slice(idx + 1).trim();
    // values that are string literals may have been extracted already via readListValue
    if (name === 'quranAudio') {
      obj.quranAudio = Array.isArray(value) ? value : parseArgValue(value);
      continue;
    }
    obj[name] = parseArgValue(value);
  }

  if (!obj.id) continue;
  const cat = obj.category || 'custom';
  const audioUrls = Array.isArray(obj.quranAudio) ? obj.quranAudio.filter(u => /^https?:/.test(u || '')) : [];
  const isAudio = (obj.audio && obj.audio.trim() !== '') || audioUrls.length > 0;

  const existing = (db.adhkar || []).find(a => a.id === obj.id);
  const now = new Date().toISOString();

  imported.push({
    id: obj.id,
    category: cat === 'after-prayer' ? 'afterPrayer' : cat,
    categoryNameAr: CATEGORIES[cat === 'after-prayer' ? 'afterPrayer' : cat] || 'أذكار عامة',
    arabic: obj.arabic || '',
    english: obj.english || '',
    repeat: obj.repeat || 1,
    source: obj.source || '',
    virtue: obj.virtue || '',
    virtueEn: obj.virtueEn || '',
    isAudio: !!isAudio,
    audioUrl: audioUrls[0] || '',
    audio: obj.audio || '',
    createdAt: (existing && existing.createdAt) || now,
    updatedAt: now,
  });
}

const keepExtra = (db.adhkar || []).filter(a => !imported.some(n => n.id === a.id));
db.adhkar = imported.concat(keepExtra);

fs.writeFileSync(DATA, JSON.stringify(db, null, 2), 'utf8');
console.log(`Imported ${imported.length} adhkar, kept ${keepExtra.length} extra, total=${db.adhkar.length}`);