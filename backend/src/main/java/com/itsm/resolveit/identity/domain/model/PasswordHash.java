package com.itsm.resolveit.identity.domain.model;

/** A one-way password hash (BCrypt). The raw password is never stored. */
public record PasswordHash(String value) {

    public PasswordHash {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Password hash is required");
        }
    }

    /** Never print the hash, not even in logs or test output. */
    @Override
    public String toString() {
        return "PasswordHash[***]";
    }
}
