# QMS Incident Demo Spec

Mock QMS for a live demo:

> A bot takes a Slack message about a lab incident, drafts the deviation, attaches evidence, and opens the record in the QMS for QA approval.

Use one record type for the demo: **Quality Incident**, which QA can promote to a **Deviation**. That matches how real eQMS tools work (intake first, then quality event).

The bot prefills intake fields from Slack and opens the record in `Draft` for QA.

---

## Demo flow

```
Slack message
  → Bot drafts record
  → Record opens in QMS
  → QA reviews / approves
```

### Suggested lifecycle states

- `Draft`
- `Submitted`
- `Under QA Review`
- `Investigation`
- `CAPA Required`
- `No CAPA`
- `Pending QA Approval`
- `Approved`
- `Closed`
- `Cancelled`
- `Not a Deviation`

Demo start state: **`Draft`**

---

## UI screens to build

1. **Inbox / list**
   - Columns: ID, title, status, priority, department, created, owner
2. **Record view**
   - Sticky header + tabs: `Overview`, `Impact`, `Investigation`, `CAPA`, `Evidence`, `History`
3. **Open-from-bot state**
   - Banner: `Drafted from Slack by Quality Bot · awaiting QA review`
4. **QA actions**
   - `Request more info`
   - `Approve as incident`
   - `Promote to deviation`
   - `Cancel`

---

## 1. Record header (system)

| Field key | Label | Type | Required | Filled by | Example / notes |
|---|---|---|---|---|---|
| `id` | Record ID | string, auto | yes | system | `INC-2026-0142` |
| `recordType` | Record type | enum | yes | system / QA | `Incident`, `Deviation`, `Lab Investigation` |
| `title` | Title | string, max 120 | yes | bot | `Temperature excursion – Incubator IC-12` |
| `status` | Status | enum | yes | system | see lifecycle states |
| `priority` | Priority | enum | yes | bot / QA | `Low`, `Medium`, `High`, `Critical` |
| `severity` | Severity | enum | no | QA | `Minor`, `Major`, `Critical` |
| `sourceChannel` | Source | enum | yes | bot | `Slack`, `Email`, `Manual`, `LIMS`, `Instrument` |
| `sourceRef` | Source reference | string | no | bot | Slack permalink / message ID |
| `createdAt` | Created at | datetime | yes | system | `2026-09-21T08:16:00+02:00` |
| `updatedAt` | Updated at | datetime | yes | system | |
| `dueDate` | Due date | date | no | system | e.g. created + 15 business days |
| `site` | Site / facility | enum | yes | bot | `Berlin Lab` |
| `department` | Department | enum | yes | bot | `Microbiology`, `QC Chemistry`, `Sample Receipt` |
| `area` | Area / room | string | no | bot | `MB-Lab 2 / Room 3.14` |

---

## 2. Intake — bot should fill these

| Field key | Label | Type | Required to open | Filled by | Example |
|---|---|---|---|---|---|
| `occurredAt` | Date/time occurred | datetime | yes | bot | `2026-09-21T08:14:00+02:00` |
| `discoveredAt` | Date/time discovered | datetime | yes | bot | `2026-09-21T08:14:00+02:00` |
| `reportedAt` | Date/time reported | datetime | yes | system | Slack timestamp |
| `reportedByName` | Reported by | string | yes | bot | `Lisa Chen` |
| `reportedByRole` | Reporter role | string | no | bot | `Lab Technician` |
| `reportedByEmail` | Reporter email | string | no | bot | `lisa.chen@lab.example` |
| `owner` | Record owner | user | yes | QA | QA reviewer |
| `summary` | Short description | text, max 280 | yes | bot | One-line event summary |
| `description` | Full description | rich text | yes | bot | What / when / where / who found it |
| `immediateActions` | Immediate actions | rich text | yes | bot | `Samples secured. Incubator taken out of use. QA notified.` |
| `category` | Category | enum | yes | bot | `Equipment`, `Method`, `Sample Handling`, `Reagent`, `Data Integrity`, `Facility`, `Personnel`, `Documentation` |
| `subcategory` | Subcategory | enum | no | bot | depends on category, e.g. `Temperature excursion` |
| `nature` | Nature | enum | yes | bot | `Unplanned`, `Planned` |
| `isRepeat` | Similar event in last 12 months? | boolean | no | QA | `false` |
| `relatedEventIds` | Related events | list of IDs | no | QA | |

