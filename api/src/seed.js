import { ENUMS } from "./schema.js";

export const TARGET_SEED_COUNT = 500;

export const seedRecords = [
  {
    id: "INC-2026-0142",
    recordType: "Incident",
    title: "Temperature excursion – Incubator IC-12",
    status: "Draft",
    priority: "High",
    sourceChannel: "Slack",
    sourceRef: "https://acme.slack.com/archives/C012LAB/p1758437640000",
    site: "Berlin Lab",
    department: "Microbiology",
    area: "MB-Lab 2",
    occurredAt: "2026-09-21T08:14:00+02:00",
    discoveredAt: "2026-09-21T08:14:00+02:00",
    reportedAt: "2026-09-21T08:14:32+02:00",
    reportedByName: "Lisa Chen",
    reportedByRole: "Lab Technician",
    reportedByEmail: "lisa.chen@lab.example",
    owner: null,
    summary:
      "Incubator IC-12 read 39.2 °C instead of 37.0 °C; two in-process batches affected.",
    description:
      "At 08:14 the incubator IC-12 display showed 39.2 °C against a setpoint of 37.0 °C (±1.0). Batches MB-24091 and MB-24092 were in incubation. Photo of the display and the Slack report are attached.",
    immediateActions:
      "Samples secured. Incubator taken out of service. QA notified via Slack.",
    category: "Equipment",
    subcategory: "Temperature excursion",
    nature: "Unplanned",
    isRepeat: false,
    relatedEventIds: [],
    equipmentName: "Incubator IC-12",
    equipmentId: "EQ-INC-0012",
    methodName: "Microbial enumeration",
    sopId: "SOP-MB-017 v4.2",
    processStep: "Incubation",
    expectedValue: "37.0 ± 1.0",
    actualValue: "39.2",
    unit: "°C",
    limsSampleIds: ["S-88421", "S-88422"],
    batchLots: [
      {
        product: "Product X",
        batchNo: "MB-24091",
        stage: "In testing",
        quantity: null,
        impactUnknown: true,
      },
      {
        product: "Product X",
        batchNo: "MB-24092",
        stage: "In testing",
        quantity: null,
        impactUnknown: true,
      },
    ],
    productNames: ["Product X"],
    reagentLots: [],
    classification: null,
    gxpType: "GMP",
    productImpact: null,
    patientSafetyImpact: null,
    dataIntegrityImpact: null,
    reportabilityImpact: null,
    regulatoryImpact: null,
    impactRationale: null,
    containmentNeeded: null,
    containmentActions: null,
    disposition: null,
    investigationRequired: null,
    investigationOwner: null,
    investigationDueDate: null,
    investigationSummary: null,
    rootCauseMethod: null,
    rootCause: null,
    rootCauseCategory: null,
    contributingFactors: [],
    similarEventsReviewed: null,
    capaRequired: null,
    capaJustification: null,
    capaIds: [],
    effectivenessCheckRequired: null,
    capaActions: [],
    attachments: [
      {
        id: "ATT-001",
        fileName: "slack-message.txt",
        fileType: "text/plain",
        source: "Slack",
        caption: "Original Slack report",
        uploadedAt: "2026-09-21T08:16:10+02:00",
        uploadedBy: "Quality Bot",
        url: "/demo/attachments/slack-message.txt",
      },
      {
        id: "ATT-002",
        fileName: "incubator-display.svg",
        fileType: "image/svg+xml",
        source: "Slack",
        caption: "Display reading 39.2 °C",
        uploadedAt: "2026-09-21T08:16:11+02:00",
        uploadedBy: "Quality Bot",
        url: "/demo/attachments/incubator-display.svg",
      },
      {
        id: "ATT-003",
        fileName: "temp-log.csv",
        fileType: "text/csv",
        source: "Upload",
        caption: "Last 24h temperature log",
        uploadedAt: "2026-09-21T08:16:12+02:00",
        uploadedBy: "Quality Bot",
        url: "/demo/attachments/temp-log.csv",
      },
    ],
    attachmentCount: 3,
    qaReviewer: null,
    qaDecision: null,
    qaComments: null,
    approvedAt: null,
    closedAt: null,
    closureSummary: null,
    electronicSignature: null,
    linkedIncidents: [],
    linkedDeviations: [],
    linkedCapas: [],
    linkedSops: ["SOP-MB-017"],
    linkedEquipment: ["EQ-INC-0012"],
    linkedChangeControls: [],
    draftedFromSlack: true,
    auditTrail: [
      {
        at: "2026-09-21T08:16:00+02:00",
        actor: "Quality Bot",
        action: "Created record",
        from: null,
        to: "Draft",
        comment: "Drafted from Slack message in #lab-incidents",
      },
      {
        at: "2026-09-21T08:16:12+02:00",
        actor: "Quality Bot",
        action: "Attached files",
        from: "0",
        to: "3",
        comment: "Slack message, display photo, temperature log",
      },
    ],
  },
  {
    id: "DEV-2026-0088",
    recordType: "Deviation",
    title: "Missed stability pull – Chamber ST-04",
    status: "Closed",
    priority: "Medium",
    sourceChannel: "LIMS",
    sourceRef: "LIMS-STAB-8821",
    site: "Berlin Lab",
    department: "QC Chemistry",
    area: "Stability suite",
    occurredAt: "2026-08-04T06:00:00+02:00",
    discoveredAt: "2026-08-04T09:40:00+02:00",
    reportedAt: "2026-08-04T09:55:00+02:00",
    reportedByName: "Tom Berger",
    reportedByRole: "Lab Supervisor",
    reportedByEmail: "tom.berger@lab.example",
    owner: "Maria Alvarez",
    summary: "T=3 month stability pull for Product Y was missed by one calendar day.",
    description:
      "Chamber ST-04 pull for Product Y batch CH-23911 was scheduled 03 Aug. Pull occurred 04 Aug after LIMS overdue alert.",
    immediateActions: "Samples pulled, labelled late, QA notified. Chamber access log attached.",
    category: "Sample Handling",
    subcategory: "Missed timepoint",
    nature: "Unplanned",
    isRepeat: false,
    relatedEventIds: [],
    equipmentName: "Stability chamber ST-04",
    equipmentId: "EQ-ST-0004",
    methodName: "Stability protocol STP-Y-03",
    sopId: "SOP-QC-044 v2.1",
    processStep: "Stability pull",
    expectedValue: "T=3 months on 2026-08-03",
    actualValue: "Pulled 2026-08-04",
    unit: null,
    limsSampleIds: ["ST-33901"],
    batchLots: [
      {
        product: "Product Y",
        batchNo: "CH-23911",
        stage: "Released",
        quantity: "12 units",
        impactUnknown: false,
      },
    ],
    productNames: ["Product Y"],
    reagentLots: [],
    classification: "Deviation",
    gxpType: "GMP",
    productImpact: "None",
    patientSafetyImpact: "None",
    dataIntegrityImpact: "None",
    reportabilityImpact: "Amend report",
    regulatoryImpact: "None",
    impactRationale: "One-day delay; samples remained in specified storage conditions.",
    containmentNeeded: false,
    containmentActions: null,
    disposition: "Use as is",
    investigationRequired: true,
    investigationOwner: "Tom Berger",
    investigationDueDate: "2026-08-18",
    investigationSummary: "Calendar reminder not set after protocol amendment.",
    rootCauseMethod: "5 Whys",
    rootCause: "Protocol amendment did not update the LIMS scheduler.",
    rootCauseCategory: "Method",
    contributingFactors: ["No dual check on scheduler"],
    similarEventsReviewed: "No similar events in 12 months.",
    capaRequired: true,
    capaJustification: "Scheduler update is required after protocol changes.",
    capaIds: ["CAPA-2026-0022"],
    effectivenessCheckRequired: true,
    capaActions: [
      {
        id: "CA-0088-01",
        type: "Corrective",
        description: "Update LIMS scheduler on protocol amendment",
        owner: "QC Chemistry",
        dueDate: "2026-08-20",
        status: "Done",
        evidence: "Change ticket CC-441",
      },
    ],
    attachments: [],
    attachmentCount: 0,
    qaReviewer: "Maria Alvarez",
    qaDecision: "Promote to deviation",
    qaComments: "Closed after CAPA verification.",
    approvedAt: "2026-08-22T11:00:00+02:00",
    closedAt: "2026-08-29T16:20:00+02:00",
    closureSummary: "Deviation closed. Scheduler control implemented.",
    electronicSignature: {
      signedBy: "Maria Alvarez",
      meaning: "Approved",
      signedAt: "2026-08-22T11:00:00+02:00",
    },
    linkedIncidents: [],
    linkedDeviations: [],
    linkedCapas: ["CAPA-2026-0022"],
    linkedSops: ["SOP-QC-044"],
    linkedEquipment: ["EQ-ST-0004"],
    linkedChangeControls: ["CC-441"],
    draftedFromSlack: false,
    auditTrail: [
      {
        at: "2026-08-04T09:56:00+02:00",
        actor: "Tom Berger",
        action: "Created record",
        from: null,
        to: "Draft",
        comment: "Opened from LIMS overdue alert",
      },
      {
        at: "2026-08-29T16:20:00+02:00",
        actor: "Maria Alvarez",
        action: "Changed status",
        from: "Approved",
        to: "Closed",
        comment: "CAPA verified",
      },
    ],
  },
  {
    id: "INC-2026-0138",
    recordType: "Incident",
    title: "Balance drift during weigh-in – BAL-03",
    status: "Under QA Review",
    priority: "Medium",
    sourceChannel: "Manual",
    sourceRef: null,
    site: "Berlin Lab",
    department: "QC Chemistry",
    area: "Weigh room",
    occurredAt: "2026-09-12T14:22:00+02:00",
    discoveredAt: "2026-09-12T14:22:00+02:00",
    reportedAt: "2026-09-12T14:40:00+02:00",
    reportedByName: "Lisa Chen",
    reportedByRole: "Lab Technician",
    reportedByEmail: "lisa.chen@lab.example",
    owner: "Maria Alvarez",
    summary: "Analytical balance BAL-03 failed daily check by 0.4 mg.",
    description:
      "Daily check weight 100.000 mg read 100.400 mg. Work stopped. Adjacent balances used after verification.",
    immediateActions: "Balance taken out of use. Facilities ticket opened.",
    category: "Equipment",
    subcategory: "Calibration drift",
    nature: "Unplanned",
    isRepeat: false,
    relatedEventIds: [],
    equipmentName: "Analytical balance BAL-03",
    equipmentId: "EQ-BAL-0003",
    methodName: null,
    sopId: "SOP-QC-011 v6.0",
    processStep: "Weigh-in",
    expectedValue: "100.000 ± 0.100 mg",
    actualValue: "100.400",
    unit: "mg",
    limsSampleIds: [],
    batchLots: [],
    productNames: [],
    reagentLots: [],
    classification: null,
    gxpType: "GMP",
    productImpact: "Unknown",
    patientSafetyImpact: "None",
    dataIntegrityImpact: "Possible",
    reportabilityImpact: null,
    regulatoryImpact: null,
    impactRationale: null,
    containmentNeeded: true,
    containmentActions: "Weighings since last passing check under review.",
    disposition: null,
    investigationRequired: true,
    investigationOwner: "Tom Berger",
    investigationDueDate: "2026-09-26",
    investigationSummary: null,
    rootCauseMethod: null,
    rootCause: null,
    rootCauseCategory: null,
    contributingFactors: [],
    similarEventsReviewed: null,
    capaRequired: null,
    capaJustification: null,
    capaIds: [],
    effectivenessCheckRequired: null,
    capaActions: [],
    attachments: [],
    attachmentCount: 0,
    qaReviewer: "Maria Alvarez",
    qaDecision: null,
    qaComments: null,
    approvedAt: null,
    closedAt: null,
    closureSummary: null,
    electronicSignature: null,
    linkedIncidents: [],
    linkedDeviations: [],
    linkedCapas: [],
    linkedSops: ["SOP-QC-011"],
    linkedEquipment: ["EQ-BAL-0003"],
    linkedChangeControls: [],
    draftedFromSlack: false,
    auditTrail: [
      {
        at: "2026-09-12T14:41:00+02:00",
        actor: "Lisa Chen",
        action: "Created record",
        from: null,
        to: "Draft",
        comment: "Manual intake",
      },
      {
        at: "2026-09-12T16:10:00+02:00",
        actor: "Maria Alvarez",
        action: "Changed status",
        from: "Submitted",
        to: "Under QA Review",
        comment: null,
      },
    ],
  },
  {
    id: "INC-2026-0131",
    recordType: "Incident",
    title: "Sample receipt label mismatch",
    status: "Investigation",
    priority: "Low",
    sourceChannel: "Email",
    sourceRef: "ticket-4412",
    site: "Berlin Lab",
    department: "Sample Receipt",
    area: "Goods-in",
    occurredAt: "2026-09-03T10:05:00+02:00",
    discoveredAt: "2026-09-03T10:18:00+02:00",
    reportedAt: "2026-09-03T10:30:00+02:00",
    reportedByName: "Tom Berger",
    reportedByRole: "Lab Supervisor",
    reportedByEmail: "tom.berger@lab.example",
    owner: "Maria Alvarez",
    summary: "Courier paperwork listed S-88011; vial label showed S-88012.",
    description:
      "Two companion samples arrived together. Paperwork and vial IDs did not match. Samples quarantined.",
    immediateActions: "Quarantine. Courier contacted. Customer notified.",
    category: "Sample Handling",
    subcategory: "Identity",
    nature: "Unplanned",
    isRepeat: false,
    relatedEventIds: [],
    equipmentName: null,
    equipmentId: null,
    methodName: null,
    sopId: "SOP-SR-002 v3.0",
    processStep: "Receipt",
    expectedValue: "Label matches CoA",
    actualValue: "S-88011 vs S-88012",
    unit: null,
    limsSampleIds: ["S-88011", "S-88012"],
    batchLots: [],
    productNames: [],
    reagentLots: [],
    classification: "Incident only",
    gxpType: "ISO 17025",
    productImpact: "Possible",
    patientSafetyImpact: "N/A",
    dataIntegrityImpact: "None",
    reportabilityImpact: "Hold results",
    regulatoryImpact: "None",
    impactRationale: "Identity not confirmed; testing not started.",
    containmentNeeded: true,
    containmentActions: "Both vials quarantined pending customer confirmation.",
    disposition: "Quarantine",
    investigationRequired: true,
    investigationOwner: "Tom Berger",
    investigationDueDate: "2026-09-17",
    investigationSummary: "Awaiting courier scan logs.",
    rootCauseMethod: null,
    rootCause: null,
    rootCauseCategory: null,
    contributingFactors: [],
    similarEventsReviewed: null,
    capaRequired: null,
    capaJustification: null,
    capaIds: [],
    effectivenessCheckRequired: null,
    capaActions: [],
    attachments: [],
    attachmentCount: 0,
    qaReviewer: "Maria Alvarez",
    qaDecision: "Approve as incident",
    qaComments: null,
    approvedAt: null,
    closedAt: null,
    closureSummary: null,
    electronicSignature: null,
    linkedIncidents: [],
    linkedDeviations: [],
    linkedCapas: [],
    linkedSops: ["SOP-SR-002"],
    linkedEquipment: [],
    linkedChangeControls: [],
    draftedFromSlack: false,
    auditTrail: [
      {
        at: "2026-09-03T10:31:00+02:00",
        actor: "Tom Berger",
        action: "Created record",
        from: null,
        to: "Draft",
        comment: "Opened from email",
      },
    ],
  },
];

