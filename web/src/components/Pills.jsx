export function StatusPill({ value }) {
  if (!value) return <span className="placeholder">—</span>;
  const cls = value.split(" ")[0];
  return <span className={`pill ${cls}`}>{value}</span>;
}

export function PriorityPill({ value }) {
  return <span className={`pill ${value || ""}`}>{value || "—"}</span>;
}

export function BotChip() {
  return <span className="pill bot">Filled by bot</span>;
}

export function EmptyQA({ text = "To be completed by QA" }) {
  return <span className="placeholder">{text}</span>;
}

export function formatWhen(iso) {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
