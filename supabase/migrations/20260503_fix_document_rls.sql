-- Migration to fix Document RLS policies for shared access
-- Created: 2026-05-03

-- 1. DROP EXISTING RESTRICTIVE POLICIES
DROP POLICY IF EXISTS "Users can view their own documents" ON documents;
DROP POLICY IF EXISTS "Users can insert their own documents" ON documents;
DROP POLICY IF EXISTS "Users can update their own documents" ON documents;
DROP POLICY IF EXISTS "Users can delete their own documents" ON documents;

DROP POLICY IF EXISTS "Users can view tasks from their documents" ON tasks;
DROP POLICY IF EXISTS "Users can insert tasks to their documents" ON tasks;
DROP POLICY IF EXISTS "Users can update tasks from their documents" ON tasks;
DROP POLICY IF EXISTS "Users can delete tasks from their documents" ON tasks;

-- 2. APPLY ZERO RECURSION STRATEGY (Allow Select all, filter in app)
-- Documents
CREATE POLICY "Users can view all documents" ON documents FOR SELECT USING (true);
CREATE POLICY "Users can insert any document" ON documents FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any document" ON documents FOR UPDATE USING (true);
CREATE POLICY "Users can delete any document" ON documents FOR DELETE USING (true);

-- Tasks
CREATE POLICY "Users can view all tasks" ON tasks FOR SELECT USING (true);
CREATE POLICY "Users can insert any task" ON tasks FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any task" ON tasks FOR UPDATE USING (true);
CREATE POLICY "Users can delete any task" ON tasks FOR DELETE USING (true);

-- Task Tags
DROP POLICY IF EXISTS "Users can view task_tags for their tasks" ON task_tags;
DROP POLICY IF EXISTS "Users can insert task_tags for their tasks" ON task_tags;
DROP POLICY IF EXISTS "Users can delete task_tags from their tasks" ON task_tags;
CREATE POLICY "Users can view all task_tags" ON task_tags FOR SELECT USING (true);
CREATE POLICY "Users can insert any task_tag" ON task_tags FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can delete any task_tag" ON task_tags FOR DELETE USING (true);

