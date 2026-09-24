# Reference Plan — paginate the incidents list

Show this **after** attendees publish their own plans. It is a facilitator key, not a starter file to paste into Plan mode at minute zero.

## Problem

`GET /api/incidents` loads every row. The inbox table in `web/src/pages/IncidentList.jsx` renders the entire filtered array. That is fine for four seeds; it will not hold a realistic Berlin Lab inbox.

## Scope

**In**

- Page `GET /api/incidents` with explicit query params
- Return a total count so the UI can render “page x of y”
- Keep sort stable: `created_at DESC`, then `id DESC` as a tie-break
- Inbox controls: page size, previous/next (and/or numbered pages), range text
- Preserve today’s client-side search + status filter **or** document a follow-up if those move server-side (pick one; see Decision)
- Tests for the new query contract
- Empty last page and out-of-range page behavior

**Out**

- Changing create/detail/attachment routes
- Server-side full-text search (unless the plan explicitly moves filter + page together)
- Cursor/keyset pagination (offset is enough for this lab)
- Rewriting Dashboard into a metrics API — but the plan must say what Dashboard does after the list is paged

## Decision (recommended)

Keep **filter client-side only if page size ≥ total** is unacceptable. The honest lab choice:

1. **v1 (this plan):** server pagination of the unfiltered list; search/status remain client-side **on the current page only**, and the UI copy says so — **or**
2. **v1-better:** `q` + `status` become query params applied in SQL/`data` filters **before** `LIMIT`, and the client sends them on every page change.

Prefer **v1-better** if time allows. If a plan keeps client-side filter without warning, mark it incomplete.

Dashboard: either keep `GET /api/incidents` without paging (or `?pageSize=-1` — do not do that) **or** add `GET /api/incidents/stats` later. Recommended for this exercise: Dashboard calls the same paged endpoint with a small `pageSize` for “recent records” and uses `total` for the KPI. Do not silently show KPI = page length.

## API

`GET /api/incidents`

| Query | Default | Rules |
|---|---|---|
| `page` | `1` | 1-based integer ≥ 1 |
| `pageSize` | `20` | Integer; allow `10`, `20`, `50` (reject or clamp others) |
| `status` | (all) | Optional; must be an `ENUMS.status` value |
| `q` | (none) | Optional; case-insensitive match on `id`, `title`, `department`, `owner` |

Response (breaking change from a raw array — call this out):

```json
{
  "items": [ { "id": "INC-2026-0142", "title": "…", "status": "Draft" } ],
  "page": 1,
  "pageSize": 20,
  "total": 4,
  "totalPages": 1
}
```

`items[]` stays a `listProjection` object. Do not embed the full `data` blob.

SQL sketch (not to paste as final code in the lab):

- `WHERE` from `q` / `status` on columns (owner may be null)
- `COUNT(*)` with the **same** WHERE (do not count the unfiltered table)
- `ORDER BY created_at DESC, id DESC`
- `LIMIT pageSize OFFSET (page - 1) * pageSize`

Invalid `page` / `pageSize`: `400` with a clear error. `page` > `totalPages` when `total > 0`: empty `items`, still return `total` (do not clamp without saying so — pick empty page **or** clamp to last page and document it). `total = 0`: `totalPages = 0` or `1` — pick one and test it.

## UI (`IncidentList.jsx`)

- `getIncidents()` in `web/src/api.js` becomes `getIncidents({ page, pageSize, q, status })` and reads `{ items, total, … }`
- Controls below the table: Previous (disabled on page 1), Next (disabled on last page), page-size select, text `Showing 1–4 of 4`
- Changing `q`, `status`, or `pageSize` resets to `page = 1`
- Empty state already exists (“No records match the filter”) — keep it
- Do not paginate the create or detail pages

Optional: `?page=` in the inbox URL so refresh keeps the page. Nice, not required.

## Acceptance checks

1. With only seeds, pageSize 20 → one page, `total === 4` (or current row count), KPI on Dashboard uses `total` not `items.length` if it is updated in the same change.
2. After creating records until `total > pageSize`, page 2 returns the older rows; no duplicate IDs across pages.
3. `ORDER BY created_at DESC` holds across a page boundary (newest row is always index 0 of page 1).
4. Filter `status=Draft` reduces `total`; page math uses the filtered count.
5. `GET /api/incidents?page=0` or `pageSize=0` → 400.
6. Existing tests that assume a JSON **array** (`http.test.js` “lists seeded incidents”) are updated to the envelope.
7. Attachments and `GET /api/incidents/:id` unchanged.

## Implementation notes (for the later Agent pass)

- Touch `api/src/index.js`, `web/src/api.js`, `IncidentList.jsx`, likely `Dashboard.jsx`, `api/src/http.test.js`
- Do not add pagination helpers under `exercises/`
- Do not implement this plan during Ex 03 unless the facilitator opens Agent mode
