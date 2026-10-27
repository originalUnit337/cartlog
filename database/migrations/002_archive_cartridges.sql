ALTER TABLE cartridges
    ADD COLUMN archived_at TIMESTAMPTZ;

ALTER TABLE cartridge_logs
    DROP CONSTRAINT IF EXISTS cartridge_logs_action_check;

ALTER TABLE cartridge_logs
    ADD CONSTRAINT cartridge_logs_action_check
    CHECK (action IN ('created', 'updated', 'statusChanged', 'removed'));
