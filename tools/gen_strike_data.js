// Gera data/strikes/*.tres (catálogo de golpes em pé, COMBAT_DESIGN §3.2). Uso: node tools/gen_strike_data.js
// Mapeamento de entrada: membro + variante (STRAIGHT = tecla sozinha, CURVED = segurando E, BODY = segurando Q).
// Todos os números são [PROV] (calibrados nos lotes IA x IA da E-05).
const fs = require('fs');
const LIMB = { LEAD_HAND: 0, REAR_HAND: 1, LEAD_LEG: 2, REAR_LEG: 3 };
const VAR = { STRAIGHT: 0, CURVED: 1, BODY: 2 };
// id, membro, variante, alvos, alcance, tolerância Z, preparação, execução, recuperação, encadeamento, potência, fôlego, atributo
const S = [
  ['jab', 'LEAD_HAND', 'STRAIGHT', ['head', 'body'], 0.85, 0.3, 6, 3, 10, 8, 8.0, 1.5, 'boxe'],
  ['cross', 'REAR_HAND', 'STRAIGHT', ['head', 'body'], 0.9, 0.3, 9, 3, 14, 8, 16.0, 3.0, 'boxe'],
  ['lead_hook', 'LEAD_HAND', 'CURVED', ['head', 'body'], 0.6, 0.6, 11, 4, 16, 8, 18.0, 3.0, 'boxe'],
  ['uppercut', 'REAR_HAND', 'CURVED', ['head'], 0.5, 0.45, 10, 4, 16, 8, 19.0, 3.0, 'boxe'],
  ['teep', 'LEAD_LEG', 'STRAIGHT', ['body'], 1.15, 0.3, 11, 4, 16, 6, 9.0, 3.0, 'kickboxing'],
  ['calf_kick', 'LEAD_LEG', 'CURVED', ['legs'], 0.95, 0.5, 9, 3, 13, 6, 10.0, 2.5, 'kickboxing'],
  ['low_kick', 'REAR_LEG', 'STRAIGHT', ['legs'], 1.1, 0.6, 13, 4, 18, 6, 14.0, 3.5, 'kickboxing'],
  ['body_kick', 'REAR_LEG', 'BODY', ['body'], 1.15, 0.6, 16, 4, 22, 4, 22.0, 5.0, 'kickboxing'],
  ['high_kick', 'REAR_LEG', 'CURVED', ['head'], 1.15, 0.6, 20, 4, 26, 2, 30.0, 6.5, 'kickboxing'],
];
const dir = 'data/strikes';
fs.mkdirSync(dir, { recursive: true });
for (const f of fs.readdirSync(dir)) if (f.endsWith('.tres')) fs.unlinkSync(`${dir}/${f}`);
for (const [id, limb, variant, targets, reach, tol, su, ac, re, ch, pow, st, attr] of S) {
  const p = {
    id: `&"${id}"`, limb: LIMB[limb], variant: VAR[variant], targets: `PackedStringArray(${targets.map((t) => `"${t}"`).join(', ')})`,
    base_reach_m: reach, depth_tolerance_m: tol, startup_frames: su, active_frames: ac, recovery_frames: re,
    chain_window_frames: ch, feint_cutoff: 0.6, power: pow.toFixed(1), stamina_cost: st.toFixed(1), technique_attribute: `&"${attr}"`,
  };
  let s = '[gd_resource type="Resource" script_class="StrikeDef" load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://src/definitions/strike_def.gd" id="1"]\n\n[resource]\nscript = ExtResource("1")\n';
  for (const [k, v] of Object.entries(p)) s += `${k} = ${v}\n`;
  fs.writeFileSync(`${dir}/${id}.tres`, s);
}
console.log(`${S.length} golpes gerados`);
