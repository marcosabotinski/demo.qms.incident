import express from "express";
import cors from "cors";
import multer from "multer";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { getDb, initSchema, nextIncidentId, query, resolveDbPath, seedIfEmpty } from "./db.js";
import { CREATE_REQUIRED, ENUMS, listProjection } from "./schema.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const __filename = fileURLToPath(import.meta.url);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024, files: 10 },
});

function emptyRecord() {
  return {
    recordType: "Incident",
    severity: null,
    sourceRef: null,
    area: null,
    reportedByRole: null,
    reportedByEmail: null,
    owner: null,
    subcategory: null,
    isRepeat: false,
    relatedEventIds: [],
    equipmentName: null,
    equipmentId: null,
    methodName: null,
    sopId: null,
    processStep: null,
    expectedValue: null,
    actualValue: null,
    unit: null,
    limsSampleIds: [],
    batchLots: [],
    productNames: [],
    reagentLots: [],
    classification: null,
    gxpType: null,
    productImpact: null,
    patientSafetyImpact: null,
    dataIntegrityImpact: null,
    reportabilityImpact: null,
    regulatoryImpact: null,
    impactRationale: null,
    containmentNeeded: null,
    containmentActions: null,
    disposition: null,
    investigationRequired: null,
    investigationOwner: null,
    investigationDueDate: null,
    investigationSummary: null,
    rootCauseMethod: null,
    rootCause: null,
    rootCauseCategory: null,
    contributingFactors: [],
    similarEventsReviewed: null,
    capaRequired: null,
    capaJustification: null,
    capaIds: [],
    effectivenessCheckRequired: null,
    capaActions: [],
    attachments: [],
    attachmentCount: 0,
    qaReviewer: null,
    qaDecision: null,
    qaComments: null,
    approvedAt: null,
    closedAt: null,
    closureSummary: null,
    electronicSignature: null,
    linkedIncidents: [],
    linkedDeviations: [],
    linkedCapas: [],
    linkedSops: [],
    linkedEquipment: [],
    linkedChangeControls: [],
    draftedFromSlack: false,
    auditTrail: [],
  };
}

function dueDateFrom(createdAt) {
  const d = new Date(createdAt);
  let added = 0;
  while (added < 15) {
    d.setDate(d.getDate() + 1);
    const day = d.getDay();
    if (day !== 0 && day !== 6) added += 1;
  }
  return d.toISOString().slice(0, 10);
}

