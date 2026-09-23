import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import { getDb, initSchema, nextIncidentId, openDb, query, seedDemoRecords, setDb } from "./db.js";

describe("sqlite store", () => {
  before(() => {
    setDb(openDb(":memory:"));
    initSchema();
  });

  after(() => {
    getDb().close();
  });

  it("seeds the four demo quality incidents", () => {
    const result = seedDemoRecords();
    assert.equal(result.inserted, 4);
    assert.equal(result.total, 4);
    const { rows } = query("SELECT id, status FROM incidents ORDER BY id");
    assert.deepEqual(
      rows.map((r) => r.id),
      ["DEV-2026-0088", "INC-2026-0131", "INC-2026-0138", "INC-2026-0142"]
    );
    const again = seedDemoRecords();
    assert.equal(again.inserted, 0);
    assert.equal(again.total, 4);
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
});