### Lab-specific intake

| Field key | Label | Type | Required | Filled by | Example |
|---|---|---|---|---|---|
| `equipmentName` | Equipment | string | no | bot | `Incubator IC-12` |
| `equipmentId` | Equipment ID | string | no | bot | `EQ-INC-0012` |
| `methodName` | Method / assay | string | no | bot | `Microbial enumeration` |
| `sopId` | SOP / procedure | string | no | bot | `SOP-MB-017 v4.2` |
| `processStep` | Process step | string | no | bot | `Incubation` |
| `expectedValue` | Expected / spec | string | no | bot | `37.0 °C ± 1.0` |
| `actualValue` | Actual value | string | no | bot | `39.2 °C` |
| `unit` | Unit | string | no | bot | `°C` |
| `limsSampleIds` | Sample / LIMS IDs | list of strings | no | bot | `S-88421`, `S-88422` |
| `batchLots` | Batches / lots | list of objects | no | bot | see object below |
| `productNames` | Products / materials | list of strings | no | bot | `Product X`, `QC strain E. coli` |
| `reagentLots` | Reagent / media lots | list of strings | no | bot | `TSA-2408-17` |

### `batchLots[]` object

| Field key | Label | Type | Example |
|---|---|---|---|
| `product` | Product | string | `Product X` |
| `batchNo` | Batch / lot no. | string | `MB-24091` |
| `stage` | Stage | enum | `In testing`, `Released`, `Quarantine` |
| `quantity` | Quantity | string | `24 plates` |
| `impactUnknown` | Impact unknown | boolean | `true` |

---

## 3. Classification and impact (QA after open)

| Field key | Label | Type | Required for approval | Filled by | Options / notes |
|---|---|---|---|---|---|
| `classification` | Classification | enum | yes | QA | `Incident only`, `Deviation`, `OOS`, `OOT`, `Nonconformance` |
| `gxpType` | GxP type | enum | no | QA | `GMP`, `GLP`, `GCP`, `ISO 17025`, `IT` |
| `productImpact` | Product / sample impact | enum | yes | QA | `None`, `Possible`, `Confirmed`, `Unknown` |
| `patientSafetyImpact` | Patient safety impact | enum | yes | QA | `None`, `Possible`, `Confirmed`, `N/A` |
| `dataIntegrityImpact` | Data integrity impact | enum | yes | QA | `None`, `Possible`, `Confirmed` |
| `reportabilityImpact` | Reportable result impact | enum | no | QA | `None`, `Hold results`, `Invalidate run`, `Amend report` |
| `regulatoryImpact` | Regulatory impact | enum | no | QA | `None`, `Notify required`, `Unknown` |
| `impactRationale` | Impact rationale | rich text | yes | QA | why the impact rating was chosen |
| `containmentNeeded` | Containment needed | boolean | yes | QA | |
| `containmentActions` | Containment details | rich text | if yes | QA | quarantine, stop testing, inform customer |
| `disposition` | Disposition | enum | later | QA | `Use as is`, `Retest`, `Invalidate`, `Reject`, `Quarantine`, `N/A` |

---

## 4. Investigation

Leave empty in the live demo except a placeholder. Show the section so the record looks real.

