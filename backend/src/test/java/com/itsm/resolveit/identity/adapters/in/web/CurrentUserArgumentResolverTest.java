package com.itsm.resolveit.identity.adapters.in.web;

import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.identity.ActorRole;
import com.itsm.resolveit.identity.domain.model.Role;
import org.junit.jupiter.api.Test;

/** Every domain role has its published counterpart with the same meaning. */
class CurrentUserArgumentResolverTest {

    @Test
    void everyDomainRoleMapsToTheSamePublishedRole() {
        for (Role role : Role.values()) {
            assertThat(CurrentUserArgumentResolver.actorRole(role).name()).isEqualTo(role.name());
        }
        assertThat(ActorRole.values()).hasSameSizeAs(Role.values());
    }
}
