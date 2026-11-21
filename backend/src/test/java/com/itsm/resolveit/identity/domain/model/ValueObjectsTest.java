package com.itsm.resolveit.identity.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Validation rules of the identity value objects and the UserSession lifetime. */
class ValueObjectsTest {

    @Test
    void emailIsStoredInLowerCaseSoUniquenessIsCaseInsensitive() {
        assertThat(new EmailAddress("  Employee1@ResolveIT.Local ").value()).isEqualTo("employee1@resolveit.local");
        assertThat(new EmailAddress("A@B.CO")).isEqualTo(new EmailAddress("a@b.co"));
    }

    @Test
    void emailMustBeValidAndAtMost254Characters() {
        assertThat(EmailAddress.tryParse("not-an-email")).isEmpty();
        assertThat(EmailAddress.tryParse("two@@at.signs")).isEmpty();
        assertThat(EmailAddress.tryParse(null)).isEmpty();
        String local = "a".repeat(64);
        String tooLong = local + "@" + "b".repeat(254 - local.length() - 1 - 4 + 1) + ".com";
        assertThat(tooLong).hasSizeGreaterThan(254);
        assertThat(EmailAddress.tryParse(tooLong)).isEmpty();
        assertThat(EmailAddress.tryParse("employee1@resolveit.local")).isPresent();
    }

    @Test
    void displayNameIsRequiredAndBounded() {
        assertThatThrownBy(() -> new DisplayName(" ")).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new DisplayName("x".repeat(101))).isInstanceOf(IllegalArgumentException.class);
        assertThat(new DisplayName(" Employee One ").value()).isEqualTo("Employee One");
    }

    @Test
    void secretsAreNeverPrinted() {
        assertThat(new PasswordHash("$2a$10$secret").toString()).doesNotContain("secret");
        assertThat(new SessionToken("eyJ.secret.sig").toString()).doesNotContain("secret");
    }

    @Test
    void aSessionIsValidOnlyForItsUserAndUntilItExpires() {
        UserId owner = new UserId(UUID.randomUUID());
        Instant now = Instant.parse("2026-11-20T08:00:00Z");
        UserSession session = UserSession.start(new SessionId(UUID.randomUUID()), owner, now, Duration.ofHours(8));

        assertThat(session.expiresAt()).isEqualTo(now.plus(Duration.ofHours(8)));
        assertThat(session.isValidFor(owner, now.plus(Duration.ofHours(7)))).isTrue();
        assertThat(session.isValidFor(owner, now.plus(Duration.ofHours(8)))).isFalse();
        assertThat(session.isValidFor(new UserId(UUID.randomUUID()), now)).isFalse();
    }
}
