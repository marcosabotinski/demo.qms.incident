import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { getIncidents } from "../api.js";
import { PriorityPill, StatusPill } from "../components/Pills.jsx";

const OPEN = new Set([
  "Draft",
  "Submitted",
  "Under QA Review",
  "Investigation",
  "CAPA Required",
  "No CAPA",
  "Pending QA Approval",
]);

export default function Dashboard() {
  const [rows, setRows] = useState([]);
  const [err, setErr] = useState("");

  useEffect(() => {
    getIncidents().then(setRows).catch((e) => setErr(e.message));
  }, []);

  const stats = useMemo(() => {
    const open = rows.filter((r) => OPEN.has(r.status));
    const drafts = rows.filter((r) => r.status === "Draft");
    const high = rows.filter((r) => r.priority === "High" || r.priority === "Critical");
    const closed = rows.filter((r) => r.status === "Closed");
    const byDept = {};
    for (const r of rows) byDept[r.department] = (byDept[r.department] || 0) + 1;
    return { open: open.length, drafts: drafts.length, high: high.length, closed: closed.length, byDept };
  }, [rows]);

  const maxDept = Math.max(1, ...Object.values(stats.byDept));

  return (
    <div>
      <div className="page-head">
        <div>
          <h2>Quality dashboard</h2>
          <p>Berlin Lab · live intake for quality incidents and deviations</p>
        </div>
        <Link className="btn" to="/incidents/new">
          New incident
        </Link>
      </div>
      {err ? <p className="error">{err}</p> : null}
      <div className="kpis">
        <div className="kpi">
          <div className="label">Open records</div>
          <div className="value">{stats.open}</div>
          <div className="hint">Across incidents and deviations</div>
        </div>
        <div className="kpi">
          <div className="label">Draft / awaiting QA</div>
          <div className="value">{stats.drafts}</div>
          <div className="hint">Includes Slack bot intake</div>
        </div>
        <div className="kpi">
          <div className="label">High / critical</div>
          <div className="value">{stats.high}</div>
          <div className="hint">Priority queue</div>
        </div>
        <div className="kpi">
          <div className="label">Closed</div>
          <div className="value">{stats.closed}</div>
          <div className="hint">Demo year to date</div>
        </div>
      </div>
      <div className="grid-2">
        <div className="card">
          <h3>Recent records</h3>
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Title</th>
                <th>Status</th>
                <th>Priority</th>
                <th>Owner</th>
              </tr>
            </thead>
            <tbody>
              {rows.slice(0, 6).map((r) => (
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
                  <td>{r.owner || "Unassigned"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="card">
          <h3>By department</h3>
          <div className="bars">
            {Object.entries(stats.byDept).map(([name, n]) => (
              <div className="bar-row" key={name}>
                <span>{name}</span>
                <div className="bar">
                  <span style={{ width: `${(n / maxDept) * 100}%` }} />
                </div>
                <strong>{n}</strong>
              </div>
            ))}
          </div>
          <p className="muted" style={{ marginTop: 16, fontSize: 12 }}>
            Dummy operational mix for the Berlin Lab demo. Investigation and CAPA modules remain read-only.
          </p>
        </div>
      </div>
    </div>
  );
}
