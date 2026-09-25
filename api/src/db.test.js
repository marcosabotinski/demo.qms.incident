import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import { getDb, initSchema, nextIncidentId, openDb, query, resetDemoData, seedDemoRecords, setDb } from "./db.js";

describe("sqlite store", () => {
  before(() => {
    setDb(openDb(":memory:"));
    initSchema();
  });

  after(() => {
    getDb().close();
  });

  it("seeds featured walkthrough records plus volume rows", () => {
    const result = seedDemoRecords();
    assert.ok(result.inserted >= 480 && result.inserted <= 520);
    assert.equal(result.total, result.inserted);
    const { rows } = query("SELECT id, status FROM incidents ORDER BY id");
    const ids = rows.map((r) => r.id);
    for (const id of ["DEV-2026-0088", "INC-2026-0131", "INC-2026-0138", "INC-2026-0142"]) {
      assert.ok(ids.includes(id), `missing featured id ${id}`);
    }
    const again = seedDemoRecords();
    assert.equal(again.inserted, 0);
    assert.equal(again.total, result.total);
  });

  it("parses incident JSON on read", () => {
    const { rows } = query("SELECT data FROM incidents WHERE id = ?", ["INC-2026-0142"]);
    assert.equal(rows[0].data.recordType, "Incident");
    assert.equal(rows[0].data.attachments.length, 3);
  });

  it("allocates the next incident id from 143", () => {
    assert.equal(nextIncidentId(), `INC-${new Date().getFullYear()}-0143`);
    assert.equal(nextIncidentId(), `INC-${new Date().getFullYear()}-0144`);
  });

  it("reset restores the same seed volume", () => {
    const { rows: before } = query("SELECT COUNT(*) AS n FROM incidents");
    const result = resetDemoData();
    assert.equal(result.inserted, before[0].n);
    assert.equal(result.total, before[0].n);
    assert.ok(result.total >= 480 && result.total <= 520);
  });
});
