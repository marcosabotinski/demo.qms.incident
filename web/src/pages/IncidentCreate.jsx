import { useEffect, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { createIncident, getMeta, uploadAttachments } from "../api.js";

function formatBytes(n) {
  if (!n && n !== 0) return "";
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / (1024 * 1024)).toFixed(1)} MB`;
}

function localNow() {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

const emptyBatch = () => ({ product: "", batchNo: "", stage: "In testing", quantity: "", impactUnknown: true });

function initialForm() {
  const now = localNow();
  return {
    title: "",
    priority: "Medium",
    sourceChannel: "Manual",
    sourceRef: "",
    site: "Berlin Lab",
    department: "Microbiology",
    area: "",
    occurredAt: now,
    discoveredAt: now,
    reportedByName: "",
    reportedByRole: "",
    reportedByEmail: "",
    summary: "",
    description: "",
    immediateActions: "",
    category: "Equipment",
    subcategory: "",
    nature: "Unplanned",
    equipmentName: "",
    equipmentId: "",
    methodName: "",
    sopId: "",
    processStep: "",
    expectedValue: "",
    actualValue: "",
    unit: "",
    limsSampleIds: "",
    batchLots: [emptyBatch()],
  };
}

export default function IncidentCreate() {
  const nav = useNavigate();
  const fileInputRef = useRef(null);
  const [enums, setEnums] = useState(null);
  const [form, setForm] = useState(initialForm);
  const [files, setFiles] = useState([]);
  const [err, setErr] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    getMeta().then((m) => setEnums(m.enums));
  }, []);

  function set(key, value) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  function setBatch(i, key, value) {
    setForm((f) => ({
      ...f,
      batchLots: f.batchLots.map((b, idx) => (idx === i ? { ...b, [key]: value } : b)),
    }));
  }

  function addFiles(fileList) {
    const picked = Array.from(fileList || []).map((file) => ({ file, caption: "" }));
    if (picked.length) setFiles((prev) => [...prev, ...picked]);
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  async function onSubmit(e) {
    e.preventDefault();
    setErr("");
    setSaving(true);
    try {
      const payload = {
        ...form,
        occurredAt: form.occurredAt ? new Date(form.occurredAt).toISOString() : "",
        discoveredAt: form.discoveredAt ? new Date(form.discoveredAt).toISOString() : "",
        limsSampleIds: form.limsSampleIds,
        batchLots: form.batchLots.filter((b) => b.batchNo || b.product),
      };
      const rec = await createIncident(payload);
      if (files.length) {
        await uploadAttachments(rec.id, files);
      }
      nav(files.length ? `/incidents/${rec.id}?tab=Evidence` : `/incidents/${rec.id}`);
    } catch (ex) {
      const extra = ex.payload?.missing?.length ? ` (${ex.payload.missing.join(", ")})` : "";
      setErr(`${ex.message}${extra}`);
    } finally {
      setSaving(false);
    }
  }

  return (
    <form className="form" onSubmit={onSubmit}>
      <div className="page-head">
        <div>
          <h2>Create quality incident</h2>
          <p>Opens a Draft record for QA. Investigation, impact, and CAPA stay empty until review.</p>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <Link className="btn secondary" to="/incidents">
            Cancel
          </Link>
          <button className="btn" disabled={saving}>
            {saving ? "Saving…" : "Open as draft"}
          </button>
        </div>
      </div>
      {err ? <p className="error">{err}</p> : null}

      <section className="form-card">
        <h3>Record header</h3>
        <div className="form-grid">
          <label className="control full">
            <span>Title *</span>
            <input maxLength={120} value={form.title} onChange={(e) => set("title", e.target.value)} required />
          </label>
          <label className="control">
            <span>Priority *</span>
            <select value={form.priority} onChange={(e) => set("priority", e.target.value)} required>
              {(enums?.priority || []).map((v) => (
                <option key={v}>{v}</option>
              ))}
            </select>
          </label>
          <label className="control">
            <span>Source</span>
            <select value={form.sourceChannel} onChange={(e) => set("sourceChannel", e.target.value)}>
              {(enums?.sourceChannel || []).map((v) => (
                <option key={v}>{v}</option>
              ))}
            </select>
          </label>
          <label className="control">
            <span>Source reference</span>
            <input value={form.sourceRef} onChange={(e) => set("sourceRef", e.target.value)} />
          </label>
          <label className="control">
            <span>Site</span>
            <select value={form.site} onChange={(e) => set("site", e.target.value)}>
              {(enums?.site || []).map((v) => (
                <option key={v}>{v}</option>
              ))}
            </select>
          </label>
          <label className="control">
            <span>Department</span>
            <select value={form.department} onChange={(e) => set("department", e.target.value)}>
              {(enums?.department || []).map((v) => (
                <option key={v}>{v}</option>
              ))}
            </select>
          </label>
          <label className="control">
            <span>Area / room</span>
            <input value={form.area} onChange={(e) => set("area", e.target.value)} />
          </label>
        </div>
      </section>

      <section className="form-card">
        <h3>Intake</h3>
        <div className="form-grid">
          <label className="control">
            <span>Occurred</span>
            <input type="datetime-local" value={form.occurredAt} onChange={(e) => set("occurredAt", e.target.value)} />
          </label>
          <label className="control">
            <span>Discovered</span>
            <input type="datetime-local" value={form.discoveredAt} onChange={(e) => set("discoveredAt", e.target.value)} />
          </label>
          <label className="control">
            <span>Reported by</span>
            <input value={form.reportedByName} onChange={(e) => set("reportedByName", e.target.value)} />
          </label>
          <label className="control">
            <span>Reporter role</span>
            <input value={form.reportedByRole} onChange={(e) => set("reportedByRole", e.target.value)} />
          </label>
          <label className="control full">
            <span>Summary <em className="muted">(max 280)</em></span>
            <input maxLength={280} value={form.summary} onChange={(e) => set("summary", e.target.value)} />
          </label>
          <label className="control full">
            <span>Description *</span>
            <textarea value={form.description} onChange={(e) => set("description", e.target.value)} required />
          </label>
          <label className="control full">
            <span>Immediate actions</span>
            <textarea value={form.immediateActions} onChange={(e) => set("immediateActions", e.target.value)} />
          </label>
          <label className="control">
            <span>Category</span>
            <select value={form.category} onChange={(e) => set("category", e.target.value)}>
              {(enums?.category || []).map((v) => (
                <option key={v}>{v}</option>
              ))}
            </select>
          </label>
          <label className="control">
            <span>Subcategory</span>
            <input value={form.subcategory} onChange={(e) => set("subcategory", e.target.value)} />
          </label>
          <label className="control">
            <span>Nature</span>
            <select value={form.nature} onChange={(e) => set("nature", e.target.value)}>
              {(enums?.nature || []).map((v) => (
                <option key={v}>{v}</option>
              ))}
            </select>
          </label>
        </div>
      </section>

      <section className="form-card">
        <h3>Lab context</h3>
        <div className="form-grid">
          <label className="control">
            <span>Equipment</span>
            <input value={form.equipmentName} onChange={(e) => set("equipmentName", e.target.value)} />
          </label>
          <label className="control">
            <span>Equipment ID</span>
            <input value={form.equipmentId} onChange={(e) => set("equipmentId", e.target.value)} />
          </label>
          <label className="control">
            <span>Expected / spec</span>
            <input value={form.expectedValue} onChange={(e) => set("expectedValue", e.target.value)} />
          </label>
          <label className="control">
            <span>Actual value</span>
            <input value={form.actualValue} onChange={(e) => set("actualValue", e.target.value)} />
          </label>
          <label className="control">
            <span>Unit</span>
            <input value={form.unit} onChange={(e) => set("unit", e.target.value)} />
          </label>
          <label className="control">
            <span>SOP / procedure</span>
            <input value={form.sopId} onChange={(e) => set("sopId", e.target.value)} />
          </label>
          <label className="control full">
            <span>LIMS sample IDs</span>
            <input
              placeholder="S-88421, S-88422"
              value={form.limsSampleIds}
              onChange={(e) => set("limsSampleIds", e.target.value)}
            />
          </label>
        </div>
        <p style={{ fontSize: 12, fontWeight: 650, margin: "14px 0 8px" }}>Affected batches</p>
        {form.batchLots.map((b, i) => (
          <div className="batch-row" key={i}>
            <input placeholder="Product" value={b.product} onChange={(e) => setBatch(i, "product", e.target.value)} />
            <input placeholder="Batch no." value={b.batchNo} onChange={(e) => setBatch(i, "batchNo", e.target.value)} />
            <select value={b.stage} onChange={(e) => setBatch(i, "stage", e.target.value)}>
              {(enums?.batchStage || ["In testing"]).map((v) => (
                <option key={v}>{v}</option>
              ))}
            </select>
            <input placeholder="Qty" value={b.quantity} onChange={(e) => setBatch(i, "quantity", e.target.value)} />
            <button
              type="button"
              className="btn secondary"
              onClick={() => setForm((f) => ({ ...f, batchLots: f.batchLots.filter((_, idx) => idx !== i) }))}
            >
              Remove
            </button>
          </div>
        ))}
        <button type="button" className="btn secondary" onClick={() => setForm((f) => ({ ...f, batchLots: [...f.batchLots, emptyBatch()] }))}>
          Add batch
        </button>
      </section>

      <section className="form-card">
        <h3>Evidence</h3>
        <p className="muted" style={{ marginTop: 0, fontSize: 13 }}>
          Choose files from disk. They are stored with the incident and shown on the Evidence tab.
        </p>
        <input
          ref={fileInputRef}
          type="file"
          multiple
          className="file-input"
          onChange={(e) => addFiles(e.target.files)}
        />
        <button type="button" className="btn secondary" onClick={() => fileInputRef.current?.click()}>
          Choose files
        </button>
        {files.length ? (
          <ul className="file-list">
            {files.map((item, i) => (
              <li key={`${item.file.name}-${i}`}>
                <div>
                  <strong>{item.file.name}</strong>
                  <span className="muted">
                    {item.file.type || "file"} · {formatBytes(item.file.size)}
                  </span>
                </div>
                <input
                  placeholder="Caption (optional)"
                  value={item.caption}
                  onChange={(e) =>
                    setFiles((prev) => prev.map((x, idx) => (idx === i ? { ...x, caption: e.target.value } : x)))
                  }
                />
                <button
                  type="button"
                  className="btn secondary"
                  onClick={() => setFiles((prev) => prev.filter((_, idx) => idx !== i))}
                >
                  Remove
                </button>
              </li>
            ))}
          </ul>
        ) : (
          <p className="muted" style={{ marginBottom: 0 }}>No files selected.</p>
        )}
      </section>
    </form>
  );
}
