package com.itsm.resolveit.incident.domain.model;

/**
 * Why a resolved incident is reopened (common rules: 10–500 characters after trimming). Missing or out-of-range
 * reasons are refused with {@code INCIDENT_REOPEN_REASON_REQUIRED}.
 */
public record ReopenReason(String value) {

    public static final int MIN_LENGTH = 10;
    public static final int MAX_LENGTH = 500;

    public ReopenReason {
        String text = value == null ? "" : value.strip();
        if (text.length() < MIN_LENGTH || text.length() > MAX_LENGTH
                || text.chars().anyMatch(c -> Character.isISOControl(c) && c != '\n' && c != '\r' && c != '\t')) {
            throw new IncidentReopenReasonRequiredException();
        }
        value = text;
    }
}
