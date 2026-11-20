package com.itsm.resolveit.identity.adapters.out.integration;

import com.itsm.resolveit.identity.application.port.out.PasswordVerifier;
import com.itsm.resolveit.identity.domain.model.PasswordHash;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.HexFormat;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/** {@link PasswordVerifier} with BCrypt (common rules: passwords are stored as BCrypt hashes). */
public class BCryptPasswordVerifier implements PasswordVerifier {

    /** BCrypt only reads the first 72 bytes; longer input can never have been hashed by us. */
    static final int BCRYPT_MAX_BYTES = 72;

    private final BCryptPasswordEncoder encoder;
    private final String dummyHash;

    public BCryptPasswordVerifier(BCryptPasswordEncoder encoder) {
        this.encoder = encoder;
        byte[] random = new byte[16];
        new SecureRandom().nextBytes(random);
        this.dummyHash = encoder.encode(HexFormat.of().formatHex(random));
    }

    @Override
    public boolean matches(String rawPassword, PasswordHash hash) {
        if (tooLongForBCrypt(rawPassword)) {
            verifyAgainstDummy("");
            return false;
        }
        return encoder.matches(rawPassword, hash.value());
    }

    @Override
    public void verifyAgainstDummy(String rawPassword) {
        String candidate = tooLongForBCrypt(rawPassword) ? "" : rawPassword;
        encoder.matches(candidate, dummyHash);
    }

    private static boolean tooLongForBCrypt(String rawPassword) {
        return rawPassword.getBytes(StandardCharsets.UTF_8).length > BCRYPT_MAX_BYTES;
    }
}
