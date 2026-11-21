package com.itsm.resolveit.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The unconditional rows of the permission table (common rules), one assertion per role. */
class PermissionTest {

    @Test
    void adminHasEveryUnconditionalPermission() {
        for (Permission permission : Permission.values()) {
            assertThat(actor(ActorRole.ADMIN).may(permission)).as(permission.name()).isTrue();
        }
    }

    @Test
    void employeeMayOnlyCreateIncidents() {
        Actor employee = actor(ActorRole.EMPLOYEE);

        assertThat(employee.may(Permission.CREATE_INCIDENT)).isTrue();
        assertThat(employee.may(Permission.VIEW_ALL_INCIDENTS)).isFalse();
        assertThat(employee.may(Permission.ASSIGN_INCIDENT)).isFalse();
        assertThat(employee.may(Permission.CHANGE_PRIORITY)).isFalse();
        assertThat(employee.may(Permission.MANAGE_USERS)).isFalse();
    }

    @Test
    void supportAgentHasNoUnconditionalPermission() {
        for (Permission permission : Permission.values()) {
            assertThat(actor(ActorRole.SUPPORT_AGENT).may(permission)).as(permission.name()).isFalse();
        }
    }

    @Test
    void requireThrowsAuthForbiddenWhenTheRoleLacksThePermission() {
        assertThatThrownBy(() -> actor(ActorRole.EMPLOYEE).require(Permission.MANAGE_USERS))
                .isInstanceOfSatisfying(AccessDeniedException.class,
                        denied -> assertThat(denied.errorCode().code()).isEqualTo("AUTH_FORBIDDEN"));
        actor(ActorRole.ADMIN).require(Permission.MANAGE_USERS);
    }

    private static Actor actor(ActorRole role) {
        return new Actor(UUID.randomUUID(), role);
    }
}
