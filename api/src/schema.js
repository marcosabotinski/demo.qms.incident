export const ENUMS = {
  recordType: ["Incident", "Deviation", "Lab Investigation"],
  status: [
    "Draft",
    "Submitted",
    "Under QA Review",
    "Investigation",
    "CAPA Required",
    "No CAPA",
    "Pending QA Approval",
    "Approved",
    "Closed",
    "Cancelled",
    "Not a Deviation",
  ],
  priority: ["Low", "Medium", "High", "Critical"],
  severity: ["Minor", "Major", "Critical"],
  sourceChannel: ["Slack", "Email", "Manual", "LIMS", "Instrument"],
  site: ["Berlin Lab"],
  department: ["Microbiology", "QC Chemistry", "Sample Receipt"],
  category: [
    "Equipment",
    "Method",
    "Sample Handling",
    "Reagent",
    "Data Integrity",
    "Facility",
    "Personnel",
    "Documentation",
  ],
  nature: ["Unplanned", "Planned"],
  batchStage: ["In testing", "Released", "Quarantine"],
};

export const CREATE_REQUIRED = ["title", "priority", "description"];

export function listProjection(row) {
  const d = row.data;
  return {
    id: row.id,
    title: row.title,
    status: row.status,
    priority: row.priority,
    department: row.department,
    owner: row.owner,
    createdAt: row.created_at,
    recordType: d.recordType,
    sourceChannel: d.sourceChannel,
    site: d.site,
  };
}
