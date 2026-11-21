package com.itsm.resolveit.identity.domain.model;

/** The department a user works in: free text, required, 1–80 characters (RIT-US-06, Update 01). */
public record Department(String value) {

    public static final int MAX_LENGTH = 80;

    public Department {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Department is required");
        }
        value = value.strip();
        if (value.chars().anyMatch(Character::isISOControl)) {
            throw new IllegalArgumentException("Department must not contain control characters");
        }
        if (value.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("Department must be at most " + MAX_LENGTH + " characters");
        }
    }

    @Override
    public String toString() {
        return value;
    }
}
