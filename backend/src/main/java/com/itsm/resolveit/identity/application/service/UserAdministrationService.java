package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.Permission;
import com.itsm.resolveit.identity.application.port.in.ChangeUserStatusUseCase;
import com.itsm.resolveit.identity.application.port.in.ListUsersQuery;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.port.out.UserListReadModel;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry.UserAuditAction;
import com.itsm.resolveit.identity.domain.model.UserId;
import com.itsm.resolveit.identity.domain.model.UserNotFoundException;
import java.time.Clock;
import java.time.Instant;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/** The Admin's user list and activate/deactivate (RIT-US-08). Admin only (MANAGE_USERS). */
public class UserAdministrationService implements ListUsersQuery, ChangeUserStatusUseCase {

    private final UserRepository users;
    private final UserListReadModel readModel;
    private final UserAuditLog auditLog;
    private final Clock clock;

    public UserAdministrationService(UserRepository users, UserListReadModel readModel, UserAuditLog auditLog,
                                     Clock clock) {
        this.users = Objects.requireNonNull(users, "users");
        this.readModel = Objects.requireNonNull(readModel, "readModel");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional(readOnly = true)
    @Override
    public UserPage list(Actor actor, Criteria criteria) {
        actor.require(Permission.MANAGE_USERS);
        return readModel.find(criteria, clock.instant());
    }

    @Transactional
    @Override
    public UserRow changeStatus(Command command) {
        command.actor().require(Permission.MANAGE_USERS);
        Instant now = clock.instant();
        User user = users.lockById(command.userId()).orElseThrow(() -> new UserNotFoundException(command.userId()));
        boolean changed = command.active()
                ? user.activate()
                : user.deactivate(new UserId(command.actor().userId()));
        if (changed) {
            users.save(user);
            auditLog.append(new UserAuditEntry(user.id(), command.actor().userId(),
                    command.active() ? UserAuditAction.USER_ACTIVATED : UserAuditAction.USER_DEACTIVATED,
                    command.active() ? "inactive" : "active", command.active() ? "active" : "inactive", now));
        }
        return readModel.findRow(user.id(), now).orElseThrow(() -> new UserNotFoundException(command.userId()));
    }
}
