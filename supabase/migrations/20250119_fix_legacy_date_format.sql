-- =====================================================
-- FIX LEGACY DATE FORMATS IN EXPENSES TABLE
-- One-time migration to convert Italian format dates (dd/MM/yyyy) to ISO 8601
-- =====================================================

-- This migration fixes date entries that were saved in Italian format (dd/MM/yyyy)
-- and converts them to ISO 8601 format (YYYY-MM-DD)

-- STEP 1: Create a function to detect and convert Italian format dates
CREATE OR REPLACE FUNCTION convert_italian_date_format()
RETURNS void AS $$
DECLARE
  expense_record RECORD;
  date_str TEXT;
  converted_date TIMESTAMPTZ;
  affected_count INT := 0;
BEGIN
  -- Loop through all expenses
  FOR expense_record IN
    SELECT id, date::TEXT as date_text
    FROM expenses
  LOOP
    date_str := expense_record.date_text;

    -- Check if date matches Italian format pattern (dd/MM/yyyy)
    -- Italian format has format like: "08/09/2025" or "31/12/2024"
    IF date_str ~ '^\d{2}/\d{2}/\d{4}' THEN
      BEGIN
        -- Parse Italian format date: dd/MM/yyyy
        -- Split the date string and reconstruct as ISO format
        converted_date := TO_TIMESTAMP(
          SPLIT_PART(date_str, '/', 3) || '-' ||  -- year
          SPLIT_PART(date_str, '/', 2) || '-' ||  -- month
          SPLIT_PART(date_str, '/', 1),           -- day
          'YYYY-MM-DD'
        );

        -- Update the expense with the converted date
        UPDATE expenses
        SET date = converted_date
        WHERE id = expense_record.id;

        affected_count := affected_count + 1;

        RAISE NOTICE 'Converted expense %: % -> %',
          expense_record.id,
          date_str,
          converted_date;

      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to convert date for expense %: % (error: %)',
          expense_record.id,
          date_str,
          SQLERRM;
      END;
    END IF;
  END LOOP;

  RAISE NOTICE 'Migration complete: % expenses converted', affected_count;
END;
$$ LANGUAGE plpgsql;

-- STEP 2: Execute the conversion
SELECT convert_italian_date_format();

-- STEP 3: Clean up the temporary function
DROP FUNCTION convert_italian_date_format();

-- STEP 4: Add comment
COMMENT ON TABLE expenses IS 'Expenses table - Date format fixed on 2025-01-19';
