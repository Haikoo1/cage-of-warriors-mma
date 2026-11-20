// Gera os dados da carreira (E-07/E-08). Uso: node tools/gen_career_data.js
// Fontes: CHARACTER_DESIGN §6.2 (categorias, limites de referência a validar — R-020), CAREER_DESIGN §2–§10.
// Tudo [PROV]. Nomes de organizações são fictícios (D-010).
const fs = require('fs');

function val(v) {
  if (typeof v === 'string') return v.startsWith('&') ? `&"${v.slice(1)}"` : JSON.stringify(v);
  if (Array.isArray(v)) return `PackedStringArray(${v.map((x) => JSON.stringify(x)).join(', ')})`;
  if (typeof v === 'object') return '{\n' + Object.entries(v).map(([k, x]) => `&"${k}": ${val(x)}`).join(',\n') + '\n}';
  if (typeof v === 'number' && !Number.isInteger(v)) return String(v);
  return String(v);
}
function write(dir, id, cls, script, props) {
  fs.mkdirSync(dir, { recursive: true });
  let s = `[gd_resource type="Resource" script_class="${cls}" load_steps=2 format=3]\n\n[ext_resource type="Script" path="${script}" id="1"]\n\n[resource]\nscript = ExtResource("1")\n`;
  for (const [k, v] of Object.entries(props)) s += `${k} = ${val(v)}\n`;
  fs.writeFileSync(`${dir}/${id}.tres`, s);
}
function clean(dir) { if (fs.existsSync(dir)) for (const f of fs.readdirSync(dir)) if (f.endsWith('.tres')) fs.unlinkSync(`${dir}/${f}`); }

// --- 12 categorias (8 M + 4 F), D-007
const WC = [
  ['m_flyweight', 0, 'Peso-mosca', 125, ['m_light']], ['m_bantamweight', 0, 'Peso-galo', 135, ['m_light']],
  ['m_featherweight', 0, 'Peso-pena', 145, ['m_light', 'm_medium']], ['m_lightweight', 0, 'Peso-leve', 155, ['m_medium']],
  ['m_welterweight', 0, 'Peso meio-médio', 170, ['m_medium']], ['m_middleweight', 0, 'Peso-médio', 185, ['m_medium', 'm_heavy']],
  ['m_light_heavyweight', 0, 'Peso meio-pesado', 205, ['m_heavy']], ['m_heavyweight', 0, 'Peso-pesado', 265, ['m_heavy', 'm_superheavy']],
  ['f_strawweight', 1, 'Peso-palha', 115, ['f_light']], ['f_flyweight', 1, 'Peso-mosca', 125, ['f_light', 'f_medium']],
  ['f_bantamweight', 1, 'Peso-galo', 135, ['f_medium']], ['f_featherweight', 1, 'Peso-pena', 145, ['f_medium']],
];
clean('data/weight_classes');
for (const [id, div, name, lb, bio] of WC) {
  const heavy = lb >= 205;
  write('data/weight_classes', id, 'WeightClassDef', 'res://src/definitions/weight_class_def.gd', {
    id: '&' + id, division: div, display_key: name, limit_lb: lb + 0.0, tolerance_lb: 1.0, allowed_biotypes: bio,
    damage_mult: heavy ? 1.15 : (lb <= 125 ? 0.9 : 1.0), move_cost_mult: heavy ? 1.15 : 1.0, move_speed_mult: heavy ? 0.92 : (lb <= 125 ? 1.06 : 1.0),
  });
}

// --- Atividades de treino (CAREER §4.1)
const A = [
  ['boxing', 'Técnico: Boxe', 'boxing', { boxe: 0.35, defesa_em_pe: 0.15 }, 6, 0.004],
  ['kickboxing', 'Técnico: Muay Thai', 'kickboxing', { kickboxing: 0.35, defesa_em_pe: 0.15 }, 6, 0.004],
  ['wrestling', 'Técnico: Wrestling', 'wrestling', { wrestling_ofensivo: 0.3, wrestling_defensivo: 0.3, controle_solo: 0.12 }, 8, 0.008],
  ['jiujitsu', 'Técnico: Jiu-jitsu', 'jiujitsu', { jiu_jitsu: 0.32, defesa_finalizacao: 0.28, controle_solo: 0.12 }, 6, 0.005],
  ['movement', 'Técnico: Movimentação', 'none', { mobilidade: 0.3 }, 4, 0.002],
  ['strength', 'Físico: Força', 'physical', { forca: 0.3, robustez: 0.08 }, 8, 0.007],
  ['conditioning', 'Físico: Condicionamento', 'physical', { condicionamento: 0.4 }, 8, 0.003],
  ['explosion', 'Físico: Explosão', 'physical', { velocidade: 0.22 }, 7, 0.006],
  ['sparring', 'Sparring', 'none', { qi_luta: 0.2, compostura: 0.12, boxe: 0.08, kickboxing: 0.08, wrestling_ofensivo: 0.08, jiu_jitsu: 0.08 }, 11, 0.015],
  ['tactics', 'Tático: Lições do treinador', 'none', { qi_luta: 0.18 }, 2, 0.0],
  ['study', 'Tático: Estudo do adversário', 'none', {}, 1, 0.0, 0, true],
  ['recovery', 'Recuperação (fisio)', 'none', {}, -7, 0.0],
  ['rest', 'Descanso', 'none', {}, -6, 0.0],
  ['side_job', 'Trabalho paralelo', 'none', {}, 2, 0.0, 120],
];
clean('data/training');
for (const [id, name, area, gains, load, risk, money = 0, fight = false] of A) {
  write('data/training', id, 'TrainingActivityDef', 'res://src/definitions/training_activity_def.gd', {
    id: '&' + id, display_name: name, area: '&' + area, gains, load: load + 0.0, injury_risk: risk + 0.0,
    money_per_block: money + 0.0, requires_fight: fight,
  });
}

