// 使い方: node render.mjs stills 2,9,15  /  node render.mjs video
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright');
import { spawn } from 'node:child_process';
import { writeFileSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const dir = path.dirname(fileURLToPath(import.meta.url));
const mode = process.argv[2] || 'stills';
const FPS = 30;
mkdirSync(path.join(dir, 'out'), { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
page.on('pageerror', e => console.error('pageerror', e));
await page.goto('file://' + path.join(dir, 'emaki.html'));
await page.evaluate(() => window.setup());
const { SFX, DUR } = await page.evaluate(() => ({ SFX: window.SFX, DUR: window.DUR }));
writeFileSync(path.join(dir, 'out', 'sfx.json'), JSON.stringify({ DUR, SFX }));

if (mode === 'stills') {
  for (const t of (process.argv[3] || '2').split(',').map(Number)) {
    await page.evaluate(t => window.render(t), t);
    await page.screenshot({ path: path.join(dir, 'out', `still_${t}.png`) });
  }
} else {
  const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'mjpeg', '-i', '-',
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-preset', 'medium', path.join(dir, 'out', 'video_noaudio.mp4')], { stdio: ['pipe', 'inherit', 'inherit'] });
  const N = Math.round(DUR * FPS);
  for (let f = 0; f < N; f++) {
    await page.evaluate(t => window.render(t), f / FPS);
    const buf = await page.screenshot({ type: 'jpeg', quality: 93 });
    if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    if (f % 150 === 0) console.log(`frame ${f}/${N}`);
  }
  ff.stdin.end();
  await new Promise(r => ff.on('close', r));
}
await browser.close();
