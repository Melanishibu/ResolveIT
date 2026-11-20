package com.itsm.resolveit.identity.adapters.out.integration;

import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.NewPassword;
import com.itsm.resolveit.identity.domain.model.PasswordHash;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/** RIT-US-07 Plan question 2: every password the policy allows can be stored and verified. */
class BCryptPasswordHasherTest {

    private static final EmailAddress ASHA = new EmailAddress("asha@resolveit.local");
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(4);
    private final BCryptPasswordHasher hasher = new BCryptPasswordHasher(encoder);
    private final BCryptPasswordVerifier verifier = new BCryptPasswordVerifier(encoder);

    @Test
    void aShortPasswordIsPlainBCrypt() {
        PasswordHash hash = hasher.hash(NewPassword.forUser("Welcome2026Asha", ASHA));

        assertThat(hash.value()).startsWith("$2a$");
        assertThat(verifier.matches("Welcome2026Asha", hash)).isTrue();
        assertThat(verifier.matches("Welcome2026Asha!", hash)).isFalse();
    }

    @Test
    void a128CharacterPasswordIsStoredAndVerified() {
        String longPassword = "a1" + "x".repeat(126);
        String almostTheSame = "a1" + "x".repeat(125) + "y";

        PasswordHash hash = hasher.hash(NewPassword.forUser(longPassword, ASHA));

        assertThat(hash.value()).startsWith("{sha256}$2a$");
        assertThat(verifier.matches(longPassword, hash)).isTrue();
        assertThat(verifier.matches(almostTheSame, hash)).as("bytes beyond 72 count").isFalse();
    }

    @Test
    void existingPlainHashesStillVerify() {
        PasswordHash existing = new PasswordHash(encoder.encode("ResolveIT-Dev-2026"));

        assertThat(verifier.matches("ResolveIT-Dev-2026", existing)).isTrue();
    }
}
