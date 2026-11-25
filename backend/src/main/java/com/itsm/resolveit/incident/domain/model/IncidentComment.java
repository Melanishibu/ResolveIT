package com.itsm.resolveit.incident.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/** A comment on an incident (RIT-US-20): who wrote it, when, and the text. Comments are never edited or deleted. */
public record IncidentComment(UUID id, IncidentId incidentId, UUID authorId, CommentText text, Instant createdAt) {

    public IncidentComment {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(incidentId, "incidentId");
        Objects.requireNonNull(authorId, "authorId");
        Objects.requireNonNull(text, "text");
        Objects.requireNonNull(createdAt, "createdAt");
    }
}
