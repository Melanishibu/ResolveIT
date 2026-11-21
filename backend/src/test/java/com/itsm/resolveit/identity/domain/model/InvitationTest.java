package com.itsm.resolveit.identity.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Invited users, invitations and invitation tokens (RIT-US-06). */
class InvitationTest {

    private static final Instant NOW = Instant.parse("2026-11-20T10:00:00Z");

    @Test
    void anInvitedUserIsActiveWithNoPassword() {
        User user = User.invite(new UserId(UUID.randomUUID()), new EmailAddress("asha@resolveit.local"),
                new DisplayName("Asha Rao"), Role.SUPPORT_AGENT, new Department("IT Support"));

        assertThat(user.isActive()).isTrue();
        assertThat(user.passwordHash()).isEmpty();
        assertThat(user.department().value()).isEqualTo("IT Support");
    }

    @Test
    void adminsCannotBeInvited() {
        assertThatThrownBy(() -> User.invite(new UserId(UUID.randomUUID()), new EmailAddress("boss@resolveit.local"),
                new DisplayName("Boss"), Role.ADMIN, new Department("IT")))
                .isInstanceOfSatisfying(UserRoleNotAllowedException.class,
                        refused -> assertThat(refused.params()).containsEntry("role", "ADMIN"));
    }

    @Test
    void departmentIsRequiredAndAtMost80Characters() {
        assertThatThrownBy(() -> new Department("  ")).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new Department("d".repeat(81))).isInstanceOf(IllegalArgumentException.class);
        assertThat(new Department(" Finance ").value()).isEqualTo("Finance");
        assertThatThrownBy(() -> new Department("IT\u0000Support")).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new DisplayName("Asha\u0007")).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void aTokenIs32RandomBytesAndOnlyItsSha256HashIsKept() {
        InvitationToken token = InvitationToken.generate();
        Invitation invitation = Invitation.issue(new InvitationId(UUID.randomUUID()), new UserId(UUID.randomUUID()),
                token, NOW);

        assertThat(token.value()).hasSize(43); // 32 bytes, Base64url without padding
        assertThat(invitation.tokenHash()).matches("[0-9a-f]{64}").isEqualTo(token.hash()).isNotEqualTo(token.value());
        assertThat(InvitationToken.generate().value()).isNotEqualTo(token.value());
        assertThat(token.toString()).doesNotContain(token.value());
    }

    @Test
    void anInvitationIsValidFor24Hours() {
        Invitation invitation = Invitation.issue(new InvitationId(UUID.randomUUID()), new UserId(UUID.randomUUID()),
                InvitationToken.generate(), NOW);

        assertThat(invitation.status()).isEqualTo(InvitationStatus.PENDING);
        assertThat(invitation.isExpiredAt(NOW.plus(Duration.ofHours(23)))).isFalse();
        assertThat(invitation.isExpiredAt(NOW.plus(Duration.ofHours(24)))).isTrue();
    }
}
