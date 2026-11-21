-- RIT-US-10 (AB#38): when an incident last changed. Existing incidents were never changed, so updated = created.
ALTER TABLE incident.incident ADD COLUMN updated_at TIMESTAMPTZ;
UPDATE incident.incident SET updated_at = created_at;
ALTER TABLE incident.incident ALTER COLUMN updated_at SET NOT NULL;
