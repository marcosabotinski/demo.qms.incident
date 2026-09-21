import { Navigate, Route, Routes } from "react-router-dom";
import AppShell from "./layout/AppShell.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import IncidentList from "./pages/IncidentList.jsx";
import IncidentCreate from "./pages/IncidentCreate.jsx";
import IncidentDetail from "./pages/IncidentDetail.jsx";
import Placeholder from "./pages/Placeholder.jsx";

export default function App() {
  return (
    <Routes>
      <Route element={<AppShell />}>
        <Route path="/" element={<Dashboard />} />
        <Route path="/incidents" element={<IncidentList />} />
        <Route path="/incidents/new" element={<IncidentCreate />} />
        <Route path="/incidents/:id" element={<IncidentDetail />} />
        <Route
          path="/deviations"
          element={<Placeholder title="Deviations" note="Promote from a quality incident after QA review." />}
        />
        <Route
          path="/capa"
          element={<Placeholder title="CAPA" note="Corrective and preventive actions are linked from closed events." />}
        />
        <Route
          path="/documents"
          element={<Placeholder title="Documents" note="SOPs and protocols appear as linked records on an incident." />}
        />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
