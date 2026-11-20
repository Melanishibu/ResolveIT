package com.itsm.resolveit.identity.domain.model;

import java.util.Locale;

/**
 * A password a user chose (RIT-US-07), held in memory only until it is hashed. Never stored, logged or
 * printed ({@link #toString()} hides it).
 *
 * <p>Policy (common rules): 12–128 characters, at least one letter and one digit, not equal to the
 * user's email address (ignoring case).
 */
public final class NewPassword {

    public static final int MIN_LENGTH = 12;
    public static final int MAX_LENGTH = 128;

    private final String value;

    private NewPassword(String value) {
        this.value = value;
    }

    /** Checks the policy for the user with {@code email}; throws {@link PasswordPolicyViolationException}. */
    public static NewPassword forUser(String raw, EmailAddress email) {
        if (raw == null) {
            throw new PasswordPolicyViolationException();
        }
        int length = raw.length(); // UTF-16 units, as the login request counts them
        boolean hasLetter = raw.codePoints().anyMatch(Character::isLetter);
        boolean hasDigit = raw.codePoints().anyMatch(Character::isDigit);
        boolean isEmail = raw.trim().toLowerCase(Locale.ROOT).equals(email.value().toLowerCase(Locale.ROOT));
        if (length < MIN_LENGTH || length > MAX_LENGTH || !hasLetter || !hasDigit || isEmail) {
            throw new PasswordPolicyViolationException();
        }
        return new NewPassword(raw);
    }

    /** The raw password, for hashing only. */
    public String value() {
        return value;
    }

    @Override
    public String toString() {
        return "NewPassword[***]";
    }
}
