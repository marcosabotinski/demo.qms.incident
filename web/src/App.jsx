import { Navigate, Route, Routes } from "react-router-dom";
import AppShell from "./layout/AppShell.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import IncidentList from "./pages/IncidentList.jsx";
import IncidentCreate from "./pages/IncidentCreate.jsx";
import IncidentDetail from "./pages/IncidentDetail.jsx";

export default function App() {
  return (
    <Routes>
      <Route element={<AppShell />}>
        <Route path="/" element={<Dashboard />} />
        <Route path="/incidents" element={<IncidentList />} />
        <Route path="/incidents/new" element={<IncidentCreate />} />
        <Route path="/incidents/:id" element={<IncidentDetail />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
