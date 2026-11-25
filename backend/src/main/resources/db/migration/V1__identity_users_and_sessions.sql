-- RIT-US-04 (AB#13): users and sessions of the identity context (schema identity).

CREATE TABLE identity.app_user (
    id                    UUID         PRIMARY KEY,
    -- Stored in lower case, so the UNIQUE constraint makes email unique case-insensitively.
    email                 VARCHAR(254) NOT NULL,
    display_name          VARCHAR(100) NOT NULL,
    role                  VARCHAR(20)  NOT NULL,
    password_hash         VARCHAR(100) NOT NULL,
    active                BOOLEAN      NOT NULL,
    failed_login_attempts INTEGER      NOT NULL DEFAULT 0,
    locked_until          TIMESTAMPTZ,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT app_user_email_unique UNIQUE (email),
    CONSTRAINT app_user_email_lower_case CHECK (email = lower(email)),
    CONSTRAINT app_user_role_known CHECK (role IN ('ADMIN', 'SUPPORT_AGENT', 'EMPLOYEE')),
    CONSTRAINT app_user_failed_attempts_not_negative CHECK (failed_login_attempts >= 0)
);

CREATE TABLE identity.user_session (
    id         UUID        PRIMARY KEY,
    user_id    UUID        NOT NULL REFERENCES identity.app_user (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT user_session_expires_after_start CHECK (expires_at > created_at)
);

CREATE INDEX user_session_user_id_idx ON identity.user_session (user_id);
