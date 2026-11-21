package com.itsm.resolveit.identity.domain.model;

/** The opaque session token the browser keeps in the {@code RIT_SESSION} cookie. Never logged. */
public record SessionToken(String value) {

    public SessionToken {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Session token is required");
        }
    }

    @Override
    public String toString() {
        return "SessionToken[***]";
    }
}
