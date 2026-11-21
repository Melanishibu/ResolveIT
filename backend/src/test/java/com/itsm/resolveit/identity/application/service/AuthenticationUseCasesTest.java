package com.itsm.resolveit.identity.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.itsm.resolveit.identity.application.port.in.LogInCommand;
import com.itsm.resolveit.identity.application.port.in.LoginResult;
import com.itsm.resolveit.identity.application.service.IdentityFakes.InMemorySessions;
import com.itsm.resolveit.identity.application.service.IdentityFakes.InMemoryUsers;
import com.itsm.resolveit.identity.application.service.IdentityFakes.MutableClock;
import com.itsm.resolveit.identity.application.service.IdentityFakes.PlainPasswords;
import com.itsm.resolveit.identity.application.service.IdentityFakes.TransparentTokens;
import com.itsm.resolveit.identity.domain.model.Department;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.IdentityErrorCode;
import com.itsm.resolveit.identity.domain.model.InvalidCredentialsException;
import com.itsm.resolveit.identity.domain.model.LoginLockoutPolicy;
import com.itsm.resolveit.identity.domain.model.LoginTemporarilyBlockedException;
import com.itsm.resolveit.identity.domain.model.NotAuthenticatedException;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.SessionToken;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Login, logout and current-user use cases with in-memory fakes for every outbound port. */
class AuthenticationUseCasesTest {

    private static final String PASSWORD = "ResolveIT-Dev-2026";

    private final MutableClock clock = new MutableClock(Instant.parse("2026-11-20T09:00:00Z"));
    private final InMemorySessions sessions = new InMemorySessions();
    private final PlainPasswords passwords = new PlainPasswords();
    private final TransparentTokens tokens = new TransparentTokens();
    private final User employee = user("employee1@resolveit.local", true);
    private final User inactiveAgent = user("agent2@resolveit.local", false);
    private final InMemoryUsers users = new InMemoryUsers().with(employee).with(inactiveAgent);

    private final LogInService logIn = new LogInService(users,
            new IdentityFakes.InMemoryFailedLoginCounters(), sessions, passwords, tokens,
            LoginLockoutPolicy.STANDARD, Duration.ofHours(8), clock);
    private final LogOutService logOut = new LogOutService(sessions, tokens);
    private final GetCurrentUserService currentUser = new GetCurrentUserService(tokens, sessions, users, clock);

    @Test
    void validCredentialsStartAnEightHourSession() {
        LoginResult result = logIn.logIn(new LogInCommand("Employee1@ResolveIT.local", PASSWORD));

        assertThat(result.user().id()).isEqualTo(employee.id());
        assertThat(result.user().role()).isEqualTo(Role.EMPLOYEE);
        assertThat(result.expiresAt()).isEqualTo(clock.instant().plus(Duration.ofHours(8)));
        assertThat(sessions.byId).hasSize(1);
        assertThat(currentUser.currentUser(Optional.of(result.token())).name().value()).isEqualTo("Employee One");
    }

    @Test
    void unknownEmailGetsTheGenericErrorAfterADummyPasswordCheck() {
        assertThatThrownBy(() -> logIn.logIn(new LogInCommand("nobody@resolveit.local", PASSWORD)))
                .isInstanceOf(InvalidCredentialsException.class);
        assertThat(passwords.dummyChecks).isEqualTo(1);
    }

    @Test
    void malformedEmailGetsTheGenericErrorToo() {
        assertThatThrownBy(() -> logIn.logIn(new LogInCommand("not an email", PASSWORD)))
                .isInstanceOf(InvalidCredentialsException.class);
        assertThat(passwords.dummyChecks).isEqualTo(1);
    }