const PEOPLE = [
  { name: "Lisa Chen", role: "Lab Technician", email: "lisa.chen@lab.example" },
  { name: "Tom Berger", role: "Lab Supervisor", email: "tom.berger@lab.example" },
  { name: "Maria Alvarez", role: "QA Reviewer", email: "maria.alvarez@lab.example" },
  { name: "Jonas Weber", role: "Analyst", email: "jonas.weber@lab.example" },
  { name: "Priya Nair", role: "QC Specialist", email: "priya.nair@lab.example" },
  { name: "Elena Rossi", role: "Microbiologist", email: "elena.rossi@lab.example" },
];

const OWNERS = ["Maria Alvarez", "Tom Berger", "Priya Nair", null];

const AREAS = {
  Microbiology: ["MB-Lab 1", "MB-Lab 2", "Incubation suite"],
  "QC Chemistry": ["Weigh room", "HPLC lab", "Stability suite"],
  "Sample Receipt": ["Goods-in", "Cold store", "Aliquot bench"],
};

const PRODUCTS = ["Product X", "Product Y", "Product Z", "QC strain E. coli"];

const SCENARIOS = [
  {
    category: "Equipment",
    subcategory: "Temperature excursion",
    title: (n) => `Temperature excursion – Incubator IC-${String((n % 40) + 1).padStart(2, "0")}`,
    summary: (n) => `Incubator IC-${String((n % 40) + 1).padStart(2, "0")} drifted above the 37.0 °C setpoint.`,
    description:
      "Chamber display exceeded the validated range. In-process samples were secured and facilities was notified.",
    immediateActions: "Samples secured. Equipment taken out of service. QA notified.",
    department: "Microbiology",
    processStep: "Incubation",
    expectedValue: "37.0 ± 1.0",
    actualValue: "39.1",
    unit: "°C",
  },
  {
    category: "Equipment",
    subcategory: "Calibration drift",
    title: (n) => `Balance drift during weigh-in – BAL-${String((n % 20) + 1).padStart(2, "0")}`,
    summary: (n) => `Analytical balance BAL-${String((n % 20) + 1).padStart(2, "0")} failed the daily check weight.`,
    description: "Daily check weight was outside tolerance. Weighings since the last passing check are under review.",
    immediateActions: "Balance taken out of use. Facilities ticket opened.",
    department: "QC Chemistry",
    processStep: "Weigh-in",
    expectedValue: "100.000 ± 0.100 mg",
    actualValue: "100.350",
    unit: "mg",
  },
  {
    category: "Sample Handling",
    subcategory: "Missed timepoint",
    title: (n) => `Missed stability pull – Chamber ST-${String((n % 12) + 1).padStart(2, "0")}`,
    summary: "Scheduled stability pull was completed one calendar day late.",
    description: "LIMS overdue alert fired after the protocol timepoint. Samples remained in specified storage.",
    immediateActions: "Samples pulled, labelled late, QA notified.",
    department: "QC Chemistry",
    processStep: "Stability pull",
    expectedValue: "On-time pull",
    actualValue: "Pulled +1 day",
    unit: null,
  },
  {
    category: "Sample Handling",
    subcategory: "Identity",
    title: () => "Sample receipt label mismatch",
    summary: "Courier paperwork and vial label IDs did not match at goods-in.",
    description: "Companion samples arrived together. Paperwork and vial IDs disagreed. Samples were quarantined.",
    immediateActions: "Quarantine. Courier contacted. Customer notified.",
    department: "Sample Receipt",
    processStep: "Receipt",
    expectedValue: "Label matches CoA",
    actualValue: "IDs differ",
    unit: null,
  },
  {
    category: "Method",
    subcategory: "System suitability",
    title: (n) => `HPLC system suitability failure – HPLC-${String((n % 8) + 1).padStart(2, "0")}`,
    summary: "System suitability failed plate count before the sample sequence.",
    description: "Column pressure and plate count were outside the method limits. Sequence was not started.",
    immediateActions: "Run aborted. Column reserved. Method owner notified.",
    department: "QC Chemistry",
    processStep: "System suitability",
    expectedValue: "N ≥ 5000",
    actualValue: "4120",
    unit: null,
  },
  {
    category: "Reagent",
    subcategory: "Expired material",
    title: (n) => `Expired reagent used in assay – LOT-${String(2400 + (n % 80)).padStart(4, "0")}`,
    summary: "A reagent lot past its expiry was scanned into an in-process assay.",
    description: "LIMS scan accepted an expired lot after a weekend expiry rollover. Work was stopped.",
    immediateActions: "Assay halted. Lot quarantined. Remaining inventory checked.",
    department: "Microbiology",
    processStep: "Reagent prep",
    expectedValue: "In-date lot",
    actualValue: "Expired",
    unit: null,
  },
  {
    category: "Data Integrity",
    subcategory: "Audit trail",
    title: () => "Missing audit-trail review on chromatography run",
    summary: "Weekly audit-trail review was not completed before result release.",
    description: "Reviewer absence left the weekly chromatography audit-trail unsigned. Results were held.",
    immediateActions: "Results held. Backup reviewer assigned.",
    department: "QC Chemistry",
    processStep: "Data review",
    expectedValue: "Review complete",
    actualValue: "Unsigned",
    unit: null,
  },
  {
    category: "Facility",
    subcategory: "Environmental",
    title: (n) => `Cleanroom pressure alarm – Grade ${n % 2 ? "C" : "D"}`,
    summary: "Differential pressure dropped below the alert limit for more than 15 minutes.",
    description: "AHU interlock recovered after the alarm. Personnel were already clear of the room.",
    immediateActions: "Room access restricted. Facilities acknowledged the alarm.",
    department: "Microbiology",
    processStep: "Environmental monitoring",
    expectedValue: "≥ 10 Pa",
    actualValue: "4 Pa",
    unit: "Pa",
  },
  {
    category: "Personnel",
    subcategory: "Training",
    title: () => "Analyst performed method without current training",
    summary: "A method was executed after the analyst's training record had lapsed.",
    description: "LMS showed training expired two days earlier. Results were not released.",
    immediateActions: "Work stopped. Supervisor informed. Training retriggered.",
    department: "QC Chemistry",
    processStep: "Testing",
    expectedValue: "Current training",
    actualValue: "Expired",
    unit: null,
  },
  {
    category: "Documentation",
    subcategory: "Incomplete record",
    title: () => "Incomplete batch worksheet at second-person review",
    summary: "Required fields were blank when the worksheet reached second-person review.",
    description: "Balance ID and check-weight fields were empty. Reviewer rejected the packet.",
    immediateActions: "Packet returned. Testing not released.",
    department: "Sample Receipt",
    processStep: "Documentation",
    expectedValue: "Complete worksheet",
    actualValue: "Blank fields",
    unit: null,
  },
];

