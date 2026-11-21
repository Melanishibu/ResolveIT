package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.in.CurrentUserView;
import com.itsm.resolveit.identity.application.port.in.LogInCommand;
import com.itsm.resolveit.identity.application.port.in.LogInUseCase;
import com.itsm.resolveit.identity.application.port.in.LoginResult;
import com.itsm.resolveit.identity.application.port.out.FailedLoginCounterRepository;
import com.itsm.resolveit.identity.application.port.out.PasswordVerifier;
import com.itsm.resolveit.identity.application.port.out.SessionTokenIssuer;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.application.port.out.UserSessionRepository;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.FailedLoginCounter;
import com.itsm.resolveit.identity.domain.model.InvalidCredentialsException;
import com.itsm.resolveit.identity.domain.model.LoginAttemptOutcome;
import com.itsm.resolveit.identity.domain.model.LoginLockoutPolicy;
import com.itsm.resolveit.identity.domain.model.LoginTemporarilyBlockedException;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserSession;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;
import org.springframework.transaction.annotation.Transactional;

/** Logs a user in: checks the password, applies the lockout rules, starts a session. */
public class LogInService implements LogInUseCase {

    private final UserRepository users;
    private final FailedLoginCounterRepository failedLogins;
    private final UserSessionRepository sessions;
    private final PasswordVerifier passwords;
    private final SessionTokenIssuer tokens;
    private final LoginLockoutPolicy lockoutPolicy;
    private final Duration sessionLifetime;
    private final Clock clock;

    public LogInService(UserRepository users, FailedLoginCounterRepository failedLogins,
                        UserSessionRepository sessions, PasswordVerifier passwords, SessionTokenIssuer tokens,
                        LoginLockoutPolicy lockoutPolicy, Duration sessionLifetime, Clock clock) {
        this.users = Objects.requireNonNull(users, "users");
        this.failedLogins = Objects.requireNonNull(failedLogins, "failedLogins");
        this.sessions = Objects.requireNonNull(sessions, "sessions");
        this.passwords = Objects.requireNonNull(passwords, "passwords");
        this.tokens = Objects.requireNonNull(tokens, "tokens");
        this.lockoutPolicy = Objects.requireNonNull(lockoutPolicy, "lockoutPolicy");
        this.sessionLifetime = Objects.requireNonNull(sessionLifetime, "sessionLifetime");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    /** Refusals do not roll back: the failed-attempt count and the lock must be stored. */
    @Transactional(noRollbackFor = {InvalidCredentialsException.class, LoginTemporarilyBlockedException.class})
    @Override
    public LoginResult logIn(LogInCommand command) {
        Instant now = clock.instant();
        Optional<EmailAddress> email = EmailAddress.tryParse(command.email());
        Optional<User> found = email.flatMap(users::lockByEmail);
        if (found.isEmpty()) {
            passwords.verifyAgainstDummy(command.password());
            if (email.isEmpty()) {
                // Not an email address at all, so it can't belong to an account: nothing to hide.
                throw new InvalidCredentialsException();
            }
            throw refusalForUnknownEmail(email.get(), now);
        }
        User user = found.get();
        boolean passwordMatches = passwordMatches(command.password(), user);
        LoginAttemptOutcome outcome = user.recordLoginAttempt(passwordMatches, now, lockoutPolicy);
        users.save(user);
        return switch (outcome) {
            case SUCCEEDED -> startSession(user, now);
            case INVALID_CREDENTIALS -> throw new InvalidCredentialsException();
            case TEMPORARILY_BLOCKED -> throw new LoginTemporarilyBlockedException(user.minutesUntilUnlocked(now));
        };
    }

    /**
     * An email with no account is counted and locked like a real account (bug AB#180), so the responses
     * don't reveal whether the email address is registered.
     */
    private RuntimeException refusalForUnknownEmail(EmailAddress email, Instant now) {
        FailedLoginCounter counter = failedLogins.lockOrStart(email);
        LoginAttemptOutcome outcome = counter.recordFailedAttempt(now, lockoutPolicy);
        failedLogins.save(counter);
        if (outcome == LoginAttemptOutcome.TEMPORARILY_BLOCKED) {
            return new LoginTemporarilyBlockedException(counter.minutesUntilUnlocked(now));
        }
        return new InvalidCredentialsException();
    }

    /** An invited user without a password never matches; the dummy check keeps the response time the same. */
    private boolean passwordMatches(String rawPassword, User user) {
        return user.passwordHash()
                .map(hash -> passwords.matches(rawPassword, hash))
                .orElseGet(() -> {
                    passwords.verifyAgainstDummy(rawPassword);
                    return false;
                });
    }

    private LoginResult startSession(User user, Instant now) {
        UserSession session = UserSession.start(sessions.nextId(), user.id(), now, sessionLifetime);
        sessions.save(session);
        return new LoginResult(CurrentUserView.of(user), tokens.issue(session), session.expiresAt());
    }
}