| Field key | Label | Type | Required to close | Filled by | Options / notes |
|---|---|---|---|---|---|
| `investigationRequired` | Investigation required | boolean | yes | QA | |
| `investigationOwner` | Investigation owner | user | if yes | QA | |
| `investigationDueDate` | Investigation due | date | if yes | system / QA | |
| `investigationSummary` | Investigation summary | rich text | if yes | QA | |
| `rootCauseMethod` | RCA method | enum | if yes | QA | `5 Whys`, `Fishbone`, `Fault tree`, `Other` |
| `rootCause` | Root cause | rich text | if yes | QA | |
| `rootCauseCategory` | Root cause category | enum | if yes | QA | `Man`, `Machine`, `Method`, `Material`, `Measurement`, `Environment` |
| `contributingFactors` | Contributing factors | list / text | no | QA | |
| `similarEventsReviewed` | Similar events reviewed | boolean + text | no | QA | |

---

## 5. CAPA

| Field key | Label | Type | Required | Filled by | Notes |
|---|---|---|---|---|---|
| `capaRequired` | CAPA required | boolean | yes to close | QA | |
| `capaJustification` | CAPA yes/no justification | text | yes | QA | |
| `capaIds` | Linked CAPA IDs | list of strings | if yes | system | `CAPA-2026-0031` |
| `effectivenessCheckRequired` | Effectiveness check | boolean | if CAPA | QA | |

### Optional child object: `capaActions[]`

| Field key | Label | Type | Example |
|---|---|---|---|
| `id` | Action ID | string | `CA-0142-01` |
| `type` | Type | enum | `Corrective`, `Preventive` |
| `description` | Description | text | `Recalibrate incubator IC-12` |
| `owner` | Owner | user | `Facilities` |
| `dueDate` | Due date | date | `2026-09-28` |
| `status` | Status | enum | `Open`, `In progress`, `Done` |
| `evidence` | Evidence | file / text | calibration certificate |

---

## 6. Evidence / attachments

This is the demo payoff. The bot attaches Slack evidence here.

| Field key | Label | Type | Required | Filled by | Example |
|---|---|---|---|---|---|
| `attachments` | Attachments | file list | no | bot | see object below |
| `attachmentCount` | Attachment count | number | no | system | `3` |

### `attachments[]` object

| Field key | Label | Type | Example |
|---|---|---|---|
| `id` | Attachment ID | string | `ATT-001` |
| `fileName` | File name | string | `incubator-display.jpg` |
| `fileType` | MIME type | string | `image/jpeg`, `application/pdf`, `text/plain` |
| `source` | Source | enum | `Slack`, `Upload`, `LIMS`, `Instrument log` |
| `caption` | Caption | string | `Display reading 39.2 °C at 08:14` |
| `uploadedAt` | Uploaded at | datetime | `2026-09-21T08:16:12+02:00` |
| `uploadedBy` | Uploaded by | string | `Quality Bot` |
| `url` | URL / path | string | demo asset path |

### Seed files for the demo

1. Slack screenshot or exported message
2. Photo of incubator display
3. Temperature log CSV or PDF

---

## 7. Workflow, QA approval, audit

| Field key | Label | Type | Required | Filled by | Example |
|---|---|---|---|---|---|
| `qaReviewer` | QA reviewer | user | yes to approve | QA | `Maria Alvarez` |
| `qaDecision` | QA decision | enum | yes to close | QA | `Approve as incident`, `Promote to deviation`, `Reject / not a quality event`, `Request more info` |
| `qaComments` | QA comments | rich text | no | QA | |
| `approvedAt` | Approved at | datetime | on approve | system | |
| `closedAt` | Closed at | datetime | on close | system | |
| `closureSummary` | Closure summary | rich text | to close | QA | |
| `electronicSignature` | e-signature | object | on approve | QA | name, meaning, timestamp |
| `auditTrail` | Audit trail | event list | always | system | field change / status / attach / comment |

### `electronicSignature` object

| Field key | Label | Type | Example |
|---|---|---|---|
| `signedBy` | Signed by | string | `Maria Alvarez` |
| `meaning` | Meaning | enum | `Reviewed`, `Approved` |
| `signedAt` | Signed at | datetime | `2026-09-21T09:02:00+02:00` |

### `auditTrail[]` object

