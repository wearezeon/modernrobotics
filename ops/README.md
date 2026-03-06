# Beverly Hills Cop — Personal Ops System

A personal ops layer that gives a single holistic view across all running projects, finances, and communications. Dialog-first — no Kanban, no Gantt. The system observes, aggregates, and surfaces what needs attention. It never acts autonomously.

**Core principle:** The system pings when something burns. Silent when everything is fine.

## Stack

| Layer | Technology |
|-------|-----------|
| Database | PostgreSQL |
| Mail Ingestion | IMAP (Namecheap) + Gmail API |
| Notifications | Slack — bidirectional |
| Agent Layer | MCP Server — Claude reads DB, reasons, responds |
| Hosting | Own stack, separate from Zeon |

## Project Structure

```
ops/
├── docker-compose.yml          # Postgres + app services
├── Dockerfile                  # Multi-stage Node 22 Alpine build
├── package.json
├── tsconfig.json
├── .env.example                # All required env vars
└── src/
    ├── index.ts                # Entry point — starts bot, schedules IMAP cron
    ├── config.ts               # Env-based configuration
    ├── db/
    │   ├── schema.sql          # 7 core tables with enums, indexes, triggers
    │   ├── seed.sql            # Sample data for validation
    │   ├── client.ts           # PostgreSQL pool client
    │   ├── migrate.ts          # Schema runner
    │   └── seed.ts             # Seed data runner
    ├── mail/
    │   └── imap.ts             # IMAP connector — polls Namecheap inbox
    └── slack/
        └── bot.ts              # Slack bot — socket mode, structured commands
```

## Database Tables

| Table | Purpose |
|-------|---------|
| `projects` | Active projects — status, owner, priority |
| `payments` | Invoices, subscriptions, dues — amount, due date, paid status |
| `contacts` | People and companies — linked to projects and payments |
| `mail_items` | Parsed emails — structured fields, entity linking |
| `events` | Deadlines, meetings, milestones — with reminder logic |
| `notes` | Free-form context attached to any entity |
| `alerts` | Log of all Slack notifications — prevents duplicates |

## Quick Start

```bash
cd ops
cp .env.example .env    # Fill in your credentials
npm install
docker compose up db    # Start Postgres
npm run migrate         # Apply schema
npm run seed            # Load sample data
npm run dev             # Start the app
```

## Slack Bot Commands

Reply to any bot message in a thread:

| Command | Effect |
|---------|--------|
| `paid` | Mark payment as paid |
| `done` | Mark item as completed |
| `skip` | Skip / dismiss alert |
| `snooze 3d` | Snooze for N days |
| `note: some text` | Attach a note to the entity |

## Slack Channels

| Channel | Purpose |
|---------|---------|
| `#ops-daily` | Morning digest — what needs attention today |
| `#payments` | Payment alerts, overdue notices, upcoming dues |
| `#projects` | Project status changes, blockers |
| `#inbox` | Notable parsed emails |

## Build Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | Foundation | **Current** — schema, IMAP connector, Slack skeleton, seed data |
| 2 | Mail Pipeline | Gmail API, mail parser, entity linking |
| 3 | Alerts | Payment tracking, overdue logic, scheduled agent jobs |
| 4 | MCP | MCP server for Claude, bidirectional Slack command parsing |
| 5 | Hardening | Auth, rate limiting, logging, domain setup |

## Environment Variables

See [`.env.example`](ops/.env.example) for the full list. Key groups:

- **Database** — `DATABASE_URL`
- **IMAP** — `IMAP_HOST`, `IMAP_PORT`, `IMAP_USER`, `IMAP_PASS`
- **Slack** — `SLACK_BOT_TOKEN`, `SLACK_SIGNING_SECRET`, `SLACK_APP_TOKEN`
- **Scheduling** — `TZ` (default: `Europe/Berlin`), `IMAP_POLL_INTERVAL_MINUTES`
