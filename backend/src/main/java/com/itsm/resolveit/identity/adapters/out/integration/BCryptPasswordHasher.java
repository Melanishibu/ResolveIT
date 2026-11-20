package com.itsm.resolveit.identity.adapters.out.integration;

import com.itsm.resolveit.identity.application.port.out.PasswordHasher;
import com.itsm.resolveit.identity.domain.model.NewPassword;
import com.itsm.resolveit.identity.domain.model.PasswordHash;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/** {@link PasswordHasher} with BCrypt; passwords over 72 bytes are pre-hashed (see {@link LongPasswords}). */
public class BCryptPasswordHasher implements PasswordHasher {

    private final BCryptPasswordEncoder encoder;

    public BCryptPasswordHasher(BCryptPasswordEncoder encoder) {
        this.encoder = encoder;
    }

    @Override
    public PasswordHash hash(NewPassword password) {
        String raw = password.value();
        if (LongPasswords.tooLongForBCrypt(raw)) {
            return new PasswordHash(LongPasswords.MARKER + encoder.encode(LongPasswords.preHash(raw)));
        }
        return new PasswordHash(encoder.encode(raw));
    }
}
