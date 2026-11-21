-- RIT-US-16 (AB#44): resolution notes (10-2000 characters) on the incident. The RESOLVED audit entry carries the
-- notes as its new value, so the audit value columns grow to 2000 (rows stay append-only).
ALTER TABLE incident.incident ADD COLUMN resolution_notes VARCHAR(2000);
ALTER TABLE incident.incident_audit_log ALTER COLUMN old_value TYPE VARCHAR(2000);
ALTER TABLE incident.incident_audit_log ALTER COLUMN new_value TYPE VARCHAR(2000);
