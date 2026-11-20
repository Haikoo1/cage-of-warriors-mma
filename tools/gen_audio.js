// Gera efeitos sonoros por síntese (sem assets de terceiros): assets/audio/sfx/*.wav. Uso: node tools/gen_audio.js
// Mono, 16 bits, 44,1 kHz. Ruído com semente fixa para ser reproduzível.
const fs = require('fs');
const RATE = 44100;
let seed = 12345;
const rand = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff * 2 - 1; };

function wav(name, samples) {
  const data = Buffer.alloc(samples.length * 2);
  for (let i = 0; i < samples.length; i++) data.writeInt16LE(Math.round(Math.max(-1, Math.min(1, samples[i])) * 32000), i * 2);
  const h = Buffer.alloc(44);
  h.write('RIFF', 0); h.writeUInt32LE(36 + data.length, 4); h.write('WAVE', 8); h.write('fmt ', 12);
  h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22); h.writeUInt32LE(RATE, 24);
  h.writeUInt32LE(RATE * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34); h.write('data', 36); h.writeUInt32LE(data.length, 40);
  fs.mkdirSync('assets/audio/sfx', { recursive: true });
  fs.writeFileSync(`assets/audio/sfx/${name}.wav`, Buffer.concat([h, data]));
}
const len = (s) => Math.floor(s * RATE);
// Filtro passa-baixa de 1 polo
function lowpass(x, cutoff) {
  const a = Math.exp(-2 * Math.PI * cutoff / RATE); let y = 0;
  return x.map((v) => (y = (1 - a) * v + a * y));
}
function thump(freq, dur, noiseAmt, noiseCut, decay) {
  const n = len(dur); const noise = lowpass(Array.from({ length: n }, rand), noiseCut);
  return Array.from({ length: n }, (_, i) => {
    const t = i / RATE; const env = Math.exp(-t * decay);
    const f = freq * (1 + 1.5 * Math.exp(-t * 40)); // queda de afinação: "soco"
    return env * (0.9 * Math.sin(2 * Math.PI * f * t) + noiseAmt * noise[i] * Math.exp(-t * decay * 2.5));
  });
}
wav('hit_light', thump(140, 0.16, 1.4, 2500, 28));
wav('hit_heavy', thump(78, 0.32, 1.8, 1800, 14));
wav('block', thump(110, 0.14, 0.9, 700, 34));
wav('body_fall', thump(52, 0.5, 1.6, 900, 8));
// Golpe no ar: ruído filtrado com envelope de sino
{
  const n = len(0.22); const noise = Array.from({ length: n }, rand); let y = 0;
  wav('whoosh', noise.map((v, i) => { const t = i / n; const cut = 600 + 2600 * Math.sin(Math.PI * t); const a = Math.exp(-2 * Math.PI * cut / RATE); y = (1 - a) * v + a * y; return y * Math.sin(Math.PI * t) * 1.6; }));
}
// Sino do round: parciais inarmônicos, 3 toques
{
  const n = len(2.4); const out = new Array(n).fill(0);
  for (const start of [0, 0.32, 0.64]) {
    const s0 = len(start);
    for (let i = s0; i < n; i++) {
      const t = (i - s0) / RATE; const env = Math.exp(-t * 2.2) * 0.33;
      out[i] += env * (Math.sin(2 * Math.PI * 1046 * t) + 0.6 * Math.sin(2 * Math.PI * 2889 * t) + 0.35 * Math.sin(2 * Math.PI * 5270 * t));
    }
  }
  wav('bell', out);
}
// Público: ruído marrom com modulação lenta; laço sem emenda por crossfade
{
  const n = len(8); let b = 0; const raw = Array.from({ length: n + len(1) }, () => (b = 0.985 * b + 0.06 * rand()));
  const mod = (i) => 0.75 + 0.25 * Math.sin(2 * Math.PI * i / n * 3) * Math.sin(2 * Math.PI * i / n * 7 + 1);
  const lp = lowpass(raw.map((v, i) => v * mod(i % n)), 1200);
  const fade = len(1); const out = lp.slice(0, n);
  for (let i = 0; i < fade; i++) { const w = i / fade; out[i] = out[i] * w + lp[n + i] * (1 - w); }
  wav('crowd_loop', out.map((v) => v * 2.2));
}
// Vibração do público (KD, finalização, fim de luta)
{
  const n = len(2.2); let b = 0;
  const raw = Array.from({ length: n }, () => (b = 0.97 * b + 0.1 * rand()));
  const lp = lowpass(raw, 2200);
  wav('crowd_roar', lp.map((v, i) => { const t = i / n; return v * 2.6 * Math.min(1, t * 6) * Math.exp(-t * 1.6); }));
}
// Clique de menu
wav('ui_click', Array.from({ length: len(0.035) }, (_, i) => Math.sin(2 * Math.PI * 1900 * i / RATE) * Math.exp(-i / RATE * 120) * 0.5));
console.log('áudio gerado em assets/audio/sfx');
