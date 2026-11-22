// Aquarium economy sim (S0). Monte Carlo over real configs.
// Run from repo root:  node tools/aquarium-sim.js [--md]
// Reads Creatures/Rods/Fishing configs, assigns a passive rate per species inside the plan bands,
// then simulates profiles (beginner/regular/fast/unlucky/lucky + veteran) over 5/15/30 min and
// days 1/3/7/14. Offline income is OFF. Cycle time and win rates are ASSUMPTIONS until Codex
// publishes real measurements (PLANO-AQUARIO-CODEX); change PROFILES below when it does.
const fs = require("fs");
const read = (f) => fs.readFileSync(f, "utf8").replace(/\r\n/g, "\n");

// ---------- configs ----------
const csrc = read("src/shared/Config/Creatures.luau");
const creatures = [];
for (const b of csrc.split("\t{\n\t\tid = ").slice(1)) {
  const g = (k) => (b.match(new RegExp("\\t\\t" + k + ' = "?([^",\\n]+)')) || [])[1];
  const id = (b.match(/^"([^"]+)"/) || [])[1];
  if (!id) continue;
  creatures.push({
    id, rarity: g("rarity"), tier: +g("tier"), baseValue: +g("baseValue"),
    wMin: +g("weightMin"), wMax: +g("weightMax"), event: g("event"), season: g("season"),
  });
}
const order = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mystic"];
const rods = [];
for (const b of read("src/shared/Config/Rods.luau").split("\t{\n\t\tid = ").slice(1)) {
  const id = (b.match(/^"([^"]+)"/) || [])[1];
  const n = (k) => +(b.match(new RegExp(k + " = ([\\d.]+)")) || [])[1];
  if (id) rods.push({ id, price: n("price"), luck: n("luckBonus") });
}
const fsrc = read("src/shared/Config/Fishing.luau");
const wBlock = fsrc.slice(fsrc.indexOf("RARITY_WEIGHTS"), fsrc.indexOf("RARITY_COLORS"));
const W = {};
for (const r of order) W[r] = +((wBlock.match(new RegExp(r + " = ([\\d.]+)")) || [])[1] || 0);

// ---------- proposed passive rates (plan 3.2 bands) ----------
const BANDS = { Common: [0.15, 0.3], Uncommon: [0.35, 0.65], Rare: [0.7, 1.2], Epic: [1.3, 2.2], Legendary: [2.4, 4.0], Mystic: [4.2, 6.0] };
const FACTOR = { base: 1.0, giant: 1.3, gold: 1.6, both: 1.9 };
// RATE_SCALE lets us test a global tune without touching bands. 1 = plan as written.
const RATE_SCALE = +(process.env.RATE_SCALE || 1);
for (const r of order) {
  const list = creatures.filter((c) => c.rarity === r).sort((a, b) => a.baseValue - b.baseValue || a.id.localeCompare(b.id));
  const [lo, hi] = BANDS[r];
  list.forEach((c, i) => {
    const t = list.length > 1 ? i / (list.length - 1) : 0.5;
    // Stored as integer centesimos per MINUTE, multiple of 10 so x1.3/x1.6/x1.9 stay integers.
    c.cpm = Math.round(((lo + (hi - lo) * t) * RATE_SCALE * 60 * 100) / 10) * 10;
    c.rate = c.cpm / 6000; // coins per second
  });
}

// ---------- variant odds under current code ----------
const SHINY = 1 / 40;
const GIANT = 1 - Math.pow(0.85, 1 / 1.8); // weight t=u^1.8, giant when t>=0.85
const pBoth = SHINY * GIANT;
const VARIANTS = [
  ["base", (1 - SHINY) * (1 - GIANT)],
  ["giant", (1 - SHINY) * GIANT],
  ["gold", SHINY * (1 - GIANT)],
  ["both", pBoth],
];
const meanValueMult = 0.75 + 0.5 / 2.8; // E[0.75+0.5t], E[t]=1/2.8

// ---------- RNG ----------
function rng(seed) { let s = seed >>> 0; return () => ((s = (s + 0x6d2b79f5) >>> 0), (((t) => ((t = Math.imul(t ^ (t >>> 15), t | 1)), (t ^= t + Math.imul(t ^ (t >>> 7), t | 61)), ((t ^ (t >>> 14)) >>> 0) / 4294967296))(s))); }

