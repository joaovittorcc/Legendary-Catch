// Fishing Power (Poder de Pesca) pacing sim. Run: node tools/training-sim.js [duty] [r0]
// Models ONE trained stat (1 -> 1e15). Gain/s g = M + PP * r0 * M^0.3, where M = field x island x prestige.
// Field upgrades need coins AND a power gate; islands need a power gate. Coins come from fishing,
// which only runs while NOT training (duty = share of play time spent training).
// Planning numbers only (23/11/2026); re-run with the real economy before shipping.

const FIELD_MULT = [1, 2.5, 6, 15, 38, 95, 240, 600, 1500, 4000]; // level 1..10
const FIELD_COST = [0, 1500, 6000, 20000, 60000, 180000, 500000, 1400000, 3000000, 5000000]; // to reach level k+1 (index = level)
const FIELD_GATE = [0, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e12]; // PP needed to buy level k+1
const ISLAND_MULT = [1, 3, 12, 50];
const ISLAND_GATE = [0, 1e5, 1e8, 1e12];
const CAP = 1e15;

const duty = Number(process.argv[2] || 0.5);
const r0 = Number(process.argv[3] || 8e-6);
const noUpgrades = process.argv[4] === "none";

function coinsPerHour(h) {
	if (h < 10) return 30000;
	if (h < 30) return 60000;
	if (h < 60) return 120000;
	if (h < 100) return 250000;
	return 500000;
}

let pp = 1;
let coins = 0;
let field = 0; // index 0..9 = level 1..10
let island = 0;
const dt = 30; // seconds
const marks = [1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e13, 1e14, 1e15];
const reached = {};
const fieldAt = {};
const islandAt = {};
let t = 0;
while (t < 2000 * 3600 && pp < CAP) {
	const h = t / 3600;
	coins += (coinsPerHour(h) * (1 - duty) * dt) / 3600;
	if (!noUpgrades) {
		while (field < 9 && coins >= FIELD_COST[field + 1] && pp >= FIELD_GATE[field + 1]) {
			coins -= FIELD_COST[field + 1];
			field++;
			fieldAt[field + 1] = h.toFixed(1);
		}
		while (island < 3 && pp >= ISLAND_GATE[island + 1]) {
			island++;
			islandAt[island + 1] = h.toFixed(1);
		}
	}
	const M = FIELD_MULT[field] * ISLAND_MULT[island];
	pp = Math.min(CAP, pp + (M + pp * r0 * Math.pow(M, 0.3)) * duty * dt);
	t += dt;
	for (const m of marks) if (pp >= m && !(m in reached)) reached[m] = h.toFixed(1);
}
console.log(`duty=${duty} r0=${r0}${noUpgrades ? " (no upgrades)" : ""}`);
console.log("play-hours to reach PP:", JSON.stringify(reached));
console.log("field level reached at (play-hours):", JSON.stringify(fieldAt));
console.log("island reached at (play-hours):", JSON.stringify(islandAt));
console.log("final PP", pp.toExponential(2), "after", (t / 3600).toFixed(1), "h; coins left", Math.round(coins));
