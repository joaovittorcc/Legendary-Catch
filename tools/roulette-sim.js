// Catch roulette economy sim. Run: node tools/roulette-sim.js
// Mirrors src/shared/Config/Roulette.luau (keep the tables and rules in sync). Effects STACK:
// the main wheel spins again after every effect until "nothing" or MAX_MAIN spins.
// Prints the expected coin multiplier, the spin count, jackpot odds and the combined
// "1 in N" of a creature once the roulette bonus is included.
const MAIN = [["nothing", 50], ["worse", 20], ["size", 18], ["again", 8], ["mutation", 4]];
const MAX_MAIN = 4;
const AGAIN_NOTHING_BONUS = 40;
const SIZE_VALUE_EXP = 0.5;
const SIZE = [[2, 62], [3, 20], [5, 10], [10, 5], [25, 2], [50, 0.8], [100, 0.2]];
const WORSE = [[0.8, 50], [0.6, 35], [0.4, 15]];
const MUT = [["neon", 1.5, 40], ["frost", 2, 24], ["magma", 2.5, 15], ["storm", 3, 10], ["rainbow", 5, 7], ["diamond", 10, 3], ["cosmic", 25, 1]];
const mainWeight = (k, w, mains) => (k === "nothing" ? w + (mains - 1) * AGAIN_NOTHING_BONUS : k === "again" && mains >= MAX_MAIN ? 0 : w);
const pick = (list, wi) => { const t = list.reduce((a, x) => a + x[wi], 0); let r = Math.random() * t; for (const x of list) { r -= x[wi]; if (r <= 0) return x; } return list[list.length - 1]; };
function roll() {
  let size = 1, rank = 0, mains = 0;
  for (;;) {
    mains++;
    const o = pick(MAIN.map(([k, w]) => [k, mainWeight(k, w, mains)]), 1)[0];
    if (o === "nothing") break;
    if (o === "size") size *= pick(SIZE, 1)[0];
    if (o === "worse") size *= pick(WORSE, 1)[0];
    if (o === "mutation") { const m = pick(MUT, 2); rank = Math.max(rank, MUT.indexOf(m) + 1); }
    if (mains >= MAX_MAIN) break;
  }
  return { size, rank, mains, coin: Math.pow(size, SIZE_VALUE_EXP) * (rank ? MUT[rank - 1][1] : 1) };
}
// exact distribution of coin multiplier (same recursion as Roulette.buildDistribution)
const dist = new Map();
function leaf(size, rank, p) { const c = Math.pow(size, SIZE_VALUE_EXP) * (rank ? MUT[rank - 1][1] : 1); const k = c.toFixed(6); dist.set(k, (dist.get(k) || 0) + p); }
function walk(mains, size, rank, prob) {
  const ws = MAIN.map(([k, w]) => [k, mainWeight(k, w, mains)]);
  const total = ws.reduce((a, x) => a + x[1], 0);
  for (const [k, w] of ws) {
    if (w <= 0) continue;
    const pe = prob * w / total;
    if (k === "nothing") { leaf(size, rank, pe); continue; }
    if (k === "again") { walk(mains + 1, size, rank, pe); continue; }
    const list = k === "size" ? SIZE : k === "worse" ? WORSE : MUT;
    const wi = k === "mutation" ? 2 : 1;
    const sub = list.reduce((a, x) => a + x[wi], 0);
    list.forEach((x, i) => {
      const px = pe * x[wi] / sub;
      const ns = k === "mutation" ? size : size * x[0];
      const nr = k === "mutation" ? Math.max(rank, i + 1) : rank;
      if (mains >= MAX_MAIN) leaf(ns, nr, px); else walk(mains + 1, ns, nr, px);
    });
  }
}
walk(1, 1, 0, 1);
const entries = [...dist.entries()].map(([k, p]) => [+k, p]).sort((a, b) => b[0] - a[0]);
const tail = (c) => c <= 1.000001 ? 1 : entries.reduce((a, [v, p]) => a + (v >= c - 1e-6 ? p : 0), 0);
const totalP = entries.reduce((a, [, p]) => a + p, 0);

const N = 2e6; let sum = 0, spins = 0, combos = 0, x100 = 0, cosmic = 0, bigSize = 0;
const mix = { nothing: 0, bonus: 0, worse: 0 };
for (let i = 0; i < N; i++) {
  const r = roll(); sum += r.coin; spins += r.mains;
  if (r.size >= 10 && r.rank) combos++;
  if (r.size >= 100) x100++; if (r.rank === 7) cosmic++; if (r.size >= 10) bigSize++;
  mix[r.coin > 1.000001 ? "bonus" : r.coin < 0.999999 ? "worse" : "nothing"]++;
}
console.log("exact probability mass:", totalP.toFixed(6), "| distinct results:", entries.length);
console.log("expected coin multiplier per catch:", (sum / N).toFixed(3));
console.log("average main spins per catch:", (spins / N).toFixed(2));
console.log("result mix %:", Object.fromEntries(Object.entries(mix).map(([k, v]) => [k, (100 * v / N).toFixed(1)])));
console.log("size>=10:", "1 in", Math.round(N / bigSize), "| x100 size:", "1 in", Math.round(N / x100), "| cosmic:", "1 in", Math.round(N / cosmic), "| size>=10 AND mutation:", "1 in", Math.round(N / Math.max(1, combos)));
for (const c of [1.5, 2, 3, 5, 10, 25, 50]) console.log(`P(coin >= x${c}) = 1 in ${Math.round(1 / tail(c))}`);
console.log("example: Legendary 1 in 3,900 with a x10-size + diamond result (coin x31.6):", Math.round(3900 / tail(31.6)).toLocaleString("en-US"));
