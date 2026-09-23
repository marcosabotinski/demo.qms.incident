import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { getIncidents } from "../api.js";
import { PriorityPill, StatusPill } from "../components/Pills.jsx";

export default function Dashboard() {
  const [rows, setRows] = useState([]);
  const [err, setErr] = useState("");

  useEffect(() => {
    getIncidents().then(setRows).catch((e) => setErr(e.message));
  }, []);

  return (
    <div>
      <div className="page-head">
        <div>
          <h2>Quality incidents</h2>
          <p>Recent quality incidents for the Berlin Lab</p>
        </div>
        <Link className="btn" to="/incidents/new">
          New incident
        </Link>
      </div>
      {err ? <p className="error">{err}</p> : null}
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
            {!rows.length ? (
              <tr>
                <td colSpan={5} className="empty">
                  No quality incidents yet.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}
