package com.itsm.resolveit.identity.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import org.junit.jupiter.api.Test;

/** The session signing key is never committed: required outside dev/test, random there if absent. */
class SessionSigningKeysTest {

    @Test
    void withoutAKeyOutsideDevAndTestTheBackendRefusesToStart() {
        assertThatThrownBy(() -> SessionSigningKeys.resolve(properties("", false)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("RESOLVEIT_SESSION_SIGNING_KEY");
    }

    @Test
    void aKeyShorterThan32CharactersIsRefused() {
        assertThatThrownBy(() -> SessionSigningKeys.resolve(properties("too-short", true)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("too short");
    }

    @Test
    void devAndTestGetARandomKeyPerRunWhenNoneIsSet() {
        byte[] first = SessionSigningKeys.resolve(properties(null, true)).getEncoded();
        byte[] second = SessionSigningKeys.resolve(properties(null, true)).getEncoded();

        assertThat(first).hasSize(32).isNotEqualTo(second);
    }

    @Test
    void aConfiguredKeyIsUsedAsIs() {
        String key = "k".repeat(40);

        assertThat(SessionSigningKeys.resolve(properties(key, false)).getEncoded()).hasSize(40);
        assertThat(properties(key, false).toString()).doesNotContain(key);
    }

    private static SessionProperties properties(String key, boolean allowEphemeral) {
        return new SessionProperties(key, Duration.ofHours(8), allowEphemeral);
    }
}
