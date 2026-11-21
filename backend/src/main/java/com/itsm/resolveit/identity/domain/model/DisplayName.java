package com.itsm.resolveit.identity.domain.model;

/** The name shown for a user in the app (for example in the top bar). */
public record DisplayName(String value) {

    public static final int MAX_LENGTH = 100;

    public DisplayName {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Display name is required");
        }
        value = value.strip();
        if (value.chars().anyMatch(Character::isISOControl)) {
            throw new IllegalArgumentException("DisplayName must not contain control characters");
        }
        if (value.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("Display name must be at most " + MAX_LENGTH + " characters");
        }
    }

    @Override
    public String toString() {
        return value;
    }
}
