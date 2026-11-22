package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.in.ChangePasswordCommand;
import com.itsm.resolveit.identity.application.port.in.ChangePasswordUseCase;
import com.itsm.resolveit.identity.application.port.out.PasswordHasher;
import com.itsm.resolveit.identity.application.port.out.PasswordVerifier;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.application.port.out.UserSessionRepository;
import com.itsm.resolveit.identity.domain.model.AuthCurrentPasswordWrongException;
import com.itsm.resolveit.identity.domain.model.NewPassword;
import com.itsm.resolveit.identity.domain.model.PasswordHash;
import com.itsm.resolveit.identity.domain.model.PasswordSameAsCurrentException;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry.UserAuditAction;
import com.itsm.resolveit.identity.domain.model.UserNotFoundException;
import java.time.Clock;
import java.time.Instant;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/**
 * Changes a user's password: checks the current password, enforces the policy,
 * checks that the new password differs from the current one, updates the hash,
 * invalidates all other sessions, and audits PASSWORD_CHANGED (RIT-US-27).
 */
public class ChangePasswordService implements ChangePasswordUseCase {

    private final UserRepository users;
    private final UserSessionRepository sessions;
    private final PasswordVerifier verifier;
    private final PasswordHasher hasher;
    private final UserAuditLog auditLog;
    private final Clock clock;

    public ChangePasswordService(
            UserRepository users,
            UserSessionRepository sessions,
            PasswordVerifier verifier,
            PasswordHasher hasher,
            UserAuditLog auditLog,
            Clock clock) {
        this.users = Objects.requireNonNull(users, "users");
        this.sessions = Objects.requireNonNull(sessions, "sessions");
        this.verifier = Objects.requireNonNull(verifier, "verifier");
        this.hasher = Objects.requireNonNull(hasher, "hasher");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional
    @Override
    public void changePassword(ChangePasswordCommand command) {
        Instant now = clock.instant();
        User user = users.lockById(command.userId()).orElseThrow(() -> new UserNotFoundException(command.userId()));

        PasswordHash currentHash = user.passwordHash().orElseThrow(AuthCurrentPasswordWrongException::new);
        if (!verifier.matches(command.currentPassword(), currentHash)) {
            throw new AuthCurrentPasswordWrongException();
        }

        if (verifier.matches(command.newPassword(), currentHash)) {
            throw new PasswordSameAsCurrentException();
        }

        NewPassword newPassword = NewPassword.forUser(command.newPassword(), user.email());
        user.setPassword(hasher.hash(newPassword));
        users.save(user);

        sessions.deleteAllExcept(user.id(), command.currentSessionId());

        auditLog.append(new UserAuditEntry(
                user.id(),
                user.id().value(),
                UserAuditAction.PASSWORD_CHANGED,
                null,
                null,
                now));
    }
}