| Field key | Label | Type | Example |
|---|---|---|---|
| `at` | Timestamp | datetime | `2026-09-21T08:16:00+02:00` |
| `actor` | Actor | string | `Quality Bot` |
| `action` | Action | string | `Created record`, `Attached file`, `Changed status` |
| `from` | Previous value | string | `null` |
| `to` | New value | string | `Draft` |
| `comment` | Comment | string | `Drafted from Slack message` |

---

## 8. Linked records

Show as tabs or related-records chips. Not required for the live demo.

| Field key | Label | Type |
|---|---|---|
| `linkedIncidents` | Linked incidents | list of IDs |
| `linkedDeviations` | Linked deviations | list of IDs |
| `linkedCapas` | Linked CAPAs | list of IDs |
| `linkedSops` | Linked SOPs | list of IDs |
| `linkedEquipment` | Linked equipment | list of IDs |
| `linkedChangeControls` | Change controls | list of IDs |

---

## Minimum fields to open a record (bot output)

Populate only these for the live demo. Everything else can render as empty sections labeled **To be completed by QA**.

- `title`
- `status = Draft`
- `sourceChannel = Slack`
- `sourceRef`
- `occurredAt`
- `discoveredAt`
- `reportedByName`
- `site`
- `department`
- `summary`
- `description`
- `immediateActions`
- `category`
- `nature`
- `equipmentName`
- `equipmentId`
- `expectedValue`
- `actualValue`
- `batchLots` and/or `limsSampleIds`
- `attachments[]`
- `priority` (bot guess; QA can change)

---

## Seed record for the Slack demo

```json
{
  "id": "INC-2026-0142",
  "recordType": "Incident",
  "title": "Temperature excursion – Incubator IC-12",
  "status": "Draft",
  "priority": "High",
  "sourceChannel": "Slack",
  "sourceRef": "https://acme.slack.com/archives/C012LAB/p1758437640000",
  "site": "Berlin Lab",
  "department": "Microbiology",
  "area": "MB-Lab 2",
  "occurredAt": "2026-09-21T08:14:00+02:00",
  "discoveredAt": "2026-09-21T08:14:00+02:00",
  "reportedAt": "2026-09-21T08:14:32+02:00",
  "reportedByName": "Lisa Chen",
  "reportedByRole": "Lab Technician",
  "reportedByEmail": "lisa.chen@lab.example",
  "owner": null,
  "summary": "Incubator IC-12 read 39.2 °C instead of 37.0 °C; two in-process batches affected.",
  "description": "At 08:14 the incubator IC-12 display showed 39.2 °C against a setpoint of 37.0 °C (±1.0). Batches MB-24091 and MB-24092 were in incubation. Photo of the display and the Slack report are attached.",
  "immediateActions": "Samples secured. Incubator taken out of service. QA notified via Slack.",
  "category": "Equipment",
  "subcategory": "Temperature excursion",
  "nature": "Unplanned",
  "isRepeat": false,
  "relatedEventIds": [],
  "equipmentName": "Incubator IC-12",
  "equipmentId": "EQ-INC-0012",
  "methodName": "Microbial enumeration",
  "sopId": "SOP-MB-017 v4.2",
  "processStep": "Incubation",
  "expectedValue": "37.0 ± 1.0",
  "actualValue": "39.2",
  "unit": "°C",
  "limsSampleIds": ["S-88421", "S-88422"],
  "batchLots": [
    {
      "product": "Product X",
      "batchNo": "MB-24091",
      "stage": "In testing",
      "quantity": null,
      "impactUnknown": true
    },
    {
      "product": "Product X",
      "batchNo": "MB-24092",
      "stage": "In testing",
      "quantity": null,
      "impactUnknown": true
    }
  ],
  "productNames": ["Product X"],
  "reagentLots": [],
  "classification": null,
  "gxpType": "GMP",
  "productImpact": null,
  "patientSafetyImpact": null,
  "dataIntegrityImpact": null,
  "reportabilityImpact": null,
  "regulatoryImpact": null,
  "impactRationale": null,
  "containmentNeeded": null,
  "containmentActions": null,
  "disposition": null,
  "investigationRequired": null,
  "investigationOwner": null,
  "investigationDueDate": null,
  "investigationSummary": null,
  "rootCauseMethod": null,
  "rootCause": null,
  "rootCauseCategory": null,
  "contributingFactors": [],
  "similarEventsReviewed": null,
  "capaRequired": null,
  "capaJustification": null,
  "capaIds": [],
  "effectivenessCheckRequired": null,
  "capaActions": [],
  "attachments": [
    {
      "id": "ATT-001",
      "fileName": "slack-message.txt",
      "fileType": "text/plain",
      "source": "Slack",
      "caption": "Original Slack report",
      "uploadedAt": "2026-09-21T08:16:10+02:00",
      "uploadedBy": "Quality Bot",
      "url": "/demo/attachments/slack-message.txt"
    },
    {
      "id": "ATT-002",
      "fileName": "incubator-display.jpg",
      "fileType": "image/jpeg",
      "source": "Slack",
      "caption": "Display reading 39.2 °C",
      "uploadedAt": "2026-09-21T08:16:11+02:00",
      "uploadedBy": "Quality Bot",
      "url": "/demo/attachments/incubator-display.jpg"
    },
    {
      "id": "ATT-003",
      "fileName": "temp-log.csv",
      "fileType": "text/csv",
      "source": "Upload",
      "caption": "Last 24h temperature log",
      "uploadedAt": "2026-09-21T08:16:12+02:00",
      "uploadedBy": "Quality Bot",
      "url": "/demo/attachments/temp-log.csv"
    }
  ],
  "attachmentCount": 3,
  "qaReviewer": null,
  "qaDecision": null,
  "qaComments": null,
  "approvedAt": null,
  "closedAt": null,
  "closureSummary": null,
  "electronicSignature": null,
  "linkedIncidents": [],
  "linkedDeviations": [],
  "linkedCapas": [],
  "linkedSops": ["SOP-MB-017"],
  "linkedEquipment": ["EQ-INC-0012"],
  "linkedChangeControls": [],
  "auditTrail": [
    {
      "at": "2026-09-21T08:16:00+02:00",
      "actor": "Quality Bot",
      "action": "Created record",
      "from": null,
      "to": "Draft",
      "comment": "Drafted from Slack message in #lab-incidents"
    },
    {
      "at": "2026-09-21T08:16:12+02:00",
      "actor": "Quality Bot",
      "action": "Attached files",
      "from": "0",
      "to": "3",
      "comment": "Slack message, display photo, temperature log"
    }
  ]
}
```