-- Tags (these are still mostly personal, but let's make them accessible for now)
DROP POLICY IF EXISTS "Users can view their own tags" ON tags;
DROP POLICY IF EXISTS "Users can insert their own tags" ON tags;
DROP POLICY IF EXISTS "Users can update their own tags" ON tags;
DROP POLICY IF EXISTS "Users can delete their own tags" ON tags;
CREATE POLICY "Users can view all tags" ON tags FOR SELECT USING (true);
CREATE POLICY "Users can insert any tag" ON tags FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any tag" ON tags FOR UPDATE USING (true);
CREATE POLICY "Users can delete any tag" ON tags FOR DELETE USING (true);

-- Space Items (they already use EXISTS (SELECT 1 FROM documents WHERE id = document_id))
-- But with 'Users can view all documents', that should work.
-- However, to be consistent with 'Zero Recursion', we can simplify them too.

DROP POLICY IF EXISTS "Users can view note_items if they have access to document" ON note_items;
DROP POLICY IF EXISTS "Users can insert note_items if they have access to document" ON note_items;
DROP POLICY IF EXISTS "Users can update note_items if they have access to document" ON note_items;
DROP POLICY IF EXISTS "Users can delete note_items if they have access to document" ON note_items;
CREATE POLICY "Users can view all note_items" ON note_items FOR SELECT USING (true);
CREATE POLICY "Users can insert any note_item" ON note_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any note_item" ON note_items FOR UPDATE USING (true);
CREATE POLICY "Users can delete any note_item" ON note_items FOR DELETE USING (true);

-- Asterisks
DROP POLICY IF EXISTS "Access asterisk_items via document" ON asterisk_items;
CREATE POLICY "Users can view all asterisk_items" ON asterisk_items FOR SELECT USING (true);
CREATE POLICY "Users can insert any asterisk_item" ON asterisk_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any asterisk_item" ON asterisk_items FOR UPDATE USING (true);
CREATE POLICY "Users can delete any asterisk_item" ON asterisk_items FOR DELETE USING (true);

-- Resources
DROP POLICY IF EXISTS "Access resource_items via document" ON resource_items;
CREATE POLICY "Users can view all resource_items" ON resource_items FOR SELECT USING (true);
CREATE POLICY "Users can insert any resource_item" ON resource_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any resource_item" ON resource_items FOR UPDATE USING (true);
CREATE POLICY "Users can delete any resource_item" ON resource_items FOR DELETE USING (true);

-- Pantry
DROP POLICY IF EXISTS "Access pantry_items via document" ON pantry_items;
CREATE POLICY "Users can view all pantry_items" ON pantry_items FOR SELECT USING (true);
CREATE POLICY "Users can insert any pantry_item" ON pantry_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any pantry_item" ON pantry_items FOR UPDATE USING (true);
CREATE POLICY "Users can delete any pantry_item" ON pantry_items FOR DELETE USING (true);

-- Shopping List
DROP POLICY IF EXISTS "Access shopping_list_items via document" ON shopping_list_items;
CREATE POLICY "Users can view all shopping_list_items" ON shopping_list_items FOR SELECT USING (true);
CREATE POLICY "Users can insert any shopping_list_item" ON shopping_list_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any shopping_list_item" ON shopping_list_items FOR UPDATE USING (true);
CREATE POLICY "Users can delete any shopping_list_item" ON shopping_list_items FOR DELETE USING (true);

-- Pantry Quantities
CREATE POLICY "Users can view all pantry_quantities" ON pantry_quantities FOR SELECT USING (true);
CREATE POLICY "Users can insert any pantry_quantity" ON pantry_quantities FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any pantry_quantity" ON pantry_quantities FOR UPDATE USING (true);
CREATE POLICY "Users can delete any pantry_quantity" ON pantry_quantities FOR DELETE USING (true);

-- Resource Tags
CREATE POLICY "Users can view all resource_item_tags" ON resource_item_tags FOR SELECT USING (true);
CREATE POLICY "Users can insert any resource_item_tag" ON resource_item_tags FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any resource_item_tag" ON resource_item_tags FOR UPDATE USING (true);
CREATE POLICY "Users can delete any resource_item_tag" ON resource_item_tags FOR DELETE USING (true);

-- Resource Reads
CREATE POLICY "Users can view all resource_item_reads" ON resource_item_reads FOR SELECT USING (true);
CREATE POLICY "Users can insert any resource_item_read" ON resource_item_reads FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any resource_item_read" ON resource_item_reads FOR UPDATE USING (true);
CREATE POLICY "Users can delete any resource_item_read" ON resource_item_reads FOR DELETE USING (true);

-- Recurrences
DROP POLICY IF EXISTS "Users can view recurrences for their tasks" ON recurrences;
DROP POLICY IF EXISTS "Users can insert recurrences for their tasks/tags" ON recurrences;
DROP POLICY IF EXISTS "Users can update recurrences for their tasks/tags" ON recurrences;
DROP POLICY IF EXISTS "Users can delete recurrences for their tasks/tags" ON recurrences;
CREATE POLICY "Users can view all recurrences" ON recurrences FOR SELECT USING (true);
CREATE POLICY "Users can insert any recurrence" ON recurrences FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any recurrence" ON recurrences FOR UPDATE USING (true);
CREATE POLICY "Users can delete any recurrence" ON recurrences FOR DELETE USING (true);

-- Task Completions
DROP POLICY IF EXISTS "Users can view completions for their tasks" ON task_completions;
DROP POLICY IF EXISTS "Users can insert completions for their tasks" ON task_completions;
DROP POLICY IF EXISTS "Users can delete completions for their tasks" ON task_completions;
CREATE POLICY "Users can view all task_completions" ON task_completions FOR SELECT USING (true);
CREATE POLICY "Users can insert any task_completion" ON task_completions FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update any task_completion" ON task_completions FOR UPDATE USING (true);
CREATE POLICY "Users can delete any task_completion" ON task_completions FOR DELETE USING (true);
