-- ==============================================================================
-- Migration: Add Collectibles & Physical Assets Fields and Transaction History
-- Date: 2026-09-27
-- Description: Adds columns for collectibles/physical goods (grading, set, serial,
--              storage) and transaction metadata on asset_price_history.
-- ==============================================================================

-- 1. Nuove colonne per beni fisici e collezionismo su investment_assets
ALTER TABLE public.investment_assets ADD COLUMN IF NOT EXISTS edition_or_set TEXT;
ALTER TABLE public.investment_assets ADD COLUMN IF NOT EXISTS condition_or_grading TEXT;
ALTER TABLE public.investment_assets ADD COLUMN IF NOT EXISTS serial_or_cert_number TEXT;
ALTER TABLE public.investment_assets ADD COLUMN IF NOT EXISTS storage_location TEXT;
ALTER TABLE public.investment_assets ADD COLUMN IF NOT EXISTS is_physical BOOLEAN DEFAULT FALSE;

-- 2. Nuove colonne per cronologia transazioni su asset_price_history
ALTER TABLE public.asset_price_history ADD COLUMN IF NOT EXISTS transaction_type TEXT DEFAULT 'snapshot';
ALTER TABLE public.asset_price_history ADD COLUMN IF NOT EXISTS quantity_delta NUMERIC(18, 8);
ALTER TABLE public.asset_price_history ADD COLUMN IF NOT EXISTS total_amount NUMERIC(12, 2);

-- Indice per filtrare per tipologia di transazione
CREATE INDEX IF NOT EXISTS idx_asset_price_history_tx_type ON public.asset_price_history(asset_id, transaction_type);
