import Database from "better-sqlite3";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { seedRecords } from "./seed.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function resolveDbPath() {
  return process.env.SQLITE_PATH || path.join(__dirname, "../data/qms.sqlite");
}

export function openDb(dbPath = resolveDbPath()) {
  if (dbPath !== ":memory:") {
    fs.mkdirSync(path.dirname(dbPath), { recursive: true });
  }
  const database = new Database(dbPath);
  database.pragma("journal_mode = WAL");
  database.pragma("foreign_keys = ON");
  return database;
}

let db;

export function getDb() {
  if (!db) db = openDb();
  return db;
}

export function setDb(instance) {
  db = instance;
}

function hydrateRow(row) {
  if (row && typeof row.data === "string") {
    row.data = JSON.parse(row.data);
  }
  return row;
}

export function query(sql, params = []) {
  const stmt = getDb().prepare(sql);
  if (/^\s*select/i.test(sql)) {
    return { rows: stmt.all(...params).map(hydrateRow) };
  }
  stmt.run(...params);
  return { rows: [] };
}

export function initSchema(database = getDb()) {
  database.exec(`
    CREATE TABLE IF NOT EXISTS incidents (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      status TEXT NOT NULL,
      priority TEXT NOT NULL,
      department TEXT NOT NULL,
      owner TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      data TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS incident_id_seq (
      n INTEGER NOT NULL
    );
    INSERT INTO incident_id_seq (n)
      SELECT 142 WHERE NOT EXISTS (SELECT 1 FROM incident_id_seq);
    CREATE TABLE IF NOT EXISTS attachment_blobs (
      incident_id TEXT NOT NULL,
      att_id TEXT NOT NULL,
      file_name TEXT NOT NULL,
      file_type TEXT NOT NULL,
      byte_size INTEGER NOT NULL,
      content BLOB NOT NULL,
      PRIMARY KEY (incident_id, att_id)
    );
  `);
}

export function nextIncidentId(database = getDb()) {
  database.prepare("UPDATE incident_id_seq SET n = n + 1").run();
  const { n } = database.prepare("SELECT n FROM incident_id_seq").get();
  return `INC-${new Date().getFullYear()}-${String(n).padStart(4, "0")}`;
}

function insertRecord(database, rec) {
  const createdAt = rec.auditTrail?.[0]?.at ?? rec.createdAt ?? new Date().toISOString();
  database
    .prepare(
      `INSERT INTO incidents (id, title, status, priority, department, owner, created_at, updated_at, data)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      rec.id,
      rec.title,
      rec.status,
      rec.priority,
      rec.department,
      rec.owner,
      createdAt,
      createdAt,
      JSON.stringify(rec)
    );
}

export function seedIfEmpty(database = getDb()) {
  const { n } = database.prepare("SELECT COUNT(*) AS n FROM incidents").get();
  if (n > 0) return { inserted: 0, total: n };
  for (const rec of seedRecords) insertRecord(database, rec);
  return { inserted: seedRecords.length, total: seedRecords.length };
}

export function seedDemoRecords(database = getDb()) {
  let inserted = 0;
  const insert = database.prepare(
    `INSERT OR IGNORE INTO incidents (id, title, status, priority, department, owner, created_at, updated_at, data)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
  );
  for (const rec of seedRecords) {
    const createdAt = rec.auditTrail?.[0]?.at ?? rec.createdAt ?? new Date().toISOString();
    const info = insert.run(
      rec.id,
      rec.title,
      rec.status,
      rec.priority,
      rec.department,
      rec.owner,
      createdAt,
      createdAt,
      JSON.stringify(rec)
    );
    if (info.changes) inserted += 1;
  }
  const { n } = database.prepare("SELECT COUNT(*) AS n FROM incidents").get();
  return { inserted, total: n };
}

export function resetDemoData(database = getDb()) {
  database.exec("DELETE FROM attachment_blobs; DELETE FROM incidents;");
  database.prepare("UPDATE incident_id_seq SET n = 142").run();
  return seedDemoRecords(database);
}