// ---------- aquarium levels (proposal; price to be tuned by this sim) ----------
const TANK = (process.env.TANK_PRICES ? JSON.parse(process.env.TANK_PRICES) : [0, 1500, 9000, 45000]);
const SLOTS = [3, 5, 8, 12];

const pool = (event) => creatures.filter((c) => !c.event && !c.season);
const byRarity = {};
for (const r of order) byRarity[r] = pool().filter((c) => c.rarity === r);

function pickRarity(R, rod, luckMul) {
  const w = order.map((r, i) => (byRarity[r].length ? W[r] * (1 + rod.luck * i) * (i >= 2 ? luckMul : 1) : 0));
  const tot = w.reduce((a, b) => a + b, 0);
  let x = R() * tot;
  for (let i = 0; i < w.length; i++) { if ((x -= w[i]) < 0) return order[i]; }
  return "Common";
}
function pickVariant(R) {
  let x = R();
  for (const [v, p] of VARIANTS) { if ((x -= p) < 0) return v; }
  return "base";
}

// ---------- profiles (ASSUMPTIONS) ----------
// cycle: seconds per catch attempt (bite wait + fight + reveal). win: fight win rate. combo: avg combo bonus.
const PROFILES = {
  beginner: { cycle: 16, win: 0.7, combo: 1.05, luck: 1, minPerDay: 20 },
  regular: { cycle: 13, win: 0.85, combo: 1.15, luck: 1, minPerDay: 45 },
  fast: { cycle: 11, win: 0.92, combo: 1.25, luck: 1, minPerDay: 90 },
  unlucky: { cycle: 13, win: 0.85, combo: 1.15, luck: 0.5, minPerDay: 45 },
  lucky: { cycle: 13, win: 0.85, combo: 1.15, luck: 2, minPerDay: 45 },
};

const rateCache = new Map();
for (const c of creatures) for (const v of Object.keys(FACTOR)) rateCache.set(c.id + "|" + v, c.rate * FACTOR[v]);

function run(profile, seed, opts = {}) {
  const R = rng(seed);
  const P = PROFILES[profile];
  let t = 0, coins = opts.coins || 0, rodIdx = opts.rodIdx || 0, level = 0;
  const inv = {}; // "id|variant" -> count
  const src = { catch: 0, tank: 0 };
  let tankRate = 0, firstPlace = null, firstExpand = null, secondExpand = null, tankValueSpent = 0, rodSpent = 0;
  const marks = {};
  if (opts.inv) Object.assign(inv, opts.inv);
  const checkpoints = [5, 15, 30].map((m) => m * 60).concat([1, 3, 7, 14].map((d) => d * P.minPerDay * 60));
  const cpSet = new Set(checkpoints);
  const horizon = Math.max(...checkpoints);
  const rateOf = (key) => rateCache.get(key);
  const recompute = () => {
    let n = SLOTS[level], tot = 0;
    const keys = Object.keys(inv).sort((a, b) => rateOf(b) - rateOf(a));
    for (const k of keys) { const use = Math.min(inv[k], n); tot += rateOf(k) * use; n -= use; if (n <= 0) break; }
    tankRate = tot;
  };
  recompute();
  const pending = [...checkpoints].sort((a, b) => a - b);
  const snap = (label) => { marks[label] = { coins: Math.round(coins), rate: +tankRate.toFixed(2), level: level + 1, rod: rods[rodIdx].id, bought: tankValueSpent }; };
  const labels = ["5m", "15m", "30m", "d1", "d3", "d7", "d14"];
  const labelOf = new Map(checkpoints.map((c, i) => [c, labels[i]]));
  let ci = 0;
  const sortedCp = [...checkpoints].map((c, i) => [c, labels[i]]).sort((a, b) => a[0] - b[0]);
  while (t < horizon) {
    t += P.cycle;
    const gain = tankRate * P.cycle; coins += gain; src.tank += gain;
    if (R() < P.win) {
      const rod = rods[rodIdx];
      const r = pickRarity(R, rod, P.luck);
      const list = byRarity[r];
      const c = list[Math.floor(R() * list.length)];
      const v = pickVariant(R);
      const val = c.baseValue * meanValueMult * (v === "gold" || v === "both" ? 3 : 1) * P.combo;
      coins += val; src.catch += val;
      const key = c.id + "|" + v;
      inv[key] = (inv[key] || 0) + 1;
      // only re-rank when the new key can beat the current weakest slot (cheap guard)
      if (inv[key] === 1 || inv[key] <= SLOTS[level]) {
        const before = tankRate; recompute();
        if (firstPlace === null && tankRate > before) firstPlace = t;
      }
    }
    // spend: next expansion if cheaper than next rod, else rod
    for (;;) {
      const nextRod = rods[rodIdx + 1], nextLvl = TANK[level + 1];
      const wantTank = nextLvl !== undefined && (!nextRod || nextLvl <= nextRod.price);
      if (wantTank && coins >= nextLvl) { coins -= nextLvl; level++; tankValueSpent += nextLvl; recompute(); if (level === 1) firstExpand = t; if (level === 2) secondExpand = t; }
      else if (!wantTank && nextRod && coins >= nextRod.price) { coins -= nextRod.price; rodIdx++; rodSpent += nextRod.price; }
      else break;
    }
    while (sortedCp[ci] && t >= sortedCp[ci][0]) { snap(sortedCp[ci][1]); ci++; }
  }
  return { marks, firstPlace, firstExpand, secondExpand, src, rodIdx, level };
}

