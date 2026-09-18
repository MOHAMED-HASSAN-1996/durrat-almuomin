const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const AUDIO_DIR = path.join(__dirname, 'assets/audio');
const BITRATE = '96k';
const CHANNELS = 1;
const SAMPLE_RATE = 22050;

function findFiles(dir, ext) {
  const results = [];
  const list = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of list) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...findFiles(full, ext));
    } else if (entry.name.toLowerCase().endsWith(ext)) {
      results.push(full);
    }
  }
  return results;
}

const mp3Files = findFiles(AUDIO_DIR, '.mp3');
let totalBefore = 0, totalAfter = 0, ok = 0, fail = 0;

function compressOne(filePath) {
  return new Promise((resolve) => {
    try {
      const before = fs.statSync(filePath).size;
      totalBefore += before;
      const tmpPath = filePath + '.tmp';
      const cmd = `ffmpeg -i "${filePath}" -b:a ${BITRATE} -ac ${CHANNELS} -ar ${SAMPLE_RATE} -y "${tmpPath}"`;
      exec(cmd, (error, stdout, stderr) => {
        if (error || !fs.existsSync(tmpPath)) {
          fail++;
          console.log(`FAIL ${path.relative(AUDIO_DIR, filePath)}`);
          resolve();
          return;
        }
        const after = fs.statSync(tmpPath).size;
        fs.renameSync(tmpPath, filePath);
        totalAfter += after;
        ok++;
        console.log(`OK  ${path.relative(AUDIO_DIR, filePath).padEnd(40)} ${(before/1024).toFixed(1).padStart(7)}KB → ${(after/1024).toFixed(1).padStart(7)}KB`);
        resolve();
      });
    } catch (e) {
      fail++;
      console.log(`FAIL ${path.basename(filePath)}: ${e.message}`);
      resolve();
    }
  });
}

async function run() {
  console.log(`بدء ضغط ${mp3Files.length} ملف MP3...`);
  const promises = mp3Files.map(compressOne);
  await Promise.all(promises);
  console.log(`\nتم ضغط: ${ok}  فشل: ${fail}`);
  console.log(`قبل الكلي: ${(totalBefore/1024/1024).toFixed(2)} MB  بعد الكلي: ${(totalAfter/1024/1024).toFixed(2)} MB`);
}

run().catch(console.error);
