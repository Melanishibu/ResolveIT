package com.itsm.resolveit.identity.application.service;

import com.itsm.resolveit.identity.application.port.in.SetPasswordCommand;
import com.itsm.resolveit.identity.application.port.in.SetPasswordUseCase;
import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.application.port.out.PasswordHasher;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.port.out.UserRepository;
import com.itsm.resolveit.identity.domain.model.Invitation;
import com.itsm.resolveit.identity.domain.model.InvitationTokenInvalidException;
import com.itsm.resolveit.identity.domain.model.NewPassword;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry.UserAuditAction;
import java.time.Clock;
import java.time.Instant;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/**
 * Sets a password from a one-time link: the invitation is used (single use, 24 h), the password checked
 * against the policy and stored as a hash, and {@code PASSWORD_SET} audited, all in one transaction.
 */
public class SetPasswordService implements SetPasswordUseCase {

    private final InvitationRepository invitations;
    private final UserRepository users;
    private final PasswordHasher hasher;
    private final UserAuditLog auditLog;
    private final Clock clock;

    public SetPasswordService(InvitationRepository invitations, UserRepository users, PasswordHasher hasher,
                              UserAuditLog auditLog, Clock clock) {
        this.invitations = Objects.requireNonNull(invitations, "invitations");
        this.users = Objects.requireNonNull(users, "users");
        this.hasher = Objects.requireNonNull(hasher, "hasher");
        this.auditLog = Objects.requireNonNull(auditLog, "auditLog");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional
    @Override
    public void setPassword(SetPasswordCommand command) {
        Instant now = clock.instant();
        Invitation invitation = invitations.findByTokenHash(command.token().hash())
                .orElseThrow(InvitationTokenInvalidException::new);
        User user = users.findById(invitation.userId()).orElseThrow(InvitationTokenInvalidException::new);
        invitation.use(now);
        NewPassword password = NewPassword.forUser(command.newPassword(), user.email());
        user.setPassword(hasher.hash(password));
        invitations.save(invitation);
        users.save(user);
        auditLog.append(new UserAuditEntry(user.id(), user.id().value(), UserAuditAction.PASSWORD_SET, null, null,
                now));
    }
}