export function createApp() {
  const app = express();
  app.use(cors());
  app.use(express.json({ limit: "2mb" }));
  app.use("/demo/attachments", express.static(path.join(__dirname, "../attachments")));

  app.get("/api/health", (_req, res) => {
    try {
      query("SELECT 1 AS ok");
      res.json({ ok: true, sqlite: resolveDbPath() });
    } catch {
      res.status(503).json({ ok: false });
    }
  });

  app.get("/api/meta", (_req, res) => {
    res.json({
      enums: ENUMS,
      currentUser: { name: "Maria Alvarez", role: "QA Reviewer" },
    });
  });

  app.get("/api/incidents", (_req, res) => {
    const { rows } = query(
      "SELECT id, title, status, priority, department, owner, created_at, data FROM incidents ORDER BY created_at DESC"
    );
    res.json(rows.map(listProjection));
  });

  app.get("/api/incidents/:id", (req, res) => {
    const { rows } = query("SELECT id, created_at, updated_at, data FROM incidents WHERE id = ?", [
      req.params.id,
    ]);
    if (!rows[0]) return res.status(404).json({ error: "Not found" });
    res.json({
      ...rows[0].data,
      id: rows[0].id,
      createdAt: rows[0].created_at,
      updatedAt: rows[0].updated_at,
    });
  });

  app.post("/api/incidents/:id/attachments", upload.array("files", 10), (req, res) => {
    const { rows } = query("SELECT data FROM incidents WHERE id = ?", [req.params.id]);
    if (!rows[0]) return res.status(404).json({ error: "Not found" });

    const files = req.files ?? [];
    if (!files.length) return res.status(400).json({ error: "No files uploaded" });

    const data = rows[0].data;
    const existing = Array.isArray(data.attachments) ? data.attachments : [];
    const captions = [].concat(req.body.captions ?? []);
    const now = new Date().toISOString();

    const added = [];
    let n = existing.length;
    const insertBlob = getDb().prepare(
      `INSERT INTO attachment_blobs (incident_id, att_id, file_name, file_type, byte_size, content)
       VALUES (?, ?, ?, ?, ?, ?)`
    );
    for (let i = 0; i < files.length; i++) {
      const f = files[i];
      n += 1;
      const attId = `ATT-${String(n).padStart(3, "0")}`;
      const fileType = f.mimetype || "application/octet-stream";
      insertBlob.run(req.params.id, attId, f.originalname, fileType, f.size, f.buffer);
      added.push({
        id: attId,
        fileName: f.originalname,
        fileType,
        byteSize: f.size,
        source: "Upload",
        caption: captions[i] || "",
        uploadedAt: now,
        uploadedBy: data.reportedByName || "Uploader",
        url: `/api/incidents/${req.params.id}/attachments/${attId}`,
      });
    }

    const attachments = [...existing, ...added];
    const updated = {
      ...data,
      attachments,
      attachmentCount: attachments.length,
      updatedAt: now,
      auditTrail: [
        ...(Array.isArray(data.auditTrail) ? data.auditTrail : []),
        {
          at: now,
          actor: data.reportedByName || "Uploader",
          action: "Attached files",
          from: String(existing.length),
          to: String(attachments.length),
          comment: files.map((f) => f.originalname).join(", "),
        },
      ],
    };

    query("UPDATE incidents SET data = ?, updated_at = ? WHERE id = ?", [
      JSON.stringify(updated),
      now,
      req.params.id,
    ]);

    res.status(201).json({ attachments });
  });

  app.get("/api/incidents/:id/attachments/:attId", (req, res) => {
    const row = getDb()
      .prepare(
        "SELECT file_name, file_type, content FROM attachment_blobs WHERE incident_id = ? AND att_id = ?"
      )
      .get(req.params.id, req.params.attId);
    if (!row) return res.status(404).json({ error: "Not found" });
    const safeName = String(row.file_name).replace(/["\\\r\n]/g, "");
    res.setHeader("Content-Type", row.file_type || "application/octet-stream");
    res.setHeader("Content-Disposition", `inline; filename="${safeName}"`);
    res.send(row.content);
  });

  app.post("/api/incidents", (req, res) => {
    const body = req.body ?? {};
    const missing = CREATE_REQUIRED.filter((k) => !String(body[k] ?? "").trim());
    if (missing.length) {
      return res.status(400).json({ error: "Missing required fields", missing });
    }
    if (String(body.title).length > 120) {
      return res.status(400).json({ error: "Title must be 120 characters or fewer" });
    }
    const summary = String(body.summary ?? "").trim();
    if (summary.length > 280) {
      return res.status(400).json({ error: "Summary must be 280 characters or fewer" });
    }

    const now = new Date().toISOString();
    const id = nextIncidentId();
    const attachments = Array.isArray(body.attachments)
      ? body.attachments
          .filter((a) => a?.fileName)
          .map((a, i) => ({
            id: `ATT-${String(i + 1).padStart(3, "0")}`,
            fileName: a.fileName,
            fileType: a.fileType || "application/octet-stream",
            source: a.source || "Upload",
            caption: a.caption || "",
            uploadedAt: now,
            uploadedBy: body.reportedByName,
            url: a.url || null,
          }))
      : [];

    const limsSampleIds = Array.isArray(body.limsSampleIds)
      ? body.limsSampleIds.filter(Boolean)
      : String(body.limsSampleIds ?? "")
          .split(",")
          .map((s) => s.trim())
          .filter(Boolean);

    const batchLots = Array.isArray(body.batchLots)
      ? body.batchLots.filter((b) => b?.batchNo || b?.product)
      : [];

    const record = {
      ...emptyRecord(),
      id,
      recordType: "Incident",
      title: body.title.trim(),
      status: "Draft",
      priority: body.priority,
      sourceChannel: body.sourceChannel || "Manual",
      sourceRef: body.sourceRef || null,
      createdAt: now,
      updatedAt: now,
      dueDate: dueDateFrom(now),
      site: body.site || "Berlin Lab",
      department: body.department || "Microbiology",
      area: body.area || null,
      occurredAt: body.occurredAt || now,
      discoveredAt: body.discoveredAt || now,
      reportedAt: now,
      reportedByName: body.reportedByName || "Maria Alvarez",
      reportedByRole: body.reportedByRole || null,
      reportedByEmail: body.reportedByEmail || null,
      owner: body.owner || "Maria Alvarez",
      summary: summary || String(body.description).trim().slice(0, 280),
      description: body.description,
      immediateActions: body.immediateActions || null,
      category: body.category || null,
      subcategory: body.subcategory || null,
      nature: body.nature,
      equipmentName: body.equipmentName || null,
      equipmentId: body.equipmentId || null,
      methodName: body.methodName || null,
      sopId: body.sopId || null,
      processStep: body.processStep || null,
      expectedValue: body.expectedValue || null,
      actualValue: body.actualValue || null,
      unit: body.unit || null,
      limsSampleIds,
      batchLots,
      attachments,
      attachmentCount: attachments.length,
      draftedFromSlack: body.sourceChannel === "Slack",
      linkedEquipment: body.equipmentId ? [body.equipmentId] : [],
      linkedSops: body.sopId ? [body.sopId] : [],
      auditTrail: [
        {
          at: now,
          actor: body.reportedByName || "Maria Alvarez",
          action: "Created record",
          from: null,
          to: "Draft",
          comment: body.sourceChannel === "Slack" ? "Drafted from Slack" : "Manual intake",
        },
      ],
    };

    query(
      `INSERT INTO incidents (id, title, status, priority, department, owner, created_at, updated_at, data)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        record.title,
        record.status,
        record.priority,
        record.department,
        record.owner,
        now,
        now,
        JSON.stringify(record),
      ]
    );

    res.status(201).json(record);
  });

  return app;
}

function main() {
  initSchema();
  seedIfEmpty();
  const port = Number(process.env.PORT || 4000);
  createApp().listen(port, "0.0.0.0", () => {
    console.log(`QMS API listening on ${port}`);
    console.log(`SQLite ${resolveDbPath()}`);
  });
}

const isMain = process.argv[1] && path.resolve(process.argv[1]) === __filename;
if (isMain) {
  try {
    main();
  } catch (err) {
    console.error("Failed to initialize database", err);
    process.exit(1);
  }
}