// --- Academias (CAREER §4.4)
const G = [
  ['gym_garage', 'Academia do Bairro', { boxing: 1.0, kickboxing: 1.0, wrestling: 0.9, jiujitsu: 0.9, physical: 0.9 }, 1, 120, 0],
  ['gym_bjj', 'Equipe Faixa Preta (Jiu-jitsu)', { jiujitsu: 1.4, wrestling: 1.0, boxing: 0.9, kickboxing: 0.85, physical: 1.0 }, 2, 260, 0],
  ['gym_wrestling', 'Clube de Wrestling Norte', { wrestling: 1.4, physical: 1.15, jiujitsu: 0.95, boxing: 0.9, kickboxing: 0.85 }, 3, 300, 0],
  ['gym_muaythai', 'Camp Muay Thai Sul', { kickboxing: 1.4, boxing: 1.15, physical: 1.0, wrestling: 0.85, jiujitsu: 0.8 }, 2, 280, 0],
  ['gym_elite', 'Centro de Alto Rendimento', { boxing: 1.3, kickboxing: 1.3, wrestling: 1.3, jiujitsu: 1.3, physical: 1.3 }, 5, 1500, 40],
];
clean('data/gyms');
for (const [id, name, sp, st, cost, pop] of G) {
  const specialties = {}; for (const [k, v] of Object.entries(sp)) specialties[k] = v + 0.0;
  write('data/gyms', id, 'GymDef', 'res://src/definitions/gym_def.gd', {
    id: '&' + id, display_name: name, specialties, structure: st, monthly_cost: cost + 0.0, min_popularity: pop + 0.0,
  });
}

// --- Origens (CAREER §2.3)
const O = [
  ['origin_wrestler', 'Wrestler universitário', 'Quedas e cardio fortes, trocação crua.', { wrestling_ofensivo: 55, wrestling_defensivo: 55, controle_solo: 45, condicionamento: 50, forca: 45 }, 'arch_wrestler', 900, 'gym_wrestling'],
  ['origin_bjj', 'Competidor de jiu-jitsu', 'Perigoso no chão, precisa aprender a derrubar e trocar.', { jiu_jitsu: 58, defesa_finalizacao: 52, controle_solo: 45, mobilidade: 45 }, 'arch_wrestler', 900, 'gym_bjj'],
  ['origin_kickboxer', 'Kickboxer / Muay Thai', 'Trocação afiada, defesa de queda fraca.', { kickboxing: 58, boxe: 48, defesa_em_pe: 50, robustez: 45 }, 'arch_striker', 1500, 'gym_muaythai'],
  ['origin_mma', 'Atleta de academia de MMA', 'Sem pontos fortes, sem fraquezas graves.', { boxe: 42, kickboxing: 40, wrestling_ofensivo: 40, wrestling_defensivo: 42, jiu_jitsu: 40, qi_luta: 45 }, 'arch_striker', 1500, 'gym_garage'],
];
clean('data/origins');
for (const [id, name, desc, base, arch, money, gym] of O) {
  const b = {}; for (const [k, v] of Object.entries(base)) b[k] = v + 0.0;
  write('data/origins', id, 'OriginDef', 'res://src/definitions/origin_def.gd', {
    id: '&' + id, display_name: name, description: desc, base_attributes: b, default_attribute: 36.0,
    archetype: '&' + arch, starting_money: money + 0.0, starting_gym: '&' + gym,
  });
}

// --- Organizações fictícias (CAREER §7, R-021): nível 1..4
const ORG = [
  ['org_local', 'Circuito Arena Local', 1, 4, 2, 600, 600, 10, 42, 1, 0],
  ['org_lfc', 'Liga Fronteira (LFC)', 2, 4, 2, 3000, 3000, 9, 54, 4, 1000],
  ['org_pcc', 'Pan-Continental Combat (PCC)', 3, 3, 2, 10000, 10000, 8, 64, 4, 1080],
  ['org_gcl', 'Grand Cage League (GCL)', 4, 2, 2, 25000, 25000, 10, 74, 4, 1160],
];
clean('data/organizations');
for (const [id, name, tier, every, bouts, show, win, roster, mean, fights, minr] of ORG) {
  write('data/organizations', id, 'OrganizationDef', 'res://src/definitions/organization_def.gd', {
    id: '&' + id, display_name: name, tier, ruleset_id: '&rs_standard', event_interval_weeks: every, bouts_per_class: bouts,
    show_purse: show + 0.0, win_purse: win + 0.0, roster_per_class: roster, attribute_mean: mean + 0.0,
    contract_fights: fights, min_rating: minr + 0.0,
  });
}

// --- Balanceamento da carreira (padrões no script)
write('data/balance', 'career_balance', 'CareerBalanceDef', 'res://src/definitions/career_balance_def.gd', {});
console.log('dados da carreira gerados');
