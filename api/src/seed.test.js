import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { allSeedRecords, generateVolumeRecords, seedRecords, TARGET_SEED_COUNT } from "./seed.js";

const FEATURED_IDS = ["DEV-2026-0088", "INC-2026-0131", "INC-2026-0138", "INC-2026-0142"];

describe("seed catalog", () => {
  it("keeps the four featured walkthrough records", () => {
    assert.equal(seedRecords.length, 4);
    assert.deepEqual(seedRecords.map((r) => r.id), [
      "INC-2026-0142",
      "DEV-2026-0088",
      "INC-2026-0138",
      "INC-2026-0131",
    ]);
    assert.equal(seedRecords[0].attachments.length, 3);
  });

  it("builds about 500 unique incidents including the featured set", () => {
    assert.ok(TARGET_SEED_COUNT >= 480 && TARGET_SEED_COUNT <= 520);
    assert.equal(allSeedRecords.length, TARGET_SEED_COUNT);
    const ids = allSeedRecords.map((r) => r.id);
    assert.equal(new Set(ids).size, ids.length);
    for (const id of FEATURED_IDS) {
      assert.ok(ids.includes(id));
    }
  });

  it("does not consume the post-reset incident id sequence", () => {
    const year = new Date().getFullYear();
    const blocked = allSeedRecords.filter((r) => {
      const match = r.id.match(/^(?:INC|DEV)-(\d{4})-(\d{4})$/);
      return match && Number(match[1]) === year && Number(match[2]) >= 143;
    });
    assert.deepEqual(blocked, []);
  });

  it("generates volume rows deterministically with varied fields", () => {
    const first = generateVolumeRecords();
    const second = generateVolumeRecords();
    assert.equal(first.length, TARGET_SEED_COUNT - seedRecords.length);
    assert.deepEqual(
      first.map((r) => r.id),
      second.map((r) => r.id)
    );
    const statuses = new Set(first.map((r) => r.status));
    const priorities = new Set(first.map((r) => r.priority));
    const departments = new Set(first.map((r) => r.department));
    const categories = new Set(first.map((r) => r.category));
    assert.ok(statuses.size >= 5);
    assert.ok(priorities.size >= 3);
    assert.ok(departments.size >= 3);
    assert.ok(categories.size >= 5);
  });
});
