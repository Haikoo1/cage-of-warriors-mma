// Gera data/grappling/*.tres (técnicas de grappling da E-04). Uso: node tools/gen_grappling_data.js
// Fonte de design: COMBAT_DESIGN §4 (R-009, R-010, R-031). Todos os números são [PROV].
const fs = require('fs');
const DIR = { NONE: 0, FORWARD: 1, BACK: 2, UP: 3, DOWN: 4 };
const WO = 'wrestling_ofensivo', WD = 'wrestling_defensivo', CS = 'controle_solo', JJ = 'jiu_jitsu', DF = 'defesa_finalizacao', FO = 'forca';
// [id, from, role, dir, to, result_top, startup, pressure, resistance, defense_dir, stamina, extra]
const T = [
  ['enter_clinch', 'EP', 'any', 'NONE', 'CL', 'none', 8, WO, WD, 'BACK', 2, { max_range_m: 0.9 }],
  ['double_leg', 'EP', 'any', 'DOWN', 'SG', 'attacker', 20, WO, WD, 'DOWN', 5, { max_range_m: 1.3, counter_state: 'SC', counter_top: 'defender' }],
  ['single_leg', 'EP', 'any', 'UP', 'SG', 'attacker', 15, WO, WD, 'DOWN', 4, { max_range_m: 1.2, counter_state: 'EP', counter_top: 'none' }],
  ['pummel', 'CL', 'any', 'UP', 'CL', 'none', 10, WO, WO, 'UP', 2, { grants_advantage: true }],
  ['push_to_cage', 'CL', 'any', 'FORWARD', 'CG', 'attacker', 14, FO, WD, 'BACK', 3, { requires_advantage: true }],
  ['clinch_trip', 'CL', 'any', 'DOWN', 'SG', 'attacker', 14, WO, WD, 'DOWN', 4, { requires_advantage: true }],
  ['break_clinch', 'CL', 'any', 'BACK', 'EP', 'none', 10, WD, WO, 'FORWARD', 2, {}],
  ['cage_takedown', 'CG', 'top', 'DOWN', 'SG', 'attacker', 18, WO, WD, 'DOWN', 4, {}],
  ['cage_break', 'CG', 'bottom', 'BACK', 'EP', 'none', 12, WD, WO, 'FORWARD', 3, {}],
  ['cage_reverse', 'CG', 'bottom', 'UP', 'CG', 'attacker', 14, WO, FO, 'UP', 3, {}],
  ['guard_pass', 'SG', 'top', 'FORWARD', 'SM', 'keep', 16, CS, JJ, 'FORWARD', 4, {}],
  ['half_pass', 'SM', 'top', 'FORWARD', 'SL', 'keep', 16, CS, JJ, 'FORWARD', 4, {}],
  ['half_recover_guard', 'SM', 'bottom', 'UP', 'SG', 'keep', 14, JJ, CS, 'UP', 3, {}],
  ['half_sweep', 'SM', 'bottom', 'DOWN', 'SG', 'attacker', 18, JJ, CS, 'DOWN', 4, {}],
  ['half_stand', 'SM', 'bottom', 'BACK', 'SR', 'keep', 14, WD, CS, 'BACK', 3, {}],
  ['kimura', 'SM', 'top', 'DOWN', '', 'keep', 20, JJ, DF, 'DOWN', 5, { kind: 'submission', squeeze_rate: 16.0, escapes_needed: 3, escape_state: 'SM', escape_top: 'attacker' }],
  ['triangle', 'SG', 'bottom', 'FORWARD', '', 'keep', 20, JJ, DF, 'FORWARD', 5, { kind: 'submission', squeeze_rate: 17.0, escapes_needed: 3, escape_state: 'SG', escape_top: 'defender' }],
  ['armbar', 'SG', 'bottom', 'DOWN', '', 'keep', 22, JJ, DF, 'DOWN', 5, { kind: 'submission', squeeze_rate: 19.0, escapes_needed: 3, escape_state: 'SG', escape_top: 'defender' }],
  ['arm_triangle', 'SL', 'top', 'DOWN', '', 'keep', 22, JJ, DF, 'DOWN', 5, { kind: 'submission', squeeze_rate: 16.0, escapes_needed: 3, escape_state: 'SM', escape_top: 'attacker' }],
  ['guillotine', 'CG', 'bottom', 'DOWN', '', 'keep', 18, JJ, DF, 'DOWN', 5, { kind: 'submission', squeeze_rate: 18.0, escapes_needed: 3, escape_state: 'CG', escape_top: 'defender' }],
  ['guard_sweep', 'SG', 'bottom', 'UP', 'SG', 'attacker', 16, JJ, CS, 'UP', 4, {}],
  ['guard_stand', 'SG', 'bottom', 'BACK', 'SR', 'keep', 14, WD, CS, 'BACK', 3, {}],
  ['mount', 'SL', 'top', 'UP', 'SO', 'keep', 16, CS, JJ, 'UP', 4, {}],
  ['recover_guard', 'SL', 'bottom', 'FORWARD', 'SM', 'keep', 14, JJ, CS, 'FORWARD', 4, {}],
  ['turn_to_stand', 'SL', 'bottom', 'BACK', 'SC', 'keep', 12, WD, CS, 'BACK', 3, {}],
  ['take_back', 'SO', 'top', 'BACK', 'SC', 'keep', 14, CS, JJ, 'BACK', 3, {}],
  ['mount_escape', 'SO', 'bottom', 'FORWARD', 'SM', 'keep', 18, JJ, CS, 'FORWARD', 5, {}],
  ['give_back', 'SO', 'bottom', 'BACK', 'SC', 'keep', 10, WD, CS, 'BACK', 2, {}],
  ['back_escape', 'SC', 'bottom', 'FORWARD', 'SG', 'attacker', 18, JJ, CS, 'FORWARD', 5, {}],
  ['rear_naked_choke', 'SC', 'top', 'DOWN', '', 'keep', 20, JJ, DF, 'DOWN', 5,
    { kind: 'submission', squeeze_rate: 18.0, escapes_needed: 3, escape_state: 'SG', escape_top: 'defender' }],
  ['stand_up', 'SR', 'bottom', 'UP', 'EP', 'none', 16, WD, WO, 'UP', 3, {}],
  ['drag_down', 'SR', 'top', 'DOWN', 'SG', 'keep', 14, WO, WD, 'DOWN', 3, {}],
];
const out = 'data/grappling';
fs.mkdirSync(out, { recursive: true });
for (const f of fs.readdirSync(out)) if (f.endsWith('.tres')) fs.unlinkSync(`${out}/${f}`);
const sn = (v) => `&"${v}"`;
for (const [id, from, role, dir, to, top, startup, pa, ra, dd, st, extra] of T) {
  const p = {
    id: sn(id), kind: sn(extra.kind || 'transition'), from_state: sn(from), role: sn(role), direction: DIR[dir],
    to_state: sn(to), result_top: sn(top), startup_frames: startup, pressure_attr: sn(pa), resistance_attr: sn(ra),
    defense_direction: DIR[dd], stamina_cost: st.toFixed(1),
  };
  if (extra.max_range_m) p.max_range_m = extra.max_range_m;
  if (extra.counter_state) { p.counter_state = sn(extra.counter_state); p.counter_top = sn(extra.counter_top); }
  if (extra.requires_advantage) p.requires_advantage = 'true';
  if (extra.grants_advantage) p.grants_advantage = 'true';
  if (extra.kind === 'submission') {
    p.squeeze_rate = extra.squeeze_rate.toFixed(1); p.escapes_needed = extra.escapes_needed;
    p.escape_state = sn(extra.escape_state); p.escape_top = sn(extra.escape_top);
  }
  let s = '[gd_resource type="Resource" script_class="GrappleTechniqueDef" load_steps=2 format=3]\n\n' +
    '[ext_resource type="Script" path="res://src/definitions/grapple_technique_def.gd" id="1"]\n\n[resource]\nscript = ExtResource("1")\n';
  for (const [k, v] of Object.entries(p)) s += `${k} = ${v}\n`;
  fs.writeFileSync(`${out}/${id}.tres`, s);
}
console.log(`${T.length} técnicas geradas em ${out}`);
