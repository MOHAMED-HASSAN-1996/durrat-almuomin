#!/usr/bin/env node
/*
 * Import built-in live radio stations from lib/data/radio_live_stations_data.dart
 * (the app's dedicated links file) into admin_dashboard/data.json.
 *
 * The cartoon: the same file that the Flutter app compiles from is also the
 * dashboard's radio seed, so editing the links once keeps both sides in sync.
 *
 * Usage:  node scripts/import_radio.js
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const DART = path.join(ROOT, 'lib', 'data', 'radio_live_stations_data.dart');
const DATA = path.join(ROOT, 'admin_dashboard', 'data.json');

const src = fs.readFileSync(DART, 'utf8');
const db = JSON.parse(fs.readFileSync(DATA, 'utf8'));

function readString(s, i, quote) {
  let out = '';
  i += 1;
  while (i < s.length) {
    const c = s[i];
    if (c === '\\') { out += s[i + 1]; i += 2; continue; }
    if (c === quote) { i += 1; break; }
    out += c;
    i += 1;
  }
  return { value: out, index: i };
}

const stations = [];
const head = src.indexOf('builtInLiveStations');
if (head === -1) {
  console.error('builtInLiveStations not found in', DART);
  process.exit(1);
}
// Scan consecutive ( ... ) records starting from the header until '];'
let i = src.indexOf('(', head);
while (i !== -1 && i < src.indexOf('];', head)) {
  const start = i;
  let depth = 1;
  let k = start + 1;
  while (k < src.length && depth > 0) {
    const c = src[k];
    if (c === "'" || c === '"') { k = readString(src, k, c).index; continue; }
    if (c === '(') depth += 1;
    else if (c === ')') depth -= 1;
    k += 1;
  }
  if (depth !== 0) { console.error('Unbalanced parentheses'); process.exit(1); }
  const block = src.slice(start + 1, k - 1);
  const st = {};
  let cur = '';
  let p = 0;
  for (let j = 0; j < block.length; j++) {
    const c = block[j];
    if (c === "'" || c === '"') { const r = readString(block, j, c); cur += block.slice(j, r.index); j = r.index - 1; continue; }
    if (c === '(') p += 1;
    else if (c === ')') p -= 1;
    if (c === ',' && p === 0) { cur = cur.trim(); if (cur) { const idx = cur.indexOf(':'); if (idx !== -1) st[cur.slice(0, idx).trim()] = cur.slice(idx + 1).trim().replace(/^['"]|['"]$/g, ''); } cur = ''; continue; }
    cur += c;
  }
  cur = cur.trim();
  if (cur) { const idx = cur.indexOf(':'); if (idx !== -1) st[cur.slice(0, idx).trim()] = cur.slice(idx + 1).trim().replace(/^['"]|['"]$/g, ''); }

  if (st.id && st.name && st.url) {
    st.isActive = st.isActive !== false && st.isActive !== 'false';
    stations.push(st);
  }
  i = src.indexOf('(', k);
}

if (stations.length === 0) {
  console.error('No stations parsed from', DART);
  process.exit(1);
}

const now = new Date().toISOString();
const existing = new Map((db.radio || []).map((r) => [r.id, r]));
const merged = stations.map((st) => {
  const prev = existing.get(st.id) || {};
  return {
    id: st.id,
    name: st.name,
    url: st.url,
    category: st.category || 'live',
    isActive: st.isActive !== false,
    createdAt: prev.createdAt || now,
    updatedAt: prev.updatedAt || now,
  };
});

// Keep dashboard-only stations that are not part of the built-ins.
const extra = (db.radio || []).filter((r) => !stations.some((s) => s.id === r.id));
db.radio = merged.concat(extra);

fs.writeFileSync(DATA, JSON.stringify(db, null, 2), 'utf8');
console.log(`Synced ${merged.length} built-in radio stations + ${extra.length} extra into data.json`);