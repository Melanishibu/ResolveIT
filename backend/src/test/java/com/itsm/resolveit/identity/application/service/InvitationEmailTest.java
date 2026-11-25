package com.itsm.resolveit.identity.application.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.itsm.resolveit.identity.application.port.out.EmailSender.EmailMessage;
import com.itsm.resolveit.identity.domain.event.UserInvited;
import com.itsm.resolveit.identity.domain.model.DisplayName;
import com.itsm.resolveit.identity.domain.model.EmailAddress;
import com.itsm.resolveit.identity.domain.model.InvitationId;
import com.itsm.resolveit.identity.domain.model.InvitationToken;
import com.itsm.resolveit.identity.domain.model.Role;
import com.itsm.resolveit.identity.domain.model.UserId;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** RIT-US-06: the invitation email has the name, role and set-password link, and never a password. */
class InvitationEmailTest {

    // Scenario: Email never contains a password
    @Test
    void emailNeverContainsAPassword() {
        InvitationToken token = InvitationToken.generate();

        EmailMessage email = new InvitationEmail("http://localhost:5000/").compose(invited(token, Role.SUPPORT_AGENT));

        assertThat(email.to().value()).isEqualTo("asha@resolveit.local");
        assertThat(email.subject()).isEqualTo("Your ResolveIT account");
        assertThat(email.body())
                .contains("Hello Asha Rao")
                .contains("Technician")
                .contains("http://localhost:5000/set-password?token=" + token.value())
                .doesNotContain("ResolveIT-Dev-2026")
                .doesNotContainIgnoringCase("password:")
                .doesNotContainIgnoringCase("your password is");
        assertThat(email.toString()).doesNotContain(token.value());
    }

    @Test
    void employeesAreCalledEmployee() {
        EmailMessage email = new InvitationEmail("https://resolveit.example").compose(
                invited(InvitationToken.generate(), Role.EMPLOYEE));

        assertThat(email.body()).contains("with the role Employee").contains("https://resolveit.example/set-password?token=");
    }

    private static UserInvited invited(InvitationToken token, Role role) {
        return new UserInvited(new UserId(UUID.randomUUID()), new InvitationId(UUID.randomUUID()),
                new EmailAddress("asha@resolveit.local"), new DisplayName("Asha Rao"), role, token, UUID.randomUUID());
    }
}
