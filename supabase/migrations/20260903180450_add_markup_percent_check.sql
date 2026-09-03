-- Documentation-only, no live behavior change. This DDL was already applied
-- directly via Supabase MCP on 2026-09-03. Codex's independent verification
-- pass on the Venmo-surcharge/Markup number-input fix (commit 67c10dd) found
-- that v3_batches had a real CHECK constraint protecting venmo_surcharge_percent
-- (0-30) but none protecting markup_percent -- the 0-100 bound existed only in
-- the admin UI's client-side clamp, not enforced by the database. This closes
-- that gap with the matching DB-level guardrail.

ALTER TABLE v3_batches
  ADD CONSTRAINT v3_batches_markup_percent_check
  CHECK (markup_percent >= 0 AND markup_percent <= 100);
