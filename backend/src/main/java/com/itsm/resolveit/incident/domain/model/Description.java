package com.itsm.resolveit.incident.domain.model;

/** Incident description (common rules: 1–2000 characters). Line breaks and tabs are allowed. */
public record Description(String value) {

    public static final int MAX_LENGTH = 2000;

    public Description {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Description is required");
        }
        value = value.strip();
        if (value.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("Description must be at most " + MAX_LENGTH + " characters");
        }
        if (value.chars().anyMatch(c -> Character.isISOControl(c) && c != '\n' && c != '\r' && c != '\t')) {
            throw new IllegalArgumentException("Description must not contain control characters");
        }
    }

    @Override
    public String toString() {
        return value;
    }
}
