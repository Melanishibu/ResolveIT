package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.in.ForgotPasswordCommand;
import com.itsm.resolveit.identity.application.port.in.ForgotPasswordUseCase;
import com.itsm.resolveit.identity.application.port.out.DomainEventPublisher;
import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.domain.event.PasswordResetRequested;
import com.itsm.resolveit.identity.domain.model.Invitation;
import com.itsm.resolveit.identity.domain.model.InvitationToken;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry.UserAuditAction;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;
import org.springframework.transaction.annotation.Transactional;

/**
 * Handles password reset requests (RIT-US-23):
 * If an active user with a password exists, issues a 1-hour reset token and emails the link.
 * Rate limited to at most 3 reset emails per user per hour (extra requests silently ignored).
 * Always returns normally so caller can respond 202 without leaking user existence.
 */
public class ForgotPasswordService implements ForgotPasswordUseCase {

    private final UserRepository users;
    private final InvitationRepository invitations;
    private final UserAuditLog auditLog;
    private final DomainEventPublisher events;
    private final Clock clock;

    public ForgotPasswordService(UserRepository users, InvitationRepository invitations, UserAuditLog auditLog,
                                 DomainEventPublisher events, Clock clock) {
        this.users = Objects.requireNonNull(users, "users");
        this.invitations = Objects.requireNonNull(invitations, "invitations");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.events = Objects.requireNonNull(events, "events");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional
    @Override
    public void forgotPassword(ForgotPasswordCommand command) {
        Optional<User> maybeUser = users.lockByEmail(command.email());
        if (maybeUser.isEmpty()) {
            return;
        }
        User user = maybeUser.get();
        if (!user.isActive() || user.passwordHash().isEmpty()) {
            return;
        }

        Instant now = clock.instant();
        Instant oneHourAgo = now.minus(Duration.ofHours(1));
        int resetsInLastHour = auditLog.countByUserIdAndActionSince(user.id(),
                UserAuditAction.PASSWORD_RESET_REQUESTED, oneHourAgo);
        if (resetsInLastHour >= 3) {
            return;
        }

        invitations.invalidatePending(user.id(), now);
        InvitationToken token = InvitationToken.generate();
        Invitation invitation = Invitation.issueReset(invitations.nextId(), user.id(), token, now);
        invitations.save(invitation);

        auditLog.append(new UserAuditEntry(user.id(), user.id().value(), UserAuditAction.PASSWORD_RESET_REQUESTED,
                null, user.email().value(), now));

        events.publish(new PasswordResetRequested(user.id(), invitation.id(), user.email(), user.displayName(), token));
    }
}
