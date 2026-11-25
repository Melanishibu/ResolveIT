package com.itsm.resolveit.identity.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;

import com.itsm.resolveit.identity.application.port.in.LogInCommand;
import com.itsm.resolveit.identity.application.service.IdentityFakes.InMemoryFailedLoginCounters;
import com.itsm.resolveit.identity.application.service.IdentityFakes.InMemorySessions;
import com.itsm.resolveit.identity.application.service.IdentityFakes.InMemoryUsers;
import com.itsm.resolveit.identity.application.service.IdentityFakes.MutableClock;
import com.itsm.resolveit.identity.application.service.IdentityFakes.PlainPasswords;
import com.itsm.resolveit.identity.application.service.IdentityFakes.TransparentTokens;
import com.itsm.resolveit.identity.domain.model.Department;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.InvalidCredentialsException;
import com.itsm.resolveit.identity.domain.model.LoginLockoutPolicy;
import com.itsm.resolveit.identity.domain.model.LoginTemporarilyBlockedException;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Bug AB#180: an unknown email is refused and locked exactly like a real account. */
class UnknownEmailLockoutTest {

    private static final String PASSWORD = "ResolveIT-Dev-2026";

    private final MutableClock clock = new MutableClock(Instant.parse("2026-11-21T09:00:00Z"));
    private final InMemoryFailedLoginCounters failedLogins = new InMemoryFailedLoginCounters();
    private final InMemoryUsers users = new InMemoryUsers()
            .with(user("employee1@resolveit.local", true))
            .with(user("agent2@resolveit.local", false));
    private final LogInService logIn = new LogInService(users, failedLogins, new InMemorySessions(),
            new PlainPasswords(), new TransparentTokens(), LoginLockoutPolicy.STANDARD, Duration.ofHours(8), clock);

    @Test
    void unknownEmailGetsTheSameResponsesAsARealOneAfterFiveFailures() {
        for (int attempt = 1; attempt <= 6; attempt++) {
            Throwable forAccount = attempt("employee1@resolveit.local", "wrong-" + attempt);
            Throwable forUnknown = attempt("nobody@resolveit.local", "wrong-" + attempt);

            assertSameRefusal(forUnknown, forAccount);
            assertThat(forAccount).isInstanceOf(attempt <= 5
                    ? InvalidCredentialsException.class
                    : LoginTemporarilyBlockedException.class);
        }
    }

    @Test
    void lockedInactiveAccountAnswersLikeAnUnknownEmail() {
        for (int attempt = 1; attempt <= 6; attempt++) {
            Throwable forInactive = attempt("agent2@resolveit.local", "wrong-" + attempt);
            Throwable forUnknown = attempt("nobody@resolveit.local", "wrong-" + attempt);

            assertSameRefusal(forUnknown, forInactive);
        }
    }

    @Test
    void unknownEmailIsCountedCaseInsensitively() {
        for (int attempt = 1; attempt <= 5; attempt++) {
            attempt(attempt % 2 == 0 ? "Nobody@ResolveIT.local" : "nobody@resolveit.local", "wrong");
        }

        assertThat(attempt("NOBODY@resolveit.local", "wrong")).isInstanceOf(LoginTemporarilyBlockedException.class);
    }

    @Test
    void unknownEmailLockExpiresAfterFifteenMinutesLikeARealAccount() {
        for (int attempt = 1; attempt <= 5; attempt++) {
            attempt("nobody@resolveit.local", "wrong");
        }
        clock.advance(Duration.ofMinutes(15));

        assertThat(attempt("nobody@resolveit.local", "wrong")).isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void textThatIsNotAnEmailAddressIsRefusedWithoutBeingCounted() {
        for (int attempt = 1; attempt <= 6; attempt++) {
            assertThat(attempt("not-an-email", "wrong")).isInstanceOf(InvalidCredentialsException.class);
        }
        assertThat(failedLogins.byEmail).isEmpty();
    }

    private Throwable attempt(String email, String password) {
        return catchThrowable(() -> logIn.logIn(new LogInCommand(email, password)));
    }

    private static void assertSameRefusal(Throwable actual, Throwable expected) {
        assertThat(actual).isNotNull().hasSameClassAs(expected).hasMessage(expected.getMessage());
        if (expected instanceof LoginTemporarilyBlockedException blocked) {
            assertThat(((LoginTemporarilyBlockedException) actual).params()).isEqualTo(blocked.params());
        }
    }

    private static User user(String email, boolean active) {
        return User.reconstitute(new UserId(UUID.randomUUID()), new EmailAddress(email),
                new DisplayName("Probe User"), Role.EMPLOYEE, new Department("QA"),
                PlainPasswords.hashOf(PASSWORD), active, 0, null);
    }
}
