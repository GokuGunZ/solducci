-- ==============================================================================
-- Migration: Create Investments, Portfolios, Assets and Allocations Schema
-- Date: 2026-09-27
-- Description: Adds tables and RLS for investment portfolios, assets,
--              historical price snapshots, and multi-asset expense allocations.
-- ==============================================================================

-- 1. Tabella Portafogli di Investimento
CREATE TABLE IF NOT EXISTS public.investment_portfolios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    broker_name TEXT,
    color_hex TEXT DEFAULT '#6366F1',
    icon TEXT DEFAULT 'trending_up',
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_investment_portfolios_user_id ON public.investment_portfolios(user_id);
CREATE INDEX IF NOT EXISTS idx_investment_portfolios_group_id ON public.investment_portfolios(group_id);

-- 2. Tabella Singoli Asset
CREATE TABLE IF NOT EXISTS public.investment_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_id UUID NOT NULL REFERENCES public.investment_portfolios(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    ticker TEXT,
    asset_class TEXT NOT NULL DEFAULT 'etf',
    total_quantity NUMERIC(18, 8) DEFAULT 0,
    invested_capital NUMERIC(12, 2) DEFAULT 0,
    current_price NUMERIC(18, 4) DEFAULT 0,
    last_price_update TIMESTAMPTZ DEFAULT now(),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_investment_assets_portfolio_id ON public.investment_assets(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_investment_assets_ticker ON public.investment_assets(ticker);

-- 3. Tabella Storico Prezzi (Snapshots)
CREATE TABLE IF NOT EXISTS public.asset_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES public.investment_assets(id) ON DELETE CASCADE,
    price NUMERIC(18, 4) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    source TEXT DEFAULT 'manual', -- 'purchase', 'manual', 'api'
    note TEXT
);

CREATE INDEX IF NOT EXISTS idx_asset_price_history_asset_id_timestamp ON public.asset_price_history(asset_id, timestamp DESC);

-- 4. Tabella Allocazione Multi-Asset per Spesa di Investimento
CREATE TABLE IF NOT EXISTS public.expense_asset_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id BIGINT NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
    asset_id UUID NOT NULL REFERENCES public.investment_assets(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL,
    quantity NUMERIC(18, 8) NOT NULL,
    price_per_unit NUMERIC(18, 4) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_expense_asset_allocations_expense_id ON public.expense_asset_allocations(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_asset_allocations_asset_id ON public.expense_asset_allocations(asset_id);

-- 5. Aggiunta colonne portfolio_id su tabella expenses e incomes (se non presenti)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'portfolio_id'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN portfolio_id UUID REFERENCES public.investment_portfolios(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'incomes' 
        AND column_name = 'portfolio_id'
    ) THEN
        ALTER TABLE public.incomes ADD COLUMN portfolio_id UUID REFERENCES public.investment_portfolios(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'incomes' 
        AND column_name = 'asset_id'
    ) THEN
        ALTER TABLE public.incomes ADD COLUMN asset_id UUID REFERENCES public.investment_assets(id) ON DELETE SET NULL;
    END IF;
END $$;

-- ==============================================================================
-- Row Level Security (RLS)
-- ==============================================================================
ALTER TABLE public.investment_portfolios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investment_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_asset_allocations ENABLE ROW LEVEL SECURITY;

-- Policies per investment_portfolios
DROP POLICY IF EXISTS "Users can view own or group portfolios" ON public.investment_portfolios;
CREATE POLICY "Users can view own or group portfolios"
    ON public.investment_portfolios FOR SELECT
    USING (
        auth.uid()::text = user_id::text
        OR (
            group_id IS NOT NULL 
            AND EXISTS (
                SELECT 1 FROM public.group_members 
                WHERE group_members.group_id = investment_portfolios.group_id 
                AND group_members.user_id::text = auth.uid()::text
            )
        )
    );

DROP POLICY IF EXISTS "Users can insert own or group portfolios" ON public.investment_portfolios;
CREATE POLICY "Users can insert own or group portfolios"
    ON public.investment_portfolios FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can update own or group portfolios" ON public.investment_portfolios;
CREATE POLICY "Users can update own or group portfolios"
    ON public.investment_portfolios FOR UPDATE
    USING (
        auth.uid()::text = user_id::text
        OR (
            group_id IS NOT NULL 
            AND EXISTS (
                SELECT 1 FROM public.group_members 
                WHERE group_members.group_id = investment_portfolios.group_id 
                AND group_members.user_id::text = auth.uid()::text
            )
        )
    );

DROP POLICY IF EXISTS "Users can delete own portfolios" ON public.investment_portfolios;
CREATE POLICY "Users can delete own portfolios"
    ON public.investment_portfolios FOR DELETE
    USING (auth.uid()::text = user_id::text);

-- Policies per investment_assets
DROP POLICY IF EXISTS "Users can view assets of accessible portfolios" ON public.investment_assets;
CREATE POLICY "Users can view assets of accessible portfolios"
    ON public.investment_assets FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.investment_portfolios p
            WHERE p.id = investment_assets.portfolio_id
            AND (
                p.user_id::text = auth.uid()::text
                OR (
                    p.group_id IS NOT NULL 
                    AND EXISTS (
                        SELECT 1 FROM public.group_members gm
                        WHERE gm.group_id = p.group_id 
                        AND gm.user_id::text = auth.uid()::text
                    )
                )
            )
        )
    );

DROP POLICY IF EXISTS "Users can manage assets of accessible portfolios" ON public.investment_assets;
CREATE POLICY "Users can manage assets of accessible portfolios"
    ON public.investment_assets FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.investment_portfolios p
            WHERE p.id = investment_assets.portfolio_id
            AND (
                p.user_id::text = auth.uid()::text
                OR (
                    p.group_id IS NOT NULL 
                    AND EXISTS (
                        SELECT 1 FROM public.group_members gm
                        WHERE gm.group_id = p.group_id 
                        AND gm.user_id::text = auth.uid()::text
                    )
                )
            )
        )
    );

-- Policies per asset_price_history
DROP POLICY IF EXISTS "Users can view price history of accessible assets" ON public.asset_price_history;
CREATE POLICY "Users can view price history of accessible assets"
    ON public.asset_price_history FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.investment_assets a
            JOIN public.investment_portfolios p ON p.id = a.portfolio_id
            WHERE a.id = asset_price_history.asset_id
            AND (
                p.user_id::text = auth.uid()::text
                OR (
                    p.group_id IS NOT NULL 
                    AND EXISTS (
                        SELECT 1 FROM public.group_members gm
                        WHERE gm.group_id = p.group_id 
                        AND gm.user_id::text = auth.uid()::text
                    )
                )
            )
        )
    );

-- Policies per expense_asset_allocations
DROP POLICY IF EXISTS "Users can manage allocations of their expenses" ON public.expense_asset_allocations;
CREATE POLICY "Users can manage allocations of their expenses"
    ON public.expense_asset_allocations FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.expenses e
            WHERE e.id = expense_asset_allocations.expense_id
            AND (
                e.user_id::text = auth.uid()::text
                OR (
                    e.group_id IS NOT NULL 
                    AND EXISTS (
                        SELECT 1 FROM public.group_members gm
                        WHERE gm.group_id = e.group_id 
                        AND gm.user_id::text = auth.uid()::text
                    )
                )
            )
        )
    );