function aggregate(profile, n, opts) {
  const res = [];
  for (let i = 0; i < n; i++) res.push(run(profile, 1000 + i, opts));
  const med = (xs) => { xs = xs.filter((x) => x !== null && x !== undefined).sort((a, b) => a - b); return xs.length ? xs[Math.floor(xs.length / 2)] : null; };
  const out = { p: profile, firstPlace: med(res.map((r) => r.firstPlace)), firstExpand: med(res.map((r) => r.firstExpand)), secondExpand: med(res.map((r) => r.secondExpand)), neverExpand: res.filter((r) => r.firstExpand === null).length / n, marks: {} };
  for (const l of ["5m", "15m", "30m", "d1", "d3", "d7", "d14"]) {
    out.marks[l] = {
      rate: med(res.map((r) => r.marks[l] && r.marks[l].rate)),
      level: med(res.map((r) => r.marks[l] && r.marks[l].level)),
      rod: med(res.map((r) => r.marks[l] && rods.findIndex((x) => x.id === r.marks[l].rod))),
    };
  }
  const tc = res.reduce((s, r) => s + r.src.catch, 0), tt = res.reduce((s, r) => s + r.src.tank, 0);
  out.tankShare = tt / (tc + tt);
  return out;
}

// ---------- reports ----------
const fmt = (s) => (s === null || s === undefined ? "n/a" : (s / 60).toFixed(1) + " min");
const lines = [];
const P = (s = "") => lines.push(s);

P(`## Parametros (RATE_SCALE=${RATE_SCALE}, TANK=${JSON.stringify(TANK)}, SLOTS=${JSON.stringify(SLOTS)})`);
P("");
P(`Probabilidade real hoje: Gigante ${(GIANT * 100).toFixed(2)}% (peso nos 15% superiores, mas t=u^1.8 concentra no fim baixo), Cintilante ${(SHINY * 100).toFixed(1)}%, Gigante+Cintilante ${(pBoth * 100).toFixed(3)}% (1 em ${Math.round(1 / pBoth)} capturas).`);
P("");

// rates table
P("## Taxa por especie (passivo/s, base)");
P("");
P("| Raridade | Especies | Faixa | Min..Max aplicado |");
P("|---|---:|---|---|");
for (const r of order) {
  const l = creatures.filter((c) => c.rarity === r);
  P(`| ${r} | ${l.length} | ${BANDS[r][0]}-${BANDS[r][1]} | ${Math.min(...l.map((c) => c.rate)).toFixed(2)}..${Math.max(...l.map((c) => c.rate)).toFixed(2)} |`);
}
P("");

