-- Create a table for tracking realtime collaboration on notes
CREATE TABLE IF NOT EXISTS note_collaborators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  last_active TIMESTAMP WITH TIME ZONE DEFAULT now(),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  CONSTRAINT unique_note_user UNIQUE(note_id, user_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_note_collaborators_note_id ON note_collaborators(note_id);
CREATE INDEX IF NOT EXISTS idx_note_collaborators_user_id ON note_collaborators(user_id);
CREATE INDEX IF NOT EXISTS idx_note_collaborators_active ON note_collaborators(is_active);
CREATE INDEX IF NOT EXISTS idx_note_collaborators_last_active ON note_collaborators(last_active);

-- Add Row Level Security
ALTER TABLE note_collaborators ENABLE ROW LEVEL SECURITY;

-- Allow users to see collaborators on notes they are working on
CREATE POLICY "Users can view collaborators for their notes"
  ON note_collaborators
  FOR SELECT
  USING (
    note_id IN (
      SELECT id FROM notes WHERE user_id = auth.uid()
    )
    OR
    user_id = auth.uid()
  );

-- Users can only add/update their own collaboration status
CREATE POLICY "Users can update their own collaboration status"
  ON note_collaborators
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own collaboration status"
  ON note_collaborators
  FOR UPDATE
  USING (user_id = auth.uid());

-- Enable this table for realtime
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;

ALTER PUBLICATION supabase_realtime ADD TABLE note_collaborators; 