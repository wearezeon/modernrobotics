-- Beverly Hills Cop — Ops System Schema v1
-- Phase 1: Foundation

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- CONTACTS — people and companies, linked to projects/payments
-- ============================================================
CREATE TABLE contacts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    email       TEXT,
    company     TEXT,
    role        TEXT,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_contacts_email ON contacts (email);

-- ============================================================
-- PROJECTS — all active projects with status tracking
-- ============================================================
CREATE TYPE project_status AS ENUM ('active', 'paused', 'completed', 'archived');
CREATE TYPE project_priority AS ENUM ('critical', 'high', 'medium', 'low');

CREATE TABLE projects (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    status          project_status NOT NULL DEFAULT 'active',
    priority        project_priority NOT NULL DEFAULT 'medium',
    owner_id        UUID REFERENCES contacts(id),
    description     TEXT,
    last_update     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_projects_status ON projects (status);
CREATE INDEX idx_projects_priority ON projects (priority);

-- ============================================================
-- PAYMENTS — invoices, subscriptions, dues
-- ============================================================
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'overdue', 'cancelled');
CREATE TYPE payment_direction AS ENUM ('inbound', 'outbound');

CREATE TABLE payments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    description TEXT NOT NULL,
    amount      NUMERIC(12, 2) NOT NULL,
    currency    TEXT NOT NULL DEFAULT 'EUR',
    direction   payment_direction NOT NULL DEFAULT 'outbound',
    status      payment_status NOT NULL DEFAULT 'pending',
    due_date    DATE,
    paid_at     TIMESTAMPTZ,
    source      TEXT,
    project_id  UUID REFERENCES projects(id),
    contact_id  UUID REFERENCES contacts(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_payments_status ON payments (status);
CREATE INDEX idx_payments_due_date ON payments (due_date);

-- ============================================================
-- MAIL_ITEMS — parsed emails with structured fields
-- ============================================================
CREATE TABLE mail_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id      TEXT UNIQUE,
    account         TEXT NOT NULL,
    sender          TEXT NOT NULL,
    subject         TEXT,
    body_summary    TEXT,
    raw_body        TEXT,
    received_at     TIMESTAMPTZ NOT NULL,
    amounts         JSONB,
    keywords        TEXT[],
    action_items    TEXT[],
    contact_id      UUID REFERENCES contacts(id),
    project_id      UUID REFERENCES projects(id),
    processed       BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_mail_items_account ON mail_items (account);
CREATE INDEX idx_mail_items_received ON mail_items (received_at DESC);
CREATE INDEX idx_mail_items_message_id ON mail_items (message_id);

-- ============================================================
-- EVENTS — deadlines, meetings, milestones
-- ============================================================
CREATE TYPE event_type AS ENUM ('deadline', 'meeting', 'milestone', 'reminder');

CREATE TABLE events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           TEXT NOT NULL,
    event_type      event_type NOT NULL DEFAULT 'deadline',
    event_date      TIMESTAMPTZ NOT NULL,
    confirmed       BOOLEAN NOT NULL DEFAULT false,
    reminder_sent   BOOLEAN NOT NULL DEFAULT false,
    project_id      UUID REFERENCES projects(id),
    contact_id      UUID REFERENCES contacts(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_events_date ON events (event_date);

-- ============================================================
-- NOTES — free-form context attached to any entity
-- ============================================================
CREATE TABLE notes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL,
    entity_id   UUID NOT NULL,
    text        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notes_entity ON notes (entity_type, entity_id);

-- ============================================================
-- ALERTS — log of all Slack notifications sent
-- ============================================================
CREATE TYPE alert_channel AS ENUM ('ops-daily', 'payments', 'projects', 'inbox');

CREATE TABLE alerts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel         alert_channel NOT NULL,
    entity_type     TEXT NOT NULL,
    entity_id       UUID NOT NULL,
    message         TEXT NOT NULL,
    slack_ts        TEXT,
    resolved        BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_alerts_entity ON alerts (entity_type, entity_id);
CREATE INDEX idx_alerts_resolved ON alerts (resolved) WHERE NOT resolved;

-- ============================================================
-- Updated_at trigger function
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_contacts_updated BEFORE UPDATE ON contacts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_projects_updated BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_payments_updated BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_events_updated BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at();
