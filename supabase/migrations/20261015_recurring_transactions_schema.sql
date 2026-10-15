-- ============================================================================
-- Migration: Create recurring_transactions table and associate with expenses/incomes
-- Date: 2026-10-15
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.recurring_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Tipo di movimento
    is_income BOOLEAN NOT NULL DEFAULT FALSE,
    title TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    is_variable_amount BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Categorizzazione & Destinazione
    category TEXT NOT NULL,
    wallet_id UUID REFERENCES public.wallets(id) ON DELETE SET NULL,
    portfolio_id UUID REFERENCES public.investment_portfolios(id) ON DELETE SET NULL,
    
    -- Supporto Multi-User / Gruppi
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    paid_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    split_type TEXT DEFAULT 'equal' CHECK (split_type IN ('equal', 'custom', 'full', 'none')),
    split_data JSONB,
    
    -- Frequenza & Calendarizzazione
    frequency TEXT NOT NULL CHECK (frequency IN ('weekly', 'biweekly', 'monthly', 'bimonthly', 'quarterly', 'semiannual', 'yearly')),
    interval_count INT NOT NULL DEFAULT 1,
    day_of_month INT CHECK (day_of_month BETWEEN 1 AND 31),
    day_of_week INT CHECK (day_of_week BETWEEN 0 AND 6),
    
    -- Ciclo di vita & Date
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    next_due_date DATE NOT NULL,
    last_generated_at TIMESTAMPTZ,
    
    -- Automazione & Controllo
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    requires_confirmation BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE public.recurring_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own recurring transactions" ON public.recurring_transactions;
CREATE POLICY "Users can manage their own recurring transactions"
    ON public.recurring_transactions
    FOR ALL
    USING (
        auth.uid() = user_id 
        OR (group_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.group_members 
            WHERE group_members.group_id = recurring_transactions.group_id 
            AND group_members.user_id = auth.uid()
        ))
    );

CREATE INDEX IF NOT EXISTS idx_recurring_user ON public.recurring_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_recurring_due ON public.recurring_transactions(next_due_date) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_recurring_group ON public.recurring_transactions(group_id);

-- Aggiunta colonna opzionale su expenses e incomes
ALTER TABLE public.expenses 
    ADD COLUMN IF NOT EXISTS recurring_transaction_id UUID REFERENCES public.recurring_transactions(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_expenses_recurring ON public.expenses(recurring_transaction_id);

ALTER TABLE public.incomes 
    ADD COLUMN IF NOT EXISTS recurring_transaction_id UUID REFERENCES public.recurring_transactions(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_incomes_recurring ON public.incomes(recurring_transaction_id);
