-- Migration to update the document_type check constraint to include new types
-- Created: 2026-04-29

-- 1. Identify the existing constraint name (it's usually documents_document_type_check)
-- 2. Drop the existing constraint
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_document_type_check;

-- 3. Add the updated constraint with all current document types
ALTER TABLE documents ADD CONSTRAINT documents_document_type_check 
  CHECK (document_type IN ('todo', 'shopping_list', 'dispensa', 'generic_list', 'note', 'asterisk', 'resource_list'));

-- 4. Update the comment to reflect the new types
COMMENT ON COLUMN documents.document_type IS 'Type of document: todo, shopping_list, dispensa, generic_list, note, asterisk, resource_list';
