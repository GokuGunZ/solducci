-- Migration: Create wallets, incomes, and wallet_transfers tables
-- Date: 2026-09-26

-- 1. Create wallets table
CREATE TABLE IF NOT EXISTS public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'bank' CHECK (type IN ('bank', 'cash', 'savings', 'credit_card')),
    initial_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    color_hex TEXT NOT NULL DEFAULT '#10B981',
    icon_name TEXT NOT NULL DEFAULT 'account_balance',
    is_default BOOLEAN NOT NULL DEFAULT false,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for wallets
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own wallets"
    ON public.wallets
    FOR ALL
    USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_wallets_user ON public.wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallets_user_default ON public.wallets(user_id) WHERE is_default = true;

-- 2. Add optional wallet_id to expenses table (Safe & Backward compatible)
ALTER TABLE public.expenses 
    ADD COLUMN IF NOT EXISTS wallet_id UUID REFERENCES public.wallets(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_expenses_wallet ON public.expenses(wallet_id);

-- 3. Create incomes table
CREATE TABLE IF NOT EXISTS public.incomes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES public.wallets(id) ON DELETE SET NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    date DATE NOT NULL,
    category TEXT NOT NULL DEFAULT 'stipendio' 
        CHECK (category IN ('stipendio', 'regalo', 'rimborso', 'rendita', 'vendite', 'altro')),
    is_recurring BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for incomes
ALTER TABLE public.incomes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own incomes"
    ON public.incomes
    FOR ALL
    USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_incomes_user_date ON public.incomes(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_incomes_wallet ON public.incomes(wallet_id);

-- 4. Create wallet_transfers table (Giroconti)
CREATE TABLE IF NOT EXISTS public.wallet_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    from_wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
    to_wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT different_wallets CHECK (from_wallet_id <> to_wallet_id)
);

-- Enable RLS for transfers
ALTER TABLE public.wallet_transfers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own wallet transfers"
    ON public.wallet_transfers
    FOR ALL
    USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_transfers_user ON public.wallet_transfers(user_id);
CREATE INDEX IF NOT EXISTS idx_transfers_from_wallet ON public.wallet_transfers(from_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transfers_to_wallet ON public.wallet_transfers(to_wallet_id);

-- 5. Helper function to create default wallets for a user if none exist
CREATE OR REPLACE FUNCTION public.create_default_wallets_for_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.wallets WHERE user_id = p_user_id) THEN
        INSERT INTO public.wallets (user_id, name, type, initial_balance, color_hex, icon_name, is_default)
        VALUES 
            (p_user_id, 'Conto Principale', 'bank', 0.00, '#10B981', 'account_balance', true),
            (p_user_id, 'Contanti', 'cash', 0.00, '#F59E0B', 'payments', false);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
