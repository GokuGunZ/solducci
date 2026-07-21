-- Migration for Infinite Canvas File System (Nodes Table)

CREATE TABLE IF NOT EXISTS canvas_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES canvas_nodes(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'folder', 'markdown', 'url'
    lexorank VARCHAR(255) NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    payload JSONB DEFAULT '{}'::jsonb,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    last_accessed_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Fast recursive and ordering queries
CREATE INDEX idx_canvas_nodes_parent_id ON canvas_nodes(parent_id);
CREATE INDEX idx_canvas_nodes_lexorank ON canvas_nodes(lexorank);
CREATE INDEX idx_canvas_nodes_group_user ON canvas_nodes(group_id, user_id);

-- Enable RLS
ALTER TABLE canvas_nodes ENABLE ROW LEVEL SECURITY;

-- Unified Policy for SELECT, INSERT, UPDATE, DELETE
-- Note: FOR ALL policies apply to all operations using the USING clause (and WITH CHECK clause implicitly matches USING)
CREATE POLICY "Access canvas_nodes based on user or group" ON canvas_nodes
    FOR ALL USING (
        user_id = auth.uid() 
        OR 
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_members.group_id = canvas_nodes.group_id 
            AND group_members.user_id = auth.uid()
        )
    );
