import { NavLink, Outlet, useLocation } from "react-router-dom";

const links = [
  { to: "/", label: "Dashboard", end: true },
  { to: "/incidents", label: "Incidents" },
];

function crumb(pathname) {
  if (pathname === "/") return "Home / Dashboard";
  if (pathname.startsWith("/incidents/new")) return "Quality / Incidents / New record";
  if (pathname.startsWith("/incidents/")) return "Quality / Incidents / Record";
  if (pathname.startsWith("/incidents")) return "Quality / Incidents";
  return "Acme Quality";
}

export default function AppShell() {
  const { pathname } = useLocation();
  return (
    <div className="app">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark">AQ</div>
          <div>
            <h1>Acme Quality</h1>
            <p>Berlin Lab</p>
          </div>
        </div>
        <nav className="nav">
          {links.map((l) => (
            <NavLink key={l.to} to={l.to} end={l.end} className={({ isActive }) => (isActive ? "active" : "")}>
              {l.label}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-foot">
          <div className="avatar">MA</div>
          <div>
            <strong>Maria Alvarez</strong>
            <span>QA Reviewer</span>
          </div>
        </div>
      </aside>
      <div className="main">
        <header className="topbar">
          <div className="crumb">
            <strong>Acme Quality</strong> · {crumb(pathname)}
          </div>
          <input className="search" placeholder="Search records, equipment, SOP…" disabled />
        </header>
        <div className="content">
          <Outlet />
        </div>
      </div>
    </div>
  );
}
