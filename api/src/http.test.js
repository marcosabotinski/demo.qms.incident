import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import { getDb, initSchema, openDb, seedDemoRecords, setDb } from "./db.js";
import { createApp } from "./index.js";

describe("http create/list/detail/attachments", () => {
  let server;
  let base;

  before(async () => {
    setDb(openDb(":memory:"));
    initSchema();
    seedDemoRecords();
    const app = createApp();
    server = app.listen(0, "127.0.0.1");
    await new Promise((resolve) => server.once("listening", resolve));
    const { port } = server.address();
    base = `http://127.0.0.1:${port}`;
  });

  after(async () => {
    await new Promise((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
    getDb().close();
  });

  it("lists seeded incidents", async () => {
    const res = await fetch(`${base}/api/incidents`);
    assert.equal(res.status, 200);
    const rows = await res.json();
    assert.ok(rows.length >= 480 && rows.length <= 520);
    assert.ok(rows.some((r) => r.id === "INC-2026-0142"));
  });

  it("opens a seeded incident", async () => {
    const res = await fetch(`${base}/api/incidents/INC-2026-0142`);
    assert.equal(res.status, 200);
    const rec = await res.json();
    assert.equal(rec.title, "Temperature excursion – Incubator IC-12");
    assert.equal(rec.recordType, "Incident");
  });

  it("creates a quality incident and serves an attachment", async () => {
    const created = await fetch(`${base}/api/incidents`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        title: "Pipette out of calibration – P-22",
        priority: "High",
        description: "Daily check failed; pipette taken out of service.",
      }),
    });
    assert.equal(created.status, 201);
    const rec = await created.json();
    assert.match(rec.id, /^INC-\d{4}-0143$/);
    assert.equal(rec.status, "Draft");

    const form = new FormData();
    form.append("captions", "Check sheet");
    form.append("files", new Blob(["lot,result\nP-22,fail\n"], { type: "text/csv" }), "check.csv");
    const uploaded = await fetch(`${base}/api/incidents/${rec.id}/attachments`, {
      method: "POST",
      body: form,
    });
    assert.equal(uploaded.status, 201);
    const payload = await uploaded.json();
    assert.equal(payload.attachments[0].fileName, "check.csv");

    const blob = await fetch(`${base}${payload.attachments[0].url}`);
    assert.equal(blob.status, 200);
    assert.equal(await blob.text(), "lot,result\nP-22,fail\n");

    const listed = await fetch(`${base}/api/incidents`);
    const rows = await listed.json();
    assert.ok(rows.some((r) => r.id === rec.id));
  });
});
