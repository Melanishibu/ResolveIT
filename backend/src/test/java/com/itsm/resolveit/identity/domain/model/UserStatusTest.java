package com.itsm.resolveit.identity.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;

/** RIT-US-08 domain rules: activate, deactivate, no self-deactivation. */
class UserStatusTest {

    private static final UserId ADMIN = new UserId(UUID.randomUUID());

    @Test
    void anAdminDeactivatesAndActivatesAUser() {
        User agent = user(new UserId(UUID.randomUUID()), true);

        assertThat(agent.deactivate(ADMIN)).isTrue();
        assertThat(agent.isActive()).isFalse();
        assertThat(agent.deactivate(ADMIN)).as("already inactive: no change").isFalse();
        assertThat(agent.activate()).isTrue();
        assertThat(agent.isActive()).isTrue();
        assertThat(agent.activate()).as("already active: no change").isFalse();
    }

    @Test
    void anAdminCannotDeactivateThemselves() {
        User admin = user(ADMIN, true);

        assertThatThrownBy(() -> admin.deactivate(ADMIN)).isInstanceOf(UserCannotDeactivateSelfException.class);
        assertThat(admin.isActive()).isTrue();
    }

    private static User user(UserId id, boolean active) {
        return User.reconstitute(id, new EmailAddress("u" + id.value().toString().substring(0, 8) + "@resolveit.local"),
                new DisplayName("Some One"), Role.SUPPORT_AGENT, new Department("IT"), null, active, 0, null);
    }
}
