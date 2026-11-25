package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.Permission;
import com.itsm.resolveit.identity.application.port.in.CreateUserCommand;
import com.itsm.resolveit.identity.application.port.in.CreateUserUseCase;
import com.itsm.resolveit.identity.application.port.in.CreatedUserView;
import com.itsm.resolveit.identity.application.port.out.DomainEventPublisher;
import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.domain.event.UserInvited;
import com.itsm.resolveit.identity.domain.model.Invitation;
import com.itsm.resolveit.identity.domain.model.InvitationToken;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry.UserAuditAction;
import com.itsm.resolveit.identity.domain.model.UserEmailTakenException;
import java.time.Clock;
import java.time.Instant;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/** Creates an invited user with their invitation in one transaction; the email follows after the commit. */
public class CreateUserService implements CreateUserUseCase {

    private final UserRepository users;
    private final InvitationRepository invitations;
    private final UserAuditLog auditLog;
    private final DomainEventPublisher events;
    private final Clock clock;

    public CreateUserService(UserRepository users, InvitationRepository invitations, UserAuditLog auditLog,
                             DomainEventPublisher events, Clock clock) {
        this.users = Objects.requireNonNull(users, "users");
        this.invitations = Objects.requireNonNull(invitations, "invitations");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.events = Objects.requireNonNull(events, "events");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional
    @Override
    public CreatedUserView create(CreateUserCommand command) {
        command.actor().require(Permission.MANAGE_USERS);
        if (users.existsByEmail(command.email())) {
            throw new UserEmailTakenException(command.email());
        }
        Instant now = clock.instant();
        User user = User.invite(users.nextId(), command.email(), command.name(), command.role(), command.department());
        InvitationToken token = InvitationToken.generate();
        Invitation invitation = Invitation.issue(invitations.nextId(), user.id(), token, now);
        users.save(user);
        invitations.save(invitation);
        auditLog.append(new UserAuditEntry(user.id(), command.actor().userId(), UserAuditAction.USER_CREATED, null,
                user.role().name() + " " + user.email().value(), now));
        events.publish(new UserInvited(user.id(), invitation.id(), user.email(), user.displayName(), user.role(), token,
                command.actor().userId()));
        return new CreatedUserView(user.id(), user.displayName(), user.email(), user.role(), user.department(),
                user.isActive(), invitation.status());
    }
}
