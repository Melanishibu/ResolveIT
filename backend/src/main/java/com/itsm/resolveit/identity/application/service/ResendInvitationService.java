package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.Permission;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery.UserRow;
import com.itsm.resolveit.identity.application.port.in.ResendInvitationCommand;
import com.itsm.resolveit.identity.application.port.in.ResendInvitationUseCase;
import com.itsm.resolveit.identity.application.port.out.DomainEventPublisher;
import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.port.out.UserListReadModel;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.domain.event.UserInvited;
import com.itsm.resolveit.identity.domain.model.Invitation;
import com.itsm.resolveit.identity.domain.model.InvitationToken;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserAlreadyActivatedException;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry.UserAuditAction;
import com.itsm.resolveit.identity.domain.model.UserNotFoundException;
import java.time.Clock;
import java.time.Instant;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/** Resend an invitation email (RIT-US-22). Admin only (MANAGE_USERS). */
public class ResendInvitationService implements ResendInvitationUseCase {

    private final UserRepository users;
    private final InvitationRepository invitations;
    private final UserListReadModel readModel;
    private final UserAuditLog auditLog;
    private final DomainEventPublisher events;
    private final Clock clock;

    public ResendInvitationService(UserRepository users, InvitationRepository invitations,
                                   UserListReadModel readModel, UserAuditLog auditLog,
                                   DomainEventPublisher events, Clock clock) {
        this.users = Objects.requireNonNull(users, "users");
        this.invitations = Objects.requireNonNull(invitations, "invitations");
        this.readModel = Objects.requireNonNull(readModel, "readModel");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.events = Objects.requireNonNull(events, "events");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional
    @Override
    public UserRow resend(ResendInvitationCommand command) {
        command.actor().require(Permission.MANAGE_USERS);
        Instant now = clock.instant();
        User user = users.lockById(command.userId()).orElseThrow(() -> new UserNotFoundException(command.userId()));
        if (user.passwordHash().isPresent()) {
            throw new UserAlreadyActivatedException(command.userId());
        }
        invitations.invalidatePending(user.id(), now);
        InvitationToken token = InvitationToken.generate();
        Invitation invitation = Invitation.issue(invitations.nextId(), user.id(), token, now);
        invitations.save(invitation);
        auditLog.append(new UserAuditEntry(user.id(), command.actor().userId(), UserAuditAction.INVITATION_RESENT,
                null, user.email().value(), now));
        events.publish(new UserInvited(user.id(), invitation.id(), user.email(), user.displayName(), user.role(),
                token, command.actor().userId(), true));
        return readModel.findRow(user.id(), now).orElseThrow(() -> new UserNotFoundException(command.userId()));
    }
}
