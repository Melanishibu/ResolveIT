-- RIT-US-06 (AB#48): departments, users without a password, invitations and the append-only user audit log.

-- Every user has a department (1–80 characters). Rows that existed before get a placeholder; the dev seed sets
-- the real ones. New users always get one from the application.
ALTER TABLE identity.app_user ADD COLUMN department VARCHAR(80) NOT NULL DEFAULT 'Unassigned';
ALTER TABLE identity.app_user ALTER COLUMN department DROP DEFAULT;

-- Invited users have no password until they set one from the invitation link (RIT-US-07).
ALTER TABLE identity.app_user ALTER COLUMN password_hash DROP NOT NULL;

CREATE TABLE identity.invitation (
    id         UUID        PRIMARY KEY,
    user_id    UUID        NOT NULL REFERENCES identity.app_user (id),
    -- SHA-256 of the token, hex encoded. The token itself is never stored.
    token_hash CHAR(64)    NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    status     VARCHAR(20) NOT NULL,
    CONSTRAINT invitation_token_hash_unique UNIQUE (token_hash),
    CONSTRAINT invitation_status_known CHECK (status IN ('PENDING', 'SENT', 'SEND_FAILED', 'USED')),
    CONSTRAINT invitation_expires_after_creation CHECK (expires_at > created_at)
);

CREATE INDEX invitation_user_id_idx ON identity.invitation (user_id);

-- Append-only (common rules, Audit): entries are only ever inserted. No passwords, tokens or links.
CREATE TABLE identity.user_audit_log (
    id          UUID         PRIMARY KEY,
    user_id     UUID         NOT NULL,
    actor_id    UUID,
    action      VARCHAR(40)  NOT NULL,
    old_value   VARCHAR(500),
    new_value   VARCHAR(500),
    occurred_at TIMESTAMPTZ  NOT NULL
);

CREATE INDEX user_audit_log_user_id_idx ON identity.user_audit_log (user_id, occurred_at);

-- The application's database role may not change or remove audit entries. PostgreSQL lets the owner revoke its own
-- privileges, so this holds even though the application role also owns the table.
REVOKE UPDATE, DELETE, TRUNCATE ON identity.user_audit_log FROM PUBLIC;
REVOKE UPDATE, DELETE, TRUNCATE ON identity.user_audit_log FROM CURRENT_USER;

-- Superusers ignore privileges (the local docker-compose and Testcontainers users are superusers), so the database
-- also refuses changes with triggers, for every role.
CREATE FUNCTION identity.refuse_audit_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Audit entries are append-only: % on % is refused', TG_OP, TG_TABLE_NAME
        USING ERRCODE = 'insufficient_privilege';
END;
$$;

CREATE TRIGGER user_audit_log_no_update_or_delete
    BEFORE UPDATE OR DELETE ON identity.user_audit_log
    FOR EACH ROW EXECUTE FUNCTION identity.refuse_audit_change();

CREATE TRIGGER user_audit_log_no_truncate
    BEFORE TRUNCATE ON identity.user_audit_log
    FOR EACH STATEMENT EXECUTE FUNCTION identity.refuse_audit_change();