    @Test
    void wrongPasswordIsRefusedAndTheFailureIsStored() {
        assertThatThrownBy(() -> logIn.logIn(new LogInCommand("employee1@resolveit.local", "wrong")))
                .isInstanceOf(InvalidCredentialsException.class);
        assertThat(users.byId.get(employee.id()).failedLoginAttempts()).isEqualTo(1);
        assertThat(users.saves).isEqualTo(1);
        assertThat(sessions.byId).isEmpty();
    }

    @Test
    void inactiveUserIsRefusedWithTheGenericError() {
        assertThatThrownBy(() -> logIn.logIn(new LogInCommand("agent2@resolveit.local", PASSWORD)))
                .isInstanceOf(InvalidCredentialsException.class)
                .extracting(error -> ((InvalidCredentialsException) error).errorCode())
                .isEqualTo(IdentityErrorCode.AUTH_INVALID_CREDENTIALS);
    }

    @Test
    void fiveFailuresBlockTheCorrectPasswordWithTheMinutesToWait() {
        for (int attempt = 0; attempt < 5; attempt++) {
            assertThatThrownBy(() -> logIn.logIn(new LogInCommand("employee1@resolveit.local", "wrong")))
                    .isInstanceOf(InvalidCredentialsException.class);
        }
        clock.advance(Duration.ofMinutes(5));

        assertThatThrownBy(() -> logIn.logIn(new LogInCommand("employee1@resolveit.local", PASSWORD)))
                .isInstanceOfSatisfying(LoginTemporarilyBlockedException.class,
                        blocked -> assertThat(blocked.params()).containsEntry("retryAfterMinutes", 10L));
    }

    @Test
    void logoutEndsTheSessionSoTheSameTokenNoLongerWorks() {
        SessionToken token = logIn.logIn(new LogInCommand("employee1@resolveit.local", PASSWORD)).token();

        logOut.logOut(Optional.of(token));

        assertThat(sessions.byId).isEmpty();
        assertThatThrownBy(() -> currentUser.currentUser(Optional.of(token)))
                .isInstanceOf(NotAuthenticatedException.class);
    }

    @Test
    void logoutWithoutAValidSessionDoesNothing() {
        logOut.logOut(Optional.empty());
        logOut.logOut(Optional.of(new SessionToken("forged")));

        assertThat(sessions.byId).isEmpty();
    }

    @Test
    void currentUserNeedsAValidUnexpiredSessionOfAnActiveUser() {
        assertThatThrownBy(() -> currentUser.currentUser(Optional.empty())).isInstanceOf(NotAuthenticatedException.class);
        assertThatThrownBy(() -> currentUser.currentUser(Optional.of(new SessionToken("forged"))))
                .isInstanceOf(NotAuthenticatedException.class);

        SessionToken token = logIn.logIn(new LogInCommand("employee1@resolveit.local", PASSWORD)).token();
        clock.advance(Duration.ofHours(8));

        assertThatThrownBy(() -> currentUser.currentUser(Optional.of(token)))
                .as("the session lasts 8 hours")
                .isInstanceOf(NotAuthenticatedException.class);
    }

    @Test
    void aDeactivatedUsersSessionIsRejectedOnTheNextRequest() {
        SessionToken token = logIn.logIn(new LogInCommand("employee1@resolveit.local", PASSWORD)).token();
        users.with(User.reconstitute(employee.id(), employee.email(), employee.displayName(), employee.role(),
                employee.department(), employee.passwordHash().orElseThrow(), false, 0, null));

        assertThatThrownBy(() -> currentUser.currentUser(Optional.of(token)))
                .isInstanceOf(NotAuthenticatedException.class);
    }

    private static User user(String email, boolean active) {
        return User.reconstitute(new UserId(UUID.randomUUID()), new EmailAddress(email),
                new DisplayName(email.startsWith("employee") ? "Employee One" : "Agent Two"),
                email.startsWith("employee") ? Role.EMPLOYEE : Role.SUPPORT_AGENT,
                new Department("Finance"), PlainPasswords.hashOf(PASSWORD), active, 0, null);
    }
}