// active income reference
function activeCoinsPerMin(rodIdx, cycle, win, combo) {
  const rod = rods[rodIdx];
  const w = order.map((r, i) => (byRarity[r].length ? W[r] * (1 + rod.luck * i) : 0));
  const tot = w.reduce((a, b) => a + b, 0);
  let v = 0;
  order.forEach((r, i) => { if (!w[i]) return; const avg = byRarity[r].reduce((s, c) => s + c.baseValue, 0) / byRarity[r].length; v += (w[i] / tot) * avg; });
  const shinyMul = 1 + SHINY * 2;
  return (v * meanValueMult * shinyMul * combo * win * 60) / cycle;
}
P("## Renda ativa de referencia (pescar, sem aquario)");
P("");
P("| Vara | Coins/min (regular) | Preco | Min p/ pagar |");
P("|---|---:|---:|---:|");
rods.forEach((rod, i) => { const a = activeCoinsPerMin(i, 13, 0.85, 1.15); P(`| ${rod.id} | ${a.toFixed(0)} | ${rod.price} | ${rod.price ? (rod.price / a).toFixed(1) : "-"} |`); });
P("");

// ceiling
P("## Teto: tanque cheio (renda passiva/s) vs pesca ativa");
P("");
P("| Cenario | 3 vagas | 5 | 8 | 12 | x pesca ativa (Astral) com 12 |");
P("|---|---:|---:|---:|---:|---:|");
const astral = activeCoinsPerMin(4, 13, 0.85, 1.15) / 60;
const sets = [
  ["Mediana: Rara base media", () => 0.95],
  ["Tanque de Lendarias base", () => 3.2],
  ["Lendarias Gigante+Dourada", () => 3.2 * FACTOR.both],
  ["Misticas Gigante+Dourada", () => 6.0 * FACTOR.both],
];
for (const [name, f] of sets) {
  const r = SLOTS.map((n) => (f() * n * RATE_SCALE * (name.startsWith("Mediana") ? 1 : 1) * 1.1).toFixed(1));
  P(`| ${name} (+10% sinergia) | ${r.join(" | ")} | ${(parseFloat(r[3]) / astral).toFixed(1)}x |`);
}
P("");
P(`Pesca ativa com Astral ~ ${astral.toFixed(1)} coins/s (${(astral * 60).toFixed(0)}/min).`);
P("");

// profiles
const wantN = +(process.env.N || 200);
P("## Perfis (mediana de " + wantN + " execucoes cada, renda offline desligada)");
P("");
P("| Perfil | 1a vaga ocupada | 1a expansao | 2a expansao | % sem expandir | Taxa 5m | 15m | 30m | d1 | d3 | d7 | d14 | Nivel d14 | Vara d14 | Passivo/total |");
P("|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|");
for (const p of Object.keys(PROFILES)) {
  const a = aggregate(p, wantN);
  const m = a.marks;
  P(`| ${p} | ${fmt(a.firstPlace)} | ${fmt(a.firstExpand)} | ${fmt(a.secondExpand)} | ${(a.neverExpand * 100).toFixed(0)}% | ${m["5m"].rate} | ${m["15m"].rate} | ${m["30m"].rate} | ${m.d1.rate} | ${m.d3.rate} | ${m.d7.rate} | ${m.d14.rate} | ${m.d14.level} | ${rods[m.d14.rod].id} | ${(a.tankShare * 100).toFixed(0)}% |`);
}
P("");

// veteran
const vInv = {};
const vSpecies = creatures.filter((c) => !c.event && !c.season).slice(0, 60);
for (const c of vSpecies) vInv[c.id + "|base"] = 4;
for (const c of vSpecies.filter((c, i) => i % 6 === 0)) vInv[c.id + "|gold"] = 1;
const vet = aggregate("regular", 50, { coins: 200000, rodIdx: 3, inv: vInv });
P("## Veterano (estimativa: 200 mil moedas, vara Storm, 60 especies x4, ~1 Cintilante a cada 6)");
P("");
P(`Taxa do tanque nos checkpoints (regular, jogando): 5m ${vet.marks["5m"].rate}/s, 30m ${vet.marks["30m"].rate}/s, d1 ${vet.marks.d1.rate}/s. Nivel do tanque no d1: ${vet.marks.d1.level}. Tempo ate 1a expansao: ${fmt(vet.firstExpand)}.`);
P("Premissa: veterano real vem de perfil migrado; medir saldo/colecao reais antes de fixar precos (ver pontos abertos).");
P("");

if (process.argv.includes("--md")) console.log(lines.join("\n"));
else console.log(lines.join("\n"));

// export per-species table for config draft
if (process.argv.includes("--rates")) {
  console.log("\n-- rates --");
  for (const c of creatures) console.log(`${c.id}\t${c.rarity}\t${c.cpm}\t${(c.cpm / 100).toFixed(1)}`);
}
