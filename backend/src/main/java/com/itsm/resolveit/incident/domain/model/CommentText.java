package com.itsm.resolveit.incident.domain.model;

/** The text of a comment (common rules: 1–1000 characters after trimming). Line breaks and tabs are allowed. */
public record CommentText(String value) {

    public static final int MAX_LENGTH = 1000;

    public CommentText {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Comment text is required");
        }
        value = value.strip();
        if (value.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("Comment text must be at most " + MAX_LENGTH + " characters");
        }
        if (value.chars().anyMatch(c -> Character.isISOControl(c) && c != '\n' && c != '\r' && c != '\t')) {
            throw new IllegalArgumentException("Comment text must not contain control characters");
        }
    }
}
