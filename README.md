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

`scripts/deploy-aws.sh` creates a `t3.small` in `us-east-1`, attaches an NSG (security group) that allows HTTP `:80` and SSH only from **your current public IP**, copies this repo onto the VM, and starts `compose.aws.yml` (Postgres + API + nginx frontend).

Stop the instance when you are not demoing it. Compute and the public IPv4 fee stop; the 8 GB root volume is about **$0.64/month**. `./scripts/destroy-aws.sh` is the $0 teardown.

```bash
# needs terraform + AWS credentials (env vars or ~/.aws)
./scripts/deploy-aws.sh
```

The script prints `http://<public-ip>`. Postgres and the API are not published on the host; nginx on port 80 proxies `/api` and `/demo`.

Optional env vars: `ALLOWED_CIDR` (skip IP detection), `AWS_REGION`, `INSTANCE_TYPE`.

State lives at `infra/aws/terraform.tfstate` (local backend). Commit it if you want to keep the VM in git. The operator key stays in `infra/aws/.ssh/` and is gitignored.

Tear down:

```bash
./scripts/destroy-aws.sh
```

## Seeded records

| ID | Status | Notes |
|---|---|---|
| `INC-2026-0142` | Draft | Slack bot temperature excursion |
| `DEV-2026-0088` | Closed | Older deviation so the inbox is not empty |
| `INC-2026-0138` | Under QA Review | Balance drift |
| `INC-2026-0131` | Investigation | Sample receipt mismatch |
