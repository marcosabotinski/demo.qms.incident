import { getDb, initSchema, resetDemoData, resolveDbPath, seedDemoRecords } from "./db.js";
import { seedRecords } from "./seed.js";

const reset = process.argv.includes("--reset");
initSchema();
const result = reset ? resetDemoData() : seedDemoRecords();
const rows = getDb()
  .prepare("SELECT id, status, title FROM incidents ORDER BY created_at DESC")
  .all();
const featuredIds = new Set(seedRecords.map((r) => r.id));
const featured = rows.filter((row) => featuredIds.has(row.id));

console.log(`SQLite ${resolveDbPath()}`);
console.log(
  reset
    ? `Reset and seeded ${result.total} record(s).`
    : `Seeded ${result.inserted} new record(s); ${result.total} total.`
);
console.log("Featured walkthrough records:");
for (const row of featured) {
  console.log(`  ${row.id}\t${row.status}\t${row.title}`);
}
console.log(`Plus ${rows.length - featured.length} generated volume records.`);
