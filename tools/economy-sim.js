// Economy sim for Legendary Catch (expected values, no randomness).
// Run from the repo root:  node tools/economy-sim.js
// Reads Config/Creatures.luau, Config/Rods.luau, Config/Fishing.luau (weights) and prints, per rod:
// expected coins per catch, coins per minute, minutes to afford the next rod and odds of a Mystic.
const fs = require("fs");
const read = (f) => fs.readFileSync(f, "utf8").replace(/\r\n/g, "\n");

const creaturesSrc = read("src/shared/Config/Creatures.luau");
const creatures = [];
for (const b of creaturesSrc.split("\t{\n\t\tid = ").slice(1)) {
  const g = (k) => (b.match(new RegExp("\\t\\t" + k + ' = "?([^",\\n]+)')) || [])[1];
  const id = (b.match(/^"([^"]+)"/) || [])[1];
  if (!id) continue;
  creatures.push({ id, rarity: g("rarity"), baseValue: +g("baseValue"), event: g("event") });
}
const pi = creaturesSrc.indexOf("local PLANNED");
const live = creatures.filter((c) => creaturesSrc.indexOf('"' + c.id + '"') < pi || pi < 0);

const rods = [];
for (const b of read("src/shared/Config/Rods.luau").split("\t{\n\t\tid = ").slice(1)) {
  const id = (b.match(/^"([^"]+)"/) || [])[1];
  const n = (k) => +(b.match(new RegExp(k + " = ([\\d.]+)")) || [])[1];
  if (id) rods.push({ id, price: n("price"), luck: n("luckBonus") });
}

const fishing = read("src/shared/Config/Fishing.luau");
const order = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mystic"];
const weights = {};
const wBlock = fishing.slice(fishing.indexOf("RARITY_WEIGHTS"), fishing.indexOf("RARITY_COLORS"));
for (const r of order) weights[r] = +((wBlock.match(new RegExp(r + " = ([\\d.]+)")) || [])[1] || 0);

const SECONDS_PER_CATCH = 13; // bite wait + fight + reveal (measured earlier)
const catchesPerMin = 60 / SECONDS_PER_CATCH;
const VALUE_MULT = 0.75 + 0.5 * (1 / 2.8); // weight rolled as t^1.8 -> E[t] = 1/2.8
const SHINY = 1 + (1 / 40) * (3 - 1);
const COMBO = 1.15; // average combo bonus for an engaged player

function row(rod, instinct, prestige) {
  const eff = {};
  let total = 0;
  order.forEach((r, i) => {
    const rank = i + 1;
    const pool = live.filter((c) => c.rarity === r && !c.event);
    const w = pool.length
      ? weights[r] * (1 + 0.01 * instinct * (rank - 1)) * (1 + rod.luck * (rank - 1)) * (1 + 0.04 * prestige * (rank - 1))
      : 0;
    eff[r] = { w, pool };
    total += w;
  });
  let value = 0;
  for (const r of order) {
    const { w, pool } = eff[r];
    if (!w) continue;
    const avg = pool.reduce((s, c) => s + c.baseValue, 0) / pool.length;
    value += (w / total) * avg;
  }
  value *= VALUE_MULT * SHINY * COMBO * (1 + 0.1 * prestige);
  const mystic = total ? eff.Mystic.w / total : 0;
  return { value, perMin: value * catchesPerMin, mystic };
}

for (const [label, instinct, prestige] of [["no training, no prestige", 0, 0], ["Instinct 25", 25, 0], ["Instinct 25 + prestige 5", 25, 5]]) {
  console.log("\n== " + label + " ==");
  console.log("rod         price     coins/catch coins/min  min to next rod  1 Mystic per N catches");
  rods.forEach((rod, i) => {
    const r = row(rod, instinct, prestige);
    const next = rods[i + 1];
    const mins = next ? (next.price / r.perMin).toFixed(0) : "-";
    console.log(
      rod.id.padEnd(11), String(rod.price).padEnd(9), r.value.toFixed(0).padEnd(11), r.perMin.toFixed(0).padEnd(10),
      String(mins).padEnd(16), r.mystic ? Math.round(1 / r.mystic) : "never"
    );
  });
}
const counts = {};
for (const c of live) counts[c.rarity] = (counts[c.rarity] || 0) + (c.event ? 0 : 1);
console.log("\nrolling pool (non-event) by rarity:", JSON.stringify(counts));
