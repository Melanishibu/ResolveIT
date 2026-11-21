package com.itsm.resolveit.identity.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** RIT-US-07 domain rules: password policy, single-use 24-hour invitations, setting a password. */
class SetPasswordRulesTest {

    private static final EmailAddress ASHA = new EmailAddress("asha@resolveit.local");
    private static final Instant NOW = Instant.parse("2026-11-21T10:00:00Z");

    @Test
    void aPasswordNeeds12To128CharactersALetterAndADigit() {
        assertThat(NewPassword.forUser("Welcome2026Asha", ASHA).value()).isEqualTo("Welcome2026Asha");
        assertThat(NewPassword.forUser("a1" + "x".repeat(126), ASHA)).isNotNull();
        assertThatThrownBy(() -> NewPassword.forUser("short1", ASHA)).isInstanceOf(PasswordPolicyViolationException.class);
        assertThatThrownBy(() -> NewPassword.forUser("a1" + "x".repeat(127), ASHA))
                .as("129 characters").isInstanceOf(PasswordPolicyViolationException.class);
        assertThatThrownBy(() -> NewPassword.forUser("onlyletterspassword", ASHA))
                .isInstanceOf(PasswordPolicyViolationException.class);
        assertThatThrownBy(() -> NewPassword.forUser("123456789012345", ASHA))
                .isInstanceOf(PasswordPolicyViolationException.class);
        EmailAddress withDigit = new EmailAddress("asha2026@resolveit.local");
        assertThat(NewPassword.forUser("asha2026@resolveit.locaL!", withDigit)).as("differs from the email").isNotNull();
        assertThatThrownBy(() -> NewPassword.forUser("ASHA2026@resolveit.local", withDigit))
                .as("the email itself, any case").isInstanceOf(PasswordPolicyViolationException.class);
        assertThat(NewPassword.forUser("Welcome2026Asha", ASHA).toString()).doesNotContain("Welcome");
    }

    @Test
    void anInvitationWorksOnceAndFor24Hours() {
        Invitation fresh = invitationCreatedAt(NOW.minus(Duration.ofHours(23)));
        fresh.use(NOW);
        assertThat(fresh.status()).isEqualTo(InvitationStatus.USED);
        assertThatThrownBy(() -> fresh.use(NOW)).isInstanceOf(InvitationTokenInvalidException.class);

        Invitation expired = invitationCreatedAt(NOW.minus(Duration.ofHours(24)));
        assertThatThrownBy(() -> expired.use(NOW)).isInstanceOf(InvitationTokenExpiredException.class);

        Invitation sendFailed = invitationCreatedAt(NOW);
        sendFailed.markSendFailed();
        sendFailed.use(NOW);
        assertThat(sendFailed.status()).as("the link works even if the email failed").isEqualTo(InvitationStatus.USED);

        Invitation usedBeforeTheEmailWasRecorded = invitationCreatedAt(NOW);
        usedBeforeTheEmailWasRecorded.use(NOW);
        usedBeforeTheEmailWasRecorded.markSent();
        usedBeforeTheEmailWasRecorded.markSendFailed();
        assertThat(usedBeforeTheEmailWasRecorded.status()).as("a used link stays used").isEqualTo(InvitationStatus.USED);
    }

    @Test
    void settingAPasswordEndsAnyLoginLock() {
        User user = User.reconstitute(new UserId(UUID.randomUUID()), ASHA, new DisplayName("Asha Rao"),
                Role.EMPLOYEE, new Department("Finance"), null, true, 5, NOW.plus(Duration.ofMinutes(10)));

        user.setPassword(new PasswordHash("$2a$10$hash"));

        assertThat(user.passwordHash()).isPresent();
        assertThat(user.failedLoginAttempts()).isZero();
        assertThat(user.isLockedAt(NOW)).isFalse();
    }

    private static Invitation invitationCreatedAt(Instant createdAt) {
        return Invitation.issue(new InvitationId(UUID.randomUUID()), new UserId(UUID.randomUUID()),
                InvitationToken.generate(), createdAt);
    }
}
