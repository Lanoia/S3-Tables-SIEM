# DIY SIEM on S3 Tables

A proof of concept for a low-cost security analytics stack on AWS.
Raw log files stay in S3 and carry their own history as S3 annotations.
Parsed events live as rows in S3 Tables. Athena is the only way to read either store.
A Streamlit UI and scheduled detection rules are both Athena clients.

**Status:** Phase 0 (setup)

## Architecture

The full design is in [`docs/design/DIY-SIEM-S3-Table.pdf`](docs/design/DIY-SIEM-S3-Table.pdf).

| Component | Purpose | Phase |
|---|---|---|
| Raw log bucket | Keeps every original log file, versioned and untouched | 1 |
| S3 annotations | Ingest, triage and detection notes attached to each raw file | 1 to 4 |
| Annotation table | S3 Metadata table that makes annotations queryable with SQL | 1 |
| Events table (S3 Tables) | One row per log event, common columns across sources | 1 |
| Athena | Runs every search and every rule | 1 |
| Streamlit UI | Search, drill into a raw event, add triage notes | 3 |
| Detection rules + SNS | Scheduled SQL that sends an alert on a match | 4 |

**Scope of this PoC:** the Ship stage and the parser Lambdas are skipped.
A public sample dataset is loaded directly into the events table.
See [`docs/design/ship-prepare-load-pipeline.png`](docs/design/ship-prepare-load-pipeline.png).

## Repository layout

```
.
├── app/          Streamlit UI (Phase 3)
├── docs/
│   ├── design/   Design PDF and diagrams
│   └── decisions.md
├── infra/        Terraform
├── scripts/      Download, upload, annotate and load scripts
└── sql/
    ├── ddl/      CREATE TABLE statements
    └── rules/    One .sql file per detection rule (Phase 4)
```

## Prerequisites

- Access to the provided AWS account, region `ap-southeast-2`
- AWS CLI v2 and boto3, recent versions (the annotation APIs were released in June 2026)
- Terraform
- Python 3.11 or later
- Git

## Progress

- [x] Phase 0: Budget alert
- [ ] Phase 0: SSO sign-in with `aws configure sso`
- [ ] Phase 1: Raw bucket, annotations, annotation table, events table, first Athena join
- [ ] Phase 3: Streamlit search UI
- [ ] Phase 4: Detection rules and SNS alerts

## Conventions

- Region is `ap-southeast-2`.
- Every AWS resource is tagged `project=diy-siem`.
- Every event row carries `raw_object_key` and `raw_version_id`. Annotations attach to files, not events, so this pair is the only link from an event back to its history.
- No log data, credentials, `.env` files or Terraform state go into git.
