-- RIT-US-09 (AB#37): incidents, the per-year ticket counter and the append-only incident audit log (schema incident).
-- Users are referenced by UUID only: no foreign keys into the identity schema (common rules).

CREATE TABLE incident.incident (
    id            UUID          PRIMARY KEY,
    ticket_number VARCHAR(14)   NOT NULL,
    title         VARCHAR(120)  NOT NULL,
    description   VARCHAR(2000) NOT NULL,
    category      VARCHAR(20)   NOT NULL,
    priority      VARCHAR(20)   NOT NULL,
    status        VARCHAR(20)   NOT NULL,
    created_by    UUID          NOT NULL,
    created_at    TIMESTAMPTZ   NOT NULL,
    CONSTRAINT incident_ticket_number_unique UNIQUE (ticket_number),
    CONSTRAINT incident_ticket_number_format CHECK (ticket_number ~ '^INC-[0-9]{4}-[0-9]{5}$'),
    CONSTRAINT incident_category_known CHECK (category IN ('HARDWARE', 'SOFTWARE', 'NETWORK', 'ACCESS', 'OTHER')),
    CONSTRAINT incident_priority_known CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT incident_status_known CHECK (status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'))
);

CREATE INDEX incident_created_by_idx ON incident.incident (created_by, created_at);

-- One row per year; the next number is taken with one atomic upsert that locks the row until commit (BR-002).
CREATE TABLE incident.ticket_counter (
    year        INTEGER PRIMARY KEY,
    last_number INTEGER NOT NULL,
    CONSTRAINT ticket_counter_range CHECK (last_number BETWEEN 1 AND 99999)
);

-- Append-only (common rules, Audit).
CREATE TABLE incident.incident_audit_log (
    id          UUID         PRIMARY KEY,
    incident_id UUID         NOT NULL REFERENCES incident.incident (id),
    actor_id    UUID         NOT NULL,
    action      VARCHAR(30)  NOT NULL,
    old_value   VARCHAR(500),
    new_value   VARCHAR(500),
    occurred_at TIMESTAMPTZ  NOT NULL
);

CREATE INDEX incident_audit_log_incident_idx ON incident.incident_audit_log (incident_id, occurred_at);

REVOKE UPDATE, DELETE, TRUNCATE ON incident.incident_audit_log FROM PUBLIC;
REVOKE UPDATE, DELETE, TRUNCATE ON incident.incident_audit_log FROM CURRENT_USER;

-- Superusers ignore privileges (local and test database users are superusers): triggers refuse changes for every role.
CREATE FUNCTION incident.refuse_audit_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Audit entries are append-only: % on % is refused', TG_OP, TG_TABLE_NAME
        USING ERRCODE = 'insufficient_privilege';
END;
$$;

CREATE TRIGGER incident_audit_log_no_update_or_delete
    BEFORE UPDATE OR DELETE ON incident.incident_audit_log
    FOR EACH ROW EXECUTE FUNCTION incident.refuse_audit_change();

CREATE TRIGGER incident_audit_log_no_truncate
    BEFORE TRUNCATE ON incident.incident_audit_log
    FOR EACH STATEMENT EXECUTE FUNCTION incident.refuse_audit_change();
