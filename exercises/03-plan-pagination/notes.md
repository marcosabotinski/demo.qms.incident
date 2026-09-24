# Facilitator notes — pagination pitfalls

These show up in almost every Plan-mode review. Use them as a punch list, not a lecture.

## Off-by-one

- **1-based vs 0-based pages.** Humans want `page=1`. SQL wants `OFFSET 0`. `(page - 1) * pageSize` is the whole feature.
- **Last page.** 21 rows, pageSize 10 → `totalPages = 3`, not 2. `Math.ceil(total / pageSize)`.
- **Next button.** Disable when `page >= totalPages`, not when `items.length === 0` (that also fires on a bad filter).
- **Reset.** If filter changes and you leave `page=3`, you get an empty table and a “bug” report.

## Total count

- `COUNT(*)` must use the **same** `WHERE` as the page query. Counting all incidents while filtering Drafts makes the footer lie.
- Dashboard KPI “Total incidents” today is `rows.length`. After paging, that becomes “page size” unless they read `total`.
- Do not derive `total` from `items.length` on a mid page.

## Sorting with pages

- List is `ORDER BY created_at DESC` today, no secondary key. Two creates in the same second can swap across refreshes. Add `id DESC` (or `id ASC`) as a tie-break.
- Inserts during paging: a new Draft on page 1 can push a row onto page 2. Accept that for offset pagination; do not promise keyset stability in v1.
- Client-side `useMemo` filter **after** a paged fetch only sorts/filters the page. Plans that keep this without saying so will “lose” rows that exist on other pages.
- Changing sort later (title, priority) requires a matching `ORDER BY` and a default. Do not sort in React if the API already pages.

## Contract breakage

- Today’s client does `getIncidents().then(setRows)` on an array. An `{ items, total }` envelope will throw or render nothing if only the API changes.
- `http.test.js` asserts `rows.some(...)` on a parsed array. Update it in the same change.

## Scope creep to shut down

- Infinite scroll
- Virtualized tables
- Replacing SQLite
- Server-side search that ignores indexes on JSON `data` for this lab (filter on columns)

## When a plan is good enough

Query params, envelope, count, sort, inbox controls, Dashboard total, and a test that forces two pages. If those are present, do not nitpick button labels.
