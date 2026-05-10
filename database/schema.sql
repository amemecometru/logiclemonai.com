- =============================================================================
--  LogicLemon AI  ·  Outcome-Based Billing Schema
--  Inbox Triage tile · v1.0  ·  PostgreSQL 14+
--
--  Stripe model: Meters + Meter Events (the post-Mar-2024 API).
--  Doc:   https://docs.stripe.com/billing/subscriptions/usage-based
--
--  Conventions:
--    * UUID primary keys, generated server-side
--    * created_at / updated_at on every business row
--    * org_id on every business table   →   RLS-ready, multi-tenant
--    * `stripe_*` tables MIRROR Stripe entities (truth lives in Stripe)
--    * `usage_events` are RAW + IMMUTABLE
--    * `outcomes` are PRICED units — what we actually bill on
--    * `outcomes.identifier` is the idempotency key sent to Stripe
--      → re-running ingest on the same source events MUST produce the same
--        identifier (deterministic hash of source_event_ids + meter_slug).
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- case-insensitive text

-- ---------------------------------------------------------------------------
-- Schema
-- ---------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS llai;
SET search_path TO llai, public;

-- ---------------------------------------------------------------------------
-- Helper
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

-- ===========================================================================
-- 1. TENANCY  ───────────────────────────────────────────────────────────────
-- ===========================================================================

CREATE TABLE orgs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        CITEXT NOT NULL UNIQUE,
  name        TEXT   NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_orgs_updated BEFORE UPDATE ON orgs
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         CITEXT NOT NULL UNIQUE,
  display_name  TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_users_updated BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TYPE org_role AS ENUM ('owner','admin','member','viewer');

CREATE TABLE org_members (
  org_id    UUID NOT NULL REFERENCES orgs(id)  ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role      org_role NOT NULL DEFAULT 'member',
  added_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (org_id, user_id)
);

-- ===========================================================================
-- 2. TILE CATALOG  ──────────────────────────────────────────────────────────
--    Defines the LLai products and the metered units each one bills on.
-- ===========================================================================

CREATE TABLE tiles (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug         CITEXT NOT NULL UNIQUE,           -- 'inbox-triage'
  name         TEXT NOT NULL,                    -- 'Inbox Triage'
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'active',   -- active | beta | retired
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_tiles_updated BEFORE UPDATE ON tiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- The metered units a tile emits. Inbox Triage emits two:
--   * actionable_email_surfaced
--   * draft_accepted
CREATE TABLE tile_meters (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tile_id      UUID NOT NULL REFERENCES tiles(id) ON DELETE CASCADE,
  meter_slug   CITEXT NOT NULL,                  -- = stripe_meters.event_name
  label        TEXT NOT NULL,                    -- human-readable
  unit_label   TEXT NOT NULL,                    -- 'email' / 'draft'
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tile_id, meter_slug)
);

-- ===========================================================================
-- 3. STRIPE MIRROR  ─────────────────────────────────────────────────────────
--    1:1 with Stripe entities. Updated by webhook handlers + sync jobs.
--    Treat Stripe as the source of truth; we mirror for query speed + audit.
-- ===========================================================================

