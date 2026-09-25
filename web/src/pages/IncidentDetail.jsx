import { useEffect, useState } from "react";
import { Link, useParams, useSearchParams } from "react-router-dom";
import { getIncident } from "../api.js";
import { EmptyQA, formatWhen, PriorityPill, StatusPill } from "../components/Pills.jsx";

function Field({ label, children, full }) {
  return (
    <div className={`field ${full ? "full" : ""}`}>
      <label>{label}</label>
      <div className="val">{children ?? <EmptyQA />}</div>
    </div>
  );
}

function val(v) {
  if (v == null || v === "" || (Array.isArray(v) && !v.length)) return <EmptyQA />;
  if (Array.isArray(v)) return v.join(", ");
  if (typeof v === "boolean") return v ? "Yes" : "No";
  return String(v);
}

export default function IncidentDetail() {
  const { id } = useParams();
  const [params] = useSearchParams();
  const allowed = ["Overview", "Impact", "Investigation", "CAPA", "Evidence", "History"];
  const initialTab = allowed.includes(params.get("tab")) ? params.get("tab") : "Overview";
  const [rec, setRec] = useState(null);
  const [tab, setTab] = useState(initialTab);
  const [err, setErr] = useState("");

  useEffect(() => {
    getIncident(id).then(setRec).catch((e) => setErr(e.message));
  }, [id]);

  if (err) return <p className="error">{err}</p>;
  if (!rec) return <p className="muted">Loading record…</p>;

  return (
    <div>
      <div className="page-head">
        <Link className="btn secondary" to="/incidents">
          Back to inbox
        </Link>
        <div className="qa-actions">
          <button className="btn secondary">Request more info</button>
          <button className="btn secondary">Approve as incident</button>
          <button className="btn">Promote to deviation</button>
          <button className="btn secondary">Cancel</button>
        </div>
      </div>

      <div className="record-header">
        <div className="meta">
          <strong>{rec.id}</strong>
          <span className={`pill ${rec.recordType}`}>{rec.recordType}</span>
          <StatusPill value={rec.status} />
          <PriorityPill value={rec.priority} />
        </div>
        <h2>{rec.title}</h2>
        <div className="facts">
          <div>
            Site <strong>{rec.site}</strong>
          </div>
          <div>
            Department <strong>{rec.department}</strong>
          </div>
          <div>
            Owner <strong>{rec.owner || "Unassigned"}</strong>
          </div>
          <div>
            Source <strong>{rec.sourceChannel}</strong>
          </div>
          <div>
            Created <strong>{formatWhen(rec.createdAt || rec.reportedAt)}</strong>
          </div>
        </div>
      </div>

      <div className="tabs">
        {["Overview", "Impact", "Investigation", "CAPA", "Evidence", "History"].map((t) => (
          <button key={t} className={tab === t ? "active" : ""} onClick={() => setTab(t)}>
            {t}
          </button>
        ))}
      </div>

      {tab === "Overview" && (
        <>
          <div className="section">
            <h3>Intake</h3>
            <div className="fields">
              <Field label="Occurred">{formatWhen(rec.occurredAt)}</Field>
              <Field label="Discovered">{formatWhen(rec.discoveredAt)}</Field>
              <Field label="Reported by">
                {rec.reportedByName}
                {rec.reportedByRole ? ` · ${rec.reportedByRole}` : ""}
              </Field>
              <Field label="Category">
                {rec.category}
                {rec.subcategory ? ` / ${rec.subcategory}` : ""}
              </Field>
              <Field label="Nature">{rec.nature}</Field>
              <Field label="Area">{val(rec.area)}</Field>
              <Field label="Summary" full>
                {rec.summary}
              </Field>
              <Field label="Description" full>
                {rec.description}
              </Field>
              <Field label="Immediate actions" full>
                {rec.immediateActions}
              </Field>
            </div>
          </div>
          <div className="section">
            <h3>Lab context</h3>
            <div className="fields">
              <Field label="Equipment">{val(rec.equipmentName)}</Field>
              <Field label="Equipment ID">{val(rec.equipmentId)}</Field>
              <Field label="Expected">{val(rec.expectedValue)}</Field>
              <Field label="Actual">
                {val(rec.actualValue)} {rec.unit || ""}
              </Field>
              <Field label="SOP">{val(rec.sopId)}</Field>
              <Field label="LIMS IDs">{val(rec.limsSampleIds)}</Field>
              <Field label="Batches" full>
                {rec.batchLots?.length
                  ? rec.batchLots.map((b) => `${b.product || "—"} ${b.batchNo} (${b.stage})`).join(" · ")
                  : null}
              </Field>
            </div>
          </div>
        </>
      )}

      {tab === "Impact" && (
        <div className="fields">
          <Field label="Classification">{val(rec.classification)}</Field>
          <Field label="GxP type">{val(rec.gxpType)}</Field>
          <Field label="Product / sample impact">{val(rec.productImpact)}</Field>
          <Field label="Patient safety">{val(rec.patientSafetyImpact)}</Field>
          <Field label="Data integrity">{val(rec.dataIntegrityImpact)}</Field>
          <Field label="Reportability">{val(rec.reportabilityImpact)}</Field>
          <Field label="Impact rationale" full>
            {val(rec.impactRationale)}
          </Field>
          <Field label="Containment needed">{val(rec.containmentNeeded)}</Field>
          <Field label="Containment actions">{val(rec.containmentActions)}</Field>
        </div>
      )}

      {tab === "Investigation" && (
        <div className="fields">
          <Field label="Investigation required">{val(rec.investigationRequired)}</Field>
          <Field label="Owner">{val(rec.investigationOwner)}</Field>
          <Field label="Due">{val(rec.investigationDueDate)}</Field>
          <Field label="RCA method">{val(rec.rootCauseMethod)}</Field>
          <Field label="Summary" full>
            {val(rec.investigationSummary)}
          </Field>
          <Field label="Root cause" full>
            {val(rec.rootCause)}
          </Field>
        </div>
      )}

      {tab === "CAPA" && (
        <div className="fields">
          <Field label="CAPA required">{val(rec.capaRequired)}</Field>
          <Field label="Justification">{val(rec.capaJustification)}</Field>
          <Field label="Linked CAPAs">{val(rec.capaIds)}</Field>
          <Field label="Actions" full>
            {rec.capaActions?.length
              ? rec.capaActions.map((a) => `${a.id} · ${a.type} · ${a.description} (${a.status})`).join(" · ")
              : null}
          </Field>
        </div>
      )}

      {tab === "Evidence" && (
        <div className="files">
          {(rec.attachments || []).map((a) => (
            <a className="file-chip" key={a.id} href={a.url || "#"} target="_blank" rel="noreferrer">
              {a.fileType?.startsWith("image/") && a.url ? (
                <img src={a.url} alt={a.caption} />
              ) : (
                <div className="preview">{a.fileType || "file"}</div>
              )}
              <figcaption>
                <strong>{a.fileName}</strong>
                <span className="muted">
                  {a.source} · {a.caption}
                </span>
              </figcaption>
            </a>
          ))}
          {!rec.attachments?.length ? <div className="empty">No attachments yet.</div> : null}
        </div>
      )}

      {tab === "History" && (
        <table>
          <thead>
            <tr>
              <th>When</th>
              <th>Actor</th>
              <th>Action</th>
              <th>From</th>
              <th>To</th>
              <th>Comment</th>
            </tr>
          </thead>
          <tbody>
            {(rec.auditTrail || []).map((e, i) => (
              <tr key={i}>
                <td>{formatWhen(e.at)}</td>
                <td>{e.actor}</td>
                <td>{e.action}</td>
                <td>{e.from || "—"}</td>
                <td>{e.to || "—"}</td>
                <td>{e.comment || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
