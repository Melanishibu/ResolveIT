package com.itsm.resolveit.incident.domain.model;

import com.itsm.resolveit.shared.error.DomainException;
import java.util.Map;

/** Resolving needs notes of 10–2000 characters ({@code INCIDENT_RESOLUTION_NOTES_REQUIRED}, 400). */
public final class IncidentResolutionNotesRequiredException extends DomainException {

    public IncidentResolutionNotesRequiredException() {
        super(IncidentErrorCode.INCIDENT_RESOLUTION_NOTES_REQUIRED,
                Map.of("min", String.valueOf(ResolutionNotes.MIN_LENGTH), "max",
                        String.valueOf(ResolutionNotes.MAX_LENGTH)));
    }
}
