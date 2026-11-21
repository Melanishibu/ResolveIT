package com.itsm.resolveit.incident.domain.model;

/** Incident title (common rules: 1–120 characters, trimmed, not blank). */
public record Title(String value) {

    public static final int MAX_LENGTH = 120;

    public Title {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Title is required");
        }
        value = value.strip();
        if (value.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("Title must be at most " + MAX_LENGTH + " characters");
        }
        if (value.chars().anyMatch(c -> Character.isISOControl(c))) {
            throw new IllegalArgumentException("Title must not contain control characters");
        }
    }

    @Override
    public String toString() {
        return value;
    }
}
