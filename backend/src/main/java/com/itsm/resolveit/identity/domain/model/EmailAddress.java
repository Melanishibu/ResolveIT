package com.itsm.resolveit.identity.domain.model;

import java.util.Locale;
import java.util.Optional;
import java.util.regex.Pattern;

/**
 * A user's email address, the login name.
 *
 * <p>Common rules: valid, at most 254 characters, unique case-insensitively. The value is kept in
 * lower case, so equality and the database uniqueness constraint are case-insensitive.
 */
public record EmailAddress(String value) {

    public static final int MAX_LENGTH = 254;

    /** One "@", no whitespace, a dot in the domain part. Deliberately simple; the mailbox is the proof. */
    private static final Pattern FORMAT = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

    public EmailAddress {
        if (value == null) {
            throw new IllegalArgumentException("Email address is required");
        }
        value = value.trim().toLowerCase(Locale.ROOT);
        if (value.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("Email address must be at most " + MAX_LENGTH + " characters");
        }
        if (!FORMAT.matcher(value).matches()) {
            throw new IllegalArgumentException("Email address is not valid");
        }
    }

    /** Parses untrusted input; empty when it is not a valid email address. */
    public static Optional<EmailAddress> tryParse(String candidate) {
        try {
            return Optional.of(new EmailAddress(candidate));
        } catch (IllegalArgumentException invalid) {
            return Optional.empty();
        }
    }

    @Override
    public String toString() {
        return value;
    }
}
