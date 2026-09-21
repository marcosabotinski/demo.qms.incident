const base = "";

export async function api(path, options = {}) {
  const res = await fetch(`${base}${path}`, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) {
    const err = new Error(data?.error || res.statusText);
    err.payload = data;
    throw err;
  }
  return data;
}

export const getIncidents = () => api("/api/incidents");
export const getIncident = (id) => api(`/api/incidents/${encodeURIComponent(id)}`);
export const createIncident = (body) =>
  api("/api/incidents", { method: "POST", body: JSON.stringify(body) });
export const getMeta = () => api("/api/meta");

export async function uploadAttachments(id, items) {
  const fd = new FormData();
  for (const it of items) {
    // Keep captions and files in the same order so the server can align them.
    fd.append("captions", it.caption || "");
    fd.append("files", it.file, it.file.name);
  }
  const res = await fetch(`/api/incidents/${encodeURIComponent(id)}/attachments`, {
    method: "POST",
    body: fd,
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) {
    const err = new Error(data?.error || res.statusText);
    err.payload = data;
    throw err;
  }
  return data;
}
