// Catch roulette economy sim. Run: node tools/roulette-sim.js
// Mirrors src/shared/Config/Roulette.luau (keep the tables in sync). Prints the expected coin
// multiplier per catch, the outcome mix and how often each jackpot happens.
const MAIN = [["nothing", 50], ["worse", 20], ["size", 18], ["again", 8], ["mutation", 4]];
const AGAIN_NOTHING_BONUS = 25; // each re-spin adds this much weight to "nothing"
const MAX_AGAIN = 3;
const SIZE_VALUE_EXP = 0.5; // coins grow with sqrt(size): x100 size = x10 coins
const SIZE = [[2, 62], [3, 20], [5, 10], [10, 5], [25, 2], [50, 0.8], [100, 0.2]];
const WORSE = [[0.8, 50], [0.6, 35], [0.4, 15]];
const MUT = [["neon", 1.5, 40], ["frost", 2, 24], ["magma", 2.5, 15], ["storm", 3, 10], ["rainbow", 5, 7], ["diamond", 10, 3], ["cosmic", 25, 1]];
const pick = (list, wi) => { const t = list.reduce((a, x) => a + x[wi], 0); let r = Math.random() * t; for (const x of list) { r -= x[wi]; if (r <= 0) return x; } return list[list.length - 1]; };
function roll() {
  let size = 1, mut = null, again = 0, spins = 0;
  for (;;) {
    spins++;
    const main = MAIN.map(([k, w]) => [k, k === "nothing" ? w + again * AGAIN_NOTHING_BONUS : k === "again" && again >= MAX_AGAIN ? 0 : w]);
    const o = pick(main, 1)[0];
    if (o === "again") { again++; continue; }
    if (o === "size") size *= pick(SIZE, 1)[0];
    if (o === "worse") size *= pick(WORSE, 1)[0];
    if (o === "mutation") mut = pick(MUT, 2);
    return { size, mut, spins, o };
  }
}
const N = 2e6; let sum = 0, spins = 0; const mix = {}; let x100 = 0, cosmic = 0;
for (let i = 0; i < N; i++) { const r = roll(); const v = Math.pow(r.size, SIZE_VALUE_EXP) * (r.mut ? r.mut[1] : 1); sum += v; spins += r.spins; mix[r.o] = (mix[r.o] || 0) + 1; if (r.size >= 100) x100++; if (r.mut && r.mut[0] === "cosmic") cosmic++; }
console.log("expected coin multiplier per catch:", (sum / N).toFixed(3));
console.log("average spins per catch:", (spins / N).toFixed(2));
console.log("final outcome mix %:", Object.fromEntries(Object.entries(mix).map(([k, v]) => [k, (100 * v / N).toFixed(1)])));
console.log("x100 size: 1 in", Math.round(N / x100), "| cosmic: 1 in", Math.round(N / cosmic));
