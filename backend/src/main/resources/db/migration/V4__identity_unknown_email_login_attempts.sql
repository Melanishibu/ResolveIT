-- Bug AB#180: failed login attempts for email addresses that have no account, so that the lockout answers
-- the same for unknown and real accounts and doesn't reveal whether an email address is registered.

CREATE TABLE identity.unknown_email_login_attempt (
    -- Stored in lower case, like identity.app_user.email.
    email                 VARCHAR(254) PRIMARY KEY,
    failed_login_attempts INTEGER      NOT NULL DEFAULT 0,
    locked_until          TIMESTAMPTZ,
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT unknown_email_login_attempt_email_lower_case CHECK (email = lower(email)),
    CONSTRAINT unknown_email_login_attempt_failed_not_negative CHECK (failed_login_attempts >= 0)
);
