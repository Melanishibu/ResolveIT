package com.itsm.resolveit.identity.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.itsm.resolveit.identity.application.port.in.UserProfileView;
import com.itsm.resolveit.identity.application.service.IdentityFakes.InMemoryUsers;
import com.itsm.resolveit.identity.domain.model.Department;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserId;
import com.itsm.resolveit.identity.domain.model.UserNotFoundException;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Unit tests for {@link GetMyProfileService} matching RIT-US-27 Gherkin scenarios. */
class GetMyProfileTest {

    private static final Instant MEMBER_SINCE = Instant.parse("2026-11-20T10:00:00Z");

    private InMemoryUsers users;
    private GetMyProfileService service;
    private User user;

    @BeforeEach
    void setUp() {
        users = new InMemoryUsers();
        service = new GetMyProfileService(users);

        UserId userId = new UserId(UUID.randomUUID());
        user = User.reconstitute(userId, new EmailAddress("employee1@resolveit.local"),
                new DisplayName("Employee One"), Role.EMPLOYEE, new Department("Finance"),
                null, true, 0, null, MEMBER_SINCE);
        users.with(user);
    }

    // Scenario: User sees their profile
    @Test
    void userSeesTheirProfile() {
        UserProfileView profile = service.getMyProfile(user.id());

        assertThat(profile.name().value()).isEqualTo("Employee One");
        assertThat(profile.email().value()).isEqualTo("employee1@resolveit.local");
        assertThat(profile.role()).isEqualTo(Role.EMPLOYEE);
        assertThat(profile.department().value()).isEqualTo("Finance");
        assertThat(profile.memberSince()).isEqualTo(MEMBER_SINCE);
    }

    @Test
    void unknownUserThrowsNotFound() {
        UserId unknown = new UserId(UUID.randomUUID());
        assertThatThrownBy(() -> service.getMyProfile(unknown))
                .isInstanceOf(UserNotFoundException.class);
    }
}