---

## Slack source message (demo copy)

**Channel:** `#lab-incidents`  
**From:** Lisa Chen  
**Time:** 21 Sep 2026, 08:14

> Incubator IC-12 shows 39.2 °C instead of 37 °C.  
> Batches MB-24091 and MB-24092 are inside.  
> Photo of the display attached. Taking it out of service now.

---

## Mock users

| Name | Role | Used for |
|---|---|---|
| Lisa Chen | Lab Technician | Slack reporter |
| Quality Bot | System / integration | Creates draft, attaches evidence |
| Maria Alvarez | QA Reviewer | Opens record, classifies, approves |
| Tom Berger | Lab Supervisor | Optional investigation owner |

---

## Implementation notes for Cursor

- This is a **mock UI**, not a validated eQMS. Visual realism matters more than Part 11 completeness.
- Prefill the seed record on first load so the demo can jump straight to the open record.
- Mark bot-filled fields with a small chip: `Filled by bot`.
- Empty QA sections should stay visible with placeholder text: `To be completed by QA`.
- Evidence tab should show thumbnails / file chips immediately. That is the “attaches evidence” moment.
- Header should look like a real QMS record: ID, status pill, priority pill, site, owner.
- Keep the first view scannable. Do not put investigation and CAPA above the fold.
- Suggested visual language: dense enterprise form, not a consumer app. Light gray canvas, white cards, tabular field rows, status pills.
- Optional second list row in the inbox: `DEV-2026-0088` already `Closed`, so the new draft does not look like the only record in the system.
