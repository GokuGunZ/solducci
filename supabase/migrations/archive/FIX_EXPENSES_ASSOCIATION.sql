-- =====================================================
-- FIX: Associa spese esistenti al profilo utente
-- =====================================================
-- IMPORTANTE: Modifica 'TUA-EMAIL@QUI.COM' con la tua email!
-- =====================================================

DO $$
DECLARE
  current_user_id UUID;
  current_email TEXT := 'TUA-EMAIL@QUI.COM';  -- ← MODIFICA QUI!
BEGIN
  -- 1. Trova il tuo user ID
  SELECT id INTO current_user_id
  FROM auth.users
  WHERE email = current_email;

  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Utente con email % non trovato!', current_email;
  END IF;

  RAISE NOTICE 'User ID trovato: %', current_user_id;

  -- 2. Associa tutte le spese senza user_id o con user_id vuoto
  UPDATE expenses
  SET user_id = current_user_id::text
  WHERE user_id IS NULL OR user_id = '' OR user_id = 'null';

  RAISE NOTICE 'Spese aggiornate!';

  -- 3. Mostra il risultato
  RAISE NOTICE '---';
  RAISE NOTICE 'Riepilogo spese per utente:';

  -- Questa query mostra il conteggio
  FOR r IN (
    SELECT
      COALESCE(user_id, 'NULL') as uid,
      COUNT(*) as count
    FROM expenses
    GROUP BY user_id
  )
  LOOP
    RAISE NOTICE 'User ID %= % spese', r.uid, r.count;
  END LOOP;

END $$;

-- Verifica finale
SELECT
  'Totale spese nel database:' as info,
  COUNT(*) as count
FROM expenses;

SELECT
  'Spese associate al tuo account:' as info,
  COUNT(*) as count
FROM expenses e
JOIN auth.users u ON e.user_id = u.id::text;

-- ✅ COMPLETATO!
SELECT 'Associazione spese completata! ✅' as status;
