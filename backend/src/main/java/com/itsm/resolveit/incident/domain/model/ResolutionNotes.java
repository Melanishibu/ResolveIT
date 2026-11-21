package com.itsm.resolveit.incident.domain.model;

/**
 * What was done to resolve an incident (common rules: 10–2000 characters after trimming). Missing or out-of-range
 * notes are refused with {@code INCIDENT_RESOLUTION_NOTES_REQUIRED}.
 */
public record ResolutionNotes(String value) {

    public static final int MIN_LENGTH = 10;
    public static final int MAX_LENGTH = 2000;

    public ResolutionNotes {
        String text = value == null ? "" : value.strip();
        if (text.length() < MIN_LENGTH || text.length() > MAX_LENGTH
                || text.chars().anyMatch(c -> Character.isISOControl(c) && c != '\n' && c != '\r' && c != '\t')) {
            throw new IncidentResolutionNotesRequiredException();
        }
        value = text;
    }
}
