// Gera ícones em pixel art (32x32) para HUD e telas, estilo RPG. Uso: node tools/gen_icons.js
// Desenhados por código (sem assets de terceiros): primitivas + contorno automático + escrita PNG com zlib.
const fs = require('fs');
const zlib = require('zlib');
const S = 32;

function canvas() { return Array.from({ length: S * S }, () => null); }
function px(c, x, y, col) { x = Math.round(x); y = Math.round(y); if (x >= 0 && y >= 0 && x < S && y < S) c[y * S + x] = col; }
function rect(c, x, y, w, h, col) { for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) px(c, x + i, y + j, col); }
function ellipse(c, cx, cy, rx, ry, col) { for (let y = -ry; y <= ry; y++) for (let x = -rx; x <= rx; x++) if ((x * x) / (rx * rx) + (y * y) / (ry * ry) <= 1.0) px(c, cx + x, cy + y, col); }
function line(c, x0, y0, x1, y1, col, w = 1) { const n = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0)) * 2 + 1; for (let k = 0; k <= n; k++) { const t = k / n; rect(c, Math.round(x0 + (x1 - x0) * t - (w - 1) / 2), Math.round(y0 + (y1 - y0) * t - (w - 1) / 2), w, w, col); } }
function poly(c, pts, col) { // preenchimento por scanline
  for (let y = 0; y < S; y++) { const xs = []; for (let i = 0; i < pts.length; i++) { const [x0, y0] = pts[i], [x1, y1] = pts[(i + 1) % pts.length]; if ((y0 <= y && y1 > y) || (y1 <= y && y0 > y)) xs.push(x0 + (y - y0) / (y1 - y0) * (x1 - x0)); } xs.sort((a, b) => a - b); for (let i = 0; i + 1 < xs.length; i += 2) for (let x = Math.ceil(xs[i]); x <= Math.floor(xs[i + 1]); x++) px(c, x, y, col); }
}
function outline(c, col = [22, 14, 18]) { const o = c.slice(); for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) { if (c[y * S + x]) continue; for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const xx = x + dx, yy = y + dy; if (xx >= 0 && yy >= 0 && xx < S && yy < S && c[yy * S + xx]) { o[y * S + x] = col; break; } } } return o; }
function png(name, c) {
  const raw = Buffer.alloc((S * 4 + 1) * S);
  for (let y = 0; y < S; y++) { raw[y * (S * 4 + 1)] = 0; for (let x = 0; x < S; x++) { const p = c[y * S + x]; const o = y * (S * 4 + 1) + 1 + x * 4; if (p) { raw[o] = p[0]; raw[o + 1] = p[1]; raw[o + 2] = p[2]; raw[o + 3] = 255; } } }
  const crcTable = Array.from({ length: 256 }, (_, n) => { let c2 = n; for (let k = 0; k < 8; k++) c2 = c2 & 1 ? 0xedb88320 ^ (c2 >>> 1) : c2 >>> 1; return c2 >>> 0; });
  const crc = (buf) => { let c2 = 0xffffffff; for (const b of buf) c2 = crcTable[(c2 ^ b) & 0xff] ^ (c2 >>> 8); return (c2 ^ 0xffffffff) >>> 0; };
  const chunk = (type, data) => { const len = Buffer.alloc(4); len.writeUInt32BE(data.length); const td = Buffer.concat([Buffer.from(type), data]); const cr = Buffer.alloc(4); cr.writeUInt32BE(crc(td)); return Buffer.concat([len, td, cr]); };
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(S, 0); ihdr.writeUInt32BE(S, 4); ihdr[8] = 8; ihdr[9] = 6;
  fs.mkdirSync('assets/ui/icons', { recursive: true });
  fs.writeFileSync(`assets/ui/icons/${name}.png`, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}
const GOLD = [[120, 80, 20], [200, 150, 40], [250, 210, 90], [255, 245, 190]];
const RED = [[110, 20, 24], [180, 36, 40], [230, 70, 64]];
const icons = {};

icons.belt = (c) => { // cinturão de campeão
  rect(c, 1, 12, 30, 9, [30, 24, 26]); rect(c, 1, 13, 30, 1, [60, 50, 54]);
  for (const x of [3, 25]) { rect(c, x, 11, 4, 11, GOLD[1]); rect(c, x, 11, 4, 1, GOLD[3]); }
  ellipse(c, 16, 16, 9, 8, GOLD[0]); ellipse(c, 16, 16, 8, 7, GOLD[1]); ellipse(c, 15, 15, 6, 5, GOLD[2]); ellipse(c, 14, 13, 2, 2, GOLD[3]);
  ellipse(c, 16, 16, 3, 3, RED[1]); px(c, 15, 15, RED[2]); for (const [x, y] of [[16, 9], [16, 23], [9, 16], [23, 16]]) px(c, x, y, GOLD[3]);
};
icons.glove = (c) => { ellipse(c, 15, 13, 9, 9, RED[1]); ellipse(c, 13, 11, 5, 5, RED[2]); ellipse(c, 23, 16, 4, 5, RED[1]); rect(c, 9, 20, 12, 7, [235, 235, 240]); rect(c, 9, 22, 12, 1, [190, 190, 200]); px(c, 11, 8, [255, 160, 150]); };
icons.bolt = (c) => { poly(c, [[18, 2], [7, 18], [15, 18], [12, 30], [25, 12], [17, 12], [21, 2]], [250, 220, 70]); poly(c, [[18, 4], [11, 15], [16, 15]], [255, 250, 190]); };
icons.dumbbell = (c) => { rect(c, 8, 14, 16, 4, [150, 150, 160]); rect(c, 3, 9, 4, 14, [70, 70, 80]); rect(c, 7, 11, 3, 10, [90, 90, 100]); rect(c, 25, 9, 4, 14, [70, 70, 80]); rect(c, 22, 11, 3, 10, [90, 90, 100]); rect(c, 8, 14, 16, 1, [200, 200, 210]); };
icons.heart = (c) => { ellipse(c, 11, 11, 6, 6, RED[1]); ellipse(c, 21, 11, 6, 6, RED[1]); poly(c, [[5, 13], [27, 13], [16, 27]], RED[1]); ellipse(c, 10, 9, 2, 2, RED[2]); };
icons.shield = (c) => { poly(c, [[5, 5], [27, 5], [27, 15], [16, 29], [5, 15]], [70, 110, 190]); poly(c, [[8, 8], [24, 8], [24, 15], [16, 25], [8, 15]], [110, 160, 230]); rect(c, 15, 8, 2, 16, [220, 230, 250]); rect(c, 8, 13, 16, 2, [220, 230, 250]); };
icons.link = (c) => { // grappling: elos entrelaçados
  for (const [cx, cy] of [[11, 16], [21, 16]]) { ellipse(c, cx, cy, 8, 6, [170, 170, 180]); ellipse(c, cx, cy, 5, 3, null); } rect(c, 12, 13, 3, 6, [210, 210, 220]);
};
icons.brain = (c) => { ellipse(c, 16, 15, 11, 9, [230, 140, 170]); ellipse(c, 12, 13, 5, 4, [245, 175, 195]); line(c, 16, 7, 16, 24, [180, 90, 120]); line(c, 9, 15, 13, 18, [180, 90, 120]); line(c, 20, 11, 24, 14, [180, 90, 120]); rect(c, 14, 23, 5, 5, [200, 120, 150]); };
icons.coin = (c) => { ellipse(c, 16, 16, 12, 12, GOLD[0]); ellipse(c, 16, 16, 11, 11, GOLD[1]); ellipse(c, 15, 15, 8, 8, GOLD[2]); rect(c, 15, 9, 2, 14, GOLD[0]); rect(c, 12, 11, 7, 2, GOLD[0]); rect(c, 12, 15, 7, 2, GOLD[0]); rect(c, 12, 19, 7, 2, GOLD[0]); ellipse(c, 11, 10, 2, 2, GOLD[3]); };
icons.star = (c) => { const pts = []; for (let k = 0; k < 10; k++) { const a = -Math.PI / 2 + k * Math.PI / 5; const r = k % 2 ? 5.5 : 13; pts.push([16 + Math.cos(a) * r, 17 + Math.sin(a) * r]); } poly(c, pts, GOLD[2]); ellipse(c, 14, 13, 2, 2, GOLD[3]); };
icons.trophy = (c) => { poly(c, [[8, 4], [24, 4], [22, 16], [10, 16]], GOLD[1]); rect(c, 10, 5, 3, 9, GOLD[3]); rect(c, 14, 16, 4, 6, GOLD[0]); rect(c, 9, 22, 14, 4, GOLD[1]); rect(c, 7, 26, 18, 3, [70, 50, 30]); for (const x of [4, 24]) rect(c, x, 6, 4, 6, GOLD[0]); };
icons.injury = (c) => { rect(c, 12, 4, 8, 24, [230, 60, 60]); rect(c, 4, 12, 24, 8, [230, 60, 60]); rect(c, 13, 5, 2, 22, [255, 140, 140]); };
icons.calendar = (c) => { rect(c, 4, 7, 24, 21, [235, 235, 240]); rect(c, 4, 7, 24, 6, RED[1]); for (const x of [9, 21]) rect(c, x, 4, 2, 6, [80, 80, 90]); for (let j = 0; j < 3; j++) for (let i = 0; i < 4; i++) rect(c, 7 + i * 5, 15 + j * 4, 3, 2, [150, 150, 160]); };
icons.kick = (c) => { poly(c, [[6, 6], [12, 6], [16, 18], [27, 21], [27, 27], [12, 27]], [210, 160, 120]); rect(c, 12, 22, 15, 5, [240, 240, 245]); };
icons.fist = (c) => { rect(c, 8, 9, 16, 14, [215, 165, 125]); for (let i = 0; i < 4; i++) rect(c, 8 + i * 4, 8, 3, 4, [235, 190, 150]); rect(c, 4, 15, 6, 6, [215, 165, 125]); rect(c, 8, 23, 14, 6, [235, 235, 245]); };
icons.target = (c) => { ellipse(c, 16, 16, 13, 13, RED[1]); ellipse(c, 16, 16, 10, 10, [240, 240, 240]); ellipse(c, 16, 16, 7, 7, RED[1]); ellipse(c, 16, 16, 3, 3, [240, 240, 240]); };
icons.mask = (c) => { ellipse(c, 16, 16, 11, 12, [215, 165, 125]); ellipse(c, 12, 14, 2, 2, [40, 30, 30]); ellipse(c, 20, 14, 2, 2, [40, 30, 30]); rect(c, 12, 21, 8, 2, [140, 70, 60]); rect(c, 6, 4, 20, 6, [50, 40, 35]); };

for (const [name, draw] of Object.entries(icons)) { const c = canvas(); draw(c); png(name, outline(c)); }
console.log(`${Object.keys(icons).length} ícones gerados em assets/ui/icons`);
