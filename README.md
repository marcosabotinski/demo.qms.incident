# demo.qms.incident

Mock eQMS for a lab quality-incident demo. The working path is **create a quality incident**; the rest of the record is shown so the UI looks like a real system.

## Run with Podman

```bash
podman machine start   # if the local machine is stopped
podman compose up --build
```

Open [http://localhost:8080](http://localhost:8080).

- Dashboard is the start page
- **Incidents** is the inbox
- **Create incident** persists a `Draft` record in Postgres

## Local development (without containers)

Postgres must be reachable at `postgres://qms:qms@localhost:5432/qms`.

```bash
# terminal 1
cd api && npm install && DATABASE_URL=postgres://qms:qms@localhost:5432/qms npm start

# terminal 2
cd web && npm install && npm run dev
```

Vite proxies `/api` and `/demo` to the API on port 4000.

## Deploy to AWS

`scripts/deploy-aws.sh` creates a `t3.small` in `eu-central-1` (Frankfurt) with an Elastic IP, then puts **Cloudflare in front**: a proxied (orange-cloud) A record at `DEMO_HOSTNAME`, SSL/TLS mode **Flexible**, and **zone IP Access Rules** ("this website") that whitelist `CF_ALLOW_IPS` (default: your current public IP). The origin serves plain HTTP on `:80`; Cloudflare terminates browser HTTPS at the edge.

The security group allows SSH `:22` from `ALLOWED_CIDR` (default: your IP) and HTTP `:80` only from Cloudflare's published IPv4 ranges. There is no TLS on the EC2 box.

You need a test hostname in a Cloudflare zone you control, a zone ID, and an API token with DNS / zone-settings / **IP Access Rules** edit. Copy `.env.example` to a gitignored `.env` (`chmod 600 .env`) and fill in the three required values. Already-exported shell values win over `.env`. AWS credentials come from `~/.aws` or `AWS_*`.

Stop the instance when you are not demoing it. Compute and the public IPv4 fee stop; the 8 GB root volume is about **$0.64/month**. `./scripts/destroy-aws.sh` is the $0 teardown (it also removes the Cloudflare DNS record, SSL setting, and IP Access Rules).

```bash
# needs terraform + AWS credentials + Cloudflare token/zone
# either: cp .env.example .env && chmod 600 .env  (then fill it in)
# or export:
CLOUDFLARE_API_TOKEN=... CF_ZONE_ID=... DEMO_HOSTNAME=test.example.com ./scripts/deploy-aws.sh
```

IP Access Rules and SSH default to your current public IP. Region is `eu-central-1`; instance type is `t3.small`.

Postgres and the API are not published on the host; nginx on origin `:80` proxies `/api` and `/demo`. Visitors hit `https://<hostname>` via Cloudflare.

**Security note:** Flexible leaves the Cloudflare→origin hop unencrypted. Locking `:80` to Cloudflare IP ranges is not cryptographic origin authentication. Zone IP Access Rules apply to **the whole zone**, not just `DEMO_HOSTNAME`, and a whitelist skips security for those IPs — it does **not** deny everyone else (that needs WAF custom rules, which this zone already has a ruleset for). Hardening is Authenticated Origin Pulls and/or SSL Full (strict) with an Origin CA certificate on the box.

State lives at `infra/aws/terraform.tfstate` (local backend). Commit it if you want to keep the VM in git. The operator key stays in `infra/aws/.ssh/` and is gitignored.

Tear down:

```bash
CLOUDFLARE_API_TOKEN=... ./scripts/destroy-aws.sh
```

## Seeded records

| ID | Status | Notes |
|---|---|---|
| `INC-2026-0142` | Draft | Slack bot temperature excursion |
| `DEV-2026-0088` | Closed | Older deviation so the inbox is not empty |
| `INC-2026-0138` | Under QA Review | Balance drift |
| `INC-2026-0131` | Investigation | Sample receipt mismatch |
