CREATE TABLE telegram_users (
    telegram_id BIGINT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT,
    username TEXT,
    language_code TEXT,
    is_premium BOOLEAN,
    added_to_attachment_menu BOOLEAN,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX telegram_users_last_seen_idx
    ON telegram_users (last_seen_at DESC);
