package com.itsm.resolveit.identity.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.itsm.resolveit.identity.application.port.in.ChangePasswordCommand;
import com.itsm.resolveit.identity.application.port.out.UserAuditLog;
import com.itsm.resolveit.identity.application.service.IdentityFakes.InMemorySessions;
import com.itsm.resolveit.identity.application.service.IdentityFakes.InMemoryUsers;
import com.itsm.resolveit.identity.application.service.IdentityFakes.PlainPasswords;
import com.itsm.resolveit.identity.domain.model.AuthCurrentPasswordWrongException;
import com.itsm.resolveit.identity.domain.model.Department;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.PasswordPolicyViolationException;
import com.itsm.resolveit.identity.domain.model.PasswordSameAsCurrentException;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.SessionId;
import com.itsm.resolveit.identity.domain.model.User;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry;
import com.itsm.resolveit.identity.domain.model.UserAuditEntry.UserAuditAction;
import com.itsm.resolveit.identity.domain.model.UserId;
import com.itsm.resolveit.identity.domain.model.UserSession;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Unit tests for {@link ChangePasswordService} matching RIT-US-27 Gherkin scenarios. */
class ChangePasswordTest {

    private static final Instant NOW = Instant.parse("2026-11-20T10:00:00Z");
    private static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);

    private InMemoryUsers users;
    private InMemorySessions sessions;
    private PlainPasswords passwords;
    private List<UserAuditEntry> auditLog;
    private ChangePasswordService service;

    private User user;
    private SessionId currentSession;
    private SessionId otherSession;

    @BeforeEach
    void setUp() {
        users = new InMemoryUsers();
        sessions = new InMemorySessions();
        passwords = new PlainPasswords();
        auditLog = new ArrayList<>();
        service = new ChangePasswordService(users, sessions, passwords, p -> PlainPasswords.hashOf(p.value()), auditLog::add, CLOCK);

        UserId userId = new UserId(UUID.randomUUID());
        user = User.reconstitute(userId, new EmailAddress("employee1@resolveit.local"),
                new DisplayName("Employee One"), Role.EMPLOYEE, new Department("Finance"),
                PlainPasswords.hashOf("OldPassword123"), true, 0, null, NOW);
        users.with(user);

        currentSession = new SessionId(UUID.randomUUID());
        otherSession = new SessionId(UUID.randomUUID());
        sessions.save(UserSession.reconstitute(currentSession, userId, NOW, NOW.plusSeconds(3600)));
        sessions.save(UserSession.reconstitute(otherSession, userId, NOW, NOW.plusSeconds(3600)));
    }

    // Scenario: User changes their password
    @Test
    void userChangesTheirPassword() {
        service.changePassword(new ChangePasswordCommand(
                user.id(), currentSession, "OldPassword123", "ValidNewPassword456"));

        User updated = users.findById(user.id()).orElseThrow();
        assertThat(passwords.matches("ValidNewPassword456", updated.passwordHash().orElseThrow())).isTrue();
        assertThat(passwords.matches("OldPassword123", updated.passwordHash().orElseThrow())).isFalse();

        assertThat(auditLog).hasSize(1);
        assertThat(auditLog.get(0).action()).isEqualTo(UserAuditAction.PASSWORD_CHANGED);
        assertThat(auditLog.get(0).userId()).isEqualTo(user.id());
    }

    // Scenario: Wrong current password
    @Test
    void wrongCurrentPassword() {
        assertThatThrownBy(() -> service.changePassword(new ChangePasswordCommand(
                user.id(), currentSession, "WrongPassword999", "ValidNewPassword456")))
                .isInstanceOf(AuthCurrentPasswordWrongException.class);
    }

    // Scenario: New password must follow the policy
    @Test
    void newPasswordMustFollowPolicy() {
        assertThatThrownBy(() -> service.changePassword(new ChangePasswordCommand(
                user.id(), currentSession, "OldPassword123", "abc")))
                .isInstanceOf(PasswordPolicyViolationException.class);
    }

    // Scenario: New password must differ from the current one
    @Test
    void newPasswordMustDifferFromCurrentOne() {
        assertThatThrownBy(() -> service.changePassword(new ChangePasswordCommand(
                user.id(), currentSession, "OldPassword123", "OldPassword123")))
                .isInstanceOf(PasswordSameAsCurrentException.class);
    }

    // Scenario: Other sessions end after a password change
    @Test
    void otherSessionsEndAfterPasswordChange() {
        service.changePassword(new ChangePasswordCommand(
                user.id(), currentSession, "OldPassword123", "ValidNewPassword456"));

        assertThat(sessions.findById(currentSession)).isPresent();
        assertThat(sessions.findById(otherSession)).isEmpty();
    }
}
