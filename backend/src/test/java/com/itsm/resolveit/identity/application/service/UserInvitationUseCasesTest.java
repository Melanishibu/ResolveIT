package com.itsm.resolveit.identity.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.itsm.resolveit.identity.AccessDeniedException;
import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.identity.ActorRole;
import com.itsm.resolveit.identity.application.port.in.CreateUserCommand;
import com.itsm.resolveit.identity.application.port.in.CreatedUserView;
import com.itsm.resolveit.identity.application.port.out.EmailSender;
import com.itsm.resolveit.identity.application.port.out.EmailSender.EmailNotSentException;
import com.itsm.resolveit.identity.application.port.out.InvitationRepository;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.service.IdentityFakes.InMemoryUsers;
import com.itsm.resolveit.identity.domain.event.UserInvited;
import com.itsm.resolveit.identity.domain.model.Department;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.Invitation;
import com.itsm.resolveit.identity.domain.model.InvitationId;
import com.itsm.resolveit.identity.domain.model.InvitationStatus;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.UserId;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry.UserAuditAction;
import com.itsm.resolveit.identity.domain.model.UserEmailTakenException;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** CreateUser and SendInvitation use cases with in-memory fakes (RIT-US-06). */
class UserInvitationUseCasesTest {

    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-11-20T10:00:00Z"), ZoneOffset.UTC);
    private static final Actor ADMIN = new Actor(UUID.randomUUID(), ActorRole.ADMIN);

    private final InMemoryUsers users = new InMemoryUsers();
    private final InMemoryInvitations invitations = new InMemoryInvitations();
    private final List<UserAuditEntry> audit = new ArrayList<>();
    private final List<Object> published = new ArrayList<>();
    private final CreateUserService createUser = new CreateUserService(users, invitations, audit::add,
            published::add, CLOCK);

    @Test
    void anAdminCreatesAnActiveUserWithAPendingInvitationAndAnAuditEntry() {
        CreatedUserView created = createUser.create(command(ADMIN, "asha@resolveit.local", Role.SUPPORT_AGENT));

        assertThat(created.active()).isTrue();
        assertThat(created.invitationStatus()).isEqualTo(InvitationStatus.PENDING);
        assertThat(users.byId.get(created.id()).passwordHash()).isEmpty();
        assertThat(invitations.byId).hasSize(1);
        assertThat(audit).singleElement().satisfies(entry -> {
            assertThat(entry.action()).isEqualTo(UserAuditAction.USER_CREATED);
            assertThat(entry.actorId()).isEqualTo(ADMIN.userId());
        });
        assertThat(published).singleElement().isInstanceOf(UserInvited.class);
    }

    @Test
    void onlyAdminsMayCreateUsers() {
        assertThatThrownBy(() -> createUser.create(command(new Actor(UUID.randomUUID(), ActorRole.SUPPORT_AGENT),
                "asha@resolveit.local", Role.EMPLOYEE))).isInstanceOf(AccessDeniedException.class);
        assertThat(users.byId).isEmpty();
    }

    @Test
    void aTakenEmailIsRefusedCaseInsensitively() {
        createUser.create(command(ADMIN, "asha@resolveit.local", Role.EMPLOYEE));

        assertThatThrownBy(() -> createUser.create(command(ADMIN, "ASHA@resolveit.local", Role.EMPLOYEE)))
                .isInstanceOf(UserEmailTakenException.class);
    }

    @Test
    void aSentInvitationIsRecordedWithItsAuditEntry() {
        UserInvited event = invite();
        List<EmailSender.EmailMessage> sent = new ArrayList<>();

        sendWith(sent::add).send(event);

        assertThat(sent).singleElement().satisfies(mail -> assertThat(mail.to()).isEqualTo(event.email()));
        assertThat(invitations.byId.get(event.invitationId()).status()).isEqualTo(InvitationStatus.SENT);
        assertThat(audit).extracting(UserAuditEntry::action)
                .containsExactly(UserAuditAction.USER_CREATED, UserAuditAction.INVITATION_SENT);
    }

    @Test
    void aFailedSendKeepsTheUserAndMarksTheInvitationSendFailed() {
        UserInvited event = invite();

        sendWith(message -> {
            throw new EmailNotSentException("down", null);
        }).send(event);

        assertThat(invitations.byId.get(event.invitationId()).status()).isEqualTo(InvitationStatus.SEND_FAILED);
        assertThat(users.byId).hasSize(1);
        assertThat(audit).extracting(UserAuditEntry::action).containsExactly(UserAuditAction.USER_CREATED);
    }

    private UserInvited invite() {
        createUser.create(command(ADMIN, "asha@resolveit.local", Role.SUPPORT_AGENT));
        return (UserInvited) published.getFirst();
    }

    private SendInvitationService sendWith(EmailSender sender) {
        UserAuditLog log = audit::add;
        return new SendInvitationService(invitations, log, sender, new InvitationEmail("http://localhost:5000"), CLOCK);
    }

    private static CreateUserCommand command(Actor actor, String email, Role role) {
        return new CreateUserCommand(actor, new DisplayName("Asha Rao"), new EmailAddress(email), role,
                new Department("IT Support"));
    }

    private static final class InMemoryInvitations implements InvitationRepository {
        final Map<InvitationId, Invitation> byId = new HashMap<>();

        @Override
        public InvitationId nextId() {
            return new InvitationId(UUID.randomUUID());
        }

        @Override
        public void save(Invitation invitation) {
            byId.put(invitation.id(), invitation);
        }

        @Override
        public Optional<Invitation> findById(InvitationId id) {
            return Optional.ofNullable(byId.get(id));
        }

        @Override
        public Optional<Invitation> findByTokenHash(String tokenHash) {
            return byId.values().stream().filter(i -> i.tokenHash().equals(tokenHash)).findFirst();
        }

        @Override
        @Override
        public void invalidatePending(UserId userId, Instant now) {
            byId.values().stream()
                    .filter(i -> i.userId().equals(userId) && (i.status() == InvitationStatus.PENDING
                            || i.status() == InvitationStatus.SENT
                            || i.status() == InvitationStatus.SEND_FAILED))
                    .forEach(i -> i.use(now));
        }
        }
    }
}
