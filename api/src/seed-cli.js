import { getDb, initSchema, resetDemoData, resolveDbPath, seedDemoRecords } from "./db.js";

const reset = process.argv.includes("--reset");
initSchema();
const result = reset ? resetDemoData() : seedDemoRecords();
const rows = getDb()
  .prepare("SELECT id, status, title FROM incidents ORDER BY created_at DESC")
  .all();

console.log(`SQLite ${resolveDbPath()}`);
console.log(
  reset
    ? `Reset and seeded ${result.total} record(s).`
    : `Seeded ${result.inserted} new record(s); ${result.total} total.`
);
for (const row of rows) {
  console.log(`  ${row.id}\t${row.status}\t${row.title}`);
}
