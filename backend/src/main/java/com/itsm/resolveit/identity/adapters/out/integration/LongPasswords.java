package com.itsm.resolveit.identity.adapters.out.integration;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;

/**
 * BCrypt reads at most 72 bytes, but the password policy allows 128 characters (RIT-US-07, Plan
 * question 2). A longer password is first reduced to Base64(SHA-256(password)) (44 ASCII bytes) and the
 * stored hash is marked with {@link #MARKER}, so the verifier knows to do the same. Hashes without the
 * marker are plain BCrypt (every password of at most 72 bytes, and all earlier hashes).
 */
final class LongPasswords {

    static final int BCRYPT_MAX_BYTES = 72;
    static final String MARKER = "{sha256}";

    private LongPasswords() {
    }

    static boolean tooLongForBCrypt(String rawPassword) {
        return rawPassword.getBytes(StandardCharsets.UTF_8).length > BCRYPT_MAX_BYTES;
    }

    static String preHash(String rawPassword) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(rawPassword.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(digest);
        } catch (NoSuchAlgorithmException impossible) {
            throw new IllegalStateException("SHA-256 is always available", impossible);
        }
    }
}
