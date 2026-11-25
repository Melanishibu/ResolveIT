-- RIT-US-20 (AB#53): comments on incidents. Append-only: no edit or delete (common rules).
CREATE TABLE incident.incident_comment (
    id          UUID          PRIMARY KEY,
    incident_id UUID          NOT NULL REFERENCES incident.incident (id),
    author_id   UUID          NOT NULL,
    text        VARCHAR(1000) NOT NULL,
    created_at  TIMESTAMPTZ   NOT NULL
);

CREATE INDEX incident_comment_incident_idx ON incident.incident_comment (incident_id, created_at);
