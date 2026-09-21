import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { getIncidents } from "../api.js";
import { formatWhen, PriorityPill, StatusPill } from "../components/Pills.jsx";

export default function IncidentList() {
  const [rows, setRows] = useState([]);
  const [q, setQ] = useState("");
  const [status, setStatus] = useState("");
  const [err, setErr] = useState("");

  useEffect(() => {
    getIncidents().then(setRows).catch((e) => setErr(e.message));
  }, []);

  const filtered = useMemo(() => {
    return rows.filter((r) => {
      const hay = `${r.id} ${r.title} ${r.department} ${r.owner || ""}`.toLowerCase();
      if (q && !hay.includes(q.toLowerCase())) return false;
      if (status && r.status !== status) return false;
      return true;
    });
  }, [rows, q, status]);

  const statuses = [...new Set(rows.map((r) => r.status))];

  return (
    <div>
      <div className="page-head">
        <div>
          <h2>Quality incidents</h2>
          <p>Inbox of incidents and quality events. Create a draft for QA review.</p>
        </div>
        <Link className="btn" to="/incidents/new">
          Create incident
        </Link>
      </div>
      {err ? <p className="error">{err}</p> : null}
      <div className="toolbar filters">
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Filter by ID, title, owner…" />
        <select value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">All statuses</option>
          {statuses.map((s) => (
            <option key={s}>{s}</option>
          ))}
        </select>
      </div>
      <div className="card" style={{ padding: 0 }}>
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Title</th>
              <th>Status</th>
              <th>Priority</th>
              <th>Department</th>
              <th>Created</th>
              <th>Owner</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((r) => (
              <tr key={r.id}>
                <td>
                  <Link className="id-link" to={`/incidents/${r.id}`}>
                    {r.id}
                  </Link>
                </td>
                <td>{r.title}</td>
                <td>
                  <StatusPill value={r.status} />
                </td>
                <td>
                  <PriorityPill value={r.priority} />
                </td>
                <td>{r.department}</td>
                <td>{formatWhen(r.createdAt)}</td>
                <td>{r.owner || "Unassigned"}</td>
              </tr>
            ))}
            {!filtered.length ? (
              <tr>
                <td colSpan={7} className="empty">
                  No records match the filter.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}
