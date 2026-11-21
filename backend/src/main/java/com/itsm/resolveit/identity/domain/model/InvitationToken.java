package com.itsm.resolveit.identity.domain.model;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;

/**
 * The secret in an invitation link: 32 random bytes, Base64url encoded (RIT-US-06).
 *
 * <p>Only {@link #hash()} (SHA-256, hex) is ever stored. The raw value lives in memory just long
 * enough to build the link, and is never logged ({@link #toString()} hides it).
 */
public final class InvitationToken {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int BYTES = 32;

    private final String value;

    private InvitationToken(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Invitation token is required");
        }
        this.value = value;
    }

    /** A new random token. */
    public static InvitationToken generate() {
        byte[] bytes = new byte[BYTES];
        RANDOM.nextBytes(bytes);
        return new InvitationToken(Base64.getUrlEncoder().withoutPadding().encodeToString(bytes));
    }

    /** A token received from a link (RIT-US-07). */
    public static InvitationToken of(String value) {
        return new InvitationToken(value);
    }

    /** The value for the link. Handle with care: it grants a one-time password set. */
    public String value() {
        return value;
    }

    /** SHA-256 of the token, hex encoded: the only form that is stored. */
    public String hash() {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException impossible) {
            throw new IllegalStateException("SHA-256 is always available", impossible);
        }
    }

    @Override
    public String toString() {
        return "InvitationToken[***]";
    }
}
