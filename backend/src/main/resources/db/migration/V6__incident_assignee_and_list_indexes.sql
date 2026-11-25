-- RIT-US-11 (AB#39): the assigned Support Agent (set by RIT-US-12) and indexes for the role-scoped, sorted list.
ALTER TABLE incident.incident ADD COLUMN assigned_to UUID;

CREATE INDEX incident_created_at_idx ON incident.incident (created_at);
CREATE INDEX incident_assigned_to_idx ON incident.incident (assigned_to, created_at);