function mulberry32(seed) {
  return function rng() {
    let t = (seed += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function pick(rng, list) {
  return list[Math.floor(rng() * list.length)];
}

function pad(n) {
  return String(n).padStart(4, "0");
}

function berlinStamp(year, dayOffset, hour, minute) {
  const start = Date.UTC(year, 0, 1, 0, 0, 0);
  const d = new Date(start + dayOffset * 86400000);
  const month = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  const hh = String(hour).padStart(2, "0");
  const mm = String(minute).padStart(2, "0");
  return `${year}-${month}-${day}T${hh}:${mm}:00+02:00`;
}

function volumeId(index, recordType) {
  let year;
  let seq;
  if (index < 200) {
    year = 2024;
    seq = index + 1;
  } else if (index < 400) {
    year = 2025;
    seq = index - 199;
  } else {
    year = 2026;
    seq = index - 399;
  }
  const prefix = recordType === "Deviation" && year < 2026 ? "DEV" : "INC";
  return `${prefix}-${year}-${pad(seq)}`;
}

function isBlockedId(id) {
  const reserved = new Set(seedRecords.map((r) => r.id));
  if (reserved.has(id)) return true;
  const match = id.match(/^(?:INC|DEV)-(\d{4})-(\d{4})$/);
  if (!match) return false;
  const year = Number(match[1]);
  const seq = Number(match[2]);
  // nextIncidentId starts at 143 for the current calendar year after reset.
  return year === new Date().getFullYear() && seq >= 143;
}

export function generateVolumeRecords(count = TARGET_SEED_COUNT - seedRecords.length) {
  const rng = mulberry32(20260921);
  const records = [];
  let index = 0;
  while (records.length < count) {
    const scenario = SCENARIOS[index % SCENARIOS.length];
    const recordType =
      index % 17 === 0 ? "Deviation" : index % 31 === 0 ? "Lab Investigation" : "Incident";
    const id = volumeId(index, recordType);
    index += 1;
    if (isBlockedId(id)) continue;

    const status = pick(rng, ENUMS.status);
    const priority = pick(rng, ENUMS.priority);
    const department = scenario.department || pick(rng, ENUMS.department);
    const sourceChannel = pick(rng, ENUMS.sourceChannel);
    const reporter = pick(rng, PEOPLE);
    const owner = ["Draft", "Submitted"].includes(status) ? pick(rng, OWNERS) : pick(rng, OWNERS.filter(Boolean));
    const year = Number(id.slice(4, 8));
    const maxDay = year === 2026 ? 260 : 364;
    const dayOffset = Math.floor(rng() * maxDay);
    const hour = 7 + Math.floor(rng() * 10);
    const minute = Math.floor(rng() * 60);
    const occurredAt = berlinStamp(year, dayOffset, hour, minute);
    const discoveredAt = berlinStamp(year, dayOffset, hour, Math.min(59, minute + 5));
    const reportedAt = berlinStamp(year, dayOffset, hour, Math.min(59, minute + 12));
    const product = pick(rng, PRODUCTS);
    const batchNo = `${department === "Microbiology" ? "MB" : "CH"}-${year % 100}${pad((index % 9000) + 100)}`;
    const closed = ["Closed", "Cancelled", "Not a Deviation"].includes(status);
    const investigating = ["Investigation", "CAPA Required", "No CAPA", "Pending QA Approval", "Approved"].includes(
      status
    );

    records.push({
      id,
      recordType,
      title: scenario.title(index),
      status,
      priority,
      sourceChannel,
      sourceRef: sourceChannel === "Manual" ? null : `${sourceChannel.toUpperCase()}-${id}`,
      site: "Berlin Lab",
      department,
      area: pick(rng, AREAS[department] || ["Lab"]),
      occurredAt,
      discoveredAt,
      reportedAt,
      reportedByName: reporter.name,
      reportedByRole: reporter.role,
      reportedByEmail: reporter.email,
      owner,
      summary: typeof scenario.summary === "function" ? scenario.summary(index) : scenario.summary,
      description: scenario.description,
      immediateActions: scenario.immediateActions,
      category: scenario.category,
      subcategory: scenario.subcategory,
      nature: pick(rng, ENUMS.nature),
      isRepeat: rng() < 0.08,
      relatedEventIds: [],
      equipmentName: null,
      equipmentId: null,
      methodName: null,
      sopId: null,
      processStep: scenario.processStep,
      expectedValue: scenario.expectedValue,
      actualValue: scenario.actualValue,
      unit: scenario.unit,
      limsSampleIds: rng() < 0.5 ? [`S-${50000 + index}`] : [],
      batchLots:
        rng() < 0.45
          ? [
              {
                product,
                batchNo,
                stage: pick(rng, ENUMS.batchStage),
                quantity: null,
                impactUnknown: true,
              },
            ]
          : [],
      productNames: rng() < 0.4 ? [product] : [],
      reagentLots: [],
      classification: investigating || closed ? pick(rng, ["Incident only", "Deviation", "OOS", "OOT"]) : null,
      gxpType: pick(rng, ["GMP", "ISO 17025", "GLP"]),
      productImpact: investigating || closed ? pick(rng, ["None", "Possible", "Unknown"]) : null,
      patientSafetyImpact: investigating || closed ? pick(rng, ["None", "N/A", "Possible"]) : null,
      dataIntegrityImpact: investigating || closed ? pick(rng, ["None", "Possible"]) : null,
      reportabilityImpact: null,
      regulatoryImpact: null,
      impactRationale: investigating || closed ? "Generated volume record for inbox and dashboard exercises." : null,
      containmentNeeded: rng() < 0.3,
      containmentActions: null,
      disposition: closed ? pick(rng, ["Use as is", "Retest", "Quarantine", "N/A"]) : null,
      investigationRequired: investigating || closed,
      investigationOwner: investigating || closed ? owner : null,
      investigationDueDate: null,
      investigationSummary: closed ? "Closed after routine review of the generated demo record." : null,
      rootCauseMethod: closed ? "5 Whys" : null,
      rootCause: closed ? "Demo volume record — root cause recorded for realism." : null,
      rootCauseCategory: closed ? pick(rng, ["Method", "Equipment", "Personnel"]) : null,
      contributingFactors: [],
      similarEventsReviewed: null,
      capaRequired: closed ? rng() < 0.4 : null,
      capaJustification: null,
      capaIds: [],
      effectivenessCheckRequired: null,
      capaActions: [],
      attachments: [],
      attachmentCount: 0,
      qaReviewer: investigating || closed ? "Maria Alvarez" : null,
      qaDecision: closed ? "Approve as incident" : null,
      qaComments: null,
      approvedAt: closed ? reportedAt : null,
      closedAt: closed ? berlinStamp(year, Math.min(maxDay, dayOffset + 14), 16, 0) : null,
      closureSummary: closed ? "Closed in demo seed volume set." : null,
      electronicSignature: null,
      linkedIncidents: [],
      linkedDeviations: [],
      linkedCapas: [],
      linkedSops: [],
      linkedEquipment: [],
      linkedChangeControls: [],
      draftedFromSlack: sourceChannel === "Slack",
      auditTrail: [
        {
          at: reportedAt,
          actor: reporter.name,
          action: "Created record",
          from: null,
          to: "Draft",
          comment: `Generated volume record ${id}`,
        },
      ],
    });
  }
  return records;
}

export const allSeedRecords = [...seedRecords, ...generateVolumeRecords()];