CREATE TABLE stripe_customers (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id              UUID NOT NULL REFERENCES orgs(id) ON DELETE RESTRICT,
  stripe_customer_id  TEXT NOT NULL UNIQUE,             -- 'cus_...'
  email               CITEXT,
  livemode            BOOLEAN NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_stripe_customers_org ON stripe_customers(org_id);
CREATE TRIGGER trg_stripe_customers_updated BEFORE UPDATE ON stripe_customers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- One row per Stripe Meter we have created.
-- event_name MUST equal the corresponding tile_meters.meter_slug.
CREATE TABLE stripe_meters (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_meter_id      TEXT NOT NULL UNIQUE,            -- 'mtr_...'
  event_name           CITEXT NOT NULL UNIQUE,          -- 'actionable_email_surfaced'
  display_name         TEXT NOT NULL,
  status               TEXT NOT NULL,                   -- 'active'|'inactive'
  default_aggregation  TEXT NOT NULL,                   -- 'sum'|'count'|'last'
  value_settings       JSONB NOT NULL DEFAULT '{}'::jsonb,
  livemode             BOOLEAN NOT NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Bridge: every tile_meter is tied to exactly one stripe_meter.
CREATE TABLE tile_meter_stripe_links (
  tile_meter_id    UUID PRIMARY KEY REFERENCES tile_meters(id) ON DELETE CASCADE,
  stripe_meter_id  UUID NOT NULL REFERENCES stripe_meters(id) ON DELETE RESTRICT
);

-- Stripe Prices attached to a Meter (recurring.usage_type='metered').
CREATE TABLE stripe_prices (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_price_id      TEXT NOT NULL UNIQUE,            -- 'price_...'
  stripe_meter_id_fk   UUID NOT NULL REFERENCES stripe_meters(id) ON DELETE RESTRICT,
  unit_amount_cents    BIGINT,                          -- integer cents
  unit_amount_decimal  NUMERIC(20,12),                  -- Stripe accepts up to 12 decimals
  currency             CHAR(3) NOT NULL,
  billing_scheme       TEXT NOT NULL,                   -- 'per_unit'|'tiered'
  tiers                JSONB,                           -- if tiered
  active               BOOLEAN NOT NULL DEFAULT TRUE,
  livemode             BOOLEAN NOT NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_stripe_prices_meter ON stripe_prices(stripe_meter_id_fk);

CREATE TYPE stripe_subscription_status AS ENUM (
  'incomplete','incomplete_expired','trialing','active',
  'past_due','canceled','unpaid','paused'
);

CREATE TABLE stripe_subscriptions (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id                    UUID NOT NULL REFERENCES orgs(id) ON DELETE RESTRICT,
  stripe_customer_id_fk     UUID NOT NULL REFERENCES stripe_customers(id) ON DELETE RESTRICT,
  stripe_subscription_id    TEXT NOT NULL UNIQUE,
  status                    stripe_subscription_status NOT NULL,
  current_period_start      TIMESTAMPTZ,
  current_period_end        TIMESTAMPTZ,
  cancel_at                 TIMESTAMPTZ,
  canceled_at               TIMESTAMPTZ,
  livemode                  BOOLEAN NOT NULL,
  metadata                  JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_stripe_subs_org ON stripe_subscriptions(org_id);
CREATE TRIGGER trg_stripe_subs_updated BEFORE UPDATE ON stripe_subscriptions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE stripe_subscription_items (
  id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_subscription_id_fk     UUID NOT NULL REFERENCES stripe_subscriptions(id) ON DELETE CASCADE,
  stripe_subscription_item_id   TEXT NOT NULL UNIQUE,
  stripe_price_id_fk            UUID NOT NULL REFERENCES stripe_prices(id),
  stripe_meter_id_fk            UUID REFERENCES stripe_meters(id),
  quantity                      BIGINT,
  created_at                    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ===========================================================================
-- 4. RUNS · USAGE EVENTS · OUTCOMES  (the heart of the schema)
-- ===========================================================================

CREATE TYPE tile_run_status AS ENUM (
  'queued','running','succeeded','partial','failed','canceled'
);

-- One row per tile execution.
CREATE TABLE tile_runs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          UUID NOT NULL REFERENCES orgs(id) ON DELETE RESTRICT,
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  tile_id         UUID NOT NULL REFERENCES tiles(id),
  trigger         TEXT NOT NULL,                   -- 'manual'|'schedule'|'webhook'
  input           JSONB NOT NULL DEFAULT '{}'::jsonb,
  output_summary  JSONB,
  status          tile_run_status NOT NULL DEFAULT 'queued',
  started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at    TIMESTAMPTZ,
  error           TEXT
);
CREATE INDEX ix_tile_runs_org_started  ON tile_runs(org_id, started_at DESC);
CREATE INDEX ix_tile_runs_tile_status  ON tile_runs(tile_id, status);

-- Raw, append-only event log. Examples for inbox-triage:
--   email_scanned · email_classified · email_archived · draft_created · draft_sent
CREATE TABLE usage_events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id       UUID NOT NULL REFERENCES orgs(id) ON DELETE RESTRICT,
  tile_run_id  UUID NOT NULL REFERENCES tile_runs(id) ON DELETE CASCADE,
  event_type   CITEXT NOT NULL,
  payload      JSONB NOT NULL DEFAULT '{}'::jsonb,
  occurred_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_usage_events_run             ON usage_events(tile_run_id);
CREATE INDEX ix_usage_events_org_type_time   ON usage_events(org_id, event_type, occurred_at DESC);
COMMENT ON TABLE usage_events IS
  'Append-only. Lock UPDATE/DELETE via role grants in production.';

-- The metered, billable units. ONE row = ONE Stripe meter event we will send.
-- `identifier` is the deterministic idempotency key — retries reuse it.
CREATE TYPE outcome_status AS ENUM (
  'pending',   -- minted, awaiting forward to Stripe
  'sent',      -- forwarded successfully
  'rejected',  -- Stripe returned 4xx (do NOT retry)
  'failed',    -- transient error; retry with backoff
  'voided'     -- canceled before forwarding (refund-equivalent)
);

CREATE TABLE outcomes (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id                UUID NOT NULL REFERENCES orgs(id) ON DELETE RESTRICT,
  tile_run_id           UUID NOT NULL REFERENCES tile_runs(id) ON DELETE RESTRICT,
  tile_id               UUID NOT NULL REFERENCES tiles(id),
  meter_slug            CITEXT NOT NULL,                 -- = stripe_meters.event_name
  stripe_meter_id_fk    UUID NOT NULL REFERENCES stripe_meters(id),
  stripe_customer_id    TEXT NOT NULL,                   -- denormalized for Stripe payload
  identifier            TEXT NOT NULL UNIQUE,            -- idempotency key sent to Stripe
  value                 NUMERIC(20,6) NOT NULL DEFAULT 1,
  occurred_at           TIMESTAMPTZ NOT NULL,
  status                outcome_status NOT NULL DEFAULT 'pending',
  source_event_ids      UUID[] NOT NULL DEFAULT '{}'::uuid[],  -- usage_events.id[]
  evidence              JSONB NOT NULL DEFAULT '{}'::jsonb,    -- any extra metadata
  sent_to_stripe_at     TIMESTAMPTZ,
  stripe_response       JSONB,
  voided_at             TIMESTAMPTZ,
  voided_reason         TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_outcomes_org_billing_window
  ON outcomes(org_id, occurred_at);
CREATE INDEX ix_outcomes_pending
  ON outcomes(status) WHERE status IN ('pending','failed');
CREATE INDEX ix_outcomes_run
  ON outcomes(tile_run_id);
CREATE INDEX ix_outcomes_customer_meter_time
  ON outcomes(stripe_customer_id, meter_slug, occurred_at DESC);
CREATE TRIGGER trg_outcomes_updated BEFORE UPDATE ON outcomes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMENT ON COLUMN outcomes.identifier IS
  'Deterministic hash. Recommended: sha256(meter_slug || ":" || sorted(source_event_ids))';

-- One row per attempt to POST to Stripe (success or failure).
CREATE TABLE stripe_meter_events (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outcome_id          UUID NOT NULL REFERENCES outcomes(id) ON DELETE RESTRICT,
  identifier          TEXT NOT NULL,                   -- = outcomes.identifier
  stripe_meter_id_fk  UUID NOT NULL REFERENCES stripe_meters(id),
  event_name          CITEXT NOT NULL,
  stripe_customer_id  TEXT NOT NULL,
  value               NUMERIC(20,6) NOT NULL,
  timestamp           TIMESTAMPTZ NOT NULL,
  payload             JSONB NOT NULL,
  request_id          TEXT,                            -- Stripe-Request-Id
  response_status     INT,
  response_body       JSONB,
  attempted_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_meter_events_outcome     ON stripe_meter_events(outcome_id);
CREATE INDEX ix_meter_events_identifier  ON stripe_meter_events(identifier);

-- ===========================================================================
- 5. INVOICES (mirrored from Stripe webhooks)
-- ===========================================================================

CREATE TYPE stripe_invoice_status AS ENUM (
  'draft','open','paid','void','uncollectible'
);

CREATE TABLE stripe_invoices (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id                      UUID NOT NULL REFERENCES orgs(id) ON DELETE RESTRICT,
  stripe_invoice_id           TEXT NOT NULL UNIQUE,
  stripe_subscription_id_fk   UUID REFERENCES stripe_subscriptions(id),
  number                      TEXT,
  status                      stripe_invoice_status NOT NULL,
  period_start                TIMESTAMPTZ,
  period_end                  TIMESTAMPTZ,
  subtotal_cents              BIGINT,
  total_cents                 BIGINT,
  amount_paid_cents           BIGINT,
  amount_remaining_cents      BIGINT,
  currency                    CHAR(3) NOT NULL,
  hosted_invoice_url          TEXT,
  invoice_pdf                 TEXT,
  livemode                    BOOLEAN NOT NULL,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_stripe_invoices_org ON stripe_invoices(org_id);
CREATE TRIGGER trg_stripe_invoices_updated BEFORE UPDATE ON stripe_invoices
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE stripe_invoice_line_items (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_invoice_id_fk     UUID NOT NULL REFERENCES stripe_invoices(id) ON DELETE CASCADE,
  stripe_invoice_item_id   TEXT NOT NULL UNIQUE,
  stripe_price_id_fk       UUID REFERENCES stripe_prices(id),
  stripe_meter_id_fk       UUID REFERENCES stripe_meters(id),
  description              TEXT,
  quantity                 BIGINT NOT NULL,
  unit_amount_cents        BIGINT,
  amount_cents             BIGINT NOT NULL,
  period_start             TIMESTAMPTZ,
  period_end               TIMESTAMPTZ
);
CREATE INDEX ix_stripe_invoice_lines_invoice ON stripe_invoice_line_items(stripe_invoice_id_fk);

-- ===========================================================================
-- 6. ADJUSTMENTS (credits, refunds)
-- ===========================================================================

CREATE TABLE credits (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id                UUID NOT NULL REFERENCES orgs(id) ON DELETE RESTRICT,
  amount_cents          BIGINT NOT NULL,
  currency              CHAR(3) NOT NULL,
  reason                TEXT NOT NULL,
  applied_to_invoice_id UUID REFERENCES stripe_invoices(id),
  created_by_user_id    UUID REFERENCES users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_credits_org ON credits(org_id);

CREATE TABLE refunds (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id                 UUID NOT NULL REFERENCES orgs(id) ON DELETE RESTRICT,
  stripe_refund_id       TEXT NOT NULL UNIQUE,
  stripe_charge_id       TEXT,
  stripe_invoice_id_fk   UUID REFERENCES stripe_invoices(id),
  amount_cents           BIGINT NOT NULL,
  currency               CHAR(3) NOT NULL,
  status                 TEXT NOT NULL,                  -- 'pending'|'succeeded'|'failed'|'canceled'
  reason                 TEXT,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_refunds_org ON refunds(org_id);

-- ===========================================================================
-- 7. RELIABILITY (idempotency, audit)
-- ===========================================================================

CREATE TABLE idempotency_keys (
  key              TEXT NOT NULL,
  org_id           UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  scope            TEXT NOT NULL,                   -- 'http:POST /v1/runs'
  request_hash     TEXT NOT NULL,                   -- sha256 of canonical request
  response_status  INT,
  response_body    JSONB,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at       TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (org_id, key)
);
CREATE INDEX ix_idempotency_expires ON idempotency_keys(expires_at);

CREATE TABLE audit_log (
  id              BIGSERIAL PRIMARY KEY,
  org_id          UUID REFERENCES orgs(id) ON DELETE SET NULL,
  actor_user_id   UUID REFERENCES users(id) ON DELETE SET NULL,
  actor_kind      TEXT NOT NULL,                    -- 'user'|'system'|'webhook'
  action          TEXT NOT NULL,                    -- 'outcome.sent'|'subscription.updated'
  target_type     TEXT NOT NULL,
  target_id       TEXT NOT NULL,
  before          JSONB,
  after           JSONB,
  occurred_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_audit_org_time  ON audit_log(org_id, occurred_at DESC);
CREATE INDEX ix_audit_target    ON audit_log(target_type, target_id);

-- ===========================================================================
-- 8. SEED — Inbox Triage tile + its two metered units
-- ===========================================================================

INSERT INTO tiles (slug, name, description) VALUES
  ('inbox-triage',
   'Inbox Triage',
   'Reads inbound email, classifies actionables, drafts replies in user voice.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO tile_meters (tile_id, meter_slug, label, unit_label) VALUES
  ((SELECT id FROM tiles WHERE slug='inbox-triage'),
   'actionable_email_surfaced',
   'Actionable email surfaced',
   'email'),
  ((SELECT id FROM tiles WHERE slug='inbox-triage'),
   'draft_accepted',
   'Draft accepted by user',
   'draft')
ON CONFLICT (tile_id, meter_slug) DO NOTHING;

-- ===========================================================================
-- 9. ROW-LEVEL SECURITY (templates — enable per deployment)
-- ===========================================================================
-- Run as a follow-up migration once your auth layer sets
-- `set_config('llai.current_org_id', :org_id, true)` per request.
--
-- ALTER TABLE tile_runs       ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE usage_events    ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE outcomes        ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE stripe_invoices ENABLE ROW LEVEL SECURITY;
-- -- (etc. for every business table)
--
-- CREATE POLICY p_tile_runs_org ON tile_runs
--   USING (org_id = current_setting('llai.current_org_id')::uuid);
-- (Repeat per table.)

COMMIT;

-- =============================================================================
-- END OF MIGRATION
-- =============================================================================
